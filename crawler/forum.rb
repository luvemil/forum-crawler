require 'nokogiri'
require 'net/http'
require 'forum/subforums'

module BaseCrawler
    class Forum < BaseCrawler::Crawler
        def initialize root_url
            super(root_url)
            @cur.data[:type] = "forum"
        end

        def self.get_data node
            # node is always get_page(@cur.data[:url])
            if @cur.data[:type] == "forum"
                return self.Subforums(node)
            # need to write the case thread
            end
        end
    end
end
