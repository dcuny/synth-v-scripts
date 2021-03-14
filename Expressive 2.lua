SCRIPT_TITLE = "Expression Curves"

-- TODO: look at distance from prior note determine "effort"
-- TODO: note pitch should drive base tension
-- TODO: move positions, based on note length (shorter notes place positions sooner)

-- Default control point position
local loudPos						= .3
local tensionPos			 		= .85
local breathPos						= .45
local genderPos						= .65


-- Standard header
function getClientInfo()
  return {
    name = SV:T(SCRIPT_TITLE),
    author = "David Cuny",
    versionNumber = 1,
    minEditorVersion = 65537
  }
end




-- Internationalization
-- FIXME! Translated by Google, so likely to be badly translated
function getTranslations(langCode)
  if langCode == "ja-jp" then
    return {
		{"Expression Curves", "自動パラメータ曲線"},
		{"Maximum Loudness Change(in decibels)", "最大ラウドネス変化（デシベル単位）"},
		{"Maximum Tension Change", "最大張力変化"},
		{"Maximum Breath Change", "最大呼吸変化"},
		{"Maximum Gender Change", "最大の性別の変化"},
		{"Expression Amount", "式の量"},
		{"Jitter Amount", "ジッタ量"},
		{"Minimum Rest for Cadence (in 8th Notes)", "ケイデンスの最小休憩（8分音符）"},
    }
  end
  return {}
end

