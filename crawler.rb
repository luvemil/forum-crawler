require 'nokogiri'
require 'net/http'

class Crawler
    attr_accessor :root_url, :root_tree
    def initialize root_url
        @root_url = root_url
        @root_tree = Tree.new(root_url,"forum")
        @cur = @root_tree
        @url = root_url
    end

    def get_page url
        uri = URI(url)
        res = Net::HTTP.get_response(uri)
        if res.code == "200"
            doc = res.body
            node = Nokogiri::HTML(doc)
            return node
        else
            return nil
        end
    end

    def do_stuff data
        data[:subforums].each do |url|
            @cur.add_children url, "forum"
        end
        data[:subthreads].each do |url|
            @cur.add_children url, "thread"
        end
    end

    def buildtree
        # This is the main function which builds the tree. It's fairly general
        # and its behaviour depends on a block which gives it data and on the
        # method do_stuff which feeds the tree.
        node = self.get_page(@url)
        while node
            data = yield(node)
            self.do_stuff(data)
            if data[:nextpage]
                node = self.get_page(data[:nextpage])
            else
                node = nil
            end
        end
    end

    def ForumCrawler
        self.buildtree do |node|
            data = Hash.new()
            data[:subforums] = get_forums(node)
            data[:subthreads] = get_threads(node)
            data[:nextpage] = get_nextpage(node)
            data
        end
    end

    def CrawlAll
        self.ForumCrawler
        @cur.children.each do |child|
            if child.attributes[:type] == "forum"
                @cur = child
                @url = child.attributes[:url]
                self.CrawlAll
            end
        end
    end

    def get_forums(node)
        forums = []
        node.css("tr td.row4 a").each do |tag_a|
            forums += [tag_a["href"]] if /showforum/.match tag_a["href"]
        end
        forums
    end

    def get_threads(node)
        threads = []
        node.css("tr td.row4 a").each do |tag_a|
            threads += [tag_a["href"]] if /showtopic=\d+$/.match tag_a["href"]
        end
        threads
    end

    def get_nextpage(node)
        links = _get_possible_next(node)
        if /showforum=\d+$/.match @url
            start = 0
        else
            start = Crawl._index(@url)
        end
        links.keep_if {|link| Crawl._index(link) > start}
        links.uniq!
        links.sort! {|a,b| Crawl._index(a) <=> Crawl._index(b)}
        return links[0]
    end

    def self._index(url)
        return 0 unless /showforum=\d+.*=\d+$/ =~ url
        return /showforum=\d+.*=(\d+)$/.match(url)[1].to_i
    end

    def _get_possible_next(node)
        links = []
        node.css("tr td a").each do |tag_a|
            if /^\d+$/.match(tag_a.content) and tag_a["href"].include?(@url)
                links += [tag_a["href"]]
            end
        end
        return links
    end

end

class Tree
    attr_accessor :attributes, :children, :parent
    def initialize url, type
        @children = []
        @attributes = { :url => url, :type => type }
    end

    def add_children url, type
        new_child = Tree.new(url, type)
        new_child.parent = self
        @children += [ new_child ]
    end
end
