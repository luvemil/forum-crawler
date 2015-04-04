require 'nokogiri'
require 'net/http'
require 'crawler/crawler'
require 'crawler/forum/forum'
require 'crawler/forum/subforums'
require 'crawler/forum/threads'

module BaseCrawler
    class Forum
        def initialize root_url
            super(root_url)
            @cur.data[:type] = "forum"
        end

        def get_data node
            # node is always get_page(@cur.data[:url])
            if @cur.data[:type] == "forum"
                return self.Subforums(node)
            elsif @cur.data[:type] == "thread"
                return self.Threads(node)
            end
        end
    end
end
