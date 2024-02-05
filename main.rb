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

$robots = []
$visited = {}
def crawl(url, depth)
	return if $visited.key?(url)

        # Throttling
        sleep 1

	filename = Base64.urlsafe_encode64(url.to_s)
	if depth > 0 && File.exist?("#{filename}.html")
		puts "Already retrieved: #{url}"
		return
	end

	res = Net::HTTP.get_response(url, {'User-Agent' => 'Mozilla/5.0 (compatible; PotatoCastlesBot; +http://potatocastles.com)'} )
	if res.is_a?(Net::HTTPRedirection)
		path = res['Location']

		puts "Redirected to: #{path}"

		if !path.ascii_only?
			puts "Skipping... URL Contains UTF-8: #{path}"
			return
		end
		begin
			nextUrl = URI.join(url, URI(path))
			if url.host != nextUrl.host
				puts "Skipping... External URL #{nextUrl}"
				return
			end
			skip = false
			$robots.each do |rule|
				if nextUrl.to_s.include? rule
					puts "Skipping... Disallowed by robots.txt rule '#{rule}'"
					skip = true
					break
				end
			end
			return if skip
			nextUrl.fragment = nil
			nextUrl.normalize!
			crawl(nextUrl, depth)
		rescue URI::InvalidURIError
			puts "Invalid URL: #{path}"
		end

		return
	end
	if !res.is_a?(Net::HTTPSuccess)
		puts "Failed on request for resource: #{url}"
		return
	end
	$visited[url] = true

	puts "Retrieved: #{url}"

	File.open("#{filename}.html", 'w') do |file|
		file.write(res.body)
	end if depth > 0

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
			skip = false
			$robots.each do |rule|
				if nextUrl.to_s.include? rule
					puts "Skipping... Disallowed by robots.txt rule '#{rule}'"
					skip = true
					break
				end
			end
			next if skip
			nextUrl.fragment = nil
			nextUrl.normalize!
			crawl(nextUrl, depth + 1)
		rescue URI::InvalidURIError
			puts "Invalid URL: #{path}"
		end
	end
end

def robots(url)
	url = URI.join(url, URI('/robots.txt'))

	res = Net::HTTP.get_response(url, {'User-Agent' => 'Mozilla/5.0 (compatible; PotatoCastlesBot; +http://potatocastles.com)'} )
	if !res.is_a?(Net::HTTPSuccess)
		puts "Failed requesting robots.txt"
		return
	end

	$robots = res.body.lines.grep(/^Disallow:/).map { |rule| rule.delete_prefix('Disallow:').strip.tr('*', '') }
end

$usage = <<-END
Usage:
  #{$0} [url]
END

if __FILE__ == $0
	abort $usage if $*[0].nil?
	url = URI($*[0])
	abort "ERROR: Missing scheme. Try http://#{url}" if url.scheme.nil?
	url.normalize!
	robots(url)
	puts '## robots.txt ##'
	puts $robots
	puts '## Crawling ##'
	crawl(url, 0)
end
