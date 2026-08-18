extends Area2D
class_name QuestObjectiveTrigger
## A reusable authored-world trigger for non-combat quest objectives.

@export_enum("find", "escort") var objective_type: String = "find"
@export var target_id: String = ""
@export var success_message: String = ""


func _ready() -> void:
    body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
    activate_for(body)


func activate_for(player: Node) -> bool:
    if target_id.is_empty() or not player or not player.has_method("has_active_objective"):
        return false
    if not player.has_active_objective(objective_type, target_id):
        return false

    match objective_type:
        "find":
            if not player.has_method("add_item"):
                return false
            player.add_item(target_id)
        "escort":
            if not player.has_method("record_escort_completed"):
                return false
            player.record_escort_completed(target_id)
        _:
            return false

    if not success_message.is_empty():
        UIManager.show_notification(success_message, "success")
    return true
