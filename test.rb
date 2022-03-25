#!/usr/bin/env ruby

require './main'

def test_strcmp
	# Finds at start of string?
	raise "Failed start" if !strcmp("A man a plan a canal panama", 0, "A")
	# Finds in middle of string
	raise "Failed middle" if !strcmp("A man a plan a canal panama", 8, "plan a can")
	# Finds at end of string
	raise "Failed end" if !strcmp("A man a plan a canal panama", 26, "a")
	# Doesn't match
	raise "Failed not a match" if strcmp("A man a plan a canal panama", 0, "dog")
	# Index too high
	raise "Failed start past end" if strcmp("0123", 4, "4")
	# Needle goes past end
	raise "Failed needle past end" if strcmp("A man a plan a canal panama", 21, "panamonium")
end

test_strcmp
