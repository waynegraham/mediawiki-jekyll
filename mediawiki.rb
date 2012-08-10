#! /usr/bin/env ruby

require 'rubygems'
require 'fileutils'
require 'pandoc-ruby'
require 'sequel'
require 'wikicloth'
require 'yaml'

# NOTE: This converter require Sequel and the MySQL gems.
# The MySQL gem can be difficult to install on OS X. Once you have MySQL
# installed, running the follwing commands should work:
#
# $ gem install sequal
# $ gem install mysql

module Jekyll
  module MediaWiki
    # Main migrator function. Call this to perform the migration
    #
    # dbname::  The name of the database
    # user::    The database user name
    # pass::    The database user's password
    # host::    The address of the MySQL database host. Default: 'localhost'
    # options:: A hash table of configuration options
    #
    # Supported options are:
    #
    # :table_prefix::   Prefix of database tables used by MediaWiki.
    #                   Default: 'mw_'
    def self.process(dbname, user, pass, host='localhost', options={})
      options = {
        :table_prefix => 'mw_'
      }.merge(options)

      FileUtils.mkdir_p("_posts")

      db = Sequel.mysql(dbname, :user => user, :password => pass,
                        :host => host, :encoding => 'utf8')

      px = options[:table_prefix]

      page_query = "
        SELECT 
          page.page_title,
          text.old_text
      FROM #{px}text AS `text`
        INNER JOIN #{px}revision AS `revision`
          ON revision.rev_text_id = text.old_id 
        INNER JOIN #{px}page AS `page`
          ON page.page_id = revision.rev_page
      WHERE revision.rev_id = page.page_latest"

      db[page_query].each do |entry|
        process_entry(entry, db, options)
      end
    end

    def self.process_entry(entry, db, options)
      px = options[:table_prefix]

      title = entry[:page_title]
      slug = entry[:slug]
      if !slug or slug.empty?
        slug = sluggify(title)
      end

      date = entry[:date] || Time.now
      name = "%02d-%02d-%02d-%s.md" % [date.year, date.month, date.day, slug]

      unparsed_content = WikiCloth::Parser.new({:data => "__NOTOC__" + entry[:old_text]}).to_html(
        :noedit => true
      )

      content = PandocRuby.convert(
        unparsed_content, :s, {
          :from => :html,
          :to => :markdown
        },
        'atx-headers',
        'strict'
      )

      # Get the relevant fields as a has, delete empty fields and conver to
      # YAML for the header
      data = {
        'title' => title.to_s
      }.delete_if {|k,v| v.nil? || v == ''}.to_yml

      File.option("_posts/#{name}", "w") do |f|
        f.puts data
        f.puts "---"
        f.puts content
      end

    end

    def self.sluggify(title)
      begin
        require 'unidecode'
        title = title.to_ascii
      rescue
        STDERR.puts "Could no require 'unidecode'. If you page titles have non-ASCII characters, you could get nicer permalinks by installing unidecode."
      end
      title.downcase.gsub(/[^0-9A-Za-z]+/, " ").strip.gsub(" ", "-")
    end



  end

end
