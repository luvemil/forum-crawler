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
            # Don't download threads on first run.
            if @cur.data[:type] == "forum"
                return self.Subforums(node)
            # elsif @cur.data[:type] == "thread"
            #     return self.Threads(node)
            end
        end

        def get_all_threads
            @cur = @root_tree
            _run_threads
        end

        def _run_threads
            # Cross the tree starting in @cur, and looks for threads to download.
            if @cur.data[:type] == "thread"
                @url = @cur.data[:url]
                node = Crawler.get_page @url
                while node
                    crawl_data = self.Threads(node)
                    self.put_data crawl_data
                    if crawl_data[:next_page]
                        @url = crawl_data[:next_page]
                        node = Crawler.get_page @url
                    else
                        node = nil
                    end
                end
            else
                @cur.children.each do |child|
                    @cur = child
                    _run_threads
                end
            end
        end
    end
end
