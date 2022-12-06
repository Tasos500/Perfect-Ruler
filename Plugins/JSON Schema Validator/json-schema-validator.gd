extends Reference 

const JSON_ERROR = preload('./json-error.gd')

# This is one and only function that need you to call outside
# If all validation checks passes, this return empty String
func parse_json(raw_data, raw_schema):
  var parsed_schema = {}
  var parsed_data = {}
  var error = parsed_data.parse_json(raw_data)

  if OK != error:
    return JSON_ERROR.ERR_INVALID_JSON_EXT % [error]

  error = parsed_schema.parse_json(raw_schema)

  if OK != error:
    return '%s%s' % [
      JSON_ERROR.ERR_WRONG_SCHEMA_GEN,
      JSON_ERROR.GDSCRIPT_ERRORS[error]
    ]

  var parsed_schema_type = typeof(parsed_schema)

  if parsed_schema_type == TYPE_BOOL or parsed_schema_type == TYPE_INT:
    return JSON_ERROR.ERR_INVALID_JSON_GEN % [JSON_ERROR.ERR_SCHEMA_FALSE]

  elif parsed_schema_type == TYPE_DICTIONARY:
    if parsed_schema.empty():
      return parsed_data

    elif not parsed_schema.has(JSON_ERROR.JSKW_TYPE):
      return JSON_ERROR.ERR_WRONG_SCHEMA_TYPE

  else:
    return JSON_ERROR.ERR_WRONG_SCHEMA_TYPE

  # Normal return empty string, meaning OK
  return _type_selection(parsed_data, parsed_schema)

func _data_to_string(data):
  return data.to_json() if typeof(data) == TYPE_DICTIONARY else '%s' % [data]

func _to_string():
  return '[JSONSchema:%d]' % [get_instance_id()]

func _type_selection(parsed_data, schema, key = JSON_ERROR.DEF_KEY_NAME):
  var typearr = _var_to_array(schema.type)
  var error = JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [typearr, key]
  var parsed_data_type = typeof(parsed_data)

  for type in typearr:
    if type == JSON_ERROR.JST_ARRAY: 
      if parsed_data_type == TYPE_ARRAY:
        error = _validate_array(parsed_data, schema, key)

    elif type == JSON_ERROR.JST_BOOLEAN:
      if parsed_data_type != TYPE_BOOL:
        return JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [[JSON_ERROR.JST_BOOLEAN], key]

      else:
        error = ''

    elif type == JSON_ERROR.JST_INTEGER:
      if parsed_data_type == TYPE_INT or parsed_data.is_valid_integer():
        error = _validate_integer(parsed_data, schema, key)

      if parsed_data_type == TYPE_REAL and parsed_data == int(parsed_data):
        error = _validate_integer(int(parsed_data), schema, key)

    elif type == JSON_ERROR.JST_NULL:
      if parsed_data_type != TYPE_NIL:
        return JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [[JSON_ERROR.JST_NULL], key]

      else:
        error = ''

    elif type == JSON_ERROR.JST_NUMBER: 
      if parsed_data_type == TYPE_REAL:
        error = _validate_number(parsed_data, schema, key)

    elif type == JSON_ERROR.JST_OBJECT:
      if parsed_data_type == TYPE_DICTIONARY:
        error = _validate_object(parsed_data, schema, key)

    elif type == JSON_ERROR.JST_STRING:
      if parsed_data_type == TYPE_STRING:
        error = _validate_string(parsed_data, schema, key)

  return error if error != null else parsed_data

func _var_to_array(variant):
  var result = []

  if typeof(variant) == TYPE_ARRAY:
    result = variant

  else:
    result.push_back(variant)

  return result

