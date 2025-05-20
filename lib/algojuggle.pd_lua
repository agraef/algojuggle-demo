
-- Copyright (c) 2025 by Albert Gräf, Sophia Renz, license: GPLv3+

inspect = require('inspect')

-- Cycle through list elements, creating the illusion of an infinite cyclic
-- list which wraps around at the end.
local function cycle(list, i)
   i = (i-1) % #list + 1
   return list[i]
end

-- Analyze a juggling pattern given as a (cyclic) list of values (positive
-- integers) k1, k2, ...  Returns two lists pat (indexed by positions p) and
-- objs (indexed by object numbers i). pat is the resulting (cyclic) juggling
-- sequence, which for each position p gives the object i which is due at that
-- position, and the corresponding value k which indicates the number of
-- positions until the object is due again. For each object i, objs[i] lists
-- the sequence of values which make up the object's cycle.

-- Note that #objs gives the total number of objects in pat, and summing up
-- the values in objs[i] gives the total length of the cycle of object i,
-- which in any case will be <= #pat, the total length of the juggling
-- sequence.

-- Error conditions: The input pattern may produce collisions if two different
-- objects are due at the same time (i.e., at the same position p in the
-- sequence). This will raise an exception.

local function analyze_pattern(pattern)
   local n = #pattern
   local sum = 0
   for _,k in ipairs(pattern) do
      sum = sum + k
   end
   local nobjs = sum/n
   -- nobjs must be integer, otherwise the pattern isn't valid
   if math.floor(nobjs) ~= nobjs then
      error("invalid pattern, average throw must be integer, but got " .. nobjs)
   end
   local objs = {}
   local pat = {}
   local obj = {} -- record the object for each position in the pattern
   local start = {} -- actual start position of object #i (may be > i)
   local max_pat = 0 -- maximum index in pat
   local trace = "" -- execution trace, to give better diagnostics
   for i = 1, nobjs do
      local last_i = i
      while obj[last_i] or cycle(pattern, last_i) <= 0 do
         -- this position is either empty or has already been filled by a
         -- previous object, look for the next free position
         last_i = last_i + 1
      end
      start[i] = last_i
      local last_k = cycle(pattern, last_i)
      local seq = { last_k }
      -- set of indices (mod n) already visited
      local i_set = { [last_i % n] = true }
      while true do
         trace = trace ..
            string.format("\n#%d: pos: %d (== %d), step: %d, seq: %s", i,
                          last_i, (last_i-1) % n + 1, last_k, inspect(seq))
         if pat[last_i] then
            -- we already have a previous object at this position, bail out
            error(string.format("collision: #%d-#%d at pos %d%s", i,
                                pat[last_i][1], last_i, trace))
         end
         if last_i > max_pat then
            max_pat = last_i
         end
         pat[last_i] = {i,last_k}
         obj[last_i] = i
         last_i = last_i+last_k
         last_k = cycle(pattern, last_i)
         if i_set[last_i % n] then
            -- position already visited, we're done, but we still mark the
            -- position as occupied by object i
            obj[last_i] = i
            break
         elseif #seq > n then
            -- this can't happen; if it does, our algorithm is probably broken
            error("this can't happen, please check the algorithm!" .. trace)
         end
         table.insert(seq, last_k)
         i_set[last_i % n] = true
      end
      objs[i] = seq
   end
   -- go through the objs table once again, fill in missing pat entries
   if max_pat % n ~= 0 then
      -- make sure that we extend the pattern to a full cycle at the end
      max_pat = max_pat + n - max_pat % n
   end
   for i = 1, nobjs do
      local last_i = start[i]
      local j = 1
      local seq = objs[i]
      while last_i <= max_pat do
         local last_k = cycle(seq, j)
         if not pat[last_i] then
            pat[last_i] = {i,last_k}
            trace = trace .. string.format("\n#%d: pat[%d]: %s", i, last_i,
                                           inspect(pat[last_i]))
         elseif pat[last_i][1] ~= i then
            trace = trace .. string.format("\n#%d: pat[%d]: %s", i, last_i,
                                           inspect({i,last_k}))
            -- collision, bail out
            error(string.format("collision: #%d-#%d at pos %d%s", i,
                                pat[last_i][1], last_i, trace))
         end
         last_i = last_i + last_k
         j = j+1
      end
   end
   -- fill in empty positions (0 = "no object")
   for i = 1, max_pat do
      if not pat[i] then
         pat[i] = {0,0}
      end
   end
   return pat, objs
