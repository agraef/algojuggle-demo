
-- This is a little convenience object to transpose incoming notes (inlet #1:
-- note numbers, inlet #2: velocities) by a given amount of semitones (inlet
-- #3) and octaves (inlet #4). Output goes to outlet #1 (note numbers) and #2
-- (velocities). The only tricky thing here is that in order to prevent
-- hanging notes we have to defer transposition changes until the note-offs
-- for previous notes have been processed.

local transpose = pd.class("transpose")

function transpose:initialize(sel, atoms)
   self.inlets = 4
   self.outlets = 2
   -- transposition (octaves, semitones, total)
   self.oct, self.semi, self.transp = 0, 0, 0
   -- last velocity
   self.vel = 0
   return true
end

function transpose:in_1_float(note)
   local transp = 12*self.oct + self.semi
   -- defer transp update until all note-offs have been processed
   if self.transp ~= transp and self.vel > 0 then
      self.transp = transp
   end
   self:outlet(2, "float", {self.vel})
   self:outlet(1, "float", {note+self.transp})
end

function transpose:in_2_float(vel)
   self.vel = vel
end

function transpose:in_3_float(semi)
   self.semi = semi
end

function transpose:in_4_float(oct)
   self.oct = oct
end
