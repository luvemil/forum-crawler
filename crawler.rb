require 'nokogiri'
require 'net/http'

class Crawler
    attr_accessor :url, :forum_tree
    def initialize url
        @url = url
    end

    def get_page
        @doc = Net::HTTP.get(url)
    end

class ForumTree
    attr_accessor :attributes, :children, :parent
    def initialize
        @children = []
        @attributes = { :url => url, :type => type }
    end

    def add_children url, type
        new_child = ForumTree(url, type)
        new_child.parent = self
        @children += new_child
    end
