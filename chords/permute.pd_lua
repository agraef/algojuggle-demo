
inspect = require('inspect')

-- random permutation of chords

local permute = pd.class("permute")

function permute:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 1
   -- permutation of 0..3
   self.prm = {0,1,2,3}
   self.enable = false
   return true
end

function permute:in_1_float(note)
   local n = math.floor(note)-36
   if self.enable and n >= 0 and n <= 15 then
      -- this leaves banks and columns intact and just permutes the rows, with
      -- the MPC chord progressions presumably this makes sure that the chord
      -- relationships are somewhat similar
      local r, c = self.prm[n // 4 + 1], n % 4
      note = r*4 + c + 36
   end
   self:outlet(1, "float", {note})
end

function permute:in_2_float(f)
   self.enable = f ~= 0
end

-- helper function to pretty-print tables
local function print_table(t)
   local s = inspect(t)
   -- remove the outer braces
   s = string.sub(s, 3, #s-2)
   -- remove superflous commas around subtables
   s = string.gsub(s, "}, ", "} ")
   return s
end

function permute:in_2_bang()
   -- compute a new permutation
   local prm = {0,1,2,3}
   for i = 1, 3 do
      local j = math.random(i, 4)
      prm[i], prm[j] = prm[j], prm[i]
   end
   pd.post("permutation " .. print_table({prm[1]+1,prm[2]+1,prm[3]+1,prm[4]+1}))
   self.prm = prm
end