end

-- algojuggle object

-- inlet #1 takes either (1) a list or a singleton float to set the siteswap
-- pattern, (2) a bang to output the next note, (3) a reset message to reset
-- the pattern to the first beat, or (4) a message of the form swap p q to
-- perform a site swap on pattern positions p < q

-- inlet #2 takes a MIDI preset, consisting of minvel and maxvel (minimum and
-- maximum velocity, to assign a velocity to each throw value) and a list of
-- MIDI note numbers (we cycle through this list to assign a note to each
-- object in the pattern)

-- outlet #1 and #2 output a note to play and its velocity for each bang message

-- in addition, for each bang message outlet #3 outputs a list with the
-- current position (1-based beat number) in the pattern along with the actual
-- pattern entry (a pair consisting of object number and throw); this is
-- useful for debugging purposes

-- outlet #4 outputs the new pattern after a successful site swap (swap message)

local algojuggle = pd.class("algojuggle")

-- helper function to pretty-print tables
local function print_table(t)
   local s = inspect(t)
   -- remove the outer braces
   s = string.sub(s, 3, #s-2)
   -- remove superflous commas around subtables
   s = string.gsub(s, "}, ", "} ")
   return s
end

function algojuggle:update()
   -- update pattern length and number of objects
   self.len = #self.pat
   self.nobjs = #self.objs
   -- update min and and max throw
   self.max = math.max(table.unpack(self.pattern))
   -- min needs special treatment, since we want to exclude zeros
   self.min = self.max
   for _,k in ipairs(self.pattern) do
      if k > 0 then
	 self.min = math.min(self.min, k)
      end
   end
   -- print the pattern on the console
   pd.post("new pattern " .. print_table(self.pattern) ..
           string.format(" (%d beats, %d objects)", self.len, self.nobjs))
   pd.post("pat = " .. print_table(self.pat))
   pd.post("objs = " .. print_table(self.objs))
end

function algojuggle:initialize(sel, atoms)
   self.inlets = 2
   self.outlets = 4
   -- beat counter
   self.pos = 0
   -- loop counter
   self.loop = nil
   -- default pattern 534
   self.pattern = {5,3,4}
   self.pat, self.objs = analyze_pattern(self.pattern)
   self:update()
   -- default MIDI setup (assumes GM drumkit)
   self.notes = {35, 42, 47, 48}
   self.minvel, self.maxvel = 80, 120
   return true
end

-- set pattern
function algojuggle:in_1_list(pattern)
   -- check input for validity
   for i,k in ipairs(pattern) do
      if type(k) ~= "number" or math.floor(k) ~= k or k < 0 then
	 self:error("invalid pattern: expected integer >= 0, got " .. k)
	 return
      end
      -- convert from float to a Lua integer
      pattern[i] = math.floor(k)
   end
   local ok, pat, objs = pcall(analyze_pattern, pattern)
   if ok then
      self.pattern = pattern
      self.pat, self.objs = pat, objs
      self:update()
      self.loop = nil
   else
      -- analyze_pattern exited with an exception, in this case pat will have
      -- the error message
      self:error(pat)
   end
end

-- MIDI setup (first two list elements are minvel, maxvel, the rest are the
-- notes to play in order)
function algojuggle:in_2_list(preset)
   -- check input for validity
   for i,k in ipairs(preset) do
      if type(k) ~= "number" or math.floor(k) ~= k or k < 0 then
	 self:error("invalid preset: expected integer >= 0, got " .. k)
	 return
      end
      -- convert from float to a Lua integer
      preset[i] = math.floor(k)
   end
   local minvel, maxvel = table.unpack(preset)
   local notes = {}
   table.move(preset, 3, #preset, 1, notes)
   -- do some more sanity tests
   if not minvel or not maxvel then
      self:error("invalid preset: not enough arguments, must be minvel, maxvel, notes")
      return
   end
   self.minvel, self.maxvel = minvel, maxvel
   if #notes > 0 then
      self.notes = notes
   end
end

function algojuggle:in_1_float(f)
   -- handle the case of a singleton list
   self:in_1_list({f})
end

-- cycle through the pattern
function algojuggle:in_1_bang()
   if self.len > 0 then
      if not self.loop or self.loop.ctr < self.loop.len then
	 -- next beat
	 self.pos = self.pos + 1
	 if self.pos > self.len then
	    self.pos = 1
	 end
	 if self.loop then
	    self.loop.ctr = self.loop.ctr + 1
	 end
      else
	 -- at the end of loop, go to the beginning
	 self.pos = self.loop.pos
	 self.loop.ctr = 1
      end
      local i, k = table.unpack(self.pat[self.pos])
      -- output the current postion and pattern entry for debugging purposes
      self:outlet(3, "list", {self.pos, i, k})
      if i == 0 then
	 -- 0 indicates no object, skip (produces a rest)
	 return
      end
      local vel = self.min == self.max and self.maxvel or
	 (k-self.min)/(self.max-self.min)*(self.maxvel-self.minvel)+self.minvel
      -- round velocity to the nearest integer
      self:outlet(2, "float", {math.floor(vel+0.5)})
      -- assign a note to each object, cycling through the available notes if
      -- needed
      self:outlet(1, "float", {cycle(self.notes, i)})
   end
end

-- set the looper
function algojuggle:in_1_loop(args)
   local rate = args[1]
   if self.len > 0 and type(rate) == "number" and rate >= 0 then
      rate = math.floor(rate)
   else
      rate = 0
   end
   if rate == 0 then
      self.loop = nil
      return
   end
   -- Rate values on the Beatstep Pro are 25 (slowest), 50, 75 and 100
   -- (fastest). We rather arbitrily map these to 4, 3, 2, 1 steps here,
   -- respectively, but you can adjust the mapping below as needed.
   rate = math.min(4, math.max(1, math.ceil(rate/25)))
   local steps = {4, 3, 2, 1}
   self.loop = { pos = self.pos, ctr = 1, len = steps[rate]}
   --pd.post("loop " .. self.loop.len .. " at " .. self.loop.pos)
end

-- reset the playback position
function algojuggle:in_1_reset()
   self.pos = 0
   self.loop = nil
end

-- set the playback position (0-based)
function algojuggle:in_1_pos(args)
   local pos = args[1]
   if self.len > 0 and type(pos) == "number" and pos >= 0 then
      self.pos = math.floor(pos) % self.len
   else
      self.pos = 0
   end
   self.loop = nil
end

-- site swap
function algojuggle:in_1_swap(sites)
   local p, q = table.unpack(sites)
   if #sites == 2 and type(p) == "number" and type(q) == "number" and
      math.floor(p) == p and math.floor(q) == q and p < q and
      p > 0 and q <= #self.pattern then
      p = math.floor(p)
      q = math.floor(q)
      local d = q - p
      if d <= self.pattern[p] then
	 -- construct the new pattern, swapping sites p and q
	 local pattern = {table.unpack(self.pattern)}
	 pattern[p], pattern[q] = pattern[q]+d, pattern[p]-d
	 pd.post("site swap " .. print_table(self.pattern) .. " -> " .. print_table(pattern))
	 self:outlet(4, "list", pattern)
      else
	 self:error("swap: wrong arguments, expected landing site " .. p+self.pattern[p] .. " >= " .. q)
      end
   else
      self:error("swap: sites must be distinct integers p < q between 1 and " .. #self.pattern)
   end
end
