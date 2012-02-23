#!/usr/bin/ruby
# http://mime-types.rubyforge.org
# gem install mime-types
require 'rubygems'
require 'rexml/document'
require 'time'
require 'uri'
require 'mime/types'

def scan(xml, directory, url)
  puts "Directory: " + directory
    
  Dir.foreach(directory) do |file|
      unless ["",".","..",".DS_Store","rss.rb","rss.xml","opml.rb","opml.xml"].include?(file)
        file_path = directory + "/" + file
        if File.directory?(file_path) 
          sub_directory = directory + "/" + file
          sub_url = url + file + "/"
          scan(xml, sub_directory, sub_url)
        else
          file_name = File.basename(file_path)
          file_extension = File.extname(file_path)
          modified_time = File.mtime(file_path)
          file_size = File.size(file_path).to_f
          compressed_file_size = file_size / 1024000
          uncoded_url = url + file
          encoded_url = URI.escape(uncoded_url)
          mime_type = MIME::Types.type_for(file_name).first
          mime_type = mime_type.nil? ? "application/octet-stream" : mime_type.content_type
          
          puts "File: " + file_name + " " + mime_type
          
          item = xml.elements['/rss/channel'].add_element('item')
          item.add_element('title').text = file
          item.add_element('pubDate').text = modified_time.rfc822
          item.add_element('link').text = encoded_url
          item.add_element('guid').text = encoded_url
          item.add_element('category').text = file_extension.gsub(".","").upcase
          item.add_element('description').text = '%.2fmb' % compressed_file_size
          enclosure = item.add_element('enclosure')
          enclosure.add_attribute("url", encoded_url)
          enclosure.add_attribute("length", '%.0f' % file_size)
          enclosure.add_attribute("type", mime_type)
        end
      end
  end  
end

def prompt(*args)
    print(*args)
    STDIN.gets
end

public_url = ARGV.empty? ? prompt("What is your public Dropbox URL?\n") : ARGV.first

unless public_url.empty?
  current_directory = File.expand_path(File.dirname(File.dirname(__FILE__)))
  puts ""
  puts "URL: " + public_url
  
  xml = REXML::Document.new '<rss version="2.0"><channel></channel></rss>'
  xml.elements['/rss/channel'].add_element('title').text = "Dropbox RSS"
  xml.elements['/rss/channel'].add_element('generator').text = "Dropbox2RSS"
  xml.elements['/rss/channel'].add_element('pubDate').text = Time.now.rfc822
  xml.elements['/rss/channel'].add_element('lastBuildDate').text = Time.now.rfc822

  scan(xml, current_directory, public_url.chomp)

  xml_file = File.open(current_directory + "/rss.xml", "w+")
  xml.write(xml_file, 0)
end