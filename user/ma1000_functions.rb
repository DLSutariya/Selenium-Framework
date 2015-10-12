require 'json'

module MA1000AutomationTool
  module UserFunctions
    module MA1000Functions

      CONFIG_SETTINGS = "config_settings.json"
      FILE_CHUNK_SIZE = 10240
      #Delete all IP addresses from IP authorized list of the terminal
      def delete_all_authorized_ip(protocol = IP_protocol_type::All)
        ip_arr = call_thrift{authorized_IP_get_list(protocol)}
        if ip_arr
          ip_arr.each{|ip|
            call_thrift{authorized_IP_delete(ip)}
          }
        end
      end

      #Delete all IP address ranges from IP authorized range list of the terminal
      def delete_all_authorized_ip_ranges(protocol = IP_protocol_type::All)

        ip_arr = call_thrift{authorized_IP_get_range_list(protocol)}

        if ip_arr
          (ip_arr.size / 2).times{|i|
            st_idx = i*2
            en_idx = st_idx + 1
            call_thrift{authorized_IP_delete_range(ip_arr[st_idx], ip_arr[en_idx])}
          }
        end

      end

      #Verify set param
      def verify_set_param(data_label, param_name, param_val, value_type, exp_err = "nil", exp_val = nil)

        exp_err_obj = eval(exp_err)

        $test_logger.result_log("Set parameter for '#{data_label}', Param='#{param_name}', ValueType='#{value_type}', ExpErr=#{(exp_err_obj!=nil)}")

        param_map = {param_name => Variant.new({value_type => param_val})}

        #Set Parameters on MA1000 terminal
        call_thrift(exp_err_obj){config_set_params(param_map)}

        if exp_err_obj == nil
          $test_logger.result_log("Verifying value set on terminal...")

          #Get Parameters from MA1000 terminal
          act_param_val = get_param_value(param_name)

          #Exp param map
          if exp_val == nil
          exp_param_map = param_map
          else
            exp_param_map = {param_name => Variant.new({value_type => exp_val})}
          end

          #Assert param values
          $test_ref.assert_equal [exp_param_map[param_name]], act_param_val, "Parameter value mis-match!"
        end

      end

      #Get param value
      def get_param_value(param_name, type = nil)
        $test_logger.result_log("Get param '#{param_name}' value from terminal")

        #Fetch actual param value from terminal
        get_value = call_thrift{config_get_params([param_name])}

        #Return exact value if type is defined
        if type != nil
          get_value = instance_eval("get_value.first.#{type}")
        end

        #Return get value
        get_value
      end

      #Get all allowed parameters from terminal
      def get_terminal_params
        $test_logger.result_log("Get terminal params")

        call_thrift{config_get_all_params_name}

      end

      #Get parameter config range
      def get_config_param_range()

        #Get list of params allowed on terminal
        allowed_params = get_terminal_params

        param_hash = Hash.new
        exp_map = Hash.new
        param_list = Array.new
        config_file = File.join(FWConfig::DATA_FOLDER_PATH, FWConfig::MA1000_FOLDER, CONFIG_SETTINGS)
        File.open( config_file, "r" ) do |f|
          param_hash = JSON.load( f )
        end
        param_hash.each {|key, value|
          value.each {|k, v|
            cur_key = "#{key}.#{k}"

            #Skip adding key if it is not allowed
            next if !allowed_params.include?(cur_key)

            param_list << cur_key
            type = v.fetch("data_type")
            type = type.to_i
            rng =  v.fetch("range")
            #0
            if type == Param_data_types::Db_integer
              if rng.include?(",") && rng.include?(":")
                rng_list_o = rng.split(',')
                con_range = nil
                rng_list = []
                rng_list_o.each_with_index{|x,i|
                  if x.include?(":")
                  con_range = x
                  else
                  rng_list[i] = x.to_i
                  end
                }

                con_rng_list = con_range.split(':')
                con_rng_list.each_with_index{|x,i| con_rng_list[i] = x.to_i}

                if con_rng_list[1].to_i > 0x7FFFFFFF
                max_val = - 1 - 0xFFFFFFFF + con_rng_list[1].to_i
                else
                max_val = con_rng_list[1]
                end

                par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                    "discontinuous_range" => rng_list,
                    "continuous_range" => Integer_range.new({"min_value" => con_rng_list[0],
                      "max_value" => max_val})})}

              elsif rng.include? ","
                rng_list = rng.split(',')
                rng_list.each_with_index{|x,i| rng_list[i] = x.to_i}
                par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                    "discontinuous_range" => rng_list})}
              elsif rng.include? ":"
                rng_list = rng.split(':')
                rng_list.each_with_index{|x,i| rng_list[i] = x.to_i}

                par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                    "continuous_range" => Integer_range.new({"min_value" => rng_list[0],
                      "max_value" => rng_list[1]})})}
              end
            #1
            elsif type == Param_data_types::Db_unsigned_int

              if rng.include?(",") && rng.include?(":")
                rng_list_o = rng.split(',')
                con_range = nil
                rng_list = []
                rng_list_o.each_with_index{|x,i|
                  if x.include?(":")
                  con_range = x
                  else
                  rng_list[i] = x.to_i
                  end
                }

                con_rng_list = con_range.split(':')
                con_rng_list.each_with_index{|x,i| con_rng_list[i] = x.to_i}

                if con_rng_list[1].to_i > 0x7FFFFFFF
                max_val = - 1 - 0xFFFFFFFF + con_rng_list[1].to_i
                else
                max_val = con_rng_list[1]
                end

                par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                    "discontinuous_range" => rng_list,
                    "continuous_range" => Integer_range.new({"min_value" => con_rng_list[0],
                      "max_value" => max_val})})}

              elsif rng.include? ","
                rng_list = rng.split(',')
                rng_list.each_with_index{|x,i| rng_list[i] = x.to_i}
                par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                    "discontinuous_range" => rng_list})}
              elsif rng.include? ":"
                rng_list = rng.split(':')
                rng_list.each_with_index{|x,i| rng_list[i] = x.to_i}

                if rng_list[1].to_i > 0x7FFFFFFF
                max_val = - 1 - 0xFFFFFFFF + rng_list[1].to_i
                else
                max_val = rng_list[1]
                end

                par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                    "continuous_range" => Integer_range.new({"min_value" => rng_list[0],
                      "max_value" => max_val})})}
              end
            #5
            elsif type == Param_data_types::Db_binary
              mx_len = rng.to_i
              par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                  "max_length" => mx_len})}
            #6
            elsif type == Param_data_types::Db_string
              mx_len = rng.to_i
              par = {"#{key}.#{k}" => Parameter_range.new({"data_type" => type,
                  "max_length" => mx_len})}
            end
            exp_map.merge!(par) unless par.nil?
          }
        }

        return param_list, exp_map

      end
      
      #Create stolencard list file and write csn in file 
      def create_stolencard_list_with_csn(csn)

        stolen_card_file = File.join(FWConfig::RES_FOLDER_PATH, "sample_stolen_card_list.txt")
        File.open( stolen_card_file, "w+" ) do |f|
          if f
             f.syswrite(csn.to_i.to_s(16))
          else
             puts "Unable to open file!"
          end          
        end
        upload_file(stolen_card_file, File_type::Stolen_card_list, File_subtype::No_subtype, "sample_stolen_card_list.txt", file_action = nil)
        
      end
 
      #Create transaction log entries on terminal
      def create_tlog_entries(num_entries=1, randomize_data=false)

        if num_entries > 1000
        show_console = true
        else
        show_console = false
        end

        $test_logger.log("Creating tlog entries: num='#{num_entries}'...", show_console)

        count = 0

        #Create transaction log entries
        num_entries.times{
          set_param_map = {"contact_info.web" => Variant.new({"UTF8string_value" => "http://www.biometric-terminals.com"})}
          #Set Parameters on MA1000 terminal
          call_thrift{config_set_params(set_param_map)}

          count += 1
          if count % 100 == 0 && show_console == true
            $test_logger.log("Entries created: #{count}/#{num_entries}", true)
          end
        }

        $test_logger.log("Tlog entries creation completed: #{count}/#{num_entries}", show_console)

      end

      #Convert int to raw word (used for custom wiegand)
      def int_to_rawword(i)

        #Swap for endianness
        wgn_len = BioPacket.swap_dword(i)

        #Convert to hexstr
        byt_str = wgn_len.to_s(16)

        #Pad 0s
        byt_str = byt_str.rjust(4*2, "0")

        #Convert to raw
        raw_utf8_str = Common.packbytes(byt_str)

        Common.unpackbytes(raw_utf8_str)
        raw_utf8_str
      end

      #Get custom wiegand configuration string (used for custom wiegand)
      def get_config_wgn_str(wgn_len, id_start, id_len)

        #Swap for endianness
        #wgn_len = BioPacket.swap_dword(wgn_len)

        #Convert to hexstr
        #byt_str = wgn_len.to_s(16)
        #Pad 0s
        #byt_str = byt_str.rjust(4*2, "0")
        #raw_utf8_str = Common.packbytes(byt_str)
        #raw_utf8_str = byt_str.unpack('a2'*(byt_str.size/2)).collect {|i| i.hex }.pack('U*')

        #raw_ascii_str.force_encoding("UTF-8")

        wgn_id = "\x0\x0\x0\x0"
        wgn_name = "test"
        wgn_name += "\x0" * 28
        wgn_size = int_to_rawword(wgn_len)
        #wgn_size = "\x2\x0\x0\x0"
        wgn_id_s = int_to_rawword(id_start)
        #wgn_id_s = "\x5\x0\x0\x0"

        wgn_id_l = int_to_rawword(id_len)
        wgn_rest = "\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0\x0"

        wgn_slot = wgn_id + wgn_name + wgn_size + wgn_id_s + wgn_id_l + wgn_rest

        byts_req = total_wgnbytesreqfor_idlen(id_len);

        full_wgn_slot = wgn_slot.ljust(byts_req, "\x0")

        full_wgn_slot
      end

      # Get total wiegand string len based on id length (used for custom wiegand)
      def total_wgnbytesreqfor_idlen(idlen)
        head_bytes = 48;
        res_bytes = 16;

        words_reqf = (idlen / 32.0);
        words_req = words_reqf.ceil
        byts_req = head_bytes + words_req * 4 + res_bytes;
      end

      #Set custom wiegand for slot
      def set_cust_wgn_slot(slot_no, wgn_size, id_start=0, id_len=wgn_size)
        wgn_slot = get_config_wgn_str(wgn_size, id_start, id_len)
        verify_set_param("Set wiegand slot #{slot_no} as #{wgn_size} bits", "wiegand.custom_format_slot#{slot_no}", wgn_slot.force_encoding("UTF-8"), "binary_value")
      end

      #Set terminal date/time and timezone settings
      def set_terminal_date_time(year, month, day, hour, minute, second, dst = nil, timezone = nil, dt_type=nil, tm_type=nil, hr_type=nil)

        #Create timezone object if parameters are specified
        if (dst != nil && timezone != nil)
          tz = Time_time_zone.new(:observe_daylight_saving_time => dst, :predefined_time_zone_UTF8 => timezone)
        else
          tz = nil
        end

        #Test config
        test_config = Terminal_configuration.new(
        :date_time_settings => Time_local_date_time_settings.new(
        :date_time => Date_time.new( :year => year,
        :month => month,
        :day => day,
        :hour => hour,
        :minute => minute,
        :second => second),
        :time_zone => tz
        ))

        test_config.date_time_settings.date_display_type = dt_type if dt_type != nil
        test_config.date_time_settings.time_display_type = tm_type if tm_type != nil
        test_config.date_time_settings.hour_display_type = hr_type if hr_type != nil

        #Call set config thrift API
        call_thrift{terminal_set_configuration(test_config)}

        #Get current config from terminal
        act_config = call_thrift{terminal_get_configuration(
        Terminal_configuration_type.new(:settings_type => Terminal_settings_type::Date_time))}

        #Ignore fields in actual structure
        act_config.date_time_settings.date_time.second = test_config.date_time_settings.date_time.second

        #Assert config struct
        $test_ref.assert_equal test_config.date_time_settings.date_time.inspect, act_config.date_time_settings.date_time.inspect, "Specified date time not set on terminal!"

        #Assert timezone if required
        if tz != nil
          $test_ref.assert_equal test_config.date_time_settings.time_zone.observe_daylight_saving_time, act_config.date_time_settings.time_zone.observe_daylight_saving_time, "Specified DST param not set on terminal!"
          $test_ref.assert_equal test_config.date_time_settings.time_zone.predefined_time_zone_UTF8, act_config.date_time_settings.time_zone.predefined_time_zone_UTF8, "Specified timezone param not set on terminal!"
        end

        $test_ref.assert_equal Date_display_format_type::VALUE_MAP[test_config.date_time_settings.date_display_type],
        Date_display_format_type::VALUE_MAP[act_config.date_time_settings.date_display_type], "Specified date display type not set on terminal!" if dt_type != nil

        $test_ref.assert_equal Time_display_format_type::VALUE_MAP[test_config.date_time_settings.time_display_type],
        Time_display_format_type::VALUE_MAP[act_config.date_time_settings.time_display_type], "Specified time display type not set on terminal!" if tm_type != nil

        $test_ref.assert_equal Time_hour_display_type::VALUE_MAP[test_config.date_time_settings.hour_display_type],
        Time_hour_display_type::VALUE_MAP[act_config.date_time_settings.hour_display_type], "Specified hour display type not set on terminal!" if hr_type != nil

      end

      #Get terminal date/time
      def get_terminal_date_time

        #Get current config from terminal
        act_config = call_thrift{terminal_get_configuration(
        Terminal_configuration_type.new(:settings_type => Terminal_settings_type::Date_time))}
        Time.new(act_config.date_time_settings.date_time.year,
        act_config.date_time_settings.date_time.month,
        act_config.date_time_settings.date_time.day,
        act_config.date_time_settings.date_time.hour,
        act_config.date_time_settings.date_time.minute,
        act_config.date_time_settings.date_time.second)

      end

      #Delete all users from terminal DB
      def delete_all_uers

        $test_logger.log("Delete all users from terminal DB")

        #Delete all records from user database
        call_thrift{user_DB_delete_all_records()}

        #Call thrift API to Get database status
        val = call_thrift{user_DB_get_status(User_type::Enrolled)}

        #Assert current records values
        $test_ref.assert_equal 0, val.size, "Number of user records on terminal DB mismatch after delete all users!"

      end

      #Touch on terminal screen using testability driver
      def touch_on_screen

        $test_logger.log("Touch on terminal screen at different position")

        $test_logger.log "\n\n###############################################\n\nManual user steps required!!!\n\n###############################################\n\n", true
        $test_logger.log("Need to update this with testability driver\nFor now please touch on terminal screen when asked!", true)

      end

      #load cbi simulation files
      def load_cbi_simu_files(simu_img)
        $test_logger.log "Loading CBI simu finger file in MA1000 mode. Path = #{simu_img}"

        simu_files = Cbi_simulation_files.new(:raw_image_file_name => simu_img)
        simu_files.uniformity_file_name = $simu_path + "CBI_1056x784.UniRef" if simu_img[/no_finger/] 
        
        call_thrift{cbi_simulation_files_load(simu_files)}

        $test_logger.log "CBI simu finger loaded."
      end

      #Send cancel command to terminal after specified delay
      def send_cancel(delay)

        $test_logger.log("Send cancel '#{delay}'")

        #If delay is 0 then call cancel immediately
        if delay == 0
          #Call cancel operation without thread
          cancel_operation @sec_cmd_proc, delay
        else
        #Create thread for cancel API
          $test_ref.new_thread("cancel_operation", @sec_cmd_proc, delay)
        end

      end

      #Return cause in STR from control result (final_result)
      def get_cause(control_result)
        if control_result.final_result.cause
          Biofinger_failure_cause::VALUE_MAP[control_result.final_result.cause]
        else
          "UNKNOWN"
        end
      end

      #Check if specified user Id exists on terminal DB
      def is_user_exist(user_id)
        usr_exists = false
        #Call thrift API to Get user
        val = call_thrift{user_DB_get_users(Set.new([user_id]),Set.new([]))}
        usr_exists = true if val[user_id]
        usr_exists
      end

      #Verify user template available on terminal DB
      def verify_user_db(user_id, simu_finger_num=nil, exp_pass = true)

        #Start simu finger thread for auth
        simu_th = simu_finger_for_op simu_finger_num, "Authenticate DB", 1, 4 if simu_finger_num

        #Call API for finger authentication
        auth_res = call_thrift{biofinger_authenticate_db(0, 10, 5, user_id, false, nil)}

        #Exit simu finger thread, if alive
        simu_th.exit if simu_th && simu_th.alive?

        #Assert authentication result
        if exp_pass
          $test_ref.assert_true auth_res.final_result.success, "Authentication DB failed with correct finger! Cause: '#{get_cause(auth_res)}'"
        else
          $test_ref.assert_false auth_res.final_result.success, "Authentication DB passed with wrong finger!"
        end

      end

      #Verify specified user templates
      def verify_user_ref(user_templates, simu_finger_num=nil)

        #Start simu finger thread for auth
        simu_th = simu_finger_for_op simu_finger_num, "Authenticate Ref", 1, 4 if simu_finger_num

        #Call API for finger authentication
        auth_res = call_thrift(nil, 60){biofinger_authenticate_ref(10, 5, user_templates, false, nil)}

        #Exit simu finger thread, if alive
        simu_th.exit if simu_th && simu_th.alive?

        #Assert authentication result
        $test_ref.assert_true auth_res.final_result.success, "Authentication ref failed with correct finger! Cause: '#{get_cause(auth_res)}'"
      end

      #Get user structure from terminal DB for specified user Id
      def get_user_db(user_id)
        val = call_thrift{user_DB_get_users(Set.new([user_id]), get_user_id)}
        val[user_id]
      end

      #Upload file to terminal
      def upload_file(file_path, file_type, file_subtype = nil, file_name = nil, file_action = nil)

        fmh = FileMultiresponseHandler.new
        fmh.open_rd(file_path, FILE_CHUNK_SIZE)

        MultiresponseHandler::client_cb_file_load = fmh.method(:file_load_cb)

        fd = File_details.new(:type => file_type, :subtype => file_subtype, :name_UTF8 => file_name)
        fc = File_chunk.new(:action => file_action)

        call_thrift(nil, 60){file_load(fd, fc)}

        fmh.close

      end

      #Delete all files
      def delete_all_files(file_type, file_subtype = nil)

        $test_logger.log("Delete all files from '#{file_type}'")

        file_list = call_thrift{file_get_filenames(file_type)}
        if file_list.size > 0
          file_list.each{|x|
            if x.subtype == file_subtype
              fd = File_details.new(:type => x.type, :subtype => file_subtype, :name_UTF8 => x.name_UTF8)
              call_thrift{file_erase(fd)}
            else
              call_thrift{file_erase(x)}
            end
          }
        else
          $test_logger.log("No files found from '#{file_type}'")
        end

      end

      #Verify files
      def verify_file(fd, file_do_not_exist=false)
        $test_logger.log("Verify file from '#{fd.type}'")

        file_list = call_thrift{file_get_filenames(fd.type)}

        if file_do_not_exist == true
          $test_ref.assert_equal 0, file_list.size, "Specified file found on terminal, it is expected not to be existed!"
        else
          if file_list.size > 0
            found = false
            file_list.each{|x|
              if (fd.subtype == x.subtype) && (x.name_UTF8 == fd.name_UTF8)
                found = true
                #Assert param values
                $test_ref.assert_equal fd.name_UTF8, x.name_UTF8, "File name Mismatch!"
              end
            }
            if found == false
              raise "No files found from '#{File_type::VALUE_MAP[fd.type]}' with sub type '#{File_subtype::VALUE_MAP[fd.subtype]}' "
            end
          else
            raise "No files found from '#{File_type::VALUE_MAP[fd.type]}'"
          end
        end
      end

      #Listen TCP socket
      def listen_tcp_socket(port)

        $test_logger.log("Listening TCP socket on port:'#{port}'")

        sock = TCPServer.open($local_ip, port)
        #Create thread read data on TCP socket
        th_ref = new_thread("socket_to_read_on_tcp", sock)

        return sock, th_ref
      end

      #Listen UDP socket
      def listen_udp_socket(port)

        $test_logger.log("Listening UDP socket on port:'#{port}'")
        sock = UDPSocket.new
        sock.bind($local_ip, port)

        #Create thread read data on UDP socket
        th_ref = new_thread("socket_to_read_on_udp", sock)

        return sock, th_ref

      end

      #Listen SSL socket
      def listen_ssl_socket(port, proto_ver)

        $test_logger.log("Listening SSL socket on port:'#{port}' and protocol ver: '#{proto_ver}'")

        #Create thread read data on SSL socket
        new_thread("socket_to_read_on_ssl", port, proto_ver)

      end

      #Listen on Serial Port
      def listen_serial_port(baudrate, databits, parity, stopbits)

        $test_logger.log("Listening on serial port with Comport:'#{$comm_serial_port}' and baudrate:'#{baudrate}'")

        #SerialPort::NONE, SerialPort::EVEN,SerialPort::ODD
        if parity == 0
          parity = SerialPort::NONE
        elsif parity == 1
          parity = SerialPort::ODD
        elsif parity == 2
          parity = SerialPort::EVEN
        end
        #Create thread read data on Serial port
        new_thread("read_on_serial", baudrate, databits, parity, stopbits)

      end

      #Set serial net Id on terminal
      def set_terminal_net_id(net_id)
        $test_logger.result_log "Set terminal net id to '#{net_id}'"

        #Set test data to config struct
        serial_params =  Serial_params_settings.new
        serial_params.net_id = net_id

        test_config = Terminal_configuration.new(:serial_params => serial_params)

        #Call set config thrift API
        call_thrift{terminal_set_configuration(test_config)}

        #Wait till net Id is applied on terminal
        sleep 3

        #Set current net id
        set_net_id(net_id)

        #Get current config from terminal
        act_config = call_thrift{terminal_get_configuration(Terminal_configuration_type.new(
     :settings_type=>Terminal_settings_type::Serial_params_cfg))}

        if act_config.serial_params.net_id < 0
        act_config.serial_params.net_id = 65536 + act_config.serial_params.net_id
        end

        #Assert config set
        $test_ref.assert_equal test_config.serial_params.net_id, act_config.serial_params.net_id, "Specified net Id not set on terminal!"
      end

      #Set serial baud rate on terminal
      def set_terminal_baud(baud_rate)
        $test_logger.result_log "Set terminal baud rate to '#{baud_rate}'"

        #Set test data to config struct
        serial_params =  Serial_params_settings.new
        serial_params.baud = baud_rate

        test_config = Terminal_configuration.new(:serial_params => serial_params)

        #Call set config thrift API
        call_thrift{terminal_set_configuration(test_config)}

        #Change class baud rate
        @baud_rate = baud_rate

        #Wait till new baud rate is applied
        sleep 3

        #Reconnect same class with new baud rate
        reset_connection

        # #Connect to serial channel
        # begin
        # new_cmd_mgr = ThriftProtocol.new(:com_port => $comm_serial_port, :baud_rate => baud_rate)
        # rescue Exception => e
        # raise e, "Error while opening serial connection at com port '#{$comm_serial_port}' and new baud rate '#{baud}'\n#{e.message}", e.backtrace
        # end

        #Get current config from terminal
        act_config = call_thrift{terminal_get_configuration(Terminal_configuration_type.new(
          :settings_type=>Terminal_settings_type::Serial_params_cfg))}

        #Assert config set
        $test_ref.assert_equal test_config.serial_params.baud, act_config.serial_params.baud, "Specified baud rate not set on terminal!"

      end

      #Set SSL passphrase on terminal
      def set_ssl_passphrase(passphrase, profile_id=Passphrase_id::SSL_profile_0)
      
        #Set Passphrase
        result = call_thrift{passphrase_set(profile_id, passphrase)}
    
        #Assert set passphrase
        $test_ref.assert_true result, "Failed to set passphrase for id #{Passphrase_id::VALUE_MAP[profile_id]}!"
      end
      private

      #Thread to cancel operation (Not to be called from script, use 'send_cancel' instead)
      def cancel_operation(cmd_proc, delay)
        $test_logger.result_log "Cancel operation '#{delay}'"

        #Wait till specified delay
        sleep delay

        #Call API for cancel operation
        cmd_proc.call_thrift{cancel_operation}

      end

      #Thread to read data on TCP port
      def socket_to_read_on_tcp(sock)
        $test_logger.result_log "Reading data on TCP...!!!"
        raise "Socket not connected!" if !sock
        data = ""
        begin
          fd = sock.sysaccept
          s = IO.for_fd(fd)
          data = s.gets
          s.close
        rescue Exception => e
          $test_logger.log_e("Error in TCP server", e)
        ensure
          begin
            sock.close
          rescue
          #ignore error
          end
          sock = nil
        end
        data
      end

      #Thread to read data on UDP port
      def socket_to_read_on_udp(sock)
        $test_logger.result_log "Reading data on UDP...!!!"
        raise "Socket not connected!" if !sock
        data = ""
        final_data = ""
        begin
         for i in 1..5
           begin          
            timeout(0.05) do
             data, addr = sock.recvfrom(4096)
             final_data = final_data + data
            end
            rescue Timeout::Error
              $test_logger.log_e "No More data received So Timeout!!!"
              break if data == "" and data
            end          
         end
        rescue Exception => e
          #$test_logger.log_e("Error in UDP server", e)
        ensure
          begin
            sock.close
          rescue
          #ignore error
          end
          sock = nil
        end
        #data
        final_data
      end

      #Thread to read data on SSL port
      def socket_to_read_on_ssl(port, proto_ver)
        $test_logger.result_log "Reading data on SSL...!!!"
        server  = TCPServer.new($local_ip, port)
        context = OpenSSL::SSL::SSLContext.new(proto_ver)
        store = OpenSSL::X509::Store.new
        context.verify_mode = OpenSSL::SSL::VERIFY_PEER
        context.cert = OpenSSL::X509::Certificate.new(File.open(Resource.get_path("ssl_ser.pem")))
        context.key  = OpenSSL::PKey::RSA.new(File.open(Resource.get_path("ssl_ser.pem")))
        store.add_file(Resource.get_path("ssl_ser.pem"))
        context.cert_store = store
        #context.ciphers = @ssl_cipher
        #context.verify_callback = proc do |preverify, ssl_context|
        # raise OpenSSL::SSL::SSLError.new unless preverify && ssl_context.error == 0
        #end
       
        secure = OpenSSL::SSL::SSLServer.new(server, context)
        data = ""
        loop do
          ssl = secure.accept
          puts "Connected"
          begin
            while data = ssl.gets
              break  
            end
          ensure
            ssl.close
            break
          end              
        end
      data
    end

      #Thread to read data on Serial port
      def read_on_serial(baudrate, databits, parity, stopbits)
        $test_logger.result_log "Reading data on Serial port...!!!"

        #Open serial port
        @s = SerialPort.new("COM" + $comm_serial_port.to_s, baudrate, databits, stopbits, parity)

        #Set com port read timeout as 2 seconds
        @s.read_timeout = 10000
        data_s = @s.read(100000)

        @s.close
        data_s
      end
    end
  end
  
  private
  
  def get_user_id
    event_actions = []
    
    User_DB_fields::VALID_VALUES.each do |value|
      unless [13,21].include?(value)
         event_actions << value
      end
    end
    return event_actions
  end
  
end