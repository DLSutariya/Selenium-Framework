require "test/unit"
require "fileutils"
require "csv"
require "rbconfig"
require "rexml/document"
require "rexml/streamlistener"
require "socket"
require "serialport"
require "timeout"
require "thrift"
require "trollop"
require "selenium-webdriver"

require_relative "common"
require_relative "logger"
require_relative "fw_config"
require_relative "resource"
require_relative "test_config"
require_relative "types"
require_relative "notes"
require_relative "user_functions"
require_relative "bio_packet"
require_relative "cmd_manager"
require_relative "cmd_holder"
require_relative "serial_cmd"
require_relative "ilv_cmd"
require_relative "ilv_message"
require_relative "thrift_protocol"
require_relative "template_tools"
require_relative "l1_api"
require_relative "image_compare"
require_relative "mech_arm"

include MA1000AutomationTool
include REXML
include UserFunctions

module MA1000AutomationTool
  class BaseTest < Test::Unit::TestCase

    #Execution cleanup event
    ObjectSpace.define_finalizer(self, proc {

      $test_logger.log("\n----- Overall Execution Summary -----", true, true)
      summary_info = $test_logger.generate_test_summary
      $test_logger.log(summary_info, true, true)
      $test_logger.summary_write("\nSummary-\n#{summary_info}")
      $test_logger.log("Result logs generated at '#{$test_logger.output_folder}'", true, true)
      $test_logger.log("\n*** WARNING: #{@@debug_counter} debug print(s) used!\n", true, true) if @@debug_counter > 0
      $test_logger.log("===== End of Run =====\n\n", false, true)

    })

    class << self
      #Script startup event
      def startup(test_type = TestType::UNKNOWN, sec_test_type = TestType::UNKNOWN)
        begin

        #Initialize test_ref as arbitrary class to support assertions
          Object.const_set("ArbitraryClass", Class.new { include Test::Unit::Assertions })
          $test_ref = ArbitraryClass.new

          #Include user functions
          include UserFunctions

          $test_logger.log("Base suite startup for '#{get_script_name}'")

          $test_logger.log("\n\n----- Test Script: #{get_script_name} -----", true)

          #script_name = File.basename(caller[0].split(":")[1],File.extname(caller[0].split(":")[1]))

          script_path = caller.first[/.*(:\d)/][0...-2]
          $test_logger.result_initialize(get_script_name, script_path)

          #Initialize class current test type variable
          @@current_test_type = test_type

          #Fetch device communication details from test config file
          $comm_serial_port = $test_config.get("Communication.ComPort") if !$comm_serial_port
          $comm_baud_rate = $test_config.get("Communication.BaudRate") if !$comm_baud_rate
          $comm_ip_address  = $test_config.get("Communication.IPAddress") if !$comm_ip_address
          $comm_tcp_port = $test_config.get("Communication.TCPPort") if !$comm_tcp_port
          ssl_tcp_port = $test_config.get("SSL.port").to_s
          ssl_cert = ""
          ssl_ver = ""
          ssl_cipher = ""
          
          #Get Simu Finger path from config file
          $simu_path = $test_config.get("FingerSimulationConfig.SimuFilesPath")

          #Intialize command processor
          @@cmd_proc = nil
          @@sec_cmd_proc = nil
          $is_test_fw = nil
          ssl_flag = false

          #Number of times to retry connection
          if $comm_type == CommType::ETHERNET
          max_retry = 5
          else
          max_retry = 10
          end

          #Reset trial counter
          trial = 0
          begin
          #Reset retry flag
            to_retry = false

            case test_type
            when TestType::UNKNOWN
              raise "Test type not specified in startup method while calling super(TestType = <?>) in script file '#{get_script_name}'!"

            when TestType::ILV

              #Initialize command processor based on communication type
              if $comm_type == CommType::ETHERNET

                $test_logger.log("Connecting to MA500 terminal on ethernet channel at IP '#{$comm_ip_address}:#{$comm_tcp_port}'...", true)

                #Connect to ethernet channel
                begin
                  @@cmd_proc = ILVCmd.new(:device_ip => $comm_ip_address, :tcp_port => $comm_tcp_port)

                rescue Exception => e
                  raise e, "Error while opening ethernet connection at IP '#{$comm_ip_address}:#{$comm_tcp_port}'\n#{e.message}", e.backtrace
                end

              elsif $comm_type == CommType::SERIAL
                raise "Not yet implemented!"
              end

              raise "Terminal not connected!" if !@@cmd_proc

              @@cmd_proc.ensure_device_status

              #Initialize device comm type and mode as nil, will be updated later if required
              $device_mode = nil

              #Get device info
              $device_product_type, $device_srno, $device_fw_ver, $device_comm_type, $sensor_type, $card_reader_type = @@cmd_proc.fetch_device_info

              #Skip secondary connection for MA500 legacy terminal
              if $device_product_type != "MA 520+ D"
                @@sec_cmd_proc = ILVCmd.new(:device_ip => $comm_ip_address, :tcp_port => $comm_tcp_port)
              end

              #Get connection mode (Used for Ethernet)
              $secured_conn = @@cmd_proc.secured_conn

              #Print device info
              $test_logger.log("Connected to terminal -\n#{$test_logger.get_device_info_str}", true)

            when TestType::THRIFT

              #Initialize command processor based on communication type
              if $comm_type == CommType::ETHERNET

                $test_logger.log("Connecting to MA1000 terminal on ethernet channel at IP '#{$comm_ip_address}:#{$comm_tcp_port}'...", true)

                #Connect to ethernet channel
                begin
                  if ssl_tcp_port == $comm_tcp_port
                    ssl_flag = true
                    ssl_cert = $test_config.get("SSL.cert_file")
                    ssl_ver = $test_config.get("SSL.ssl_ver")
                    ssl_cipher = $test_config.get("SSL.cipher")
                  end
                  @@cmd_proc = ThriftProtocol.new(:device_ip => $comm_ip_address, :tcp_port => $comm_tcp_port, :use_ssl => ssl_flag,
                  :cert_file => ssl_cert, :ssl_ver => ssl_ver, :ssl_cipher => ssl_cipher)

                rescue Exception => e
                  raise e, "Error while opening ethernet connection for MA1000 terminal at IP '#{$comm_ip_address}:#{$comm_tcp_port}'\n#{e.message}", e.backtrace
                end

              elsif $comm_type == CommType::SERIAL

                $test_logger.log("Connecting to MA1000 terminal on serial port '#{$comm_serial_port}' with baud rate of '#{$comm_baud_rate}'...", true)

                #Connect to serial channel
                begin
                  @@cmd_proc = ThriftProtocol.new(:com_port => $comm_serial_port, :baud_rate => $comm_baud_rate)
                rescue Exception => e
                  raise e, "Error while opening serial connection for MA1000 terminal at com port '#{$comm_serial_port}' and baud rate '#{$comm_baud_rate}'\n#{e.message}", e.backtrace
                end

              end

              raise "MA1000 terminal not connected!" if !@@cmd_proc || !@@cmd_proc.is_thrift_connected

              @@cmd_proc.ensure_device_status

              #Get device info
              $device_product_type, $device_srno, $device_fw_ver, $device_comm_type, $sensor_type, $device_mode, $card_reader_type = @@cmd_proc.fetch_device_info

              #Get connection mode (Used for Ethernet)
              $secured_conn = @@cmd_proc.secured_conn

              #Print device info
              $test_logger.log("Connected to MA1000 terminal -\n#{$test_logger.get_device_info_str}", true)

              #Open secondary connection
              begin
                $test_logger.log("Opening secondary connection over ethernet channel at IP '#{$comm_ip_address}:#{$comm_tcp_port}'...", true)
                @@sec_cmd_proc = ThriftProtocol.new(:device_ip => $comm_ip_address, :tcp_port => $comm_tcp_port, :ignore_check => true, :use_ssl => ssl_flag,
                  :cert_file => ssl_cert, :ssl_ver => ssl_ver, :ssl_cipher => ssl_cipher)
              rescue Exception => e
                $test_logger.log "Could not open sencondary connection to terminal!", true
                $test_logger.log_e "Error while opening secondary ethernet connection for MA1000 terminal at IP '#{$comm_ip_address}:#{$comm_tcp_port}'\n#{e.message}", e, false
              #raise e, "Error while opening secondary ethernet connection for MA1000 terminal at IP '#{$comm_ip_address}:#{$comm_tcp_port}'\n#{e.message}", e.backtrace
              end

            when TestType::SERIALCMD

              #Initialize command processor based on communication type
              if $comm_type == CommType::ETHERNET

                $test_logger.log("Connecting to L1 4G device on ethernet channel at IP '#{$comm_ip_address}:#{$comm_tcp_port}'...", true)

                #Connect to ethernet channel
                begin
                  @@cmd_proc = SerialCmd.new(:device_ip => $comm_ip_address, :tcp_port => $comm_tcp_port)

                rescue Exception => e
                  raise e, "Error while opening ethernet connection at IP '#{$comm_ip_address}:#{$comm_tcp_port}'\n#{e.message}", e.backtrace
                end

              elsif $comm_type == CommType::SERIAL

                $test_logger.log("Connecting to L1 4G device on serial port '#{$comm_serial_port}' with baud rate of '#{$comm_baud_rate}'...", true)

                #Connect to serial channel
                begin
                  @@cmd_proc = SerialCmd.new(:com_port => $comm_serial_port, :baud_rate => $comm_baud_rate)
                rescue Exception => e
                  raise e, "Error while opening serial connection at com port '#{$comm_serial_port}' and baud rate '#{$comm_baud_rate}'\n#{e.message}", e.backtrace
                end
              end

              raise "Device not connected!" if !@@cmd_proc

              @@cmd_proc.ensure_device_status

              #Get device info
              $device_product_type, $device_srno, $device_fw_ver, $device_comm_type, $sensor_type, $device_mode, $card_reader_type = @@cmd_proc.fetch_device_info

              #Get connection mode (Used for Ethernet)
              $secured_conn = @@cmd_proc.secured_conn

              #Print device info
              $test_logger.log("Connected to L1 4G device -\n#{$test_logger.get_device_info_str}", true)
              
              #Open secondary connection
              begin
                $test_logger.log("Opening secondary connection over ethernet channel at IP '#{$comm_ip_address}:#{$comm_tcp_port}'...", true)
                @@sec_cmd_proc = SerialCmd.new(:device_ip => $comm_ip_address, :tcp_port => $comm_tcp_port, :use_ssl => $secured_conn, :ignore_check => true)
              rescue Exception => e
                $test_logger.log "Could not open sencondary connection to terminal!", true
                $test_logger.log_e "Error while opening secondary ethernet connection in L1 mode at IP '#{$comm_ip_address}:#{$comm_tcp_port}'\n#{e.message}", e, false
              end

            end

            #Assign secondary command processor to main cmd proc
            @@cmd_proc.sec_cmd_proc = @@sec_cmd_proc
            $test_logger.log("Secondary connection not open! Delayed command feature won't work.", true) if !@@sec_cmd_proc

            #Check if current firmware is test firmware (CBI Simu + QT Testability)
            begin
              res = @@cmd_proc.sec_cmd_proc.set_simu_finger(false, 1, 1, "", nil, true)
              if res && res == true
                $is_test_fw = true
              else
                $is_test_fw = false
              end
            rescue Exception => ex
              $test_logger.log_e("Exception while disabling fake finger (To check test firmware)!", ex, false)
              $is_test_fw = false
            end
            $test_logger.log("Test Firmware: #{$is_test_fw}", true)
              
            #If no errors are raised till now, set flags
            @@exception_in_setup = false
            @@exception_msg_in_setup = ""
          rescue Exception => ex

            if [Errno::ECONNRESET,Errno::ECONNABORTED,Errno::ETIMEDOUT,Errno::ENOENT,Thrift::TransportException].include?(ex.class) ||
            ex.to_s[/Terminal ping failed!/]
              #,MobyBase::TestObjectNotFoundError

              if trial > max_retry
              to_retry = false
              else
              to_retry = true
              trial += 1
              end

              if to_retry == true
                ret_msg = ", retrying in 5 sec..."
              else
                ret_msg = "!"
              end

              $test_logger.log "    Cannot connect to device for trial '#{trial}/#{max_retry}'#{ret_msg}", true
              $test_logger.log_e "Connection error!", ex
              sleep 5 if to_retry == true

            end

            if !to_retry
              @@exception_in_setup = true
              @@exception_msg_in_setup = "Error occured in base test startup!\n#{ex.message}'\n at #{ex.backtrace.first}"
            end
          end while to_retry

        end
      end

      #Script shutdown event
      def shutdown

        #Close command processor
        @@cmd_proc.close if @@cmd_proc != nil
        @@sec_cmd_proc.close if @@sec_cmd_proc != nil

        $test_logger.result_cleanup(@@current_test_type)
        $test_logger.log("Base suite shutdown for '#{get_script_name}'\n")

      end

      #Get script name
      def get_script_name
        #If this "name" doesn't return correct test script name then use "caller"
        #or try with self.inspect
        name[/\w*$/]
      end

    end

    #Get test case name (stripping class name in parenthesis)
    def get_testcase_name
      name.gsub(/(\(.+\))$/,"")
    end

    #Append Testlink Id with Testcase Name
    def append_name_with_id
      tname = get_testcase_name
      #Remove data drivern label from tc name
      tname.gsub!(/\[.*\]/, "")
      tl_id = Common.get_testlink_id(tname)
      tc_name = name
      tc_name = tc_name.insert(-2, ":#{FWConfig::TESTLINK_PROJECT_PREFIX}#{tl_id}")
    end

    #Base class setup
    def setup

      #Set test reference to global variable
      $test_ref = self

      #Clear thread flag
      @any_threads = false

      #Initialize variables
      @custom_status = nil
      $fake_finger_enabled = nil

      #Check if exception is occured before executing first test case
      if(
      ( $test_logger.get_test_counter == 0 &&
      @_result.faults.last!=nil &&
      (@_result.faults.last.label == "Error" &&
      @_result.faults.last.test_name.end_with?(name[/\(.*\)/][1..-2])
      )
      ) or @@exception_in_setup)

        if(@@exception_msg_in_setup == "")
          @@exception_in_setup = true

          only_message = @_result.faults.last.message
          summary_fault_msg, detailed_fault_msg = get_formatted_error_msgs @_result.faults.last
          @@exception_msg_in_setup = detailed_fault_msg
          #@@exception_msg_in_setup = @_result.faults.last.to_s
          $test_logger.result_log("Error in testcase startup\n#{@@exception_msg_in_setup}")
        end

      end

      $test_logger.log("##### Base test setup for '#{get_testcase_name}'...")
      print "\n#{$test_logger.get_current_test_number}. #### Executing '#{append_name_with_id}'..."

      $test_logger.result_start_test(get_testcase_name)

      #Skip test execution if error in startup
      if @@exception_in_setup
        if only_message
        ommission_message = only_message
        else
        ommission_message = @@exception_msg_in_setup
        end
        omit "Test omitted due to error in base test!\n#{ommission_message}"
      end

      #check terminal connection
      ensure_conn

      #Disable Simu finger in case of Test Firmware
      if $is_test_fw == true
        begin
          #Disable simu finger thread, if running
          @@cmd_proc.set_simu_finger(false, 1, 1, "", nil, true)
        rescue Exception => ex
          $test_logger.log_e("Exception while disabling fake finger in base setup!", ex, false)
        end
      end

    end

    #check terminal connection
    def ensure_conn

      if (@@current_test_type != TestType::SAMPLE)
        #Raise exception if no connection
        raise "No connection establised at '#{comm_type_name($comm_type)}'!" if !@@cmd_proc

      #Ensure device is up and running
      @@cmd_proc.ensure_device_status

      #Reset secondary connection, if exists
      @@sec_cmd_proc.reset_connection(true) if @@sec_cmd_proc

      @@cmd_proc.ensure_device_status
      end

    end

    #Wait for all threads in test to complete
    def join_all_threads

      #Wait for test threads to complete
      Thread.list.each {|t|
        if t != Thread.current
          $test_logger.log("Waiting for thread '#{t}' to completed")
        t.join
        end
      }
    end

    #Base class teardown
    def teardown

      $test_logger.log("##### Base test teardown for #{get_testcase_name}")

      begin

      #Terminal simu finger thread, if running
        @@cmd_proc.simu_finger_th_terminate

      rescue Exception => ex
        $test_logger.log_e("Exception while disabling fake finger in base teardown!", ex)
      end

      #Wait for all test threads to complete
      join_all_threads

      #Get test result from test unit class
      test_res = nil
      test_unit_res = nil
      summary_fault_msg = ""
      detailed_fault_msg = ""

      #If exception in setup then mark test as error
      # if(@@exception_in_setup)
      # summary_fault_msg, detailed_fault_msg = get_formatted_error_msgs @_result.faults.last
      # test_res = TestResult::ERROR
      # else
      #Iterate to each faults and search for current test method name
      @_result.faults.each {|f|
        if f.test_name == name
          #.start_with?(method_name)

          sum_fault, det_fault = get_formatted_error_msgs f

          fault_loc = f.location.first[/\w+\.\w+:\d+/]

          summary_fault_msg << "\n\n"  if summary_fault_msg != ""
          summary_fault_msg << sum_fault

          detailed_fault_msg << "\n\n"  if detailed_fault_msg != ""
          detailed_fault_msg << det_fault

          #Set test unit result label
          test_unit_res = f.label if !test_unit_res

          #Give priority for custom status, if set
          if @custom_status
            case @custom_status
            when TestResult::EXP_FAIL, TestResult::PARTIAL
              test_res = @custom_status if f.label == "Error" || f.label == "Failure"
            when TestResult::NA, TestResult::BLOCKED
              test_res = @custom_status if f.label == "Omission"
            end
          end

          #If result not set by custom_status then
          if !test_res
            case f.label
            when "Error"
              test_res = TestResult::ERROR
            when "Failure"
              test_res = TestResult::FAIL #if !test_res
            when "Omission"
              test_res = TestResult::OMIT #if !test_res
            when "Notification"
              test_res = TestResult::NA #if !test_res
            when "Pending"
              test_res = TestResult::PENDING #if !test_res
            end
          end
        end
      }
      #end

      if !test_res
        #Check if test is passed
        if passed?
          test_res = TestResult::PASS
        else
          test_res = TestResult::UNKNOWN
        end
      end

      #Print result on console
      print " #{test_result_name(test_res)} "

      #Write test result in to log file
      Mutex.new.synchronize{
        $test_logger.result_end_test(test_res, test_unit_res, summary_fault_msg, detailed_fault_msg)
      }

      #Fetch all test data set
      all_data = attributes[:data]

      #Write to summary file
      $test_logger.summary_write(nil, all_data, data_label)

    end

    #Get formatted error messages from fault
    def get_formatted_error_msgs(test_fault)

      #fault_loc = test_fault.location.last[/\w+\.\w+:\d+/]
      fault_loc = test_fault.location.first[/\w+\.\w+:\d+/]
      lbl_name = test_fault.label.upcase
      lbl_name = "NOT_APPLICABLE" if lbl_name == "NOTIFICATION"
      summary_msg = "#{Logger::PREFIX_ERR} #{lbl_name} at #{fault_loc}\n#{test_fault.message}"

      detailed_msg = summary_msg
      detailed_msg << "\n    " + test_fault.location.join("\n    ")

      return summary_msg, detailed_msg
    end

    #Get formatted error messages from ruby exception
    def get_formatted_error_msgs_ex(ruby_ex)
      fault_loc = ruby_ex.backtrace.first[/\w+\.\w+:\d+/]
      summary_msg = "#{Logger::PREFIX_ERR} ERROR at #{fault_loc}\n#{ruby_ex.message}"

      detailed_msg = summary_msg
      detailed_msg << "\n    " + ruby_ex.backtrace.join("\n    ")

      return summary_msg, detailed_msg
    end

    #Add assertion overridden method of test unit
    def add_assertion
      super
      #Mutex.new.synchronize{
      $test_logger.result_assert(get_assert_msg)
    #}
    end

    #Get assert name and line number for test name
    def get_assert_msg()
      test_unit_assertions = "assertions.rb"

      this_call = ""
      caller[3..-1].each { |e|
        this_call = e.to_s
        break if !this_call.include?(test_unit_assertions)
      }

      src_file = this_call[/(.*):\d+:/,1]
      src_file_name = src_file[/\w+.\w+$/]
      src_line_no = this_call[/:(\d+):/,1]
      meth_name = this_call[/\W(\w+)\W$/,1]

      assert_line = "(Unable to get assert details from #{src_file_name}:#{src_line_no})"
      begin
        rd_line = Common.read_line_number(src_file, src_line_no.to_i).to_s.strip
        assert_line = rd_line if !rd_line.empty?
      rescue Exception => ex
        $test_logger.log_e("Error while reading assert details from source file!", ex)
      end

      #"Line##{this_call[/:\d+:/][1..-2]} #{previous_call.chop[/(\w+)$/]}"
      #res_tag = ""
      #res_tag = "... <RESULT>" if !@any_threads

      #"#{src_file_name}:#{src_line_no} in #{meth_name} #{res_tag}\n\t#{assert_line}"
      "#{src_file_name}:#{src_line_no} in #{meth_name}\n\t#{assert_line}"
    end

    #To execute test in new thread
    def new_thread (thread_method_name, *args, &block)
      @any_threads = true
      Thread.new {
        Thread.current[:thread_method_name] = thread_method_name
        ret = ""
        begin
        #Thread start time
          th_start_time = Time.new
          $test_logger.result_log "\nNew thread created '#{thread_method_name.to_s}(#{args.first.to_s if args!=nil})'", true

          #Call thread method
          ret = send(thread_method_name,*args, &block)
        rescue Test::Unit::AssertionFailedError => ex
          $test_logger.result_log "[Thread #{thread_method_name.to_s}(#{args.first.to_s if args!=nil})] Assert failed!", true
          add_failure(ex.message, ex.backtrace)
          @internal_data.problem_occurred
        rescue Exception => e
          $test_logger.result_log "[Thread #{thread_method_name.to_s}(#{args.first.to_s if args!=nil})] Exception occured!"
          add_error e
        @internal_data.problem_occurred
        end

        #Thread end time
        th_dura = Time.new - th_start_time

        #Print for thread exit ok
        $test_logger.result_log "Thread exit '#{thread_method_name.to_s}(#{args.first.to_s if args!=nil}) [#{th_dura}]'", true
        ret
      }
    end

    #To execute test in new thread
    def exe_in_thread(th_name = nil, &block)

      @any_threads = true
      Thread.new {

        if th_name
        thread_method_name = th_name
        else
          thread_method_name = Thread.current.to_s
        end

        #Wait for thread with same name
        wait_for_thread(thread_method_name);

        Thread.current[:thread_method_name] = thread_method_name
        ret = ""
        begin
        #Thread start time
          th_start_time = Time.new
          $test_logger.result_log "\nNew thread created '#{thread_method_name.to_s}'", true
          #Execute block
          instance_eval(&block)
        rescue Test::Unit::AssertionFailedError => ex
          $test_logger.result_log "[Thread #{thread_method_name.to_s}] Assert failed!", true
          add_failure(ex.message, ex.backtrace)
          @internal_data.problem_occurred
        rescue Exception => e
          $test_logger.result_log "[Thread #{thread_method_name.to_s}] Exception occured!", true
          add_error e
        @internal_data.problem_occurred
        end

        #Thread end time
        th_dura = Time.new - th_start_time

        #Print for thread exit ok
        $test_logger.result_log "Thread exit '#{thread_method_name.to_s}[#{th_dura}]'", true
        ret
      }
    end

    #To execute test in loop time in seconds
    def exe_in_loop(time_in_sec = 10, &block)

      $test_logger.result_log("\n\n#### Test will run for '#{Common.get_duration_in_words(time_in_sec)}' (#{time_in_sec}s).", true)
      @@str_excp = nil
      #loop start time
      start_time = Time.now
      i = 0
      i_pass = 0
      exec_time = 0
      loop do
        i= i + 1
        res = "i_NA"

        #Note start time
        cur_start_time = Time.now
        $test_logger.result_log("\n\n#### Iteration-#{i}: Start", true)

        #Check terminal connection
        ensure_conn
        begin
        #Execute block
          instance_eval(&block)

          #Consider test as PASS
          i_pass += 1
          res = "i_PASS"
          err_msg = ""
        rescue Exception => e
          $test_logger.log_e("Exception in Iteration-#{i}", e)
          @@str_excp = e
          res = "i_FAIL"

          #Format error message to include in summary file
          err_msg, nu_msg = get_formatted_error_msgs_ex e
        ensure
        #Terminate and wait till simu finger and flash card threads are gracefully exited
          @@cmd_proc.simu_finger_th_terminate
          @@cmd_proc.flash_card_th_exit

          #Check if reconnected
          err_msg = "#RECONNECTED#\n" + err_msg if @@cmd_proc.is_reconnected
          
          #Calculate loop end time
          end_time = Time.now
          exec_time = end_time - start_time

          $test_logger.result_log("#### Iteration-#{i}: Result=#{res} (Total time: #{exec_time}s) ", true)

          #Write to summary file
          $test_logger.write_summary_csv(i, $test_logger.script_name, "#{get_testcase_name}[#{i}]", $test_logger.test_link_id, cur_start_time, end_time, res, err_msg)

        #Exit loop if execution time exceeds specified time
        break if exec_time > time_in_sec
        end
      end

      #Prepare loop execution summary
      puts
      loop_summ = "--Loop Summary\n"
      loop_summ << "Execution Time   : #{Common.get_duration_in_words(exec_time)}\n"
      loop_summ << "Total Iterations : #{i}\n"
      loop_summ << "    PASS : #{i_pass}\n"
      loop_summ << "    FAIL : #{i - i_pass}\n"
      loop_summ << "--\n"

      #Log summary into remarks section
      $test_logger.summary_add_remarks(loop_summ)
      puts

      #Raise exception incase of any failure
      raise @@str_excp if @@str_excp

    end

    #Custom test result status NOT_APPLICABLE
    def not_applicable (message)
      @custom_status = TestResult::NA
      #Add remarks in summary file
      $test_logger.summary_add_remarks(message, TestResult::NA)
      omit "Test omitted due to marked as '#{test_result_name(@custom_status)}'!"
    end

    #Custom test result status EXPECTED_FAILURE
    def expected_failure (message)
      @custom_status = TestResult::EXP_FAIL
      #Add remarks in summary file
      $test_logger.summary_add_remarks(message, TestResult::EXP_FAIL)
    end

    #Custom test result status PARTIAL
    def partial (message)
      @custom_status = TestResult::PARTIAL
      #Add remarks in summary file
      $test_logger.summary_add_remarks(message, TestResult::PARTIAL)
    end

    #Custom test result status BLOCKED
    def blocked (message)
      @custom_status = TestResult::BLOCKED
      #Add remarks in summary file
      $test_logger.summary_add_remarks(message, TestResult::BLOCKED)
      omit "Test omitted due to marked as '#{test_result_name(@custom_status)}'!"
    end

    #Wrapper for test unit omit
    def omit_w (message)
      #Add remarks in summary file
      $test_logger.summary_add_remarks(message, TestResult::OMIT)
      omit "Test omitted by user intentionally."
    end

    #Assert GUI screen images
    def assert_gui(exp_img_path, act_img_path, fail_msg = "", allowed_dev = ImageCompare::ALLOWED_DEVIATION)
      exp_out_path, pix_count, pixel_dev, diff_img_path = ImageCompare.compare(exp_img_path, act_img_path)
      test_result = TestResult::UNKNOWN
      begin
        remarks = "GUI validation failed! - #{fail_msg}\nActual image deviates by #{pixel_dev}% when compared to reference image. Deviation is only allowed upto #{allowed_dev}%."
        assert_compare allowed_dev, ">=", pixel_dev, remarks
        test_result = TestResult::PASS

        if pixel_dev == 0
          remarks = "No deviation!"

        elsif pixel_dev <= allowed_dev
          remarks = "Actual image deviates by #{pixel_dev}% when compared to reference image, which is under allowed deviation limit of #{allowed_dev}%. Hence test is considered as PASS."
        end

      rescue Test::Unit::AssertionFailedError => ex
        test_result = TestResult::FAIL
      rescue Exception => ex
        test_result = TestResult::ERROR
      ensure
        $test_logger.log_to_html exp_out_path, diff_img_path, pixel_dev, test_result, remarks
        if test_result != TestResult::PASS
          raise ex
        else
        $test_logger.summary_add_remarks remarks
        end
      end

    end

  end

  #Print debug message on console (wrapper of puts)
  #Available throughout module MA1000AutomationTool
  @@debug_counter = 0

  def d(msg)
    @@debug_counter += 1
    puts "D#{@@debug_counter}: #{msg}"
  #puts caller[0]
  end

end