-- main function
function main()
	--[[
	-- perform localization
	local paramNameTranslated = {}
	for i = 1, #paramDispNames do
		-- SV:T() returns value from translation table
		paramNameTranslated[i] = SV:T(paramDispNames[i])
	end
	--]]

	-- create a form
	local form = {
		title = SV:T(SCRIPT_TITLE),
		message = "",
		buttons = "OkCancel",
		widgets = {
			-- loudness scaling
			{
				name = "loudScale",
				type = "Slider",
				label = SV:T("Maximum Loudness Change(in decibels)"),
				format = "%3.0f",
				minValue = -12,
				maxValue = 12,
				interval = 1,
				default = 5
			},			
			-- tension scaling
			{
				name = "tensionScale",
				type = "Slider",
				label = SV:T("Maximum Tension Change"),
				format = "%3.0f",
				minValue = -100,
				maxValue = 100,
				interval = 1,
				default = -25
			},			
			-- breath scaling
			{
				name = "breathScale",
				type = "Slider",
				label = SV:T("Maximum Breath Change"),
				format = "%3.0f",
				minValue = -100,
				maxValue = 100,
				interval = 1,
				default = 50
			},			
			-- gender scaling
			{
				name = "genderScale",
				type = "Slider",
				label = SV:T("Maximum Gender Change"),
				format = "%3.0f",
				minValue = -100,
				maxValue = 100,
				interval = 1,
				default = 25
			},			


			-- expression
			{
				name = "expression",
				type = "Slider",
				label = SV:T("Expression Amount"),
				format = "%3.0f",
				minValue = 1,
				maxValue = 100,
				interval = 5,
				default = 80
			},			
			-- jitter
			{
				name = "jitter",
				type = "Slider",
				label = SV:T("Jitter Amount"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 100,
				interval = 5,
				default = 0
			},			
			-- smallest rest
			{
				name = "minRest",
				type = "Slider",
				label = SV:T("Minimum Rest for Cadence (in 8th Notes)"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 16,
				interval = 1,
				default = 2
			},			

		}
	}

	-- render the dialog
	local results = SV:showCustomDialog(form)
  
	-- not cancelled?
	if results.status then
		-- pass parameters to buildArcs() function
		buildArcs(results.answers)
	end

	-- clean up and exit
	SV:finish()
end


-- Given an time in blicks, return the position of the next note's onset
-- returns *nil* if no following onset
function getNextOnset( at, onsets )
	for i, onset in ipairs( onsets ) do
		if onset >= at then
			-- return onset
			return onset
		end
	end
	-- no following note found, return nil
	return nil
end


-- Return a table of notes containing all the selected notes
function getSelectedRanges(options)
	-- get the selected items from the Editor object
	local selection = SV:getMainEditor():getSelection()
		
	-- get the selected notes from the selected items
	local selectedNotes = selection:getSelectedNotes()
	
	-- exit routine if no notes selected
	if #selectedNotes == 0 then
		return {}
	end
		
	-- sort the selectedNotes table based on onset time
	table.sort(selectedNotes, function(noteA, noteB)
		return noteA:getOnset() < noteB:getOnset()
	end)
	
	-- we need to build a table of all the note onsets in the track,
	-- in order to determine if a given note is followed by a rest
	local onsets = {}

	-- get the current track
	local track = SV:getMainEditor():getCurrentTrack()
	
	-- loop through all the groups in the track
	for i = 1, track:getNumGroups() do
		-- get the {NoteGroup} for the ith group
		noteGroup = track:getGroupReference(i):getTarget()
				
		-- loop through each note in the noteGroup
		for j = 1, noteGroup:getNumNotes() do
			-- insert the onset of the note into the onsets table
			table.insert( onsets, noteGroup:getNote(j):getOnset() )
		end
		
	end
	
	-- sort the onset table
	table.sort(onsets)
			
	-- holds the ranges
	local ranges = {}
	
	-- iterate through notes
	-- Note: this does *not* handle overlapping notes
	for i = 1, #selectedNotes do
		-- get the note
		local theNote = selectedNotes[i]
		
		-- get start of note in blicks
		local bStart = theNote:getOnset()
		local bEnd = theNote:getEnd()
		local lyric = theNote:getLyrics()
		newWord = (lyric ~= "+" and lyric ~= "-")

		-- get the position of the following note in groupNotes
		local nextOnset = getNextOnset( bEnd, onsets )
		
		-- a rest follows this note if there is no following note,
		-- or the onset of the next note is more than a quarter note away
		local restFollows = 
			(nextOnset == nil) or 
			(nextOnset - bEnd >= (SV.QUARTER * options.minRest / 2))
			
		-- save the values
		ranges[i] = {bStart, bEnd, restFollows, newWord}
		
	end
	
	-- return the ranges table for each selected note
	return ranges
end


-- Given *t* between (0..1), return a linearly interpolated value between (a..b)
function lerp( a, b, t )
	return a + (t * (b-a))
end


-- Insert anchor points into *am* at (bStart-offset) and (bEnd+offset).
function anchor( am, bStart, bEnd, offset )
	
	-- get the values to the left and right
	local origLeft, origRight = am:get(bStart - offset), am:get(bEnd + offset)
		
	-- set anchor to the left
	am:add(bStart - offset, origLeft)
	
	-- set anchor point to the right
	am:add(bEnd + offset, origRight)
		
	-- remove everything between
	am:remove(bStart, bEnd)
end

-- change a left anchor point
function changeLeftAnchor( am, position, value, offset )
	-- remove this note's left anchor
	am:remove(bStart)
	
	-- replace the prior note's anchor with the value
	am:add(position - offset, value)
end


-- return a value changed by *jitter* (0..1)
function jittered( value, jitter )
	local change = math.random() * (1-jitter)
	return value - (change * value)
end
			

-- Create an curve in *am* by setting anchor points at *bStart* and *bEnd*, and then placing
-- a control point at *controlPos* (a relative position from 0..1).
--
-- 	am				the parameter table to modify
--	bStart			start position of the note, in blicks
--  bEnd			end position of the note, in blicks
--  controlPos		relative position to place control point at between bStart and bEnd, from 0..1
-- 	scale			height to place control point at
--	step			offset position to place curve anchor points
-- 	jitter			percent of random jitter to apply
--	restFollows		if *true*, the note is followed by a rest
--  newWord			if *true* the note is the starting syllable of a word
--	priorEnd		position of last note, to determine if the note starts a new phrase

function createCurve( am, bStart, bEnd, controlPos, scale, step, jitter, restFollows, newWord, priorEnd )

	-- add anchors to note parameters
	anchor( am, bStart, bEnd, step )
	
	-- part of same syllable?
	if priorEnd == bStart then
		if newWord then
			-- use 50% of the scale, instead of starting at 0
			startAnchor = jittered( scale * .5, jitter )
		else
			-- use 75% of the scale, instead of starting at 0
			startAnchor = jittered( scale * .75, jitter )
		end
		
		-- change the left anchor to the new value
		changeLeftAnchor( am, bStart, startAnchor, step )	
	end

	-- calculate position of control point
	controlAt = lerp( bStart+step, bEnd-step, controlPos)
	
	if restFollows then 
		-- place the control point at the end of the note,
		-- so there's no ramp down within the note
		controlAt = bEnd-1 
	end
	
	-- insert the control point for the curve
	am:add(controlAt, jittered(scale, jitter) )

end




function buildArcs(options)

	-- get the current group from the main editor {NoteGroupReference}
	local scope = SV:getMainEditor():getCurrentGroup()
	
	-- get the target {NoteGroup}
	local group = scope:getTarget()
	
	-- call getSelectedRanges() to get the ranges
	local ranges = getSelectedRanges(options)

	-- get the {Automation} from the group by name
	local amLoudness = group:getParameter("loudness")
	local amTension = group:getParameter("tension")
	local amBreath = group:getParameter("breathiness")
	local amGender = group:getParameter("gender")
	
	-- distance to start the curve from the start/end of the note
	local density = 16
	local step = math.floor(SV.QUARTER / density)
	
	-- get parameters
	local scale = options.expression / 100
	local jitter = options.jitter / 100
	local loudScale = options.loudScale * scale
	local tensionScale = options.tensionScale / 100 * scale
	local breathScale = options.breathScale / 100 * scale
	local genderScale = options.genderScale / 100 * scale
	
	-- used to check if notes are connected
	-- FIXME: should probably be used in getSelectedRanges
	local priorEnd = nil
	
	-- iterate through the notes
	for i, r in ipairs(ranges) do
	
		-- get the start and end position of the notes
		-- as well as if a rest follows, and if it's a start of a new word
		local bStart = r[1]
		local bEnd = r[2]
		local restFollows = r[3]
		local newWordStart = r[4]
		
		-- locals
		local controlAt		
		local startAnchor

		-- scale adjusted if start of word
		local startWordScale = 1
		if newWord then
			startWordScale = 1.5
		end


		-- loudness Arc
		createCurve( amLoudness, bStart, bEnd, loudPos, startWordScale * loudScale, step, jitter, restFollows, newWord, priorEnd )

		-- tension arc		
		createCurve( amTension, bStart, bEnd, tensionPos, tensionScale, step, jitter, restFollows, newWord, priorEnd )

		-- breathiness arc		
		createCurve( amBreath, bStart, bEnd, breathPos, breathScale, step, jitter, restFollows, newWord, priorEnd )
		
		-- gender arc
		local reduceScale = 1
		if restFollows and (bEnd - bStart < SV.QUARTER) then
			-- not final, so reduce scale
			reduceScale = .4
		end	
		-- create the curve
		createCurve( amGender, bStart, bEnd, genderPos, genderScale * reduceScale, step, jitter, restFollows, newWord, priorEnd )

		-- save end position of prior
		priorEnd = bEnd

	end
end
