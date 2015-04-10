require 'rubytree'
module BaseCrawler
    class Tree < ::Tree::TreeNode
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
            new_child = Tree.new data
            new_child.parent = self
            @children += [ new_child ]
        end

        def self._gen_name name, index
            # Generate a new name for a child, given the name of the instance
            # and an index (which should be updated once a child is added).
            # Returns [ child_name, index + 1 ]
            index ||= 0 # if is not define put it to zero
            return [ "#{name}-#{index}", index + 1 ]
    end
end
