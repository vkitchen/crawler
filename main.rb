#!/usr/bin/env ruby
require 'base64'
require 'net/http'
require 'uri'

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

	filename = Base64.urlsafe_encode64(url.to_s)
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

$usage = <<-END
Usage:
  #{$0} [url]
END

if __FILE__ == $0
	abort $usage if $*[0].nil?
	url = URI($*[0])
	abort "ERROR: Missing scheme. Try http://#{url}" if url.scheme.nil?
	crawl(url)
end
