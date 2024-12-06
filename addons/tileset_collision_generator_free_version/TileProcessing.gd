const LinesToPolygonsConverter = preload ("./LinesToPolygonsConverter.gd")

var _task_queue = []
var _mutex: Mutex
var _threads = []

func start():
	if len(_threads) == 0:
		_mutex = Mutex.new()
		var processor_count = OS.get_processor_count()
		var number_of_threads = max(1, processor_count - 4)
		for i in range(number_of_threads):
			var thread = Thread.new()
			var semaphore = Semaphore.new()
			var data = {
				semaphore = semaphore,
				exit = false
			}
			_threads.append({
				thread = thread,
				data = data
			})
			thread.start(_thread_main.bind(data), Thread.PRIORITY_LOW)
	
func stop():
	for thread in _threads:
		thread.data.exit = true	
		thread.data.semaphore.post()
		
	for thread in _threads:
		thread.thread.wait_to_finish()
	
func queue_task(task):
	_mutex.lock()
	_task_queue.push_back(task)
	_mutex.unlock()
	for thread in _threads:
		thread.data.semaphore.post()

func _thread_main(data):
	while true:
		data.semaphore.wait()

		if data.exit:
			break

		_mutex.lock()
		var task = _task_queue.pop_front()
		_mutex.unlock()
		
		if task != null:
			var tile_id = task.tile_id
			var image = task.image
			var tile_set_source = task.tile_set_source
			
			var tile_data = tile_set_source.get_tile_data(tile_id, 0)
			if tile_data.get_collision_polygons_count(0) == 0:
				var tile_texture_region = tile_set_source.get_tile_texture_region(tile_id, 0)
				var tile_image = image.get_region(tile_texture_region)
				var polygons = _find_polygons(tile_image)
				for polygon_index in range(len(polygons)):
					var polygon = polygons[polygon_index]
					var polygon2 = polygon.map(func(point): return Vector2(point[0] - 0.5 * tile_texture_region.size[0], point[1] - 0.5 * tile_texture_region.size[1]))
					tile_data.call_deferred("add_collision_polygon", 0)
					tile_data.call_deferred("set_collision_polygon_points", 0, polygon_index, PackedVector2Array(polygon2))

func _find_polygons(image: Image):
	var pixels = Array()
	pixels.resize(image.get_height())
	for index in range(len(pixels)):
		var row = Array()
		row.resize(image.get_width())
		pixels[index] = row
	
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var pixel = image.get_pixel(x, y)
			pixels[y][x] = pixel.a >= 0.4
	
	var pixel_types = Array()
	pixel_types.resize(image.get_height())
	for index in range(len(pixel_types)):
		var row = Array()
		row.resize(image.get_width())
		pixel_types[index] = row

	for row_index in range(len(pixels)):
		for column_index in range(len(pixels[0])):
			if pixels[row_index][column_index]:
				var type = 0
				if row_index >= 1:
					if pixels[row_index - 1][column_index]:
						type |= (1 << 3)
				if column_index <= image.get_width() - 2:
					if pixels[row_index][column_index + 1]:
						type |= (1 << 2)
				if row_index <= image.get_height() - 2:
					if pixels[row_index + 1][column_index]:
						type |= (1 << 1)
				if column_index >= 1:
					if pixels[row_index][column_index - 1]:
						type |= (1 << 0)
				
				pixel_types[row_index][column_index] = type
	
	var all_lines = []
	for row_index in range(len(pixel_types)):
		for column_index in range(len(pixel_types[0])):
			if pixels[row_index][column_index]:
				var type = pixel_types[row_index][column_index]
				var lines
				if type == 0b0000:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0001:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)]
					]
				elif type == 0b0010:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0011:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)]
					]
				elif type == 0b0100:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0101:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
					]
				elif type == 0b0110:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b0111:
					lines = [
						[Vector2(column_index, row_index), Vector2(column_index + 1, row_index)]
					]
				elif type == 0b1000:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1001:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)]
					]
				elif type == 0b1010:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1011:
					lines = [
						[Vector2(column_index + 1, row_index), Vector2(column_index + 1, row_index + 1)]
					]
				elif type == 0b1100:
					lines = [
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)],
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1101:
					lines = [
						[Vector2(column_index + 1, row_index + 1), Vector2(column_index, row_index + 1)]
					]
				elif type == 0b1110:
					lines = [
						[Vector2(column_index, row_index + 1), Vector2(column_index, row_index)]
					]
				elif type == 0b1111:
					lines = []
				all_lines.append_array(lines)
	
	var lines_to_polygons_converter = LinesToPolygonsConverter.new()
	var polygons = lines_to_polygons_converter.convert(all_lines)
	polygons = _optimize_polygons(polygons)
	
	return polygons
	
func _optimize_polygons(polygons):
	return polygons.map(Callable(self, "_optimize_polygon"))
	
func _optimize_polygon(polygon):
	var index = 0
	
	while index < len(polygon):
		var p1 = polygon[index]
		var p2 = polygon[(index + 1) % len(polygon)]
		var p3 = polygon[(index + 2) % len(polygon)]
		if _can_be_optimized_to_one_line(p1, p2, p3):
			# print("can_be_optimized_to_one_line: ", p1, p2, p3)
			# print("before: ", polygon)
			if index == len(polygon) - 2:
				var new_polygon = polygon.slice(0, len(polygon) - 1)
				polygon = new_polygon
			elif index == len(polygon) - 1:
				var new_polygon = polygon.slice(1)
				polygon = new_polygon
			else:
				var optimized_line = _optimize_to_one_line(p1, p2, p3)
				var new_polygon = []
				new_polygon.append_array(polygon.slice(0, index))
				new_polygon.append_array(optimized_line)
				new_polygon.append_array(polygon.slice(index + 3))
				polygon = new_polygon
			# print("after: ", polygon)
		else:
			index += 1

	return polygon
	
func _can_be_optimized_to_one_line(p1, p2, p3):
	var slope1 = atan2(p2[1] - p1[1], p2[0] - p1[0])
	var slope2 = atan2(p3[1] - p2[1], p3[0] - p2[0])
	return slope1 == slope2
	
func _optimize_to_one_line(p1, p2, p3):
	return [p1, p3]
