# must occur before including cartographer files
CARTOGRAPHER_GMAP_VERSION = 3

# Load the rails application
require File.expand_path('../application', __FILE__)

# Initialize the rails application
Haidb::Application.initialize!