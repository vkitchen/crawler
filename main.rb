#!/usr/bin/env ruby
require 'uri'
require 'net/http'

uri = URI('http://vaughan.kitchen')
res = Net::HTTP.get_response(uri)
abort("Request failed!") if !res.is_a?(Net::HTTPSuccess)

def strcmp(haystack, start, needle)
	# TODO check this math
	return false if haystack.length < start + needle.length
	for i in 0...needle.length
		# TODO case insensitive
		return false if haystack[start+i].chr != needle[i].chr
	end
	true
end

def links(html)
	links = []
	start = 0
	searching = false
	for i in 0...html.length
		# TODO no guarantee href follows a
		if strcmp(html, i, "<a href")
			searching = true
			start = i
		end
		if searching && html[i].chr == '>'
			searching = false
			links << html[start..i]
		end
	end
	links
end

puts links(res.body)