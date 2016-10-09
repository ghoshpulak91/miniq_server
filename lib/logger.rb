require 'logger'
require 'fileutils' 

load_arr = []
load_arr.each do |lib|
	require File.expand_path(File.dirname(__FILE__)+"/"+lib)
end

$hostname ||= %x(hostname).chomp.strip

# crating log dir 
FileUtils.mkdir_p(File.expand_path(File.dirname(__FILE__)+"/../log/"))


# This a simple logger which saves logs in a file and ages logs monthly.
# Log level is INFO
log_file_path = File.expand_path(File.dirname(__FILE__)+"/"+"../log/run.log")
$log ||= Logger.new(log_file_path, 'monthly')
$log.level = Logger::INFO
