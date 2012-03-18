require 'log4r'
require 'log4r/configurator'

Log4r::Configurator.load_xml_file('./config/initializers/log4r.xml')
Rails.logger = Log4r::Logger[Rails.env] # Sets the Rails logger
