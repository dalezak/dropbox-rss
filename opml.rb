#!/usr/bin/ruby
require 'rexml/document'
require 'time'
require 'uri'
  
def scan(opml, directory, url, name)
  puts "Directory: " + directory
  
  xml = REXML::Document.new '<rss version="2.0"><channel></channel></rss>'
  xml.elements['/rss/channel'].add_element('title').text = "Dropbox RSS"
  xml.elements['/rss/channel'].add_element('generator').text = "opml.rb"
  
  Dir.foreach(directory) do |file|
      unless ["",".","..",".DS_Store","rss.rb","rss.xml","opml.rb","opml.xml"].include?(file)
        file_path = directory + "/" + file
        if File.directory?(file_path)
          sub_directory = directory + "/" + file
          sub_url = url + file + "/"
          scan(opml, sub_directory, sub_url, file)
        else
          file_name = File.basename(file_path)
          file_extension = File.extname(file_path)
          modified_time = File.mtime(file_path)
          compressed_file_size = File.size(file_path).to_f / 1024000
          formatted_file_size = '%.2f' % compressed_file_size  
          uncoded_url = url + file
          encoded_url = URI.escape(uncoded_url)
          
          puts "File: " + file_path
          
          item = xml.elements['/rss/channel'].add_element('item')
          item.add_element('title').text = file
          item.add_element('pubDate').text = modified_time.rfc822
          item.add_element('link').text = encoded_url
          item.add_element('category').text = file_extension.gsub(".","").upcase
          item.add_element('description').text = formatted_file_size + "mb"
        end
      end
  end 
  
  uncoded_url = url + "rss.xml"
  encoded_url = URI.escape(uncoded_url)
  
  outline = opml.elements['/opml/body/outline'].add_element('outline')
  outline.add_attribute("type", "link")
  outline.add_attribute("text", name)
  outline.add_attribute("url", encoded_url)
  outline.add_attribute("dateCreated", Time.now.rfc822)
  
  xml_file = File.open(directory + "/rss.xml", "w+")  
  xml.write(xml_file, 0)
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
  
  opml = REXML::Document.new '<opml version="1.0"><head></head><body><outline></outline></body></opml>'
  opml.elements['/opml/head'].add_element('title').text = "Dropbox OPML"
  opml.elements['/opml/head'].add_element('dateCreated').text = Time.now.rfc822
  opml.elements['/opml/head'].add_element('dateModified').text = Time.now.rfc822
  opml.elements['/opml/head'].add_element('link').text = public_url + "opml.xml"
  opml.elements['/opml/body/outline'].add_attribute("text", "RSS Feeds")

  scan(opml, current_directory, public_url.chomp, "")

  opml_file = File.open(current_directory + "/opml.xml", "w+")  
  opml.write(opml_file, 0)
end