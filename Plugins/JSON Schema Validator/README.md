# JSON-Schema-validator

This is script for Godot Engine 2.x, that validate JSON files by JSON Schema. 

## ![License file](./LICENSE)

## How to use
```gdscript
const JSON_FILE = preload('PATH TO/json-file.gd')

func _init():
  var raw_schema_file = File.new()
  var json_file_loader = JSON_FILE.new()

  raw_schema_file.open('PATH TO/schema.json', File.READ)
  var raw_schema = raw_schema_file.get_as_text()
  raw_schema_file.close()

  json_file_loader.connect('data_loaded', self, '_data_loaded', [], CONNECT_ONESHOT)
  json_file_loader.open('PATH TO/data.json', File.READ)
  json_file_loader.load_data(raw_schema)

  # Don't forget to close the file!
  json_file_loader.close()

func _data_loaded(error, data):
  print('Error: %s, Data: %s' % [error, data])

```

## Links
More about schemas and validation here: https://json-schema.org

## Special thanks
Kael the bear, Pwa for his moral support (but not kael), Viraax, Teratak, Weaslia

### Made by [Binogure Studio](https://www.binogure-studio.com)