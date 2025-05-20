
inspect = require('inspect')

local chordprog = pd.class("chordprog")

function chordprog:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 3
   self.prog = "Untitled"
   self.name = "Unnamed"
   self.progno = 1
   self.chordno = 1
   self.chord = {}
   self.chords = {}
   -- last velocity
   self.vel = 0
   -- state: 0 = play, 1 = record
   self.state = 0
   -- transposition by octaves and semitones
   self.oct = 0
   self.semi = 0
   -- read an existing chord table
   self:load()
   return true
end

function chordprog:save()
   if self.chords[self.progno] and self.chords[self.progno].prog ~= self.prog then
      -- add a new progression
      self.progno = #self.chords + 1
      self.chords[self.progno] = { prog = self.prog, chords = {} }
      self.chordno = 1
   elseif not self.chords[self.progno] then
      -- create a progression
      self.chords[self.progno] = { prog = self.prog, chords = {} }
   end
   if self.chords[self.progno].chords[self.chordno] and self.chords[self.progno].chords[self.chordno].name ~= self.name then
      -- add a new chord
      self.chordno = #self.chords[self.progno].chords + 1
      self.chords[self.progno].chords[self.chordno] = { name = self.name, chord = self.chord }
   else
      -- create a chord, or overwrite an existing one
      self.chords[self.progno].chords[self.chordno] = { name = self.name, chord = self.chord }
   end
   -- save to file
   local fp = io.open(self._canvaspath .. "chords.txt", "w")
   fp:write(inspect(self.chords))
   fp:close()
end

function chordprog:load()
   local fp = io.open(self._canvaspath .. "chords.txt", "r")
   local s = fp and fp:read("a")
   local f = s and load("return " .. s)
   -- get the chords table; TODO: we should probably do some sanity checking
   local chords = f and f()
   if chords and type(chords) == "table" then
      self.chords = chords
   end
end

function chordprog:in_1_rec(args)
   if type(args[1]) == "number" then
      self.state = args[1] ~= 0 and 1 or 0
      pd.post("chordprog: " .. (self.state==1 and "recording" or "playing"))
   else
      self:error("chordprog: rec: expected number (0 or 1), got " .. tostring(args[1]))
   end
end

function chordprog:in_1_symbol(s)
   self.prog = s
   --pd.post("prog: " .. s)
end

function chordprog:in_2_symbol(s)
   self.name = s
   --pd.post("name: " .. s)
end

function chordprog:end_chord()
   if self.last_chord then
      self:outlet(3, "float", {0})
      self:outlet(2, "list", self.last_chord)
      self.last_chord = nil
   end
end

function chordprog:start_chord(chord, vel, prog, name)
   -- first end the last chord if any
   self:end_chord()
   -- remember the new chord so that we can turn it off again later
   self.last_chord = chord
   -- now play the new chord
   self:outlet(3, "float", {vel})
   self:outlet(2, "list", chord)
   self:outlet(1, "list", {prog, name})
end

function chordprog:in_1_float(note)
   if self.state > 0 then
      -- record
      if self.vel > 0 then
	 -- add note to chord
	 table.insert(self.chord, math.floor(note))
      elseif #self.chord > 0 then
	 -- save chord
	 self:save()
	 pd.post(string.format("chordprog: recorded %s %s %s", self.chords[self.progno].prog, self.chords[self.progno].chords[self.chordno].name, inspect(self.chords[self.progno].chords[self.chordno].chord)))
	 --pd.post("chords: " .. inspect(self.chords))
	 -- reset chord, start recording next chord
	 self.chord = {}
      end
   elseif self.vel > 0 then -- play
      -- NOTE: We assume a standard 4x4 grid of pads starting at note 36 here
      local n = math.floor(note)-35
      if n >= 1 and n <= 16 then
	 if self.chords[self.progno] and self.chords[self.progno].chords[n] then
	    -- start chord
	    self:start_chord(self.chords[self.progno].chords[n].chord, self.vel, self.chords[self.progno].prog, self.chords[self.progno].chords[n].name)
	 end
      elseif n >= 17 and n <= 24 then
	 -- next 8 pads let you choose the bank
	 n = n-16
	 if self.chords[n] then
	    self.progno = n
	    pd.post("chordprog: switch to bank " .. n .. ": " .. self.chords[n].prog)
	 else
	    pd.post("chordprog: bank " .. n .. " is empty")
	 end
      elseif n >= 25 and n <= 28 then
	 -- next 4 pads transpose by octaves (down/up) and semitones (down/up)
	 if n == 25 then
	    self.oct = self.oct - 1
	    self:outlet(1, "oct", {self.oct})
	 elseif n == 26 then
	    self.oct = self.oct + 1
	    self:outlet(1, "oct", {self.oct})
	 elseif n == 27 then
	    self.semi = self.semi - 1
	    self:outlet(1, "semi", {self.semi})
	 elseif n == 28 then
	    self.semi = self.semi + 1
	    self:outlet(1, "semi", {self.semi})
	 end
      end
   else
      -- end the last chord if any
      self:end_chord()
   end
end

function chordprog:in_2_float(vel)
   self.vel = vel
end
