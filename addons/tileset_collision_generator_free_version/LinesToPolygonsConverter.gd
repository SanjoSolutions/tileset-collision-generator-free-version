var _open_polygons
var _closed_polygons
var _polygon_open_points_to_polygon

func convert(lines):
	_open_polygons = []
	_closed_polygons = []
	_polygon_open_points_to_polygon = Dictionary()
	
	for line in lines:
		var a = line[0]
		var b = line[1]
		var polygon_that_a_connects_with = _find_polygon_that_point_connects_with(a)
		var polygon_that_b_connects_with = _find_polygon_that_point_connects_with(b)
		var a_connects_with_polygon_open_point = polygon_that_a_connects_with != null
		var b_connects_with_polygon_open_point = polygon_that_b_connects_with != null
		if a_connects_with_polygon_open_point and b_connects_with_polygon_open_point:
			if polygon_that_a_connects_with == polygon_that_b_connects_with:
				# print("_close_polygon: ", polygon_that_a_connects_with)
				_close_polygon(polygon_that_a_connects_with)
			else:
				# print("_merge_polygons: ", polygon_that_a_connects_with, polygon_that_b_connects_with, a, b)
				_merge_polygons(polygon_that_a_connects_with, polygon_that_b_connects_with, a, b)
		elif a_connects_with_polygon_open_point:
			# print("_connect_a_with_polygon: ", polygon_that_a_connects_with, line)
			_connect_a_with_polygon(polygon_that_a_connects_with, line)
		elif b_connects_with_polygon_open_point:
			# print("_connect_b_with_polygon: ", polygon_that_b_connects_with, line)
			_connect_b_with_polygon(polygon_that_b_connects_with, line)
		else:
			# print("_start_new_polygon: ", line)
			_start_new_polygon(line)

	if len(_open_polygons):
		print("There were still " + str(len(_open_polygons)) + " open polygons.")

	return _closed_polygons
	
func _find_polygon_that_point_connects_with(point):
	return _polygon_open_points_to_polygon[point[0]][point[1]] if _polygon_open_points_to_polygon.has(point[0]) and _polygon_open_points_to_polygon[point[0]].has(point[1]) else null

func _close_polygon(polygon):
	_open_polygons.erase(polygon)
	_remove_point_from_polygon_open_points_to_polygon(polygon[0])
	_remove_point_from_polygon_open_points_to_polygon(polygon[-1])
	_closed_polygons.append(polygon)

func _merge_polygons(polygon_a, polygon_b, point_a, point_b):
	var connected_polygon = []

	if point_a == polygon_a[0] and point_b == polygon_b[0]:
		var polygon_b_copy = polygon_b.duplicate()
		polygon_b_copy.reverse()
		connected_polygon = _connect_polygons(polygon_b_copy, polygon_a)
	elif point_a == polygon_a[0] and point_b == polygon_b[- 1]:
		connected_polygon = _connect_polygons(polygon_b, polygon_a)
	elif point_a == polygon_a[- 1] and point_b == polygon_b[0]:
		connected_polygon = _connect_polygons(polygon_a, polygon_b)
	elif point_a == polygon_a[- 1] and point_b == polygon_b[- 1]:
		var polygon_b_copy = polygon_b.duplicate()
		polygon_b_copy.reverse()
		connected_polygon = _connect_polygons(polygon_a, polygon_b_copy)
	else:
		push_error("Unexpected case.")
		return

	_open_polygons.erase(polygon_a)
	_open_polygons.erase(polygon_b)
	_open_polygons.append(connected_polygon)

func _connect_polygons(polygon_a, polygon_b):
	var connected_polygon = []
	connected_polygon.append_array(polygon_a)
	connected_polygon.append_array(polygon_b)
	_remove_point_from_polygon_open_points_to_polygon(polygon_a[ - 1])
	_remove_point_from_polygon_open_points_to_polygon(polygon_b[0])
	_set_open_point_to_polygon(connected_polygon[0], connected_polygon)
	_set_open_point_to_polygon(connected_polygon[ - 1], connected_polygon)
	return connected_polygon

func _connect_a_with_polygon(polygon, line):
	var a = line[0]
	var b = line[1]
	if polygon[0] == a:
		_remove_point_from_polygon_open_points_to_polygon(polygon[0])
		polygon.push_front(b)
		_set_open_point_to_polygon(polygon[0], polygon)
	elif polygon[- 1] == a:
		_remove_point_from_polygon_open_points_to_polygon(polygon[ - 1])
		polygon.append(b)
		_set_open_point_to_polygon(polygon[ - 1], polygon)
	else:
		push_error("Unexpected case.")

func _connect_b_with_polygon(polygon, line):
	var a = line[0]
	var b = line[1]
	if polygon[0] == b:
		_remove_point_from_polygon_open_points_to_polygon(polygon[0])
		polygon.push_front(a)
		_set_open_point_to_polygon(polygon[0], polygon)
	elif polygon[- 1] == b:
		_remove_point_from_polygon_open_points_to_polygon(polygon[ - 1])
		polygon.append(a)
		_set_open_point_to_polygon(polygon[ - 1], polygon)
	else:
		push_error("Unexpected case.")

func _start_new_polygon(line):
	var polygon = []
	polygon.append_array(line)
	_open_polygons.append(polygon)
	_set_open_point_to_polygon(line[0], polygon)
	_set_open_point_to_polygon(line[1], polygon)

func _set_open_point_to_polygon(point, polygon):
	if not _polygon_open_points_to_polygon.has(point[0]):
		_polygon_open_points_to_polygon[point[0]] = Dictionary()
	_polygon_open_points_to_polygon[point[0]][point[1]] = polygon

func _remove_point_from_polygon_open_points_to_polygon(point):
	if _polygon_open_points_to_polygon.has(point[0]):
		_polygon_open_points_to_polygon[point[0]].erase(point[1])
