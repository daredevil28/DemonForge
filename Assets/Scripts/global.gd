#Singleton for global variables
extends Node

var notification_popup : NotificationManager
var popup_dialog : DialogManager
var game_scene_node : Node
var file_manager : FileManager
var metronome : Node
@onready var client_settings : Array = get_tree().get_nodes_in_group("ClientSettings")
@onready var volume_sliders : Array = get_tree().get_nodes_in_group("VolumeSliders")
