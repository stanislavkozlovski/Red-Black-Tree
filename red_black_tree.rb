:BLACK
:RED
:NIL_C
:LEFT
:RIGHT

# Contain combinations of directions
DIRECTIONS = {
    [:LEFT, :RIGHT] => 'LR',
    [:RIGHT, :LEFT] => 'RL',
    [:RIGHT, :RIGHT] => 'RR',
    [:LEFT, :LEFT] => 'LL'
}

class Node
  attr_accessor :value, :color, :parent, :left, :right

  def initialize(value, color, parent, left, right)
    @value = value
    @color = color
    @parent = parent
    @left = left
    @right = right
  end

  def ==(other)
    if self.color == :NIL_C && other.color==self.color
      return true
    end
    same_parents = false
    if self.parent.nil? || other.parent.nil?
      same_parents = self.parent.nil? && other.parent.nil?
    else
      same_parents = self.parent.value == other.parent.value
    end

    self.value == other.value && self.color == other.color && same_parents
  end

  def has_children?
    self.get_children_count != 0
  end

  def get_children_count
    if self.color == :NIL_C
      return 0
    end

    if self.left.color != :NIL_C && self.right.color != :NIL_C
      return 2
    elsif self.left.color != :NIL_C || self.right.color != :NIL_C
      return 1
    else
      return 0
    end
  end

  def to_s
    "#{@color} #{@value}"
  end
  def inspect
    to_s
  end
end