func _validate_array(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  # TODO: contains additionalItems minItems maxItems uniqueItems
  var error = ''
  var items_array
  
  # 'items' must be object or Array of objects
  if input_schema.has(JSON_ERROR.JSKW_ITEMS):
    items_array = _var_to_array(input_schema.items)

    for item in items_array:
      if typeof(item) != TYPE_DICTIONARY:
        return JSON_ERROR.ERR_WRONG_SHEMA_NOTA % [
          property_name,
          JSON_ERROR.JSKW_ITEMS,
          JSON_ERROR.JST_OBJECT
        ]
  
  # Check every item of input Array on 
  for idx in input_data.size():
    var suberror = []

    for subschema in items_array:
      suberror.push_back(_type_selection(_data_to_string(input_data[idx]), subschema, '%s[%s]' % [property_name, idx]))

    # At least one returned string must be correct (empty). If no one present, it's wrong.
    if not suberror.has(''):
      # Then we post all suberror array for a maintenance.
      return JSON_ERROR.ERR_INVALID_JSON_GEN % [suberror]
  
  return error

func _validate_boolean(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  # nothing to check
  return ''

func _validate_integer(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  # all processing is performed in
  return _validate_number(input_data, input_schema, property_name)

func _validate_null(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  # nothing to check
  return ''

func _validate_number(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  
  var types = _var_to_array(input_schema.type)
  # integer mode turns on only if types has integer and has not number
  var integer_mode = types.has(JSON_ERROR.JST_INTEGER) and not types.has(JSON_ERROR.JST_NUMBER)
  
  # processing multiple check
  if input_schema.has(JSON_ERROR.JSKW_MULT_OF):
    var mult = int(input_schema[JSON_ERROR.JSKW_MULT_OF]) if integer_mode else float(input_schema[JSON_ERROR.JSKW_MULT_OF])

    mult = int(input_schema[JSON_ERROR.JSKW_MULT_OF]) if integer_mode else mult

    if fmod(input_data, mult) != 0:
      if integer_mode:
        return JSON_ERROR.ERR_MULT_D % [
          property_name,
          input_data,
          mult
        ]

      else:
        return JSON_ERROR.ERR_MULT_F % [
          property_name,
          input_data,
          mult
        ]
  
  # processing minimum check
  if input_schema.has(JSON_ERROR.JSKW_MINIMUM):
    var minimum = int(input_schema[JSON_ERROR.JSKW_MINIMUM]) if integer_mode else float(input_schema[JSON_ERROR.JSKW_MINIMUM])

    if input_data < minimum:
      if integer_mode:
        return JSON_ERROR.ERR_RANGE_D % [
          property_name,
          input_data,
          JSON_ERROR.JSM_GREATER_EQ,
          minimum
        ]

      else:
        return JSON_ERROR.ERR_RANGE_F % [
          property_name,
          input_data,
          JSON_ERROR.JSM_GREATER_EQ,
          minimum
        ]

  # processing exclusive minimum check
  if input_schema.has(JSON_ERROR.JSKW_MIN_EX):
    var minimum = int(input_schema[JSON_ERROR.JSKW_MIN_EX]) if integer_mode else float(input_schema[JSON_ERROR.JSKW_MIN_EX])
    if input_data <= minimum:
      if integer_mode:
        return JSON_ERROR.ERR_RANGE_D % [
          property_name,
          input_data,
          JSON_ERROR.JSM_GREATER,
          minimum
        ]

      else:
        return JSON_ERROR.ERR_RANGE_F % [
          property_name,
          input_data,
          JSON_ERROR.JSM_GREATER,
          minimum
        ]
  
  # processing maximum check
  if input_schema.has(JSON_ERROR.JSKW_MAXIMUM):
    var maximum = int(input_schema[JSON_ERROR.JSKW_MAXIMUM]) if integer_mode else float(input_schema[JSON_ERROR.JSKW_MAXIMUM])
    if input_data > maximum:
      if integer_mode:
        return JSON_ERROR.ERR_RANGE_D % [property_name, input_data, JSON_ERROR.JSM_LESS_EQ, maximum]

      else:
        return JSON_ERROR.ERR_RANGE_F % [property_name, input_data, JSON_ERROR.JSM_LESS_EQ, maximum]   

  # processing exclusive minimum check
  if input_schema.has(JSON_ERROR.JSKW_MAX_EX):
    var maximum = int(input_schema[JSON_ERROR.JSKW_MAX_EX]) if integer_mode else float(input_schema[JSON_ERROR.JSKW_MAX_EX])
    if input_data >= maximum:
      if integer_mode:
        return JSON_ERROR.ERR_RANGE_D % [
          property_name,
          input_data,
          JSON_ERROR.JSM_LESS,
          maximum
        ]

      else:
        return JSON_ERROR.ERR_RANGE_F % [
          property_name,
          input_data,
          JSON_ERROR.JSM_LESS,
          maximum
        ]
  
  return ''

func _validate_object(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  # TODO: patternProperties

  # Process dependencies
  if input_schema.has(JSON_ERROR.JSKW_DEPEND):
    for dependency in input_schema.dependencies.keys():
      if input_data.has(dependency):
        var dependency_type = typeof(input_schema.dependencies[dependency])
        
        if dependency_type == TYPE_ARRAY:
          if input_schema.has(JSON_ERROR.JSKW_REQ):
            for property in input_schema.dependencies[dependency]:
              input_schema.required.append(property)

          else:
            input_schema.required = input_schema.dependencies[dependency]

        elif dependency_type == TYPE_DICTIONARY:
          for key in input_schema.dependencies[dependency].keys():
            if input_schema.has(key):
              var input_type = typeof(input_schema[key])

              if input_type == TYPE_ARRAY:
                for element in input_schema.dependencies[dependency][key]:
                  input_schema[key].append(element)

              elif input_type == TYPE_DICTIONARY:
                for element in input_schema.dependencies[dependency][key].keys():
                  input_schema[key][element] = input_schema.dependencies[dependency][key][element]

              else:
                input_schema[key] = input_schema.dependencies[dependency][key]

            else:
              input_schema[key] = input_schema.dependencies[dependency][key]

        else:
          return JSON_ERROR.ERR_WRONG_SCHEMA_GEN + JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
            JSON_ERROR.JSL_OR % [
              JSON_ERROR.JST_ARRAY,
              JSON_ERROR.JSM_OBJ_DICT
            ],
            property_name
          ]

  # Process properties
  if input_schema.has(JSON_ERROR.JSKW_PROP):
    var error

    # Process required
    if input_schema.has(JSON_ERROR.JSKW_REQ):
      if typeof(input_schema.required) != TYPE_ARRAY:
        return JSON_ERROR.ERR_REQ_PROP_GEN % property_name

      for item in input_schema.required:
        if not input_data.has(item):
          return JSON_ERROR.ERR_REQ_PROP_MISSING % [
            item,
            property_name
          ]
    
    # Continue validating schema subelements
    if typeof(input_schema.properties) != TYPE_DICTIONARY:
      return JSON_ERROR.ERR_WRONG_SCHEMA_GEN + JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JSM_OBJ_DICT,
        property_name
      ]
    
    # Process property items
    for key in input_schema.properties:
      if not input_schema.properties[key].has(JSON_ERROR.JSKW_TYPE):
        return JSON_ERROR.ERR_WRONG_PROP_TYPE

      # TODO: additional properties check
      if input_data.has(key):
        error = _type_selection(_data_to_string(input_data[key]), input_schema.properties[key], key)

        if error:
          return error

  # Process additional properties
  if input_schema.has(JSON_ERROR.JSKW_PROP_ADD):
    var additionalPropertieType = typeof(input_schema.additionalProperties)

    if additionalPropertieType == TYPE_BOOL:
      if not input_schema.additionalProperties:
        for key in input_data:
          if not input_schema.properties.has(key):
            return JSON_ERROR.ERR_NO_PROP_ADD % key

    elif additionalPropertieType == TYPE_DICTIONARY:
      for key in input_data:
        if not input_schema.properties.has(key):
          return _type_selection(_data_to_string(input_data[key]), input_schema.additionalProperties, key)

    else:
      return JSON_ERROR.ERR_WRONG_SCHEMA_GEN + JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JSL_OR % [
          JSON_ERROR.JST_BOOLEAN,
          JSON_ERROR.JSM_OBJ_DICT
        ],
        property_name
      ]

  # Process properties names
  if input_schema.has(JSON_ERROR.JSKW_PROP_NAMES):
    var error

    if typeof(input_schema.propertyNames) != TYPE_DICTIONARY:
      return JSON_ERROR.ERR_WRONG_SCHEMA_GEN + JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JSM_OBJ_DICT,
        property_name
      ]

    for key in input_data:
      error = _validate_string(key, input_schema.propertyNames, key)

      if error:
        return error

  # Process minProperties maxProperties
  if input_schema.has(JSON_ERROR.JSKW_PROP_MIN):
    if typeof(input_schema[JSON_ERROR.JSKW_PROP_MIN]) != TYPE_REAL:
      return JSON_ERROR.ERR_WRONG_SCHEMA_GEN + JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JST_INTEGER,
        property_name
      ]

    if input_data.keys().size() < input_schema[JSON_ERROR.JSKW_PROP_MIN]:
      return JSON_ERROR.ERR_FEW_PROP % [
        input_data.keys().size(),
        input_schema[JSON_ERROR.JSKW_PROP_MIN]
      ]

  if input_schema.has(JSON_ERROR.JSKW_PROP_MAX):
    if typeof(input_schema[JSON_ERROR.JSKW_PROP_MAX]) != TYPE_REAL:
      return JSON_ERROR.ERR_WRONG_SCHEMA_GEN + JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JST_INTEGER,
        property_name
      ]

    if input_data.keys().size() > input_schema[JSON_ERROR.JSKW_PROP_MAX]:
      return JSON_ERROR.ERR_MORE_PROP % [
        input_data.keys().size(),
        input_schema[JSON_ERROR.JSKW_PROP_MAX]
      ]

