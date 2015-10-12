module MA1000AutomationTool
  require "yaml"

  class TestConfig

    attr_reader :file_name, :file_path
    
    @config = nil
    
    #Initialize test config file
    def initialize(config_file)
      begin
		$test_logger.log("Loading configuration file #{config_file}")
		    @file_name = config_file[/\w+\.\w+$/]
		    @file_path = config_file
        @config = YAML::load(File.open(config_file))
      rescue Exception => e
        raise e, e.message + "\nError while loading config file '#{config_file}'!", e.backtrace
      end
    end

    #Get test config attribute value
    def get(attrib_path)
      
      begin
        first,*elements = attrib_path.split('.')
        config_ele = @config[first]
        elements.each { |val|
          raise "Test config attribute '#{attrib_path}' not found!" if !config_ele
          config_ele = Common.get_obj_copy(config_ele[val])
  
        }
  
        $test_logger.result_log("Config Read[#{attrib_path}]=#{config_ele}") if $test_logger != nil
      rescue Exception => ex
        raise ex, "Error while getting test config!\n#{ex.message}", ex.backtrace
      end          

      config_ele
    end
  end
end