class RedBlackTree
  @@nil_leaf = Node.new(value=NIL, color=:NIL_C, parent=NIL, left=NIL, right=NIL)
  attr_accessor :count, :root
  def initialize
    @count = 0
    @root = NIL
  end

  def add(value)
    if @root.nil?
      @root = Node.new(value=value, color=:BLACK, parent=NIL, left=@@nil_leaf, right=@@nil_leaf)
      @count += 1
      return
    end

    parent, direction = find_parent value
    if direction.nil?
      return  # value is in the tree
    end

    new_node = Node.new(value=value, color=:RED, parent=parent, left=@@nil_leaf, right=@@nil_leaf)
    if direction == :LEFT
      parent.left = new_node
    else
      parent.right = new_node
    end

    try_rebalance new_node
    @count += 1
  end

  def try_rebalance(new_node)
    parent = new_node.parent
    value = new_node.value

    if parent.nil? ||  # what the fuck?
        parent.parent.nil? || # parent is root
        parent.color != :RED  # no red-red, no problem :)
      return
    end

    grandfather = parent.parent
    direction = if parent.value > new_node.value then :LEFT else :RIGHT end
    parent_direction = if grandfather.value > parent.value then :LEFT else :RIGHT end
    uncle = if parent_direction == :LEFT then grandfather.right else grandfather.left end
    general_direction = DIRECTIONS[[direction, parent_direction]]

    if uncle == @@nil_leaf || uncle.color == :BLACK
      if general_direction == 'LL'
        # LL => Right rotation
        right_rotation(new_node, parent, grandfather, to_recolor=true)
      elsif general_direction == 'RR'
        # RR => Left rotation
        left_rotation(new_node, parent, grandfather, to_recolor=true)
      elsif general_direction == 'LR'
        # LR => Right rotation, left rotation
        right_rotation(NIL, new_node, parent, to_recolor=false)
        # due to the right rotation, parent and new_node positions have switched
        left_rotation(parent, new_node, grandfather, to_recolor=true)
      elsif general_direction == 'RL'
        # RL => Left rotation, right rotation
        left_rotation(NIL, new_node, parent, to_recolor=false)
        # due to the left rotation, parent and new_node positions have switches
        right_rotation(parent, new_node, grandfather, to_recolor=true)
      end
    else
      # uncle is red, simply recolor
      recolor(grandfather)
    end

  end

  def right_rotation(node, parent, grandfather, to_recolor=false)
    grand_grandfather = grandfather.parent
    # grandfather will become the right child of parent
    update_parent(node=parent, parent_old_child=grandfather, new_parent=grand_grandfather)

    old_right = parent.right
    parent.right = grandfather
    grandfather.parent = parent
    grandfather.left = old_right
    old_right.parent = grandfather

    if to_recolor  # recolor the nodes after a move to preserve invariants
      parent.color = :BLACK
      node.color = :RED
      grandfather.color = :RED
    end
  end

  def left_rotation(node, parent, grandfather, to_recolor=false)
    grand_grandfather = grandfather.parent
    # grandfather will become the left child of parent
    update_parent(node=parent, parent_old_child=grandfather, new_parent=grand_grandfather)

    old_left = parent.left
    parent.left = grandfather
    grandfather.parent = parent
    grandfather.right = old_left
    old_left.parent = grandfather

    if to_recolor
      parent.color = :BLACK
      grandfather.color = :RED
      node.color = :RED
    end
  end

  # recolors the grandfather red, coloring his children black
  def recolor(grandfather)
    grandfather.left.color = :BLACK
    grandfather.right.color = :BLACK
    if @root != grandfather
      grandfather.color = :RED
    end

    try_rebalance grandfather
  end

  # our node 'switches' place with the old child, assigning a new parent to the node
  # if the new_parent is NIL, this means that our node becomes the root of the tree
  def update_parent(node, parent_old_child, new_parent)
    node.parent = new_parent
    if not new_parent.nil?
      # determine the old child's position to put the node there
      if new_parent.value > parent_old_child.value
        new_parent.left = node
      else
        new_parent.right = node
      end
    else
      @root = node
    end
  end

  # finds a place for the value in the binary tree, returning the node and the direction it should go in
  def find_parent(value)
    find = lambda do |node|
      if node.value == value
        return
      elsif node.value > value
        # go left
        if node.left.color == :NIL_C
          # no more to go
          return node, :LEFT
        end

        return find.call node.left
      else
        # go right
        if node.right.color == :NIL_C
          # no more to go
          return node, :RIGHT
        end
        return find.call node.right
      end
    end

    find.call @root
  end

  # removes a node from the tree
  def remove(value)
    # try to get a node with 0 or 1 children (by finding a successor if needed)
    node_to_remove = find_node value
    if node_to_remove.nil?
      return  #  value not in tree
    end

    if node_to_remove.get_children_count == 2  # does not have 0 or 1 children, find successor
      # find the in-order successor and replace its value, then remove the successor
      successor = find_successor node_to_remove
      node_to_remove.value = successor.value
      node_to_remove = successor
    end

    remove_internal node_to_remove
    @count -= 1
  end

  # receives a node with 0 or 1 children and removes it according to its color/children
  def remove_internal(node_to_remove)
    left_child = node_to_remove.left
    right_child = node_to_remove.right
    not_nil_child = if left_child != @@nil_leaf then left_child else right_child end
    if node_to_remove == self.root
      if not_nil_child != @@nil_leaf
        @root = not_nil_child
        @root.parent = NIL
        @root.color = :BLACK
      else  # both children are nil and this is the root
        @root = NIL
      return
      end

      if node_to_remove.color == :RED
        # red node with no children, simple remove
        if node_to_remove.has_children?
          raise Exception('Unexpected behavior, a successor red node without 2 children should not have any children!')
        end
        remove_leaf node
      else  # node is black
        if not_nil_child.color == :RED
          # last easy chance, swap the values with the red child and simply remove it
          node_to_remove.value = not_nil_child.value
          node_to_remove.left = not_nil_child.left
          node_to_remove.right = not_nil_child.right
        else  # black child
          # 6 different cases apply here, good luck
          remove_black_node node_to_remove
        end
      end

    end

  end

  # loop through each of the 6 cases until we reach a terminating case
  # what we're left is a leaf node ready to be deleted
  def remove_black_node(node_to_remove)
    # code here
    case_1 node_to_remove
    remove_leaf node_to_remove
  end




  # simply removes a leaf node, making its parent point to a NIL_LEAF
  def remove_leaf(node)
    if node.parent.value > node.value
      node.parent.left = @@nil_leaf
    else
      node.parent.right = @@nil_leaf
    end
  end

  def find_successor(node_to_remove)
    successor = node_to_remove.right
    successor = successor.left while successor.left != @@nil_leaf
    successor
  end

  def find_node(value)
    find = Proc.new do |node|
      if node.nil? || node == @@nil_leaf
        return NIL
      elsif node.value == value
        return node
      elsif node.value > value
        return find.call node.left
      else
        return find.call node.right
      end
    end

    find.call @root
  end

  # Case 1 is when there's a double black node on the root
  # Because we're at the root, we can simply remove it
  # and reduce the black height of the whole tree.
  #
  #   __|10B|__                  __10B__
  # /         \      ==>       /       \
  #9B         20B            9B        20B
  def case_1(node_to_remove)
    if @root == node_to_remove
      node_to_remove.color = :BLACK
      return
    end

    case_2 node_to_remove
  end

  # case 2 applies when
  # the parent is BLACK
  # the sibling is RED
  # the sibling's children are BLACK or NIL
  #It takes the sibling and rotates it
  #
  #                        40B                                              60B
  #                      /   \       --CASE 2 ROTATE-->                   /   \
  #                 |20B|   60R       LEFT ROTATE                      40R   80B
  # DBL BLACK IS 20----^   /   \      SIBLING 60R                     /   \
  #                      50B    80B                                |20B|  50B
  #            (if the sibling's direction was left of its parent, we would RIGHT ROTATE it)
  #        Now the original node's parent is RED
  #        and we can apply case 4 or case 6
  def case_2(node_to_remove)
    parent = node_to_remove.parent
    sibling, direction = get_sibling node_to_remove
    if sibling.color == :RED && parent.color == :BLACK && sibling.left.color != :RED && sibling.right.color != :RED
      if direction == :RIGHT
        left_rotation(node=NIL, parent=sibling, grandfather=parent)
      else
        right_rotation(node=NIL, parent=sibling, grandfather=parent)
      end
      parent.color = :RED
      sibling.color = :BLACK
      return case_1 node_to_remove
    end

    case_3 node_to_remove
  end


