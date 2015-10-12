module MA1000AutomationTool
  module UserFunctions
    SIMU_FINGERS = ["no_finger[1048x0764x00].raw",
      ["N1_1[1048x0764x00].raw", "N1_2[1048x0764x00].raw", "N1_3[1048x0764x00].raw", "N1_4[1048x0764x00].raw"],
      ["N2_1[1048x0764x00].raw", "N2_2[1048x0764x00].raw", "N2_3[1048x0764x00].raw", "N2_4[1048x0764x00].raw"],
      ["N3_1[1048x0764x00].raw", "N3_2[1048x0764x00].raw", "N3_3[1048x0764x00].raw", "N3_4[1048x0764x00].raw"],
      ["N4_1[1048x0764x00].raw", "N4_2[1048x0764x00].raw", "N4_3[1048x0764x00].raw", "N4_4[1048x0764x00].raw"],
      "finger_down[1048x0764x00].raw", "finger_harder[1048x0764x00].raw",
      "finger_left[1048x0764x00].raw", "finger_right[1048x0764x00].raw",
      "finger_up[1048x0764x00].raw","",
      ["N1_1[1048x0764x00]_i.raw", "N1_2[1048x0764x00]_i.raw", "N1_3[1048x0764x00]_i.raw", "N1_4[1048x0764x00]_i.raw"]]

    #Set simu finger (returns true if success otherwise false)
    def set_simu_finger(to_enable, finger_number = 1, finger_capture = 1, user_msg = "", disable_simu_delay=nil, no_prints = false)
      succ_res = nil
      begin

        $test_logger.log("Inside set_simu_finger (to_enable=#{to_enable}, finger_number=#{finger_number}, finger_capture=#{finger_capture}, disable_simu_delay=#{disable_simu_delay})")

        user_msg = " :: #{user_msg}" if user_msg != ""

        simu_img = $simu_path

        if to_enable == false
          #Path for blank raw image
          simu_img += SIMU_FINGERS[0]
          log_msg = "    CBI Simu: OFF!#{user_msg}"
        else

          raise "Simulated finger number '#{finger_number}' not available!" if finger_number < 1 || finger_number > SIMU_FINGERS.size

          if SIMU_FINGERS[finger_number].is_a?(Array)
            fing_name = SIMU_FINGERS[finger_number][finger_capture - 1]
            raise "Finger image not available at number '#{finger_number}' and capture '#{finger_capture}'" if !fing_name
          else
            fing_name = SIMU_FINGERS[finger_number]
          end

          simu_img += fing_name.to_s

          log_msg = "    CBI Simu: ON (Fin #{finger_number}_#{finger_capture}, #{fing_name})#{user_msg}"
        end

        #Call load simu files in respective mode
        load_cbi_simu_files simu_img

        $test_logger.log log_msg, !no_prints

        #If to disable finger simulation after specified delay then make recursive call to function in new thread...
        if to_enable == true
        $fake_finger_enabled = true
        else
        $fake_finger_enabled = false
        end

        succ_res = true
      rescue Exception => ex
        succ_res = false
        $test_logger.log_e "Error in set simu finger! Make sure CBI simu file '#{simu_img.to_s}' is available on terminal!\n#{ex.message}", ex, !no_prints
      #$test_ref.pend "Error while loading CBI finger simulation!"
      end
      succ_res
    end

    #Terminate simu finger thread if it is running
    def simu_finger_th_terminate
      #Terminal simu finger thread, if running
      Thread.list.each {|t|
        if t[:thread_method_name].to_s == "simu_finger_order_th"

          #Request thread to exit
          t[:to_exit] = true

          $test_logger.log("Aborting simu finger thread!")

          #Wait for thread to exit
          t.join

          $test_logger.log("Simu finger thread aborted!")

        end
      }

      #Disable simu finger
      set_simu_finger(false) if $fake_finger_enabled

    end

    def simu_finger_for_op(finger_numbers, user_msg="", from_capture=1, to_capture=3, init_delay=2, inter_delay=1.5)

      $test_logger.log "Creating thread to enable finger simulation for enrollment/authentication..."

      to_capture = from_capture if to_capture < from_capture

      if finger_numbers.is_a?(Array)
      fin_arr = finger_numbers
      elsif finger_numbers.is_a?(Fixnum)
        fin_arr = [finger_numbers]
      else
        raise "Invalid finger_numbers specified! Expected either 'Fixnum' or 'Array'."
      end

      #Create finger capture array
      finger_capture_arr = []
      fin_arr.each{|fn|
        from_capture.upto(to_capture){|i|
          finger_capture_arr << [fn, i]
        }
      }

      #Terminate simu finger thread, if already running
      simu_finger_th_terminate

      @sec_cmd_proc = self if !@sec_cmd_proc

      $test_ref.new_thread("simu_finger_order_th", @sec_cmd_proc, user_msg, finger_capture_arr, init_delay, inter_delay)
    end

    #Set finger simulation images in row with custom order of finger images
    #For Eg. to set 3 simu images for finger 1 and captures 1,2,3 specify as per below:
    #     finger_capture_arr = [ [1,1], [1,2], [1,3] ]
    def simu_finger_custom_order(finger_capture_arr, user_msg="", init_delay=0.5, inter_delay=0.5)

      $test_logger.log "Creating thread to enable finger simulation for with custom order..."

      #Terminate simu finger thread, if already running
      simu_finger_th_terminate

      $test_ref.new_thread("simu_finger_order_th", @sec_cmd_proc, user_msg, finger_capture_arr, init_delay, inter_delay)
    end

    #Thread to disable finger simulation after specified delay
    def disable_finger_simu_th(cmd_proc, delay)
      $test_logger.result_log "Disable finger simulation after #{delay} seconds..."

      sleep(delay)

      cmd_proc.set_simu_finger(false)
    end

    #Thread to enable finger simulation for authentication/enrollment operations
    def simu_finger_order_th(cmd_proc, user_msg, finger_capture_arr, initial_delay, inter_delay)

      $test_logger.result_log "Enable finger simulation with order... (finger captures=#{finger_capture_arr}, cmd_proc=#{cmd_proc.class})"

      raise "Command manager not set!" if !cmd_proc

      finger_capture_arr.each_with_index{|fn_ind, pos|

        raise "Finger number not specified for location #{pos}!" if !fn_ind[0]
        #raise"Finger index not specified for finger #{fn_ind[0]}!" if !fn_ind[1]

        if pos == 0
          sleep(initial_delay)
        else
          sleep(inter_delay)
        end

        break if Thread.current[:to_exit]

        cmd_proc.set_simu_finger(true, fn_ind[0], fn_ind[1], user_msg)

        break if Thread.current[:to_exit]

        sleep(inter_delay)

        break if Thread.current[:to_exit]

        cmd_proc.set_simu_finger(false)

        break if Thread.current[:to_exit]

      }

      if Thread.current[:to_exit]
        $test_logger.result_log "Thread exit requested!"
      end

    end

    #Wait for specified thread to exit
    def wait_for_thread(th_name)

      Thread.list.each {|t|
        if t[:thread_method_name].to_s == th_name
          $test_logger.log("Waiting for #{th_name} thread..")
          #Wait for thread to exit
          t.join
          $test_logger.log("#{th_name} thread completed!")
        end
      }
    end

    #Wait for simu finger thread if it is running
    def simu_finger_th_wait
      wait_for_thread "simu_finger_order_th"
    end

    #Input keypad on terminal screen using testability driver
    def input_keypad(input)

      $test_logger.log("Keypad input value '#{input}'")

      raise "Testability driver not connected!" if !$test_ref.td_proc

      #Open new testability thread to input string
      $test_ref.exe_in_thread("input_keypad"){sleep 0.5; $test_ref.td_proc.wait_type_confirm(input)}

    end

    #Wait for flash card thread, if it is running
    def flash_card_th_wait

      #Terminal flash card thread, if running
      Thread.list.each {|t|
        if t[:thread_method_name].to_s == "flash_card_th"
          $test_logger.log("Waiting for flash card thread..")
          #Wait for thread to exit
          t.join
          $test_logger.log("Flash card thread completed!")
        end
      }

    end

    #Send exit for flash card thread, if running
    def flash_card_th_exit

      #Terminal flash card thread, if running
      Thread.list.each {|t|

        if t[:thread_method_name].to_s == "flash_card_th"
          $test_logger.log("Sending exit flag for flash card thread..")

          #Set flag
          t[:to_exit] = true

          #Wait for thread to exit
          t.join

          $test_logger.log("Flash card thread exited!")
        end
      }

    end

    #Send flash card to terminal after specified delay
    def flash_card(card_no=1, delay=2, times=1)

      $test_logger.log("Send flash card: '#{card_no}'")

      #if delay == 0
      #  #Call flash card without thread
      #  flash_card_th card_no, itera, delay
      #else

      #Wait flash card thread, if already running
      flash_card_th_wait

      #Create thread for flash card
      new_thread("flash_card_th", card_no, delay, times)
    #end

    end

    #flash card on reader
    def flash_card_th(card_no, delay, times)
      #flash card
      MechArmControl.flashcard(card_no, delay, times)
    end

  end
end