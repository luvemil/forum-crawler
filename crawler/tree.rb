module BaseCrawler
    class Tree
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
    end
end
