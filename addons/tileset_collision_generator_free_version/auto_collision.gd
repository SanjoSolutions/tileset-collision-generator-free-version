@tool
extends EditorPlugin

const TileProcessing = preload("./TileProcessing.gd")

var tile_processing

func _enter_tree():
	if Engine.is_editor_hint():
		var command_palette = EditorInterface.get_command_palette()
		var command_callable = Callable(self, "_auto_collision")
		command_palette.add_command("Generate collision", "tileset_collision_generator_free_version/generate_collision", command_callable)
		
func _exit_tree():
	if Engine.is_editor_hint():
		if tile_processing != null:
			tile_processing.stop()

func _auto_collision():
	var tileset_path = EditorInterface.get_current_path()
	var tile_set = load(tileset_path)
	if tile_set is TileSet:
		var physics_layers_count = tile_set.get_physics_layers_count()
		if physics_layers_count == 0:
			var confirmation_dialog = ConfirmationDialog.new()
			confirmation_dialog.title = "Create physics layer?"
			confirmation_dialog.ok_button_text = "Yes"
			confirmation_dialog.cancel_button_text = "No"
			confirmation_dialog.dialog_text = "The TileSet has no physics layer (for collision). Should one be created?"
			confirmation_dialog.get_ok_button().pressed.connect(_create_physics_layer_and_continue.bind(tile_set))
			EditorInterface.popup_dialog_centered(confirmation_dialog)
		elif physics_layers_count > 1:
			_auto_collision2(tile_set)
		else:
			_auto_collision2(tile_set)
	else:
		printerr("Resource \"" + tileset_path + "\" is not a TileSet.")

func _create_physics_layer_and_continue(tile_set: TileSet):
	_create_physics_layer(tile_set)
	_auto_collision2(tile_set)

func _create_physics_layer(tile_set: TileSet):
	tile_set.add_physics_layer(0)

func _auto_collision2(tile_set: TileSet):
	if tile_processing == null:
		tile_processing = TileProcessing.new()
		tile_processing.start()
	var has_shown_free_version_limiations = false
	for index in tile_set.get_source_count():
		var source_id = tile_set.get_source_id(index)
		var tile_set_source = tile_set.get_source(source_id)
		if tile_set_source is TileSetAtlasSource:
			var texture_region_size = tile_set_source.texture_region_size
			var image = tile_set_source.texture.get_image()
			# Changing this code violates the license.
			# Please consider buying the full version at: https://sanjox.itch.io/godot-collision-generator
			if image.get_width() <= 240 and image.get_height() <= 240:
				for tile_index in tile_set_source.get_tiles_count():
					var tile_id = tile_set_source.get_tile_id(tile_index)
					if tile_set_source.has_tile(tile_id):
						var task = {
							tile_id = tile_id,
							image = image,
							tile_set_source = tile_set_source
						}
						tile_processing.queue_task(task)
			elif not has_shown_free_version_limiations:
				var dialog = ConfirmationDialog.new()
				dialog.title = "Collision polygons are only generated for some of the images"
				dialog.dialog_text = "Some of the tileset images are wider or have a larger height than 240 pixel.\n The free version of this plugin only generates collision polygons for tileset images where the width is <= 240 pixel and height <= 240 pixel.\n The full version generates collision polygons for all tileset images."
				dialog.ok_button_text = "Go to full version"
				dialog.cancel_button_text = "Ok"
				dialog.get_ok_button().pressed.connect(func(): OS.shell_open("https://sanjox.itch.io/godot-collision-generator"))
				EditorInterface.popup_dialog_centered(dialog)
				has_shown_free_version_limiations = true