#Case 3 deletion is when:
#           the parent is BLACK
#          the sibling is BLACK
#         the sibling's children are BLACK (or nil)
#        Then, we make the sibling red and
#       pass the double black node upwards
#
#                           Parent is black
#              ___50B___    Sibling is black                       ___50B___
#              /         \   Sibling's children are black          /         \
#           30B          80B        CASE 3                       30B        |80B|  Continue with other cases
#          /   \        /   \        ==>                        /  \        /   \
#        20B   35R    70B   |90B|<---REMOVE                   20B  35R     70R   X
#              /  \                                               /   \
#            34B   37B                                          34B   37B
  def case_3(node_to_remove)
    parent = node_to_remove.parent
    sibling, _ = get_sibling node_to_remove
    if sibling.color == :BLACK && parent.color == :BLACK && sibling.left.color != :RED && sibling.right.color != :RED
      # color the sibling red and forward the black node upwards, calling the cases for the parent
      sibling.color = :RED
      return case_1 parent
    end

    case_4 node_to_remove
  end

# TERMINATING CASE
#   If the parent is red and the sibling is black with no red children,
#        simply swap their colors
#        DB-Double Black
#                __10R__                   __10B__        The black height of the left subtree has been incremented
#               /       \                 /       \       And the one below stays the same
#             DB        15B      ===>    X        15R     No consequences, we're done!
#                      /   \                     /   \
#                    12B   17B                 12B   17B
  def case_4(node_to_remove)
    parent = node_to_remove.parent
    sibling, _ = get_sibling node_to_remove
    if parent.color == :RED && sibling.color == :BLACK && sibling.left.color != :RED && sibling.right.color != :RED
      parent.color = :BLACK
      sibling.color = :RED
      return
    end

    case_5 node_to_remove
  end

#  Case 5 is a rotation that changes the circumstances so that we can do a case 6
#        If the closer node is red and the outer BLACK or NIL, we do a left/right rotation, depending on the orientation
#        This showcases when the CLOSER NODE's direction is RIGHT
#
#              ___50B___                                                    __50B__
#             /         \                                                  /       \
#           30B        |80B|  <-- Double black                           35B      |80B|        Case 6 is now
#          /  \        /   \      Closer node is red (35R)              /   \      /           applicable here,
#        20B  35R     70R   X     Outer is black (20B)               30R    37B  70R           so we redirect the node
#            /   \                So we do a LEFT ROTATION          /   \                      to it :)
#          34B  37B               on 35R (closer node)           20B   34B
  def case_5(node_to_remove)
    sibling, direction = get_sibling node_to_remove
    closer_node = if direction == :LEFT then sibling.right else sibling.left end
    outer_node = if direction == :LEFT then sibling.left else sibling.right end
    if closer_node.color == :RED && outer_node.color != :RED && sibling.color == :BLACK
      if direction == :LEFT
        left_rotation(node=NIL, parent=closer_node, grandfather=sibling)
      else
        right_rotation(node=NIL, parent=closer_node, grandfather=sibling)
      end
      closer_node.color = :BLACK
      sibling.color = :RED
    end

    case_6 node_to_remove
  end

# TERMINATING
#  Case 6 requires
#            SIBLING to be BLACK
#            OUTER NODE to be RED
#        Then, does a right or left rotation on the sibling
#        This will showcase when the SIBLING's direction is LEFT
#
#                            Double Black
#                    __50B__       |                               __35B__
#                   /       \      |                              /       \
#      SIBLING--> 35B      |80B| <-                             30R       50R
#                /   \      /                                  /   \     /   \
#             30R    37B  70R   Outer node is RED            20B   34B 37B    80B
#            /   \              Closer node doesn't                           /
#         20B   34B                 matter                                   70R
#                               Parent doesn't
#                                   matter
#                               So we do a right rotation on 35B!
  def case_6(node_to_remove)
    sibling, direction = get_sibling node_to_remove
    outer_node = if direction == :LEFT then sibling.left else sibling.right end

    case_6_rotation = Proc.new do |dir|
      parent_color = sibling.parent.color
      if dir == :LEFT
        right_rotation(node=NIL, parent=sibling, grandfather=sibling.parent)
      else
        left_rotation(node=NIL, parent=sibling, grandfather=sibling.parent)
      end
      # our new parent is the sibling
      sibling.color = parent_color
      sibling.right.color = :BLACK
      sibling.left.color = :BLACK
    end

    if sibling.color == :BLACK && outer_node.color == :RED
      return case_6_rotation(direction)  # terminating
    end

    raise Exception('Should not have reached here')
  end

  def get_sibling(node)
    # code here
    parent = node.parent
    parent_sibling, dir = if parent.left == node then [parent.right, :RIGHT] else [parent.left, :LEFT] end
    return parent_sibling, dir
  end

  public :add
  private :find_parent, :update_parent, :recolor, :right_rotation, :left_rotation
  # end

  def self.get_nil_leaf
    return @@nil_leaf
  end
end
