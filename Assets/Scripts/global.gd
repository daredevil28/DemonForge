extends Node
## Singleton for global variables

var notification_popup : NotificationManager
var popup_dialog : DialogManager
var game_scene_node : Node2D
var file_manager : FileManager
var metronome : Node
var background_image : TextureRect
var multi_select : MultiSelect
var progress_bar : ProgressBar
var ui_controller : Control
@onready var client_settings : Array = get_tree().get_nodes_in_group("ClientSettings")
@onready var volume_sliders : Array = get_tree().get_nodes_in_group("VolumeSliders")
@onready var instruments : Array = get_tree().get_nodes_in_group("Instruments")
