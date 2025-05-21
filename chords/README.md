# chords patch

This is a little patch to record chord progressions and play them back. Four sample banks of chords are included, I captured these from the Jazz 05, Jazz 07, Jazz 08, and Jazz 09 chord progressions on my MPC which I often use for demonstration purposes. Additional banks can be created with the recording feature, see below. You can also remove the chords.txt file to get rid of these sample banks and start recording your own progressions from scratch.

**Note:** The patch uses the `drip` object from the zexy external library to output note data, so if you're using vanilla Pd then you may have to install that library via Deken.

## MIDI Setup

For recording, you can input the chords with any MIDI device connected to any of Pd's MIDI input ports, on any MIDI channel.

For controlling playback, controller input is expected on channel 9 by default (this can be changed in the patch). The patch has been set up so that it will work with the usual kind of drum pad controllers with at least two 4x4 drum grids. If you have some kind of Novation Launchpad device, it's easy to set up a custom mode which will do this, but most drum pad devices with at least two 4x4 grids should work, if you can set it to the expected MIDI channel. If you're using a different kind of MIDI controller and you know how to program in Lua, you can adjust the input processing in the in_1_float() method in chordprog.pd_lua as needed.

MIDI output goes to the MIDI channel set with the "channel" number atom in the patch. Note that you will first have to set this to a positive number, otherwise MIDI output will be suppressed. You can also use the toggle above the "channel" number atom to quickly switch between MIDI output on channel 1 and no MIDI output.

In addition, the generated MIDI note data will also be sent to the following global receivers for internal processing in other patches loaded alongside the chords.pd patch:

- `all-notes`: This receives note data as 3-element lists consisting of note number, velocity, and channel.
- `all-arp`: This is similar to `all-notes`, but is intended to be used with the author's [Raptor7](https:/
  /github.com/agraef/raptor7) arpeggiator. It thus uses the global `all-arp` receiver of the Raptor7 patch and sends note messages in the [SMMF](https://bitbucket.org/agraef/pd-smmf/) format understood by this patch.

The note data sent to the receivers is the same as the direct MIDI output, using the last nonzero channel number set with the "channel" number atom, or 1 by default. However, note data sent to the receivers will keep running even if direct MIDI output is suppressed by setting the  "channel" number to 0.

## Recording

To create a new bank of chords, type its name into the left symbol atom, enable the "rec" toggle, and start recording chords as follows: For each chord, first type its name into the right symbol atom, then play the chord on any connected MIDI device. Repeat these two steps as needed, giving each chord a new name, then disable "rec". The new bank is now ready to be played back, see below. It is also stored as a Lua table in the chords.txt  file so that it can be reloaded next time the patch is opened.

During operation, the patch will also give some textual feedback about status changes (enabling and disabling of "rec" mode) and recorded chords in the Pd console.

**Note:** At present, it is only possible to record the chords in sequence. However, you can record the same chord multiple times to correct mistakes, as long as you don't change the chord name. On the other hand, this implies that you can't record two different adjacent chords under the same name, since a subsequent chord will overwrite the previous one unless you change the chord name. If you seriously mess up, just keep on recording anyway; it is always possible to edit chords.txt as needed later (this is a normal text file and can thus be edited with any text editor; just make sure that you don't mess up the [Lua table syntax](https://www.lua.org/manual/5.4/manual.html#3.4.9)).

## Playback

As explained above, playback is assumed to take input from a pad controller on MIDI channel 9. Notes 36..51 (the first bank on a typical pad controller) recall chords 1..16 from the current bank, and you can switch banks with notes 52..59 (the lower half of the second pad bank). This allows you to access the first 16 chords of up to eight banks of chords. When playing each chord, the patch also shows the current bank and the name of the chord in the left and right symbol atoms in the patch. The patch will also give some textual feedback in the Pd console when switching chord banks.

In addition, notes 60..63 (which will be the third row of the second bank on a typical pad controller, counting pad rows from the bottom) can be used for transposing the output by octaves (note 60 - down, note 61 - up) and semitones (note 62 - down, note 63 - up). You can also do this with the corresponding number atoms labeled "oct" and "semi" in the patch (which will also show the values entered from the controller).

All chord notes will play at the same velocity given by the velocity with which you hit the pad on the first bank, and they will last as long as you keep pressing that pad (or press another pad to recall a different chord, whichever happens first).

The launchpad subdirectory includes some ready-made custom modes for the current generation of Novation Launchpad controllers (X, Pro MK3, and Mini MK3) which also include layouts for playing back chords using the note assignment described above. Please check the corresponding [README](../launchpad/README.md) file for details.