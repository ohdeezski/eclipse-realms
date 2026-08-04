extends Node
func _ready():
    var class_list = ClassDB.get_class_list()
    for c in class_list:
        if "websocket" in c.to_lower() or "web_socket" in c.to_lower():
            print(c)
    get_tree().quit()