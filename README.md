# synth-v-scripts
Scripts for the Synthesizer V program

Expressive 2 is a script for automatically adding curves to the parameters associated with notes in Syntheziser V. The motivation is that I find it easier to move spline control points than drawing control curves.

The script obviously can't automatically create a human performance, but it tries to create a reasonable starting place that can then be manually edited.

For each selected note, the script creates an “anchor” point at the start and end of the note, and then inserts a control point between the two. This allows the control point to be moved while the "anchor" points stay in place.

You can then manually adjust the parameters dragging a single control point. To do this, you’ll need to use the pointer tool in the parameter pane, not the pencil tool.

Curves are created for the following parameters:

* Loudness
* Tension
* Breathiness
* Gender

The default values for these parameters can be set in the dialog. The "Expression" parameter globally scales all the parameters.

The “Jitter” parameter determines how much the control point values are randomized.

The script pays attention to where a syllable falls into a word, as well as if it’s at the start or end of the phrase in setting parameters.

The "Gender" is used as a way to color the timbre of the note, adding variety to a sustained tone. For long notes followed by a long rest, the Gender parameter from the dialog box. For all other notes, the Gender parameter is scaled by 40%.
