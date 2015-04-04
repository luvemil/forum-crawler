require 'nokogiri'

module BaseCrawler
    class Forum
        # class << self
        def Threads node
            Forum::Threads.get_crawl_data node, @cur.data[:url]
        end
        # end
        module Threads
            def self.get_crawl_data node, url
                messages = _do_page node
                crawl_data = { :new_data => { :messages => messages } }
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
                user_urls = pre[0].css("a").select {|tag_a| /showuser=\d+/ =~ tag_a["href"]}
                user = user_urls[0]
                user_id = _get_user_id(user["href"])
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
    end
end
