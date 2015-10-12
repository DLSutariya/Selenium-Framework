module MA1000AutomationTool
  class Resource
    #Get resource file path
    def self.get_path(res_file_name)
      $test_logger.log("Get resource full path '#{res_file_name}'")
      File.join(FWConfig::RES_FOLDER_PATH, res_file_name)
    end

    #Get raw content (binary string) from specified resource file
    def self.get_content(res_file_name, force_utf8 = false)
      $test_logger.log("Get res content '#{res_file_name}'")

      #Get file path of res file
      file_path = get_path(res_file_name)

      #Read all data from res file
      data = Common.read_all_bytes(file_path)

      data = data.force_encoding('utf-8') if force_utf8

      data
    end
  end
end
