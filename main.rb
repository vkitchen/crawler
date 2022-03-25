#!/usr/bin/env ruby
require 'uri'
require 'net/http'
require 'digest/md5'

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

$visited = {}
def crawl(url)
	return if $visited.key?(url)
	res = Net::HTTP.get_response(url)
	if !res.is_a?(Net::HTTPSuccess)
		puts "Failed on request for resource: #{url}"
		return
	end
	$visited[url] = true

	puts "Retrieved: #{url}"

	filename = Digest::MD5.hexdigest(res.body)
	File.open("#{filename}.html", 'w') do |file|
		file.puts(url)
		file.write(res.body)
	end if !File.exist?("#{filename}.html")

	lnks = links(res.body)
	lnks.each do |lnk|
		path = href(lnk)
		if !path.ascii_only?
			puts "Skipping... URL Contains UTF-8: #{path}"
			next
		end
		begin
			nextUrl = URI.join(url, URI(path))
			if url.host != nextUrl.host
				puts "Skipping... External URL #{nextUrl}"
				next
			end
			crawl(nextUrl)
		rescue URI::InvalidURIError
			puts "Invalid URL: #{path}"
		end
	end
end

if __FILE__ == $0
	crawl(URI('http://vaughan.kitchen'))
end
