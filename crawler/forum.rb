require 'nokogiri'
require 'net/http'

module BaseCrawler
    class Forum < BaseCrawler::Crawler
        def self.get_data node
            #use old get_forums, get_threads and stuff
        end

        def self.get_forums(node)
            # Returns an array of the subforums in the page.
            forums = []
            node.css("tr td.row4 a").each do |tag_a|
                forums += [tag_a["href"]] if /showforum/.match tag_a["href"]
            end
            forums
        end

        def self.get_threads(node)
            # Returns an array of the threads in the page.
            threads = []
            node.css("tr td.row4 a").each do |tag_a|
                threads += [tag_a["href"]] if /showtopic=\d+$/.match tag_a["href"]
            end
            threads
        end

        # BEGIN -- next page for forums
        def self._index(url)
            # Returns the last number in the url in case it means something (like
            # the numbering of the posts in the forum) or 0 if it doesn't, and in
            # this last case I assume that means we are dealing with the first page
            # in a subforum spanning multiple pages.
            return 0 unless /showforum=\d+.*=\d+$/ =~ url
            return /showforum=\d+.*=(\d+)$/.match(url)[1].to_i
        end

        def get_nextpage(node)
            # Returns a link to the next page.
            url = @cur.data[:url]
            links = self._get_possible_next node, url
            if /showforum=\d+$/.match url
                start = 0
            else
                start = self._index(url)
            end
            links.keep_if {|link| self._index(link) > start}
            links.uniq!
            links.sort! {|a,b| self._index(a) <=> self._index(b)}
            return links[0]
        end

        def self._get_possible_next node, url
            # Get the pages which are candidates for being next in the forum.
            # url is the URL of the current page.
            links = []
            node.css("tr td a").each do |tag_a|
                if /^\d+$/.match(tag_a.content) and self._is_same_forum(url,tag_a["href"])
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
        # END -- next page for forums

    end
end
