require 'nokogiri'
require 'net/http'
require 'crawler/tree'

module BaseCrawler
    class Crawler
        # This is the prototype crawler. Subclasses are expected to provide:
        # self.get_data node # => extract data from node
        # TODO:
        # * the current workflow assumes that all data can be deduced from the
        #   the parent, except from children. This is messy.
        attr_accessor :root_tree
        def initialize root_url
            # Maybe this can be different on subclasses. Still good as long as it
            # has a @root_tree, @cur, and data has :url key.
            # The old @url variable is substituted by @cur.data[:url].
            data = { :url => root_url }
            @root_tree = Tree.new data
            @cur = @root_tree
        end

        def self.get_page url
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

        def put_data crawl_data
            # crawl_data should have crawl_data[:children] = [ data_array ]
            # TODO:
            #   * add something to @cur.data
            if crawl_data[:children]
                crawl_data[:children].each do |child_data|
                    @cur.add_child child_data
                end
            end
            if crawl_data[:new_data]
                @cur.data.merge! crawl_data[:new_data] do |key, oldval, newval|
                    if oldval.class == Array and newval.class == Array
                        puts "Merging arrays"
                        oldval += newval
                    end
                end
            end
        end

        def crawl_page node
            while node
                crawl_data = self.get_data node
                # WARNING: get_data has to ensure that each data[:children]
                # has a key :url with the child url. After all the whole point
                # of getting data is getting urls...
                self.put_data crawl_data
                if crawl_data[:next_page]
                    @url = crawl_data[:next_page]
                    node = Crawler.get_page @url
                else
                    node = nil
                end
            end
        end

        def crawl_all
            @url = @cur.data[:url]
            node = Crawler.get_page @url
            self.crawl_page node
            @cur.children.each do |child|
                @cur = child
                self.crawl_all
            end
        end
    end
end
