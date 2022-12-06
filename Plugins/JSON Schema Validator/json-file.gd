extends File

const SCHEMA_VALIDATOR_SCENE = preload('./json-schema-validator.gd')

var schema_validator = SCHEMA_VALIDATOR_SCENE.new()

signal data_loaded(err, data)

func save_data(json_data):
  if is_open():
    store_line(json_data.to_json())

func load_data(raw_schema):
  if is_open():
    var result = get_as_text()
    var parsed_result = {}
    var err = schema_validator.parse_json(result, raw_schema)

    if typeof(err) == TYPE_STRING:
      emit_signal('data_loaded', err, null)

    else:
      emit_signal('data_loaded', null, err)
