const GDSCRIPT_ERRORS = [
  'OK', # 0
  'FAILED', # 1
  'ERR_UNAVAILABLE', # 2
  'ERR_UNCONFIGURED', # 3
  'ERR_UNAUTHORIZED', # 4
  'ERR_PARAMETER_RANGE_ERROR', # 5
  'ERR_OUT_OF_MEMORY', # 6
  'ERR_FILE_NOT_FOUND', # 7
  'ERR_FILE_BAD_DRIVE', # 8
  'ERR_FILE_BAD_PATH', # 9
  'ERR_FILE_NO_PERMISSION ', # 10
  'ERR_FILE_ALREADY_IN_USE ', # 11
  'ERR_FILE_CANT_OPEN ', # 12
  'ERR_FILE_CANT_WRITE ', # 13
  'ERR_FILE_CANT_READ ', # 14
  'ERR_FILE_UNRECOGNIZED ', # 15
  'ERR_FILE_CORRUPT ', # 16
  'ERR_FILE_MISSING_DEPENDENCIES', # 17
  'ERR_FILE_EOF', # 18
  'ERR_CANT_OPEN', # 19
  'ERR_CANT_CREATE', # 20
  'ERROR_QUERY_FAILED', # 21
  'ERR_ALREADY_IN_USE', # 22
  'ERR_LOCKED', # 23
  'ERR_TIMEOUT', # 24

  'ERR_UNKNOWN', # 25
  'ERR_UNKNOWN', # 26
  'ERR_UNKNOWN', # 27

  'ERR_CANT_AQUIRE_RESOURCE', # 28
  'ERR_INVALID_DATA', # 29
  'ERR_INVALID_PARAMETER', # 30
  'ERR_ALREADY_EXISTS', # 31
  'ERR_DOES_NOT_EXIST', # 32
  'ERR_DATABASE_CANT_READ', # 33
  'ERR_DATABASE_CANT_WRITE', # 34
  'ERR_COMPILATION_FAILED', # 35
  'ERR_METHOD_NOT_FOUND', # 36
  'ERR_LINK_FAILED', # 37
  'ERR_SCRIPT_FAILED', # 38
  'ERR_CYCLIC_LINK', # 39

  'ERR_UNKNOWN', # 40
  'ERR_UNKNOWN', # 41
  'ERR_UNKNOWN', # 42

  'ERR_PARSE_ERROR', # 43
  'ERR_BUSY', # 44

  'ERR_UNKNOWN', # 45

  'ERR_HELP', # 46
  'ERR_BUG', # 47

  'ERR_UNKNOWN', # 48

  'ERR_UNKNOWN' # 49
]

const DEF_KEY_NAME = 'schema root'
const DEF_ERROR_STRING = '##error##'

const JST_ARRAY = 'array'
const JST_BOOLEAN = 'boolean'
const JST_INTEGER = 'integer'
const JST_NULL = 'null'
const JST_NUMBER = 'number'
const JST_OBJECT = 'object'
const JST_STRING = 'string'

const JSKW_TYPE = 'type'
const JSKW_PROP = 'properties'
const JSKW_REQ = 'required'
const JSKW_TITLE = 'title'
const JSKW_DESCR = 'description'
const JSKW_DEFAULT = 'default'
const JSKW_EXAMPLES = 'examples'
const JSKW_COMMENT = '$comment'
const JSKW_ENUM = 'enum'
const JSKW_CONST = 'const'
const JSKW_ITEMS = 'items'
const JSKW_CONTAINS = 'contains'
const JSKW_ADD_ITEMS = 'additionalItems'
const JSKW_MIN_ITEMS = 'minItems'
const JSKW_MAX_ITEMS = 'maxItems'
const JSKW_UNIQUE_ITEMS = 'uniqueItems'
const JSKW_MULT_OF = 'multipleOf'
const JSKW_MINIMUM = 'minimum'
const JSKW_MIN_EX = 'exclusiveMinimum'
const JSKW_MAXIMUM = 'maximum'
const JSKW_MAX_EX = 'exclusiveMaximum'
const JSKW_PROP_ADD = 'additionalProperties'
const JSKW_PROP_PATTERN = 'patternProperties'
const JSKW_PROP_NAMES = 'propertyNames'
const JSKW_PROP_MIN = 'minProperties'
const JSKW_PROP_MAX = 'maxProperties'
const JSKW_DEPEND = 'dependencies'
const JSKW_LENGTH_MIN = 'minLength'
const JSKW_LENGTH_MAX = 'maxLength'
const JSKW_PATTERN = 'pattern'
const JSKW_FORMAT = 'format'

const JSM_GREATER = 'greater'
const JSM_GREATER_EQ = 'greater or equal'
const JSM_LESS = 'less'
const JSM_LESS_EQ = 'less or equal'
const JSM_OBJ_DICT = 'object (dictionary)'

const JSL_AND = '%s and %s'
const JSL_OR = '%s or %s'

const ERR_SCHEMA_FALSE = 'Schema declared as deny all'
const ERR_WRONG_SCHEMA_GEN = 'Schema error: '
const ERR_WRONG_SCHEMA_TYPE = 'Schema error: schema must be empty object or object with "type" keyword or boolean value'
const ERR_WRONG_SHEMA_NOTA = 'Schema error: expected that all elements of "%s.%s" must be "%s"'
const ERR_WRONG_PROP_TYPE = 'Schema error: any schema item must be object with "type" keyword'
const ERR_REQ_PROP_GEN = 'Schema error: expected array of required properties for "%s"'
const ERR_REQ_PROP_MISSING = 'Missing required property: "%s" for "%s"'
const ERR_NO_PROP_ADD = 'Additional properties are not required: found "%s"'
const ERR_FEW_PROP = '%d propertie(s) are not enough properties, at least %d are required'
const ERR_MORE_PROP = '%d propertie(s) are too many properties, at most %d are allowed'
const ERR_INVALID_JSON_GEN = 'Validation fails with message: %s'
const ERR_INVALID_JSON_EXT = 'Invalid JSON data passed with message: %s'
const ERR_TYPE_MISMATCH_GEN = 'Type mismatch: expected %s for "%s"'
const ERR_MULT_D = 'Key %s that equal %d must be multiple of %d'
const ERR_MULT_F = 'Key %s that equal %f must be multiple of %f'
const ERR_RANGE_D = 'Key %s that equal %d must be %s than %d'
const ERR_RANGE_F = 'Key %s that equal %f must be %s than %f'
const ERR_RANGE_S = 'Length of "%s" (%d) %s than declared (%d)'
const ERR_WRONG_PATTERN = 'String "%s" does not match its corresponding pattern'
