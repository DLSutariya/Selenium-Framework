module MA1000AutomationTool
  class Logger
    #Constants
    PREFIX_RES_START = "\t/->"
    PREFIX_RES_OTHER = "\t|"
    PREFIX_RES_END = "\t\\->"
    PREFIX_ERR = "***"
    
    #HTML log file constants
    HTML_START_REC = "<!--START##"
    HTML_END_REC = "##END-->"
    HTML_REC_MARKER = "##RECMARKER##"
    HTML_SRNO = "##SRNO##"
    HTML_CSSCLASS = "##CSSCLASS##"
    HTML_TESTNAME = "##TESTNAME##"
    HTML_REFIMG = "##REFIMG##"
    HTML_ACTIMG = "##ACTIMG##"
    HTML_DEV = "##DEV##"
    HTML_RESULT = "##RESULT##"
    HTML_REMARKS = "##REMARKS##"
    HTML_CLASS_PASS = "pass"
    HTML_CLASS_WARNING = "warning"
    HTML_CLASS_FAIL = "fail"
    
    #Test link file constants
    TL_FILE_START = "<?xml version='1.0' encoding='UTF-8'?>\n<results>"
    TL_FILE_END = "</results>"
    TL_TC_START = "<testcase external_id='TC_ID'>" #TC_ID = MA1K-1234
    TL_TC_END = "</testcase>"
    TL_TIME_START = "<timestamp>" #Time format YYYY-MM-DD HH:mm:SS
    TL_TIME_END = "</timestamp>"
    TL_RES_PASS = "<result>p</result>"
    TL_RES_FAIL = "<result>f</result>"
    TL_RES_BLOCK = "<result>b</result>"
    TL_NOTE_START = "<notes>"
    TL_NOTE_END = "</notes>"
    
    #Getter methods
    attr_reader :output_folder, :test_link_id, :script_name
    
    def initialize(run_name, config_name)

      #Initialize summary counters
      @summary_test_count = 0
      @summary_test_pass_count = 0
      @summary_test_error_count = 0
      @summary_test_omit_count = 0
      @summary_test_pending_count = 0
      @summary_test_na_count = 0
      @summary_test_exp_fail_count = 0
      @summary_test_blocked_count = 0
      @summary_test_partial_count = 0
      @summary_assert_count = 0
      @summary_assert_pass_count = 0
      @summary_srno = nil
      @html_record_count = 0
      
      @run_start_time = Time.new
      
      #Generate output folder name
      t = Time.new
      out_folder_name = FWConfig::RUN_FOLDER_PREFIX
      
      out_folder_name << "_" + run_name
      out_folder_name << "_" + config_name if config_name != ""
      out_folder_name << "_" + t.strftime("%Y%m%d_%H%M")
      out_folder_name = File.join(t.strftime("%Y%m%d"),out_folder_name) if FWConfig::PER_DAY_RUN_FOLDER
      
      #Create output folder
      output_folder_tmp = File.join(FWConfig::LOG_FOLDER, out_folder_name)
      n = 0
      dir_exists = false 
      begin 
        @output_folder = output_folder_tmp + ("_" + n.to_s if n != 0).to_s 
        n += 1
        dir_exists = File.directory?(@output_folder)
      end while dir_exists
      FileUtils.mkpath @output_folder if !dir_exists

      #Generate debug log file path
      debug_file_name = FWConfig::DEBUG_LOG_PREFIX + "_" + t.strftime("%Y%m%d") + FWConfig::DEBUG_LOG_EXT
      @debug_log = File.join(@output_folder, debug_file_name)

      #Generate part of log file name based on current run
      log_name_part = run_name  
      log_name_part << "_" + config_name if config_name != ""
      log_name_part << "_" + t.strftime("%Y%m%d_%H%M%S")
      
      #Generate summary log file path
      summary_file_name = FWConfig::SUMMARY_LOG_PREFIX + "_" + log_name_part + FWConfig::SUMMARY_LOG_EXT 
      @summary_log = File.join(@output_folder, summary_file_name)
      
      #Load result HTML template file
      html_log_content = Common.read_all_text(FWConfig::HTML_LOG_TEM_PATH)
      @html_record = html_log_content[/#{HTML_START_REC}(.*)#{HTML_END_REC}/m, 1] 
      @html_log_head = html_log_content[/(.*)#{HTML_START_REC}/m, 1]
      @html_log_foot = html_log_content[/#{HTML_END_REC}(.*)/m, 1]
      html_file_name = FWConfig::HTML_LOG_PREFIX + "_" + log_name_part + FWConfig::HTML_LOG_EXT
      @html_log = File.join(@output_folder, html_file_name)
      
      #Generate test link XML file path
      tl_file_name = FWConfig::TL_LOG_PREFIX + "_" + log_name_part + FWConfig::TL_LOG_EXT
      @tl_xml_log = File.join(@output_folder, tl_file_name)
      
    end

    #Log to debug file
    def log(message, print_on_console=false, notime=false)
      log_msg = message.to_s
      #puts "    #{log_msg.gsub("\n","\n    ")}" if print_on_console
      print_on_console(log_msg) if print_on_console
      
      if !notime
        
        #Find caller class name
        caller_class = ""
        caller_class = caller.first[/\w+\.\w+:\d+/] + " " if caller.length > 0
        caller_class = "" if caller_class.include?("logger.rb")
        
        #log_msg = Time.new.strftime("%Y-%b-%d %H:%M:%S.%L: ") + log_msg 
        log_msg = "#{Time.new.strftime("%Y-%b-%d %H:%M:%S.%L:")} #{caller_class}#{log_msg}"
      
        #Replace new line chars with proper indentation
        #log_msg.gsub!("\n","\n#{" "*26}") 
      end
      
      Common.append_text_to_file(@debug_log, log_msg)
    end
    
    #Log to debug file
    def log_e(message, e, print_on_console=true)
      if e.is_a? Exception
        #fault_loc = " at #{e.backtrace.first[/\w+\.\w+:\d+/]}"
        fault_loc = " at\n"
        fw_root_found = false
        
        e.backtrace.each{|bk|
          fw_root_found = true if bk[FWConfig::ROOT_FOLDER_PATH]
          break if fw_root_found == true && !bk[FWConfig::ROOT_FOLDER_PATH]
          fault_loc << "    " + bk + "\n"
        }
        
        err_msg = "\n #{e.message}"
      else
        fault_loc = ""
        err_msg = " #{e.to_s}"
      end  
      log_msg = "#{PREFIX_ERR} ERROR (#{e.class} - #{message.to_s})#{fault_loc}#{err_msg}"
      #puts "\n#{log_msg}" if print_on_console
      print_on_console(log_msg) if print_on_console
      log_msg << "\n    " + e.backtrace.join("\n    ") if e.is_a? Exception
            
      log log_msg
    end

    #Initialize result file
    def result_initialize(script_name, script_path)

      #Script Intialization time
      @script_start_time = Time.new

      #Assign script name to instance variable
      @script_name = script_name
      @script_path = script_path

      #Initialize counters
      @test_counter = 0
      @test_pass_counter = 0
      @test_fail_counter = 0
      @test_error_counter = 0
      @test_omit_counter = 0
      @test_pending_counter = 0
      @test_na_counter = 0
      @test_exp_fail_counter = 0
      @test_blocked_counter = 0
      @test_partial_counter = 0
      @assert_counter = 0
      @assert_fail_counter = 0
      @result_cleanup_done = false
      
      @test_result = TestResult::UNKNOWN
      @result_logged_in_startup = false

      #Generate result file path
      res_file_name = @script_name + "_" + @script_start_time.strftime("%Y_%m_%d") + FWConfig::RESULT_LOG_EXT
      @result_log = File.join(@output_folder, res_file_name)
      
      #Write start of test script
      log_msg = "########### Start of TestScript : " + @script_name + @script_start_time.strftime(" (%Y-%b-%d %H:%M:%S.%L)\n\n")
      Common.append_text_to_file(@result_log, log_msg)
    end

    #Cleanup result file
    def result_cleanup(test_type)

      #Script Completition time
      @script_end_time = Time.new
      
      #Update summary counters
      @summary_test_count += @test_counter
      @summary_test_pass_count += @test_pass_counter
      @summary_test_error_count += @test_error_counter
      @summary_test_omit_count += @test_omit_counter
      @summary_test_pending_count += @test_pending_counter
      @summary_test_na_count += @test_na_counter
      @summary_test_exp_fail_count += @test_exp_fail_counter
      @summary_test_blocked_count += @test_blocked_counter
      @summary_test_partial_count += @test_partial_counter
      @summary_assert_count += @assert_counter
      @summary_assert_pass_count += (@assert_counter-@assert_fail_counter)

      #Get duration in words
      duration_words = Common.get_duration_in_words(@script_end_time - @script_start_time)

      #Generate string to log
      log_msg = "Script Name\t: " + @script_name + "\n"
      log_msg << "Script Path\t: " + @script_path + "\n"
      log_msg << "Script Type\t: " + test_type_name(test_type) + "\n"
      log_msg << "Result\t\t: " + script_result() + "\n"
      log_msg << "Tests\t\t: Total #{@test_counter} (Pass #{@test_pass_counter}, Fail #{@test_fail_counter}, Error #{@test_error_counter}"
      log_msg << ", Omission #{@test_omit_counter}" if @test_omit_counter != 0
      log_msg << ", Pending #{@test_pending_counter}" if @test_pending_counter != 0
      log_msg << ", Not Applicable #{@test_na_counter}" if @test_na_counter != 0
      log_msg << ", Expected Failure #{@test_exp_fail_counter}" if @test_exp_fail_counter != 0
      log_msg << ", Blocked #{@test_blocked_counter}" if @test_blocked_counter != 0
      log_msg << ", Partial Automated #{@test_partial_counter}" if @test_partial_counter != 0
      log_msg << ")\n"
      log_msg << "Assertions\t: Total " + @assert_counter.to_s + " (Pass " +  assert_pass_count.to_s + ", Fail " + @assert_fail_counter.to_s + ")\n"
      log_msg << "########### End of TestScript (" + duration_words + ")\n\n"
      Common.append_text_to_file(@result_log, log_msg)
      log_to_result(log_msg)
      
      #Update cleanup done flag
      @result_cleanup_done = true
    end

    #Result file start test
    def result_start_test(testcase)

      #Testcase Intialization time
      @test_start_time = Time.new
      
      #Initialize variables
      @test_failed = false
      @summary_remarks = ""
      @summary_remarks_pass = ""
      @summary_remarks_fail = ""
      @summary_remarks_error = ""
      @summary_remarks_omit = ""
      @summary_remarks_pending = ""
      @summary_remarks_na = ""
      @summary_remarks_partial = ""
      @summary_remarks_blocked = ""
      @summary_remarks_expfail = ""
      
      #Increment test counter
      @test_counter += 1

      #Store test method name (with data value)
      @test_name = testcase
      
      #Store test method name (without data value)
      @test_method_name = testcase.gsub(/\[.*\]/,"")
      
      #Fetch test link Id from mapping file
      tl_id = Common.get_testlink_id(@test_method_name)
      if tl_id != nil
        @test_link_id = FWConfig::TESTLINK_PROJECT_PREFIX + tl_id.to_s
      else
        @test_link_id = ""
      end 
       
      if @test_counter == 1 && @result_logged_in_startup
        updatedMessage = "\n"
      else
        updatedMessage = ""
      end

      updatedMessage << "#{PREFIX_RES_START} Start of TestCase: " + @test_counter.to_s + " " +@test_name+ @test_start_time.strftime(" (%Y-%b-%d %H:%M:%S.%L)")
      Common.append_text_to_file(@result_log,updatedMessage)
      log_to_result(updatedMessage)
    end

    #Result file end test
    def result_end_test(test_res, test_unit_res, summary_fault_msg, detailed_fault_msg)

      #Script Completition time
      @test_end_time = Time.new
      
      #if start test is skipped, initialize used variables
      @test_start_time = @test_end_time if !@test_start_time
      @summary_remarks = "" if !@summary_remarks
      @summary_remarks_pass = "" if !@summary_remarks_pass
      @summary_remarks_error = "" if !@summary_remarks_error
      @summary_remarks_fail = "" if !@summary_remarks_fail
      @summary_remarks_pending = "" if !@summary_remarks_pending
      @summary_remarks_omit = "" if !@summary_remarks_omit
      @summary_remarks_na = "" if !@summary_remarks_na
      @summary_remarks_partial = "" if !@summary_remarks_partial
      @summary_remarks_blocked = "" if !@summary_remarks_blocked
      @summary_remarks_expfail = "" if !@summary_remarks_expfail
      
      duration_words = Common.get_duration_in_words(@test_end_time - @test_start_time)

      #If test is marked failed by test unit then update assert fail counter
      if test_unit_res == "Failure"
        @assert_fail_counter += 1
      end
      
      test_fault_summary = ""
      current_summary = ""
      @test_result = test_res
      case @test_result
      when TestResult::PASS
        @test_pass_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_pass
      when TestResult::FAIL
        @test_fail_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_fail
      when TestResult::ERROR
        @test_error_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_error
      when TestResult::OMIT
        @test_omit_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_omit
      when TestResult::PENDING
        @test_pending_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_pending
      when TestResult::NA
        @test_na_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_na
      when TestResult::EXP_FAIL
        @test_exp_fail_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_expfail
      when TestResult::BLOCKED
        @test_blocked_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_blocked
      when TestResult::PARTIAL
        @test_partial_counter += 1
        
        #Update summary remarks
        current_summary = @summary_remarks_partial
      end
      
      #Update summary remarks
      if current_summary != ""
        #@summary_remarks += "\n\n" if @summary_remarks != ""
        @summary_remarks = current_summary + "\n\n" + @summary_remarks
      end
      
      #Write prev assert if available
      #write_prev_assert(assert_res) if @prev_assert_msg
      
      #Update summary remarks
      if summary_fault_msg != ""
        @summary_remarks += "\n\n" if @summary_remarks != ""
        @summary_remarks << summary_fault_msg
      end
      
      test_fault_summary << "#{detailed_fault_msg}" if detailed_fault_msg != ""
      #test_fault_summary << "\n#{test_fault_other_msg}" if test_fault_other_msg != ""
      

      #Format test_faults
      test_fault_summary.gsub!("\n","\n#{PREFIX_RES_OTHER}\t\t")
      test_fault_summary.gsub!("#{PREFIX_RES_OTHER}\t\t***","#{PREFIX_RES_OTHER}\t***")

      log_msg = ""
      log_msg << "#{PREFIX_RES_OTHER}\t#{test_fault_summary}\n" if @test_result != TestResult::PASS
      log_msg << "#{PREFIX_RES_OTHER}\n"
      log_msg << "#{PREFIX_RES_OTHER} TestCase\t: #{@test_name}\n"
      log_msg << "#{PREFIX_RES_OTHER} Result\t: " + test_result_name(@test_result) + "\n"
      #log_msg << "#{PREFIX_RES_OTHER} Reason\t: " + @test_error_msg + "\n" if @test_error_msg!=nil
      log_msg << "#{PREFIX_RES_END} End of TestCase (" + duration_words + ")\n\n"
      Common.append_text_to_file(@result_log, log_msg)
      log_to_result(log_msg)
    end

    #Add remarks to summary file for current test case
    def summary_add_remarks(message, for_test_result_flags=TestResult::UNKNOWN)
      if message.strip != ""
        
        #Print message on console
        #print "\n    #{message.gsub("\n","\n    ")} "
        print_on_console(message)
        
        if TestResult::PASS & for_test_result_flags == TestResult::PASS && @summary_remarks_pass
          @summary_remarks_pass += "\n" if @summary_remarks_pass != ""
          @summary_remarks_pass << message
        end
        
        if TestResult::FAIL & for_test_result_flags == TestResult::FAIL && @summary_remarks_fail 
          @summary_remarks_fail += "\n" if @summary_remarks_fail != ""
          @summary_remarks_fail << message
        end
         
        if TestResult::ERROR & for_test_result_flags == TestResult::ERROR && @summary_remarks_error
          @summary_remarks_error += "\n" if @summary_remarks_error != ""
          @summary_remarks_error << message
        end
        
        if TestResult::OMIT & for_test_result_flags == TestResult::OMIT && @summary_remarks_omit
          @summary_remarks_omit += "\n" if @summary_remarks_omit != ""
          @summary_remarks_omit << message
        end
        
        if TestResult::PENDING & for_test_result_flags == TestResult::PENDING && @summary_remarks_pending
          @summary_remarks_pending += "\n" if @summary_remarks_pending != ""
          @summary_remarks_pending << message
        end
        
        if TestResult::NA & for_test_result_flags == TestResult::NA && @summary_remarks_na
          @summary_remarks_na += "\n" if @summary_remarks_na != ""
          @summary_remarks_na << message
        end
        
        if TestResult::BLOCKED & for_test_result_flags == TestResult::BLOCKED && @summary_remarks_blocked
          @summary_remarks_blocked += "\n" if @summary_remarks_blocked != ""
          @summary_remarks_blocked << message
        end
        
        if TestResult::EXP_FAIL & for_test_result_flags == TestResult::EXP_FAIL && @summary_remarks_expfail
          @summary_remarks_expfail += "\n" if @summary_remarks_expfail != ""
          @summary_remarks_expfail << message
        end
        
        if TestResult::PARTIAL & for_test_result_flags == TestResult::PARTIAL && @summary_remarks_partial
          @summary_remarks_partial += "\n" if @summary_remarks_partial != ""
          @summary_remarks_partial << message
        end
        
        if TestResult::UNKNOWN & for_test_result_flags == TestResult::UNKNOWN && @summary_remarks
          @summary_remarks += "\n" if @summary_remarks != ""
          @summary_remarks << message
        end
      end
    end

    #Get current script result
    def script_result
      @test_fail_counter == 0 && @test_error_counter == 0 && @test_omit_counter == 0 ? "PASS" : "FAIL"
    end

    #Get assert pass count
    def assert_pass_count
      @assert_counter - @assert_fail_counter
    end

    #Result file log assert message
    def result_assert(msg)
      Mutex.new.synchronize{
        @assert_counter += 1
        msg_to_write = format_result_msg("Assertion at " + msg.to_s) #.gsub("<RESULT>", res)
        Common.append_text_to_file(@result_log, msg_to_write)
        log_to_result(msg_to_write)      
      }
    end
    
    #private
    # def write_prev_assert(res)
      # #Mutex.new.synchronize{
        # msg_to_write = @prev_assert_msg.gsub("<RESULT>", res)
#         
        # #puts "old #{@prev_assert_msg.class}"
        # Common.append_text_to_file(@result_log, msg_to_write)
        # #puts "new #{@prev_assert_msg.class}"
        # log_to_result(msg_to_write)      
        # @prev_assert_msg = nil
      # #}
    # end
    
    public
    def time_since_test_start
      format("%0.2f", Time.new - @test_start_time)
    end
    
    def format_result_msg(msg)
      msg.gsub!("\n","\n#{PREFIX_RES_OTHER}\t\t\t")
      "\t|\t#{time_since_test_start}s\t->#{msg}" 
    end
   
    #Write summary log
    def summary_write(summary_info = nil, all_data=nil, data_label=nil)

      if summary_info
        
        #Append final execution summary to summary log file
        Common.append_text_to_file(@summary_log, summary_info.to_s.gsub(" : ",","))
        
        #Close HTML file
        Common.append_text_to_file(@html_log, @html_log_foot) if File.exist?(@html_log)
        
        #Close testlink XML file
        Common.append_text_to_file(@tl_xml_log, TL_FILE_END) if File.exist?(@tl_xml_log)
        
      else
        
        #Write summary remarks to result log file
        result_log @summary_remarks
        
        #Write data to summary file
        write_summary_csv(nil,@script_name,@test_name,@test_link_id,@test_start_time, @test_end_time, test_result_name(@test_result),@summary_remarks)

        #Write data driven log file if current test is data driven
        if all_data != nil
          
          begin
            #Fetch data for data driven tests and compute flags
            is_data_driven = false
            is_data_first = false
            is_data_last = false
            data_number = 0
        
            #Compute other data driven parameters
            all_data.each do |this_data|
              data_number += 1 
               
              #Check for data label for current test case
              if this_data.keys.first == data_label
                @cur_data_set = this_data
                break
              end
            end 
            
            #Compute data first/last flags
            is_data_first = true if data_number == 1
            is_data_last = true if all_data.last.keys.first == data_label
          
            $test_logger.log("Current test is data driven. Number=#{data_number}, IsFirst=#{is_data_first}, IsLast=#{is_data_last}")
            
            #If it is first test data then create data driven file
            if is_data_first == true || !@dd_log
              
              dd_file_name = FWConfig::DD_LOG_PREFIX + "_" + @test_method_name + FWConfig::DD_LOG_EXT 
              @dd_log = File.join(@output_folder, dd_file_name)
              
              $test_logger.log("Initializing data driven result file '#{@dd_log}'")
              
              #Write header row in data driven file
              CSV.open(@dd_log, 'w') do |csv|
                header = ["srno", "label"].concat(@cur_data_set[data_label].keys).concat(["result", "remarks"])
                $test_logger.log("Data driven header '#{header}'")
                csv << header 
              end
            end
            
            $test_logger.log("Writing result into data driven result file")
            
            #Append data values in data driven file
            CSV.open(@dd_log, 'a') do |csv|
              csv << [data_number, data_label].concat(@cur_data_set[data_label].values).concat([test_result_name(@test_result), @summary_remarks])
            end
            
            #Compute consolidated result
            if @dd_con_result == nil
              @dd_con_result = @test_result
            else
              
              old_res = get_testlink_result(@dd_con_result)
              new_res = get_testlink_result(@test_result)
              
              if new_res == TestResult::PASS && old_res == TestResult::PASS  
                @dd_con_result = TestResult::PASS
              elsif new_res == TestResult::OMIT && old_res == TestResult::OMIT  
                @dd_con_result = TestResult::OMIT
              elsif new_res == TestResult::UNKNOWN || new_res == TestResult::NA 
                #Skip computing unknown result
              else
                @dd_con_result = TestResult::FAIL
              end
              
              $test_logger.log("Consolidated data driven results, old_res='#{test_result_name(old_res)}', new_res='#{test_result_name(new_res)}', combined='#{test_result_name(@dd_con_result)}'")
              
            end
            
            #Compute consolidated test link notes
            @dd_con_notes = "" if @dd_con_notes == nil
            @dd_con_notes += "#{data_number}) Data[#{data_label}] = #{test_result_name(@test_result)}"
             
            if @test_result == TestResult::FAIL || @test_result == TestResult::ERROR || @test_result == TestResult::BLOCKED
              jira_ids = @summary_remarks.scan(/(JIRA ID.*-\d+)/)
              @dd_con_notes += " (#{jira_ids.join(', ')})" if jira_ids.to_s.size > 0 
            end 
            @dd_con_notes += "\n"
                      
            #If it is last test data then write result to test link XML file
            if is_data_last == true
              
              $test_logger.log("Data driven last data value")
              
              log_to_testlink(@test_link_id, @test_end_time, @dd_con_result, @dd_con_notes) 
              
              #Reset consolidate result variables
              @dd_con_result = nil
              @dd_con_notes = nil
              @dd_log = nil
            end
          rescue Exception => ex
            $test_logger.log_e("Error while logging data driven result!", ex)
          end
        else
          $test_logger.log("Current test is not data driven")
          
          #Remove path till AutomationTool main folder, if any
          @summary_remarks.gsub!(FWConfig::ROOT_FOLDER_PATH, "...#{FWConfig::ROOT_FOLDER_PATH[/\w+$/]}")
          
          #Write test link XML for non data driven test 
          log_to_testlink(@test_link_id, @test_end_time, @test_result, @summary_remarks)
        end
        
      end
    end
    
    #Write content to summary CSV file
    def write_summary_csv(srno, script_name, test_name, tl_id, st_time, en_time, res_name, remarks)

      log("In write_summary_csv. Remarks: #{remarks}")

      #Check if making summary file entry for the first time
      if @summary_srno == nil
        if File.exist?(@summary_log)
          #Read last sr no
          arr_of_arrs = CSV.read(@summary_log)
          last_line = arr_of_arrs.last
          @summary_srno = last_line.first.to_i
        else
        #Create new summary file
          @summary_srno = 0
          CSV.open(@summary_log, 'w') do |csv|
          #Write header row
            csv << ['SrNo','ScriptName','TestCaseName','TestLinkId','StartDate','EndDate','Duration','Status','Remarks']
          end
        end
      end

      #Prepare SrNo to log in summary file
      if srno == nil
        @summary_srno += 1
      srno = @summary_srno
      else
        srno = "#{@summary_srno + 1}_#{srno}"
      end

      #Log entry in summary file
      begin
        CSV.open(@summary_log, 'a') do |csv|
          duration = en_time - st_time
          print "(#{duration})"
          csv << [srno, script_name, test_name, tl_id, st_time.strftime("%Y-%b-%d %H:%M:%S"),en_time.strftime("%Y-%b-%d %H:%M:%S"),duration,res_name,remarks]
        #csv << [@summary_srno,@script_name,@test_name,@test_link_id,@test_start_time.strftime("%Y-%b-%d %H:%M:%S"),@test_end_time.strftime("%Y-%b-%d %H:%M:%S"),duration,test_result_name(@test_result),@summary_remarks]
        end
      rescue Exception => ex
      #Retry if permission error
        if ex.class == Errno::EACCES
          log "Permission denied while writing summary file! Retrying in 2 seconds...", true
          sleep 2
        retry
        end

        log_e "Error in summary_write! Error: #{ex.message}", ex
      end

    end

    #Get summary test fail count
    def summary_test_fail_count
      @summary_test_count - @summary_test_pass_count - @summary_test_error_count - @summary_test_omit_count - @summary_test_pending_count - @summary_test_na_count - @summary_test_exp_fail_count - @summary_test_blocked_count - @summary_test_partial_count
    end

    #Get summary assert fail count
    def summary_assert_fail_count
      @summary_assert_count - @summary_assert_pass_count
    end

    def get_current_test_number
      @summary_test_count + @test_counter + 1
    end
    
    def get_test_counter
      @test_counter
    end
    
    #Get total number of tests using test unit var 'added_methods' 
    def get_total_tests_count
      
      total_tc = 0
      
      begin
      
      @@added_methods.each_with_index{|m,i|
       tc = 0
       m[1].each{|n|
         
         #If method name starts with test_ consider it as test method
         if n[0,5] == "test_"
           tc+=1
         end
       }
       
       total_tc += tc
      }
      d total_tc
      rescue Exception => ex
        log_e "Error while calculating total test method count!", ex
      end
      
      total_tc
    end

    #Get device info str
    def get_device_info_str
      
      $device_product_type = "N/A" if !$device_product_type
      $device_srno = "N/A" if !$device_srno
      $device_fw_ver = "N/A" if !$device_fw_ver
      
      if !$device_comm_type
        device_comm = "N/A"
      else
        device_comm = device_comm_type_name($device_comm_type)
      end
      
      if !$device_mode
        device_mode = "N/A"
      else
        device_mode = device_mode_name($device_mode)
      end
      
      if !$sensor_type
        sensor_type = "N/A"
      else
        sensor_type = sensor_type_name($sensor_type)
      end
      
      if !$card_reader_type
        reader_type = "N/A"
      else
        reader_type = card_reader_type_name($card_reader_type)
      end
      
      dev_info_str = "Device Info     : Type = #{$device_product_type}; S/N = #{$device_srno}; F/W = #{$device_fw_ver}; Sensor = #{sensor_type}; Reader = #{reader_type}"
      dev_info_str << "\n                  Device Mode = #{device_mode}; Device Comm = #{device_comm}" if device_mode != "N/A" || device_comm != "N/A" 
      dev_info_str << " (Secured)" if $secured_conn && $secured_conn == true
      
      dev_info_str
    end

    #Get test summary details
    def generate_test_summary
      
      begin
        #Perform cleanup if not done, incase of user interruption
        if @result_cleanup_done == false
          
          #Call result cleanup
          result_cleanup(TestType::UNKNOWN)
          
          #Ignore current test status
          @summary_test_pass_count -= 1 
          @summary_test_count -=1
        end
        
        t = Time.new
        
        run_duration = Common.get_duration_in_words(t- @run_start_time)
        
        $comm_ip_address = "N/A" if !$comm_ip_address
        $comm_tcp_port = "N/A" if !$comm_tcp_port
        $comm_serial_port = "N/A" if !$comm_serial_port
        $comm_baud_rate = "N/A" if !$comm_baud_rate
        
        r =  "Test Run Mode   : #{run_mode_name($test_run_mode)}(#{$run_name})\n"
        r << "Communication   : #{comm_type_name($comm_type).capitalize} "
        r << "IP = #{$comm_ip_address}; TCP Port = #{$comm_tcp_port}\n" if $comm_type == CommType::ETHERNET
        r << "Port = COM#{$comm_serial_port}; Baud rate = #{$comm_baud_rate}\n" if $comm_type == CommType::SERIAL
        r << "#{get_device_info_str}\n"
        r << "Assertions      : Total #{@summary_assert_count} (Pass #{@summary_assert_pass_count}; Fail #{summary_assert_fail_count})\n"
        r << "Tests           : Total #{@summary_test_count} (Pass #{@summary_test_pass_count}; Fail #{summary_test_fail_count}; Error #{@summary_test_error_count}"
        r << "; Omission #{@summary_test_omit_count}" if @summary_test_omit_count != 0
        r << "; Pending #{@summary_test_pending_count}" if @summary_test_pending_count != 0
        r << "; Not Applicable #{@summary_test_na_count}" if @summary_test_na_count != 0
        r << "; Expected Failure #{@summary_test_exp_fail_count}" if @summary_test_exp_fail_count != 0
        r << "; Blocked #{@summary_test_blocked_count}" if @summary_test_blocked_count != 0
        r << "; Partial Automated #{@summary_test_partial_count}" if @summary_test_partial_count != 0
        r << ")\n"
        r << "Run Start Time  : #{@run_start_time.strftime("%Y-%b-%d %H:%M:%S.%L")}\n"
        r << "Run End Time    : #{t.strftime("%Y-%b-%d %H:%M:%S.%L")}\n"
        r << "Run Duration    : #{run_duration}\n"
      rescue Exception => ex
        r = "Error while generating summary! " + ex.message + "\n#{ex.backtrace}" 
      end
      
      r
    end
    
    #Write msg to result log file 
    def result_log(msg, print_on_console=false)
      Mutex.new.synchronize{
        
        #Print message on console
        #puts "    #{msg.gsub("\n","\n    ")}" if print_on_console
        print_on_console(msg) if print_on_console
        
        #Log for startup method
        if @test_counter == 0
          msg.gsub!("\n","\n\t")
          log_msg = "\t#{msg}" 
          @result_logged_in_startup = true
        else
          log_msg = format_result_msg(msg)
        end
        
        Common.append_text_to_file(@result_log, log_msg)
        log_to_result(log_msg)
      }      
    end
    
    #Get the temporary file path in current output folder
    def get_temp_file_path(prefix = "tmp", ext = ".tmp", sub_dir = nil)
      log("Call to get_temp_file_path, prefix: '#{prefix}', ext: '#{ext}'")
      
      raise "Invalid extension format! Expected: '.<ext>' Actual: '#{ext}'" if !ext.start_with?(".")
      
      #Check for sub directory
      dir_path = @output_folder
      if sub_dir
        dir_path = File.join(dir_path, sub_dir)
        dir_exists = File.directory?(dir_path)
        FileUtils.mkpath dir_path if !dir_exists
      end
      
      t = Time.new
      tmp_file_name = "#{prefix}_#{t.strftime('%Y%m%d_%H%M%S.%3N')}#{ext}"
      tmp_file_path = File.join(dir_path, tmp_file_name)
      
      log("Temporary file path generated in output directory as: '#{tmp_file_path}'")
      
      tmp_file_path
    end
    
    #Make HTML log entry
    def log_to_html(exp_img_path, act_img_path, pixel_dev, result, remarks="")
      
      log("Log to html, '#{exp_img_path}', '#{act_img_path}', '#{pixel_dev}', '#{result}', '#{remarks}'")
      
      #Trim images path
      exp_img_path = exp_img_path[/[\/\\](#{ImageCompare::OUTPUT_SUB_DIR}.*)/, 1]
      act_img_path = act_img_path[/[\/\\](#{ImageCompare::OUTPUT_SUB_DIR}.*)/, 1]

      #Increment html record count
      @html_record_count += 1
      
      #Replace values to HTML record (table row)
      new_record = @html_record.gsub(HTML_SRNO, @html_record_count.to_s)
      if result == TestResult::PASS
        if pixel_dev == 0.0
          new_record.gsub!(HTML_CSSCLASS, HTML_CLASS_PASS)
        else
          new_record.gsub!(HTML_CSSCLASS, HTML_CLASS_WARNING)
        end 
      elsif result == TestResult::FAIL
        new_record.gsub!(HTML_CSSCLASS, HTML_CLASS_FAIL)
      end
      new_record.gsub!(HTML_TESTNAME, @test_name)
      new_record.gsub!(HTML_REFIMG, exp_img_path)
      new_record.gsub!(HTML_ACTIMG, act_img_path)
      new_record.gsub!(HTML_DEV, "#{pixel_dev}%")
      new_record.gsub!(HTML_RESULT, test_result_name(result))
      remarks.gsub!("\n","<BR/>")
      new_record.gsub!(HTML_REMARKS, remarks)
      
      #Initialize HTML result file if file do not exist
      Common.append_text_to_file(@html_log, @html_log_head) if !File.exist?(@html_log)
      
      #Write updated table row to HTML file
      Common.append_text_to_file(@html_log, new_record)
      
    end
    
    #Make Test Link XML entry
    def log_to_testlink(tl_id, time, test_result, notes)
     
      log("Log to testlink xml")
      
      #Create test case tag for testlink XML
      test_case = TL_TC_START.gsub("TC_ID", tl_id) + "\n"
      test_case << TL_TIME_START + time.strftime("%Y-%m-%d %H:%M:%S") + TL_TIME_END + "\n"
      tl_res = nil
      case get_testlink_result(test_result)
      when TestResult::PASS
        tl_res = TL_RES_PASS
      when TestResult::FAIL
        tl_res = TL_RES_FAIL 
      when TestResult::OMIT
        tl_res = TL_RES_BLOCK 
      else
        log("Test link result not configured for result '#{test_result_name(test_result)}', hence skipped logging into test link XML!")
      end
      
      #Create test result entry in test link XML only if known result is found
      if tl_res != nil
        test_case << tl_res + "\n"
        test_case << TL_NOTE_START + escape_xml_chars(notes) + TL_NOTE_END + "\n"
        test_case << TL_TC_END + "\n"
        
        #Initialize HTML result file if file do not exist
        Common.append_text_to_file(@tl_xml_log, TL_FILE_START) if !File.exist?(@tl_xml_log)
        
        #Write updated table row to HTML file
        Common.append_text_to_file(@tl_xml_log, test_case)
      end
      
    end
    
    #Get formatted jira defect 
    def jira_str(defect_id, title)
     "JIRA ID #{FWConfig::JIRA_ID_PREFIX}#{defect_id}\n#{title}"
    end
    
    #Add summary for defects 
    def summary_defect(defect_id, title)
     df_log = jira_str(defect_id, title)
     summary_add_remarks(df_log)
    end
    
    #Escape testlink XML characters
    def escape_xml_chars(str)
      if str != nil && str != ""
        str.gsub!("<", "&lt;")
        str.gsub!(">", "&gt;")
        str.gsub!("&", "&amp;")
        str.gsub!("\t", " ")
        str.gsub!(/[\x00-\x09]|[\x80-\xff]/,'?') #Remove non-ASCII chars
      end 
      str.to_s
    end
    
    #Remove escape of XML characters
    def de_escape_xml_chars(str)
      if str != nil && str != ""
        str.gsub!("&lt;", "<")
        str.gsub!("&gt;", ">")
        str.gsub!("&amp;", "&")
      end 
      str.to_s
    end
    
    #Print pre-conditions on console and dump in log file
    def precondition(pre_arr, config_arr = nil)
      
      #Console char len
      char_len = 90
      
      #Prepare pre-conditions string
      pre_str = "\nPre-Condition(s):\n"
      if pre_arr
        #Check if string convert to array
        if pre_arr.is_a?(String)
          pre_arr = [pre_arr]  
        end
        pre_arr.each{|p|
          ps = p.scan(/.{1,#{char_len}}/).join("\n      ")
          pre_str << "    - #{ps}\n"
        }
      end
        
      #Prepare config params precondition
      if config_arr
        
        #Convert to array if config is string
        if config_arr.is_a?(String)
          config_arr = [config_arr]
        end
        
        #Prepare config string
        str = "Following parameter values should be updated in config file ('#{$test_config.file_name}') before executing this script:"
        str = str.scan(/.{1,#{char_len}}/).join("\n      ")
        pre_str << "    - #{str}\n"
        config_arr.each{|c|
          c = c.scan(/.{1,#{char_len-4}}/).join("\n          ")
          pre_str << "        > #{c}\n"  
        }
      end 
      
      #Print on console & log
      log(pre_str, true)
    end
     
    private
    #Get test link result
    def get_testlink_result(framework_result)
      case framework_result
      when TestResult::PASS, TestResult::EXP_FAIL
        tl_res = TestResult::PASS
      when TestResult::FAIL, TestResult::ERROR, TestResult::BLOCKED
        tl_res = TestResult::FAIL 
      when TestResult::OMIT
        tl_res = TestResult::OMIT 
      else
        tl_res = TestResult::UNKNOWN
      end
      tl_res
    end
   
    #Write result log entries to debug file
    def log_to_result(msg)
      
      msg.gsub!("\n\n","\n")
      msg.chomp!()
      msg.gsub!(PREFIX_RES_START,"");
      msg.gsub!(PREFIX_RES_OTHER,"");
      msg.gsub!(PREFIX_RES_END,"");
      #msg.gsub!("\n","\n#{" "*26}<Result> ");
      msg.gsub!("\n","\n<Result> ");
      
      log("<Result> " + msg)
    
    end
    
    #Print on console
    def print_on_console(msg)
      msg = msg[1..-1] if msg && msg[0] == "\n"
      print "\n #{msg.gsub("\n","\n ")}" if msg
    end
      
  end
end