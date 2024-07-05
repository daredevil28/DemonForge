extends OptionButton
## Script to setup and change languages

var _change_selected : bool = false


func _ready() -> void:
	for locale : String in TranslationServer.get_loaded_locales():
		for i : int in range(0,TranslationServer.get_all_languages().size()):	
			if(TranslationServer.compare_locales(locale, TranslationServer.get_all_languages()[i]) >= 1):
				add_icon_item(load("res://Assets/Flags/" + locale + ".png"),locale,i)
			
			if(_change_selected == false):
				if(TranslationServer.compare_locales(TranslationServer.get_locale(), TranslationServer.get_all_languages()[i]) >= 1):
					selected = get_item_index(i)
					if(selected != -1):
						_change_selected = true


func _on_item_selected(index: int) -> void:
	print("Changing locale to: " + TranslationServer.get_all_languages()[get_item_id(index)])
	TranslationServer.set_locale(TranslationServer.get_all_languages()[get_item_id(index)])
