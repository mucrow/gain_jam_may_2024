class_name Utils


static func change_parent(child: Node, new_parent: Node):
  var old_parent = child.get_parent()
  old_parent.remove_child(child)
  new_parent.add_child(child)
