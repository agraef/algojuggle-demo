
inspect = require('inspect')

-- random permutation of chords

local permute = pd.class("permute")

function permute:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 1
   -- row and column permutations of 0..3
   self.rp = {0,1,2,3}
   self.rc = {0,1,2,3}
   -- mode (0 = none, 1 = row, 2 = column, 3 = both)
   self.mode = 0
   return true
end

function permute:in_1_float(note)
   local n = math.floor(note)-36
   if self.mode > 0 and n >= 0 and n <= 15 then
      -- this leaves the banks intact and just permutes the row and column
      -- indices separately in order to maintain chord relationships to some
      -- extent (at least when using the MPC chord progressions)
      local r, c = n // 4, n % 4
      if self.mode & 1 ~= 0 then
	 r = self.rp[r+1]
      end
      if self.mode & 2 ~= 0 then
	 c = self.cp[c+1]
      end
      note = r*4 + c + 36
   end
   self:outlet(1, "float", {note})
end

function permute:in_2_float(f)
   self.mode = math.floor(f)
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

local function random_permutation(t)
   local n = #t
   for i = 1, n-1 do
      local j = math.random(i, n)
      t[i], t[j] = t[j], t[i]
   end
   return t
end

function permute:in_2_bang()
   -- compute new permutations
   self.rp = random_permutation({0,1,2,3})
   self.cp = random_permutation({0,1,2,3})
   pd.post("permutation row " .. print_table({self.rp[1]+1,self.rp[2]+1,self.rp[3]+1,self.rp[4]+1}) .. ", col " .. print_table({self.cp[1]+1,self.cp[2]+1,self.cp[3]+1,self.cp[4]+1}))
end
