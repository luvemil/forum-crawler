# forum-crawler

A simple crawler for phpBB forums

# Usage

For now you simply have a bunch of classes. If you do

```ruby
url = "<your-forum-url>"
foo = BaseCrawler::Forum.new url
foo.crawl_all
tree = foo.root_tree # => :Tree object
```

The attribute `BaseCrawler::Crawler::root_tree` contains a tree with all forum and topic links (only the first pages for now).

# How it works

The base logic is in the `BaseCrawler::Crawler` class. Any kind of crawler should inherit from this class and provide a `get_data` method, which takes in input a `Nokogiri::Node` and extracts the data. The `data` should be an `Hash`, with the following requirements:
* If you extract children, create an array in `data[:children]` containing the data required for each child creation (the requirement right now is for each `child_data` to be a `Hash` with at least the key :url).
* If you add new data (in for of `Hash`) to the current node in the tree, put the new data in `data[:new_data]`

# TODO

* ~~Crawl several forum pages~~
* ~~Crawl threads~~
* ~~Crawl multipage-threads~~
* Stop-Resume working
* Better tree structure
    - [RubyTree](https://github.com/evolve75/RubyTree)
* Polish code
* Better documentation
