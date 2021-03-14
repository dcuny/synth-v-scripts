# synth-v-scripts
**Scripts for the Synthesizer V program**

**Expressive 2**

_Expressive 2_ is a script for automatically adding curves to the parameters associated with notes in Syntheziser V. The motivation is that I find it easier to move spline control points than drawing control curves.

The script obviously can't automatically create a human performance, but it tries to create a reasonable starting place that can then be manually edited.

For each selected note, the script creates an “anchor” point at the start and end of the note, and then inserts a control point between the two. This allows the control point to be moved while the "anchor" points stay in place.

You can then manually adjust the parameters dragging a single control point. To do this, you’ll need to use the pointer tool in the parameter pane, not the pencil tool.

Curves are created for the following parameters:

* **Loudness**
* **Tension**
* **Breathiness**
* **Gender**

The default values for these parameters can be set in the dialog. The **"Expression"** parameter globally scales all the parameters.

**Jitter** determines how much the control point values are randomized.

The script pays attention to where a syllable falls into a word, as well as if it’s at the start or end of the phrase in setting parameters.

**Gender** is used color the timbre of the note, adding variety to a sustained tone. For long notes followed by a long rest, the Gender parameter from the dialog box. For all other notes, the **Gender** parameter is scaled by 40%.

"Long Notes" and "Long Rests" are by default to be a quarter note in duration. The value can be modifed by adjusting the **"Minimum Rest for Cadence (in 8th Notes)"**.

**Progressive Vibrato**

_Progressive Vibrato_ is a script for adding progressive vibrato to the selected notes. The rate of vibrato can increase as it builds, and the vibrato modulates the loudness.

Parameters are:

* **Start Vibrato Frequency** Initial vibrato rate
* **Final Vibrato Frequency** Target vibrato rate
* **Vibrato Depth** Target vibrato depth
* **"Vibrato Start Time** Delay between the onset of the note, and the onset of the vibrato
* **Vibrato Left Time** Time it takes the vibrato to reach maximum frequency, depth and amplitude
* **Vibrato Right Time** Time it takes the vibrato to decay at the end of the note
* **Vibrato Volume** Vibrato's effects on loudness
* **Use Note Defaults** If selected, uses the note's default **Final Vibrato Frequency**, **Vibrato Depth**, **Vibrato Start Time**, **Vibrato Left Time** and **Vibrato Right Time** instead of those in the dialog.

The script will also set the **Vibrato Depth** for the selected notes to zero, to prevent _Synthesizer V_ from applying the default vibrato to the note.

