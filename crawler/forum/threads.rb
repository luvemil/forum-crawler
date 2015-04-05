require 'nokogiri'

module BaseCrawler
    class Forum
        # class << self
        def Threads node
            Forum::Threads.get_crawl_data node, @url
        end
        # end
        module Threads
            def self.get_crawl_data node, url
                messages = _do_page node
                next_page = get_nextpage node, url
                if next_page
                    puts "Found next page in #{url}"
                end
                crawl_data = { :new_data => { :messages => messages }, :next_page => next_page }
            end

            def self._do_page(node)
                # Given a thread node returns an array of messages of the form
                # {:author => value, :date => value}
                msgs = _get_messages(node)
                msglist = msgs.to_a.map {|msg_node| _get_mex_data(msg_node)}
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
                # Workaround for unregistered users
                if pre[0].css("span.unreg").size > 0
                    user_name = pre[0].css('span.unreg')[0].text
                    user_id = "0" # user_id is a string containing a number
                else
                    user_urls = pre[0].css("a").select {|tag_a| /showuser=\d+/ =~ tag_a["href"]}
                    user = user_urls[0]
                    user_id = _get_user_id(user["href"]) # Fails with unregistered user TODO
                    user_name = user.text
                end
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

            # BEGIN -- next page for forums
            def self._index(url)
                # Returns the last number in the url in case it means something (like
                # the numbering of the posts in the forum) or 0 if it doesn't, and in
                # this last case I assume that means we are dealing with the first page
                # in a subforum spanning multiple pages.
                return 0 unless /showtopic=\d+.*=\d+$/ =~ url
                return /showtopic=\d+.*=(\d+)$/.match(url)[1].to_i
            end

            def self.get_nextpage node, url
                # Returns a link to the next page.
                # url is the current url, ideally @cur.data[:url] from a
                # BaseCrawl object.
                links = _get_possible_next node, url
                if /showtopic=\d+$/.match url
                    start = 0
                else
                    start = _index(url)
                end
                links.keep_if {|link| _index(link) > start}
                links.uniq!
                links.sort! {|a,b| _index(a) <=> _index(b)}
                return links[0]
            end

            def self._get_possible_next node, url
                # Get the pages which are candidates for being next in the forum.
                # url is the URL of the current page.
                links = []
                node.css("tr td a").each do |tag_a|
                    if /^\d+$/.match(tag_a.content) and _is_same_topic(url,tag_a["href"])
                        links += [tag_a["href"]]
                    end
                end
                return links
            end

            def self._is_same_topic(url, target)
                # Returns true if target is in the same forum as url
                t = /showtopic=(\d+)/.match(target)
                if not t
                    return false
                end
                n = /showtopic=(\d+)/.match(url)[1].to_i
                m = t[1].to_i
                return n == m
            end
            # END -- next page for forums

        end
    end
end
