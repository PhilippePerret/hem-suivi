require 'clir'
require 'yaml'

ERRORS = YAML.load_file(LOCALES_PATH, **{symbolize_names: true})
