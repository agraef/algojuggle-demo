
local midiset = pd.class("midiset")

-- 4 preset patterns, adjust as needed
local pats = {{5,3,4}, {4,4,1}, {5,3}, {5,5,5,1,4}}

-- site swaps, adjust as needed
local swaps = {{1,2}, {2,3}, {3,4}, {4,5},
   {1,3}, {2,4}, {3,5}, {4,6},
   {1,4}, {2,5}, {3,6}, {4,7}}

-- tempos (bpm), adjust as needed
local tempos = {30, 60, 90, 120, 180, 240, 360, 480}

-- the object takes 0, 1, or 2 args: [ch [outch]]
-- ch = MIDI input channel (default: omni)
-- outch = MIDI output channel (default: same as last input note)
function midiset:initialize(sel, atoms)
   self.inlets = 3
   self.outlets = 3
   self.notes = {}
   self.noteon = {}
   self.vel, self.chan = 0, 10
   self.tempo_index = 4
   self.sel = 0
   self.looper = false
   self.prefix = {80,120}
   -- parse creation arguments
   local args = {}
   for i = 1, #atoms do
      if type(atoms[i]) == "number" then
	 args[i] = math.floor(atoms[i])
      else
	 break
      end
   end
   if #args >= 1 then
      self.filter_ch = args[1] > 0 and args[1] or nil
      self.out_chan = args[2] and args[2] > 0 and args[2] or nil
   end
   self.init = true
   return true
end

function midiset:in_3_float(x)
   self.chan = math.floor(x)
end

function midiset:in_2_float(x)
   self.vel = math.floor(x)
end

-- pads -> tempos in sel mode
local bpmsel = {[92] = 3, [93] = 4, [96] = 5, [97] = 6, [98] = 7, [99] = 8}

function midiset:tempo_change(d)
   self.tempo_index = self.tempo_index + d
   if self.tempo_index <= 0 then
      self.tempo_index = 1
   elseif self.tempo_index > #tempos then
      self.tempo_index = #tempos
   end
   self:outlet(1, "bpm", {tempos[self.tempo_index]})
end

-- Kludge: check for multiple note events at the same logical time to prevent
-- multiple mutes/unmutes in quick succession when playing a chord
function midiset:timecheck()
   local delta = self.systime and pd.timesince(self.systime) or pd.systime()
   self.systime = pd.systime()
   -- we arbitrarily use a threshold value of 50 msec here to mean "now"
   return delta > 50
end

function midiset:in_1_float(x)
   local note = math.floor(x)
   local vel, chan = self.vel, self.chan
   if chan == 10 and note >= 84 and note <= 99 then
      -- upper plane (notes 84..99) of a 8x8 grid
      -- we use 84..93 for site swaps and 96..99 for pattern presets
      -- 95 toggles the metronome (play/stop), 94 selects tempo (bpm)
      if vel > 0 then
	 if self.sel > 0 then
	    -- tempo selection
	    local tempo_index = bpmsel[note]
	    if tempo_index then
	       -- tempo + pad, change to given tempo
	       self.tempo_index = tempo_index
	       self:tempo_change(0)
	    elseif note == 95 then
	       -- tempo + play/stop button, select previous tempo
	       self:tempo_change(-1)
	    elseif note <= 87 then
	       -- emulate the roller/looper strip of the Beatstep Pro
	       self.looper = true
	       local rate = {25, 50, 75, 100}
	       self:outlet(1, "loop", {rate[note-83]})
	    elseif note == 88 then
	       -- reset
	       self:outlet(1, "reset", {})
	    elseif note == 89 then
	       -- default velocities
	       self:in_1_prefix()
	    elseif note <= 91 then
	       -- mute (per channel)
	       -- XXXFIXME: This should really be configurable, but currently
	       -- we have no way of knowing which channels are being used in
	       -- other instances. So instead we use pad 91 to mute channel 10
	       -- (the drum channel) and pad 90 to mute any other channel.
	       if not self.filter_ch or
		  note == 91 and self.filter_ch == 10 or
		  note == 90 and self.filter_ch ~= 10 then
		  if self:timecheck() then
		     -- mute/unmute
		     self:outlet(1, "mute", {})
		  end
	       end
	    end
	    self.sel = 2
	 elseif note >= 96 then
	    self:outlet(1, "list", pats[note-95])
	 elseif note == 94 then
	    -- start selection mode
	    self.sel = 1
	 elseif note == 95 then
	    self:outlet(1, "metro", {})
	 else
	    -- site swaps
	    pd.post("swap " .. table.concat(swaps[note-83], " "))
	    self:outlet(1, "swap", swaps[note-83])
	 end
      elseif self.sel > 0 and note == 94 then
	 if self.sel == 1 then
	    -- no previous selection, select next tempo
	    self:tempo_change(1)
	 end
	 -- stop selection mode
	 self.sel = 0
	 -- also make sure to stop the looper to prevent it from hanging if
	 -- the user happens to release the tempo pad before the looper pad
	 if self.looper then
	    self.looper = false
	    self:outlet(1, "loop", {0})
	 end
      elseif self.sel > 0 and note <= 87 then
	 -- emulate the roller/looper strip of the Beatstep Pro
	 self.looper = false
	 self:outlet(1, "loop", {0})
      end
   elseif self.filter_ch and self.chan ~= self.filter_ch then
      -- ignore
      if self.sel > 0 then
	 self.sel = 2
      end
--[[ -- gets in the way when using sequencing, disabled for now
   elseif self.sel > 0 then
      if vel > 0 and self:timecheck() then
	 -- mute/unmute
	 self:outlet(1, "mute", {})
	 self.sel = 2
      end
]]
   elseif vel > 0 and not self.noteon[note] then
      self.noteon[note] = true
      table.insert(self.notes, note)
      local chan = self.out_chan and self.out_chan or self.chan
      self:outlet(3, "float", {chan})
      self:outlet(2, "list", {self.prefix[1], self.prefix[2], table.unpack(self.notes)})
   elseif vel == 0 and self.noteon[note] then
      self.noteon[note] = nil
      for k,_ in pairs(self.noteon) do
	 -- latch mode still on, bail out
	 return
      end
      -- no notes left, turn off latched notes
      self.notes = {}
   end
end

function midiset:in_1_prefix(atoms)
   self.prefix = atoms and #atoms >= 1 and atoms or {80,120}
   if #self.prefix <= 1 then
      self.prefix[2] = self.prefix[1]
   end
   if self.init then
      self:outlet(2, "list", self.prefix)
   end
end
