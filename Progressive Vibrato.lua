SCRIPT_TITLE = "Progressive Vibrato"

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
-- Note: Translated via Google, may not be accurate
function getTranslations(langCode)
  if langCode == "ja-jp" then
    return {
		{"Start Vibrato Frequency", "ビブラート周波数を開始"},
		{"Vibrato Depth", "ビブラートの深さ"},
		{"Vibrato Start Time", "ビブラート開始時間"},
		{"Vibrato Left Time", "ビブラート左時間"},
		{"Vibrato Right Time", "ビブラートの適切なタイミング"},
		{"Vibrato Volume", "ビブラートボリューム"},
		{"Use Note Defaults", "ノートのデフォルトを使用"},
    }
  end
  
  -- no options found
  return {}
end

-- main function
function main()

	-- create a form
	local form = {
		title = SV:T(SCRIPT_TITLE),
		message = "",
		buttons = "OkCancel",
		widgets = {
			-- vibrato start frequency slider
			{
				name = "vibStartFrq",
				type = "Slider",
				label = SV:T("Start Vibrato Frequency"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 100,
				interval = 1,
				default = 55
			},			
			-- vibrato depth
			{
				name = "vibDepth",
				type = "Slider",
				label = SV:T("Vibrato Depth"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 20,
				interval = 1,
				default = 10
			},			
			-- vibrato start slider
			{
				name = "vibStart",
				type = "Slider",
				label = SV:T("Vibrato Start Time"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 600,
				interval = 10,
				default = 20
			},			
			-- vibrato ramp up slider
			{
				name = "vibLeft",
				type = "Slider",
				label = SV:T("Vibrato Left Time"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 400,
				interval = 10,
				default = 20
			},			
			-- vibrato ramp down slider
			{
				name = "vibRight",
				type = "Slider",
				label = SV:T("Vibrato Right Time"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 200,
				interval = 10,
				default = 20
			},			
			-- volume slider
			{
				name = "vibLoudScale",
				type = "Slider",
				label = SV:T("Vibrato Volume"),
				format = "%3.0f",
				minValue = 0,
				maxValue = 60,
				interval = 1,
				default = 20
			},			
			-- use note defaults
			{
				name = "useNoteDefaults",
				type = "CheckBox",
				text = SV:T("Use Note Defaults"),
				default = false
			}
		}
	}

	-- render the dialog
	local results = SV:showCustomDialog(form)
  
	-- not cancelled?
	if results.status then
		-- pass values to the progressiveVibrato() function
		progressiveVibrato(results.answers)
	end

	-- clean up and exit
	SV:finish()
end

-- Get an array of blick ranges for connected notes in the selection
function getSelectedRanges(options)

	-- get the selected items from the Editor object
	local selection = SV:getMainEditor():getSelection()
		
	-- get the selected notes from the selected items
	local selectedNotes = selection:getSelectedNotes()
	
	-- exit routine if no notes selected
	if #selectedNotes == 0 then
		return {}
	end
	
	-- get the voice, if default values are needed
	local voice = SV:getMainEditor():getCurrentGroup():getVoice()
	
	-- sort notes based on onset time
	table.sort(selectedNotes, function(noteA, noteB)
		return noteA:getOnset() < noteB:getOnset()
	end)

	-- holds the ranges
	local ranges = {}
		
	-- TimeAxis:getBlickFromSeconds(t) → {number}
	-- TimeAxis:getSecondsFromBlick(b) → {number}
	-- Project:getTimeAxis() → {TimeAxis}
	-- SV:getProject() → {Project}

	-- If attribute is NIL, need to look in the Voice to find the value
	-- NoteGroupReference:getVoice() {object}
    -- tF0Left: number pitch transition - duration left (seconds)
    -- tF0Right: number pitch transition - duration right (seconds)
    -- dF0Left: number pitch transition - depth left (semitones)
    -- dF0Right: number pitch transition - depth right (semitones)
    -- tF0VbrStart: number vibrato - start (seconds) default = .250
    -- tF0VbrLeft: number vibrato - left (seconds) default = .20
    -- tF0VbrRight: number vibrato - right (seconds) default = .20
    -- dF0Vbr: number vibrato - depth (semitones) default = 1.0
    -- fF0Vbr: number vibrato - frequency (Hz) default = 5.5
    -- paramLoudness: number parameters - loudness (dB) default = 0.0
    -- paramTension: number parameters - tension default = 0.0
    -- paramBreathiness: number parameters - breathiness default = 0.0
    -- paramGender: number parameters - gender default = 0.0


	-- FIXME: Note left and right transitions don't appear to be used in
	--        in the vibrato calcuations, so they are commented out for note

	local timeAxis = SV:getProject():getTimeAxis()
		
	-- iterate through notes, don't handle overlapping notes properly
	for i = 1, #selectedNotes do
		-- get the note
		local theNote = selectedNotes[i]

		-- get the note attributes
		local theNoteAttribs = theNote:getAttributes()
		
		-- get start of note in blicks, convert to seconds
		local bStart = theNote:getOnset()
		local tStart = timeAxis:getSecondsFromBlick( bStart )

		-- get the vibrato offset in seconds from the attributes
		local tF0VbrStart = theNoteAttribs.tF0VbrStart or voice.tF0VbrStart or 0.250
		
		-- use dialog option instead?
		if not options.useNoteDefaults then
			-- get the value from the dialog
			tF0VbrStart = options.vibStart / 100
		end

		-- add left offset to get start of vibrato
		local tVibStart = tStart + tF0VbrStart
		local bVibStart = timeAxis:getBlickFromSeconds( tVibStart )
							
		-- get the end from the note
		local bEnd = theNote:getEnd()
		local tEnd = timeAxis:getSecondsFromBlick( bEnd )
				
		-- use dialog option instead?
		if not options.useNoteDefaults then
			-- get the value from the dialog 
			tF0VbrEnd = options.vibRight / 100
		end

		-- vibrato depth
		local vibDepth = theNoteAttribs.dF0Vbr or voice.dF0Vbr or 1
		
		-- if vibDepth parameter has been turned off, set to 1
		if vibDepth == 0 then
			vibDepth = voice.dF0Vbr or 1
		end

		vibDepth = vibDepth * 1.4 / 10
		if not options.useNoteDefaults then
			-- use the value from the dialog 
			vibDepth = options.vibDepth * 1.4 / 100
		end
		
		-- vibrato frequency
		local vibFrq = theNoteAttribs.fF0Vbr or voice.fF0Vbr or 5.5
		
		-- vibrato phase
		local vibPhase = theNoteAttribs.pF0Vbr or voice.pF0Vbr or 0
		
		-- vibrato left
		local vibLeft = theNoteAttribs.tF0VbrLeft or voice.tF0VbrLeft or 0.20
		if not options.useNoteDefaults then
			-- use the value from the dialog 
			vibLeft = options.vibLeft / 100
		end

		-- vibrato right
		local vibRight = theNoteAttribs.tF0VbrRight or voice.tF0VbrRight or 0.20
		if not options.useNoteDefaults then
			-- use the value from the dialog 
			vibRight = options.vibRight / 100
		end
		
		-- save the values
		ranges[i] = {bStart, bEnd, tStart, tEnd, bVibStart, tVibStart, vibDepth, vibFrq, vibPhase, vibLeft, vibRight}
		
		-- set the note vibrato depth to zero
		theNote:setAttributes({dF0Vbr=0})
		
	end
	
	-- return the ranges table for each selected note
	return ranges
end


function progressiveVibrato(options)
	-- get the current group from the main editor {NoteGroupReference}
	local scope = SV:getMainEditor():getCurrentGroup()
	
	-- get the target {NoteGroup}
	local group = scope:getTarget()
	
	-- call getSelectedRanges() to get the ranges
	local ranges = getSelectedRanges(options)

	-- get the {Automation} for pitchDelta
	local amPitch = group:getParameter("pitchDelta")

	-- get the {Automation} for loudness
	local amLoud = group:getParameter("loudness")
	
	-- vibrato envelope automation
	local amVibEnvelope = SV:create("Automation", "vibratoEnv")
		
	local step = math.floor(SV.QUARTER / 64 )
	
	-- iterate through the ranges
	for i, r in ipairs(ranges) do
	
		-- read the parameters
		local bStart = r[1]
		local bEnd = r[2]
		local tStart = r[3]
		local tEnd = r[4]
		local bVibStart = r[5]
		local tVibStart = r[6]
		local vibDepth = r[7] * 50 -- FIXME
		local vibFrq = r[8]
		local vibPhase = r[9]
		local vibLeft = r[10]
		local vibRight = r[11]
				
		-- amount vibrato changes amplitude
		local vibLoudScale = options.vibLoudScale / 1000
	
		-- get the values to the left and right
		local origLeft, origRight = amPitch:get(bStart - step), amPitch:get(bEnd + step)
		
		-- set anchor to the left and right
		amPitch:add(bStart - step, origLeft)
		amPitch:add(bEnd + step, origRight)
		
		-- remove everything between
		amPitch:remove(bStart, bEnd)
		
		-- get the loudness values to the left and right
		local origLeft, origRight = amLoud:get(bStart - step), amLoud:get(bEnd + step)
		
		-- set anchor to the left and right
		amLoud:add(bStart - step, origLeft)
		amLoud:add(bEnd + step, origRight)
		
		-- remove everything between
		amLoud:remove(bStart, bEnd)

		-- clear vibrato envelope
		amVibEnvelope:add(bStart - step, 0)
		amVibEnvelope:add(bEnd + step, 0)
		amVibEnvelope:remove(bStart, bEnd)	
		
		-- vibrato width
		bVibWidth = bEnd - bVibStart
		tVibWidth = tEnd - tVibStart
		
		-- phase change per blick
		local totalRadians = math.pi * 2 * tVibWidth * vibFrq
		local totalSteps = bVibWidth / step
		local radiansPerStep = totalRadians / totalSteps
		
		-- ramp up per step
		local ratio = math.min( vibLeft / tVibWidth, 1.0 )
		local rampUpSteps = math.floor(totalSteps * ratio)
		local rampUpDelta = vibDepth/rampUpSteps

		-- ramp down
		ratio = math.min( vibRight / tVibWidth, 1.0 )
		local rampDownSteps = math.floor(totalSteps * ratio)
		local rampDownCounter = math.floor(totalSteps * (1-ratio))
		
		-- initial radians
		local startRadians = math.pi * 2 * tVibWidth * (options.vibStartFrq/10)
		local startRadiansPerStep = startRadians / totalSteps
		
		-- rate of change for radian step
		local phaseDelta = (radiansPerStep-startRadiansPerStep) / rampUpSteps
		
		-- get start position
		local b = bVibStart
				
		-- advance until past end
		local envelope = 0
		local phaseRate = startRadiansPerStep
		local rampDownDelta = 0
		while b < bEnd do
			
			-- calculate height of vibrato
			local value = math.sin(vibPhase)*vibDepth*envelope

			-- insert into pitch and amplitude parameters
			amPitch:add(b, value)
			
			-- vibrato modulates the amplitude, but only in the positive direction
			amLoud:add(b, math.abs(value * vibLoudScale) )

			-- advance by step size
			b = b + step
			vibPhase = vibPhase + phaseRate
			
			-- ramp up?
			if rampUpSteps < 0 then
				-- envelope = 1
				phaseRate = radiansPerStep
			else
				-- increase the amplitude envelope
				envelope = envelope + rampUpDelta
				-- increase the phase
				phaseRate = phaseRate + phaseDelta
				-- decrement the number of ramp up steps remaining
				rampUpSteps = rampUpSteps - 1
			end
			
			-- decrement ramp down counter
			rampDownCounter = rampDownCounter - 1
			if rampDownCounter == -1 then
				-- determine rate of change for envelope
				rampDownDelta = envelope / rampDownSteps
			elseif rampDownCounter < 0 then
				-- reduce envelope
				envelope = math.max( envelope - rampDownDelta, 0 )
			end
			
			
		end
	end
end