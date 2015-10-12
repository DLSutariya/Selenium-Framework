module MA1000AutomationTool
  module UserFunctions

    #Set up trace to make debug log entry for each call to user function
    set_trace_func proc { |event, file, line, id, binding, classname|

      #Filter calls to user methods
      if event=='call' && classname.to_s == name && id.to_s != "load_user_methods"
        $test_logger.log "Call to user method '#{id}'"
        $test_logger.result_log("Inside user method '#{id}'")
      end
    }
    #Load user methods
    def self.load_user_methods
      user_functions_files = Dir.glob(File.join(FWConfig::USER_FOLDER, "*.rb"))
      if user_functions_files.count != 0
        $test_logger.log "Loading user functions from '#{FWConfig::USER_FOLDER}' folder:", true
      else
        $test_logger.log "No user functions found in '#{FWConfig::USER_FOLDER}' folder!", true
      end
      user_functions_files.each { |file|
        require File.expand_path(file)
        $test_logger.log "\t" + File.basename(file), true}
        include L1Functions
        include MA500Functions
        include MA1000Functions
    end

  end
end