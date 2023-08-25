require 'clir'
require 'yaml'
require 'csv'

ERRORS = YAML.load_file(LOCALES_PATH, **{symbolize_names: true})
