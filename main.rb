#!/usr/bin/env ruby
require 'uri'
require 'net/http'

def strcmp(haystack, start, needle)
	return false if haystack.length < start + needle.length
	for i in 0...needle.length
		return false if haystack[start+i].chr.downcase != needle[i].chr.downcase
	end
	true
end

def links(html)
	links = []
	start = 0
	searching = false
	for i in 0...html.length
		if strcmp(html, i, "<a")
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

def href(link)
	start = 0
	searching = false
	for i in 0...link.length
		if strcmp(link, i, "href=\"")
			searching = true
			start = i + 6
		end
		if searching && i > start && link[i].chr == '"'
			searching = false
			return link[start..i-1]
		end
	end
	""
end

if __FILE__ == $0
	uri = URI('http://vaughan.kitchen')
	res = Net::HTTP.get_response(uri)
	abort("Request failed!") if !res.is_a?(Net::HTTPSuccess)
	lnks = links(res.body)
	lnks.each do |lnk|
		puts href(lnk)
	end
end
