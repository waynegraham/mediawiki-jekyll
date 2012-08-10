# Mediawiki to Jekyll

This is a Ruby script to take the latest version of a page in a Mediawiki
installation and convert it to a Markdown file for Jekyll. The script will
create a page for each page in your Mediawiki database.

## Usage

```
git clone git://github.com/clioweb/mediawiki-jekyll.git
cd mediawiki-jekyll
bundle install
cp settings.yml.changeme settings.yml
```

Edit your `settings.yml` file with relevant values to connect to your
database. Once these are filled in:

```
ruby generate.rb
```

This will put all your Markdown pages in a directory called `pages`.

## Requirements

 * [Pandoc](http://johnmacfarlane.net/pandoc/)

