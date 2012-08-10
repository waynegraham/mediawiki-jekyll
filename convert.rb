# !/usr/bin/env/ruby

require 'yaml'
require 'fileutils'
require 'pandoc-ruby'
require 'mysql2'
require 'wikicloth'

@settings = YAML.load(File.read('settings.yml'))

client = Mysql2::Client.new(
  :host => @settings['host'],
  :username => @settings['username'],
  :password => @settings['password'],
  :database => @settings['database'])

prefix = @settings['prefix']

# SQL to select the page title and text for the most recent version of a page.
sql = "SELECT #{prefix}page.page_title, #{prefix}text.old_text FROM #{prefix}text INNER JOIN #{prefix}revision ON #{prefix}revision.rev_text_id = #{prefix}text.old_id INNER JOIN #{prefix}page ON #{prefix}page.page_id = #{prefix}revision.rev_page WHERE #{prefix}revision.rev_id = #{prefix}page.page_latest"

results = client.query(sql)

results.each do |page|

  title = page["page_title"]
  
  puts "Generating #{title}"

  text = page["old_text"]

  # Convert wikimarkup to HTML.
  textHtml = WikiCloth::Parser.new({:data => "__NOTOC__" + text}).to_html(:noedit => true, )

  # Convert HTML to markdown
  textMarkdown = PandocRuby.convert(textHtml, :s, {:from => :html, :to => :markdown}, 'atx-headers', 'strict')
  
  filename = title.downcase.gsub(/\//,'_').gsub(/\W+/,'') + '.md'

  FileUtils.mkdir_p "./pages"
  # Create our Jekyll page.
  f = File.new("./pages/#{filename}", 'w+')

  contents = <<EOC
---
layout: default
title: #{title.gsub(/_/, ' ')}
---

# #{title.gsub(/_/, ' ')}

#{textMarkdown}
EOC

  f.puts contents
end

fileCount = Dir.glob(File.join('./pages', '**', '*')).select { |file| File.file?(file) }.count

puts "Created #{fileCount} files."

