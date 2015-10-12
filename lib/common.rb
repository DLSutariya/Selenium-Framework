module MA1000AutomationTool
  class Common
    #Execute shell command
    def self.shell_execute(command, arguments)
      $test_logger.log("Shell execute '#{command}'")
      system(command + " " + arguments)
    end

    # RAW (Fixnum string) to HEX string (Printable form)
    # Example: Input string = RAW string (0xFF001234...)
    #          Output HEX string = "FF001234..." (Printable form)
    def self.unpackbytes(string)
      string.unpack('H*h*').collect {|x| x.to_str}.join
    end

    # HEX string to RAW (Fixnum string)
    # Example: Input hex = "FF001234..."
    #          Output raw string = 0xFF001234...
    def self.packbytes(hex)
      hex.unpack('a2'*(hex.size/2)).collect {|i| i.hex.chr }.join
    end

    #Append text to file
    def self.append_text_to_file(file_path, text)
      begin
        open(file_path, 'a') do |f|
        #Escape null character while writing log file
          text.gsub!("\x0","\\x0")
          f.puts text
        end
      rescue Exception => ex

      #Retry if permission error
        if ex.class == Errno::EACCES
          print "Permission denied while writing log file! Retrying in 2 seconds..."
          sleep 2
        retry
        end

        print "Error in append_text_to_file! Error: #{ex.message}\nBacktrace: #{ex.backtrace.first}"
      end
    end

    #Convert String IPAddress to hex
    def self.string_ip_to_hex(dev_ip)
      dev_ip = dev_ip.split('.')
      dev_ip_full = (dev_ip[0].to_i << 24) | (dev_ip[1].to_i << 16) | (dev_ip[2].to_i << 8) | (dev_ip[3].to_i)
      dev_ip_full
    end

    #Convert String MACAddress to hex
    def self.string_mac_to_hex(mac)
      mac_arr = Array.new
      if mac != "0"
        mac_str = mac.gsub(':', '')  + "0000"
        a = mac_str.unpack('a2'*(mac_str.size/2)).collect {|i| i.hex.chr }.join
        mac_arr = a.unpack('V*')
      else
        mac_arr = [0,0]
      end
      mac_arr
    end

    #read all bytes from file
    def self.read_all_bytes(file_path)
      data = ''
      open(file_path, 'r') { |fh|
        while !fh.eof?
          wrd = fh.read(4)
          data << wrd
        end    }
      data
    end

    #write all bytes to file
    def self.write_all_bytes(file_path, raw_str)
      open(file_path, 'wb') { |fh|
        fh.write(raw_str)
      }
    end

    #Get time duration readable string format
    def self.get_duration_in_words(time_in_seconds)

      milliseconds = format("%0.3f", time_in_seconds).split(".").last.to_i

      time_in_seconds = time_in_seconds.to_i
      seconds = time_in_seconds % 60
      minutes = (time_in_seconds / 60) % 60
      hours = time_in_seconds / (60 * 60)

      if milliseconds !=0
        ms_in_words = milliseconds.to_s + " millisecond" + ("s" if milliseconds>1).to_s
      end

      if seconds!=0
        duration_in_words = seconds.to_s + " second" + ("s" if seconds>1).to_s + (" " + duration_in_words if duration_in_words != nil).to_s
      end
      if minutes !=0
        duration_in_words = minutes.to_s + " minute" + ("s" if minutes>1).to_s + (" " + duration_in_words if duration_in_words != nil).to_s
      end
      if hours !=0
        duration_in_words = hours.to_s + " hour" + ("s" if hours>1).to_s + (" " + duration_in_words if duration_in_words != nil).to_s
      end

      duration_in_words != nil ? ("about " + duration_in_words):( ms_in_words != nil ? "about " + ms_in_words :"no time")
    end

    #Read specific line from file
    def self.read_line_number(filename, number)
      counter = 0
      read_line = nil
      File.foreach(filename) do |line|
        counter += 1
        if counter == number
        read_line = line.chomp
        break
        end
      end
      read_line = nil if counter != number
      read_line
    end

    #Copy objects
    def self.get_obj_copy(obj)
      Marshal.load( Marshal.dump(obj) )
    end

    #Convert 32-bit unsigned integer to 32-bit signed integer
    def self.uint32_to_int32(uint)
      if uint >= 2**31
      myint32 = uint - 2**32
      else
      myint32 = uint
      end
      myint32
    end

    #Convert 32-bit signed integer to 32-bit unsigned integer
    def self.int32_to_uint32(int)
      if int < 0
      myint32 = 2**32 + int
      else
      myint32 = int
      end
      myint32
    end

    #Convert relative path to absolute path
    # Example: Input = "image.jpg"
    #          Output = "C:\\image.jpg"
    def self.rel_to_abs(path)
      path = File.expand_path(path).gsub!(/\//, '\\')
      path
    end

    #Get current host IP
    def self.get_cur_local_ip(sock)
      #Return Local Host address
      sock.local_address.ip_address
    end

    #Convert fixed no or string to bool
    # Example: Input = "true" or "TRUE" or 1
    #          Output = true
    def self.convert_to_bool(str)

      if str.class == String
        str.downcase!
        if str == "true"
        val = true
        elsif str == "false"
        val = false
        else
        val = -1
        end
      elsif str.class == Fixnum
        if str == 1
        val = true
        elsif str == 0
        val = false
        else
        val = -1
        end
      end
      val
    end

    #Get full path of specified data file exists under sub-folder of 'data' folder
    def self.get_data_path(data_file)
      script_path = caller.first[/.*(:\d)/][0...-2]
      dir_path = File.dirname(script_path)
      dir_name = File.basename(dir_path)
      FWConfig::DATA_FOLDER
      data_path = File.join(FWConfig::DATA_FOLDER, dir_name, data_file)
      data_path
    end

    #Read all text from file
    def self.read_all_text(file_path)
      data = ''
      open(file_path, 'r') { |fh|
        while !fh.eof?
          data << fh.gets
        end
      }
      data
    end

    #Copy file from source to destination
    def self.copy_file(src, dest)
      FileUtils.copy_file(src, dest)
    end

    #Fetch testlink id from mapping file based on test method name
    def self.get_testlink_id(test_method)
      #Get error description based on number from CSV file

      $test_logger.log("Get testlink Id for '#{test_method}'")
      tlid = nil
      begin
        CSV.foreach(FWConfig::TESTLINK_MAPPING_PATH, :headers => true) do |row|
        #TestMethod
          if test_method.downcase == row[3].downcase
          #Test Link Id
          tlid = row[1].to_s
          break
          end
        end
        $test_logger.log("Testlink Id fetched '#{tlid.to_s}'")
      rescue Exception => ex
        $test_logger.log_e("Error while fetching testlink Id from mapping file!", ex)
      end
      tlid
    end
   
    #Fetch testcase name from mapping file based on testlink id
    def self.get_testcase_name_from_id(testcase_id)
      $test_logger.log("Get testlink name for '#{testcase_id}'")
      tname = nil
      begin
        CSV.foreach(FWConfig::TESTLINK_MAPPING_PATH, :headers => true) do |row|
          if testcase_id == row[1].to_i
          #Testcase Name
          tname = row[3].to_s
          break
          end
        end
        $test_logger.log("Testcase Name fetched '#{tname.to_s}'")
      rescue Exception => ex
        $test_logger.log_e("Error while fetching testcase name from mapping file!", ex)
      end
      tname
    end
   
    #Get raw string from fixnum (or HEX number)
    def self.fixnum_to_rawstr(hex_num, byte_size)
      
      raw_str = ""
      byt_count = 0
      begin
        byt = hex_num & 0xff
        hex_num >>= 8
        raw_str << byt.chr
        byt_count += 1 
      end while hex_num != 0 && (byt_count < byte_size)
      
      raw_str.reverse!
      
      raw_str = raw_str.rjust(byte_size, "\x0")
      
    raw_str  
    end

    #Check file exist or not at specified path
    def self.is_file_exist(path)
      
      $test_logger.log("Check file status at '#{path}'")
      status = File.exists?(path)
      if status
       $test_logger.log("File exist at '#{path}'")
      else  
       raise "File doesn't exist at '#{path}'"
      end
        
    end


  end
end
