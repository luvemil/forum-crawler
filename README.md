# forum-crawler

A simple crawler for phpBB forum

# Usage

For now you simply have a bunch of classes. If you do

```ruby
url = "<your-forum-url>"
foo = Crawler.new(url)
foo.CrawlAll
tree = foo.root_tree # => :Tree object
```

The attribute `:Crawler:root_tree` contains a tree with all forum and topic links (only the first pages for now).

# TODO

* Crawl several forum pages
* Crawl threads
