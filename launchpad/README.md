# Custom Launchpad modes for the algojuggle and chord patches

There are two different custom modes, one pair (custom modes 1 and 3) for the Launchpad Mini MK3, and functionally equivalent pairs (custom modes 5 and 6) for the Launchpad X and the Launchpad Pro MK3:

- lpmini-algojuggle1.syx, lpmini-algojuggle3.syx: custom modes 1+3 for the Launchpad Mini MK3

- lpx-algojuggle5.syx, lpx-algojuggle6.syx: custom modes 5+6 for the Launchpad X

- lppro-algojuggle5.syx, lppro-algojuggle6.syx: custom modes 5+6 for the Launchpad Pro MK3


**Note:**  These are sysex (system exclusive) files which can be transferred to your device with any sysex librarian or other program with sysex transfer capability, such as Christoph Eckert's [Simple Sysexxer](https://sourceforge.net/projects/sysexxer/) on Linux, snoize's [SysEx Librarian](https://www.snoize.com/SysExLibrarian/) on the Mac, or [MIDI-OX](http://www.midiox.com/) on Windows. See, e.g., the [Sweetwater Knowledge Base](https://www.sweetwater.com/sweetcare/articles/how-do-i-send-and-receive-sysex-on-pc-or-mac/) for details. Make sure that you pick the right files for the type of device that you have, otherwise they will fail to load. You may also want to back up your existing custom modes on the device with the Novation Components software first.

Here's how the custom modes look on the LP X, mode 5 on the left, mode 6 on the right (corresponding modes for the LP Pro and Mini MK3 will look pretty much the same):

![lpx-algojuggle](lpx-algojuggle.png)

## Drumpad Mode (LP Mini mode 1, LP X/Pro mode 5)

Mode 1/5 (left image) is a modified drum pad layout, with pad banks 1 and 2 (starting at notes 36 and 52, from bottom to top, colored yellow and rose) on the left, and pad banks 3 and 4  (starting at notes 68 and 84, colored blue and green) on the right. These are all laid out as the usual MPC-style 4x4 grids, with the lowest note in the lower left corner. All pad banks emit notes on MIDI channel 10 (the General MIDI drumkit channel), with pad banks 1-3 covering most of the GM drumkit. Bank 4 (the green one) has a special meaning in the algojuggle-ex patch, controlling various performance functions (as described in the toplevel [README](../README.md)). Also, this bank has the special tempo and start pads, in the second-highest row on the right, marked gray and white.

## Drumpad/Chords Mode (LP Mini mode 3, LP X/Pro mode 6)

Mode 3/6 (right image) is a heavily customized layout with drum pads on the right, and a collection of chord-related pads on the left. The yellow and green 4x4 grids on the right are the same as bank 1 and 4 on the drumpad mode and their function is identical. However, the yellow bank is extended one note down with the yellow pad to the left of the grid, to give you an additional note 35 (acoustic bass drum in the GM drumkit). In addition, there's a green pad in the bottom left corner which lets you toggle MIDI sync in the algojuggle-ex patch. This pad turns red when pushed, to indicate that MIDI sync is on.

The remaining pads in the topmost 7 rows on the left side are used to operate the chords patch. These all emit notes on channel 9 which is the MIDI channel the chords patch listens on when it is in its default playback mode, please check the [chords README](../chords/README.md) for details. The pink 4x4 grid at the top is used to play chords from the current chord bank. The 8 cyan pads below the chord pads are used to select 8 different banks of chords. Below that are two deep blue pads to transpose the chords by octaves (down/up) and two rose pads to transpose by semitones (down/up). The current amount of octave and semitone transposition is shown in the corresponding numboxes in the chords patch.
