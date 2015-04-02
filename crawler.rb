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
        # Actual tree building.
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
        # This provides buildtree with the actual data.
        self.buildtree do |node|
            data = Hash.new()
            data[:subforums] = get_forums(node)
            data[:subthreads] = get_threads(node)
            data[:nextpage] = get_nextpage(node)
            data
        end
    end

    def CrawlAll
        # Iterate ForumCrawler recursively.
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
        # Returns an array of the subforums in the page.
        forums = []
        node.css("tr td.row4 a").each do |tag_a|
            forums += [tag_a["href"]] if /showforum/.match tag_a["href"]
        end
        forums
    end

    def get_threads(node)
        # Returns an array of the threads in the page.
        threads = []
        node.css("tr td.row4 a").each do |tag_a|
            threads += [tag_a["href"]] if /showtopic=\d+$/.match tag_a["href"]
        end
        threads
    end

    def get_nextpage(node)
        # Returns a link to the next page.
        links = _get_possible_next(node)
        if /showforum=\d+$/.match @url
            start = 0
        else
            start = Crawler._index(@url)
        end
        links.keep_if {|link| Crawler._index(link) > start}
        links.uniq!
        links.sort! {|a,b| Crawler._index(a) <=> Crawler._index(b)}
        return links[0]
    end

    def self._index(url)
        # Returns the last number in the url in case it means something (like
        # the numbering of the posts in the forum) or 0 if it doesn't, and in
        # this last case I assume that means we are dealing with the first page
        # in a subforum spanning multiple pages.
        return 0 unless /showforum=\d+.*=\d+$/ =~ url
        return /showforum=\d+.*=(\d+)$/.match(url)[1].to_i
    end

    def _get_possible_next(node)
        # Get the pages which are candidates for being next in the forum.
        links = []
        node.css("tr td a").each do |tag_a|
            if /^\d+$/.match(tag_a.content) and Crawler._is_same_forum(@url,tag_a["href"])
                links += [tag_a["href"]]
            end
        end
        return links
    end
    def self._is_same_forum(url, target)
        # Returns true if target is in the same forum as url
        t = /showforum=(\d+)/.match(target)
        if not t
            return false
        end
        n = /showforum=(\d+)/.match(url)[1].to_i
        m = t[1].to_i
        return n == m
    end

    def self._do_page(node)
        # Given a thread node returns an array of messages of the form
        # {:author => value, :date => value}
        msgs = self._get_messages(node)
        msglist = msgs.to_a.map {|msg_node| self._get_mex_data(msg_node)}
        return msglist
    end

    def self._get_messages(node)
        # Returns a NodeSet of all the nodes containing single messages
        # node is a thread (parsed with Nokogiri)
        messages = node.xpath("//div[@class='tableborder']/table[@cellspacing='1']")
        # The best I found to select messages was table[cellspacing='1'] as
        # direct children of div.tableborder. Probably won't work anywhere else.
        return messages
    end

    def self._get_mex_data(node)
        # Returns important data from a message. Right now it is
        # data = {:date = "<date>", :author = "user_id"}
        pre = node.css "tr td.row4"
        # I assume pre = [ node_containing_user, node_containing_date]
        user_urls = pre[0].css("a").select {|tag_a| /showuser=\d+/ =~ tag_a["href"]}
        user = user_urls[0]
        user_id = self._get_user_id(user["href"])
        user_name = user.text
        # END USER
        post = pre[1].children.select{|child| /Inviato il: (.*)\n/ =~ child.content }
        date_string = /Inviato il: (.*)\n/.match(post[0])[1]
        # END date
        data = { :author => user_id, :author_name => user_name, :date => date_string }
        return data
    end

    def self._get_user_id(url)
        if /showuser=\d+/ =~ url
            return /showuser=(\d+)/.match(url)[1]
        end
        return nil
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