func _validate_string(input_data, input_schema, property_name = JSON_ERROR.DEF_KEY_NAME):
  # TODO: pattern, format 
  var error = ''

  if input_schema.has(JSON_ERROR.JSKW_LENGTH_MIN):
    if not (typeof(input_schema[JSON_ERROR.JSKW_LENGTH_MIN]) == TYPE_INT or typeof(input_schema[JSON_ERROR.JSKW_LENGTH_MIN]) == TYPE_REAL):
      return JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JST_INTEGER,
        '%s.%s' % [
          property_name,
          JSON_ERROR.JSKW_LENGTH_MIN
        ]
      ]

    if input_data.length() < input_schema[JSON_ERROR.JSKW_LENGTH_MIN]:
      return JSON_ERROR.ERR_INVALID_JSON_GEN % [
        JSON_ERROR.ERR_RANGE_S % [
          property_name,
          input_data.length(),
          JSON_ERROR.JSM_LESS,
          input_schema[JSON_ERROR.JSKW_LENGTH_MIN]
        ]
      ]
  
  if input_schema.has(JSON_ERROR.JSKW_LENGTH_MAX):
    if not (typeof(input_schema[JSON_ERROR.JSKW_LENGTH_MAX]) == TYPE_INT or typeof(input_schema[JSON_ERROR.JSKW_LENGTH_MAX]) == TYPE_REAL):
      return JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
          JSON_ERROR.JST_INTEGER,
          '%s.%s' % [
            property_name,
            JSON_ERROR.JSKW_LENGTH_MAX
          ]
        ]

    if input_data.length() > input_schema[JSON_ERROR.JSKW_LENGTH_MAX]:
      return JSON_ERROR.ERR_INVALID_JSON_GEN % [
        JSON_ERROR.ERR_RANGE_S % [
          property_name,
          input_data.length(),
          JSON_ERROR.JSM_GREATER,
          input_schema[JSON_ERROR.JSKW_LENGTH_MAX]
        ]
      ]

  if input_schema.has(JSON_ERROR.JSKW_PATTERN):
    if not (typeof(input_schema[JSON_ERROR.JSKW_PATTERN]) == TYPE_STRING):
      return JSON_ERROR.ERR_TYPE_MISMATCH_GEN % [
        JSON_ERROR.JST_STRING,
        '%s.%s' % [
          property_name,
          JSON_ERROR.JSKW_PATTERN
        ]
      ]

    var regex = RegEx.new()

    regex.compile(input_schema[JSON_ERROR.JSKW_PATTERN])

    if regex.search(input_data) == null:
      return JSON_ERROR.ERR_INVALID_JSON_GEN % [
        JSON_ERROR.ERR_WRONG_PATTERN % [property_name]
      ]

  return error
