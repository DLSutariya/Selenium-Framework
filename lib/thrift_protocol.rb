module MA1000AutomationTool
  class ThriftProtocol < CmdManager
    def initialize(options)

      #Extend MA1000 user functions
      extend MA1000Functions

      super(options)
    end

    #Time in seconds
    THRIFT_BLOCK_TIMEOUT = 30

    #Load thrift file from MA1K_thrift folder
    def self.load_thrift_file
      $test_logger.log("Loading thrift client resources from '#{FWConfig::THRIFT_FILE_FOLDER}'...", true)

      #Load IDL generated thrift files
      i = 1
      $:.push(FWConfig::THRIFT_FILE_FOLDER)
      files = Dir.glob(File.join(Dir.pwd, FWConfig::THRIFT_FILE_FOLDER, "*.rb"))
      #Add custom thrift client files
      files.concat Dir.glob(File.join(Dir.pwd, FWConfig::THRIFT_FILE_FOLDER, FWConfig::THRIFT_CLIENT_FOLDER, "*.rb"))
      files.each { |file|
        $test_logger.log "\t" + i.to_s + ") " + File.basename(file), false
        i = i + 1
        require file }
    end

    public

    def is_thrift_connected
      @th_client != nil && @th_client.size > 0
    end

    #Wrapper function to call thrift APIs
    #This will handle exceptions raised by thrift and make appropriate assert
    def call_thrift(expected_error = nil, max_time = nil, &block)

      if max_time && max_time > THRIFT_BLOCK_TIMEOUT && @comm_type != CommType::SERIAL
        #Close existing connection
        close

        #Connect to device with maximum socket timeout
        connect_to_device true, max_time
      elsif !max_time
        #if @comm_type == CommType::SERIAL
        #  max_time = THRIFT_BLOCK_TIMEOUT*2
        #else
        max_time = THRIFT_BLOCK_TIMEOUT
        #end
      end

      $test_logger.log "Inside call_thrift with expected error = '#{expected_error.to_s}' and block = '#{block_given?}'"

      raise "Block not provided in call_thrift!" if !block_given?

      ret_val = nil

      begin

      #Enclose thrift calling block within defined timeout
        timeout(max_time) do

          index = 0
          error_arr = []
          begin
            ret_val = @th_client[index].instance_eval(&block)
          rescue NameError => ex
            error_arr << ex
            if index < @th_client.size - 1
            index += 1
            retry
            else
              err_msg = ""
              error_arr.each{|this_err| err_msg << "\n#{this_err.message}"}
              raise ex, "Specified thrift API not found!#{err_msg}", ex.backtrace
            end
          end

        end

        #Assert if error is expected and there is no actual error
        $test_ref.assert false, "No error was raised while calling thrift API!\nExpected error: #{expected_error.class} - #{expected_error.to_s}" if expected_error

      rescue Exception => ex

      #Log error
        $test_logger.log_e "Error in call_thrift!", ex, false

        #Raise proper exception if its timeout error
        raise ex, "Timedout while executing thrift API block!\n#{ex.message}", ex.backtrace if ex == Timeout::Error

        if ex.is_a?(Test::Unit::AssertionFailedError) || ex.is_a?(NameError)
          raise
        else
        #If error is raised by thrift API, log assert failure
        #if ex.class.superclass == Thrift::Exception
          if !expected_error
            $test_ref.assert false, "Unexpected error occurred while calling thrift API!\nError: #{ex.class} - #{ex.message}\n\tat #{ex.backtrace.first}"
          else

          #Create expected and actual error messages
            exp_err_msg = "#{expected_error.class} - #{expected_error.message}"
            act_err_msg = "#{ex.class} - #{ex.message}"

            $test_ref.assert_equal exp_err_msg, act_err_msg, "Error mismatched while calling thrift API!\nActual error: #{ex.class} - #{ex.message}\n\tat #{ex.backtrace.first}"
          end
        #else
        #  raise
        end
      end
      ret_val
    end

    #Set serial net Id
    def set_net_id(x)
      $test_logger.log("Serial net Id change. New net Id '#{x}'")
      begin
        @transport.net_id = x
      rescue Exception => e
        $test_logger.log_e("Error while changing serial net Id to '#{x}'", e)
      end
    end

    #Get serial net Id
    def net_id
      $test_logger.log("Get serial net Id")
      begin
        n = @transport.net_id
      rescue Exception => e
        $test_logger.log_e("Error while getting current serial net Id", e)
      end
      n
    end

    #Ensure device is up and running
    #Sync communication channel for responses
    # - receive all pending response packets for last run
    # - verify device is up and running
    def ensure_device_status

      $test_logger.log("Inside ensure_device_status for Thrift Protocol")

      max_retry = 5
      retry_count = 0
      @is_reconnected = false 
      begin
        begin
        #Increment current retry
          retry_count += 1

          $test_logger.log("Ensure device status for MA1000! trial = '#{retry_count}'")

          #Reset connection after second trial onwards
          if retry_count > 1
            reset_connection
          elsif !@transport.open?
            #Connect to device if transport is not open
            connect_to_device
          end

          #Initialize retry flag to false
          to_retry = false

          #Sending check status cmd
          begin
          #Ping data
            ping_data = "\x7\x45\x67\x50"

            #Ping and check terminal status
            ping_res = call_thrift{terminal_echo(ping_data)}

            $test_logger.log "Ping reply '#{Common.unpackbytes(ping_res)}'"

            raise "Ping response mismatch! Expected='#{Common.unpackbytes(ping_data)}', Actual='#{Common.unpackbytes(ping_res)}'" if ping_res != ping_data
          rescue Exception => ex
            raise(ex, "Error while checking terminal status!\n#{ex.message}", ex.backtrace)
          end

          #Handle exception
        rescue Exception => main_ex
          
          @is_reconnected = true
          
        #Raise exception in case of max trials
          raise(main_ex, "Error while re-connecting to terminal!\n#{main_ex.message}", main_ex.backtrace) if retry_count >= max_retry

          #Log error
          $test_logger.log_e("Could not ensure terminal connection! Trial = '#{retry_count}/#{max_retry}'", main_ex)

          #Set to_retry flag
          to_retry = true

          #Wait for 5 seconds before reconnecting
          sleep 5
        end

      end while(to_retry)

    end

    #Fetch device info
    def fetch_device_info

      begin

        $test_logger.log "Fetch terminal information"

        #Error string
        error_str = ""

        #Fetch terminal info
        begin
          ter_info = call_thrift{terminal_get_info}

          #Parse product type
          pro_type = Product_type::VALUE_MAP[ter_info.product_type]

          #Parse FW version
          fw_ver =  ter_info.firmware_version

          #Parse terminal sensor type
          if ter_info.is_CBI_supported == true
            sen_type = SensorType::CBI
          elsif ter_info.is_MSI_supported == true
            sen_type = SensorType::MSI
          elsif ter_info.is_FVP_supported == true
            sen_type = SensorType::FVP
          end

          #Parse card reader info based on product number
          if ter_info.is_iclass_supported == true
            card_reader_type = CardReaderType::ICLASS
          elsif ter_info.is_mifare_desfire_supported == true
            card_reader_type = CardReaderType::MIFARE
          elsif ter_info.is_prox_supported == true
            card_reader_type = CardReaderType::PROX
          else
            card_reader_type = CardReaderType::NONE
          end

          #Fetch terminal serial number
          ter_info = call_thrift{product_get_info(Set.new([Product_info_type::Terminal_packaged_serial_number]))}
          ter_sr_no = ter_info.terminal_packaged_serial_number_UTF8
        rescue Exception => inex
          error_str += "Error in terminal_get_info (#{inex.message})"
        end

        #Terminal comm type
        device_comm = DeviceCommType::UNKNOWN
        if @comm_type == CommType::SERIAL
          ser_info = call_thrift{terminal_get_configuration(Terminal_configuration_type.new(:settings_type=>Terminal_settings_type::Serial_params_cfg))}
          ser_type = ser_info.serial_params.communication_system

          if ser_type == Communication_system_type::Half_duplex
            device_comm = DeviceCommType::RS485
          elsif ser_type == Communication_system_type::Full_duplex
            device_comm = DeviceCommType::RS422
          end

        else
          wifi_info = call_thrift{terminal_get_configuration(Terminal_configuration_type.new(:settings_type=>Terminal_settings_type::Ip,
            :ip_version => Ip_version_type::Ip_v4, :ip_channel => IP_channel::Wifi))}
          wifi_ip = wifi_info.ip_settings.ip_address

          eth_info = call_thrift{terminal_get_configuration(Terminal_configuration_type.new(:settings_type=>Terminal_settings_type::Ip,
            :ip_version => Ip_version_type::Ip_v4, :ip_channel => IP_channel::Ethernet))}
          eth_ip = eth_info.ip_settings.ip_address

          #Terminal comm type
          if $comm_ip_address == wifi_ip
            device_comm = DeviceCommType::ETH_WIFI
          elsif $comm_ip_address == eth_ip
            device_comm = DeviceCommType::ETH_WIRED
          end
        end

        #Terminal mode (Identify/Verify)
        trig_evnt = get_param_value("ucc.trigger_event", "int32_value")
        if trig_evnt.is_a?(Fixnum)
          if trig_evnt & 0x1 == 1
            ter_mode = DeviceMode::IDENTIFY
          else
            ter_mode = DeviceMode::VERIFY
          end
        else
          ter_mode = DeviceMode::UNKNOWN
        end

        $test_logger.log("Terminal info fetched successfully!")
      rescue Exception => ex

        $test_logger.log_e "Error while fetching terminal info!\n#{error_str}", ex
      end

      return pro_type, ter_sr_no, fw_ver, device_comm, sen_type, ter_mode, card_reader_type
    end

    #Check device responds or not with immediate command
    def ping(response_timeout=2)
      #Initialize ping result as false
      ping_ok = false

      begin

      #Ping data
        ping_data = "\x4\x1\x8"

        $test_logger.log "Ping with #{Common.unpackbytes(ping_data)}"

        #Ping and check terminal status
        ping_res = call_thrift(nil, response_timeout){terminal_echo(ping_data)}

        $test_logger.log "Ping reply='#{Common.unpackbytes(ping_res)}'"

        raise "Ping response not matched! Expected='#{Common.unpackbytes(ping_data)}', Actual='#{Common.unpackbytes(ping_res)}'" if ping_res != ping_data

        #Set ping result as true
        ping_ok = true
      rescue Exception => ex
        $test_logger.log_e "Error in ping!", ex, false
      end

      #Return ping result
      ping_ok
    end
  end
end
