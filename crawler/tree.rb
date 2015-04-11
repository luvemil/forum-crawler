require 'rubytree'
module BaseCrawler
    class TreeNode < ::Tree::TreeNode
        attr_accessor :data, :children, :parent
        def initialize data = nil
            @children = []
            if data
                @data = data
            else
                @data = Hash.new
            end
        end

        def add_child data
            new_child = TreeNode.new data
            new_child.parent = self
            @children += [ new_child ]
        end
    end

    class Tree
        attr_accessor :root
        attr_reader :index
        def initialize root = nil
            @root = root
        end

        def self._gen_name name, index
            # Generate a new name for a child, given the name of the instance
            # and an index (which should be updated once a child is added).
            # Returns [ child_name, index + 1 ]
            index ||= 0 # if is not define put it to zero
            return "#{name}-#{index}"
        end

        def gen_name
            # Fix root_name
            name = Tree._gen_name <root_name>, @index
            @index += 1
            return name
        end
    end
end
