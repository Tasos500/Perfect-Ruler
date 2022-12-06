extends SceneTree

const JSON_FILE = preload('../json-file.gd')

func _init():
  var raw_schema_file = File.new()
  var json_file_loader = JSON_FILE.new()

  raw_schema_file.open('res://example/schema.json', File.READ)
  var raw_schema = raw_schema_file.get_as_text()
  raw_schema_file.close()

  json_file_loader.connect('data_loaded', self, '_data_loaded', [], CONNECT_ONESHOT)
  json_file_loader.open('res://example/data.json', File.READ)
  json_file_loader.load_data(raw_schema)
  json_file_loader.close()

func _data_loaded(error, data):

  print('Error: %s, Data: %s' % [error, data])
  quit()
