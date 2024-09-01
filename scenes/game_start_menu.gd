extends CanvasLayer

signal restart

func _on_button_pressed():
	restart.emit()

func _on_option_button_item_selected(index):
	var selected_option = $OptionButton.get_item_text(index)
	get_parent().set_difficulty(selected_option)
