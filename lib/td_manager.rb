module MA1000AutomationTool
  class TDManager

    attr_reader :td_app, :is_reconnected, :sut_id
    def initialize(sut_id, app_name, ip_addr)
      @sut_id = sut_id
      @app_name = app_name
      @ip_addr = ip_addr

      #Update IP address in TD XML param file
      update_ip_tdriver_params

      #Extend TD user functions
      extend TDFunctions

      reinitialize(true)

    end

    def cmd_proc=x
      @cmd_proc=x
    end
    
    def connected?
      begin
        #Move mouse pointer and check terminal status
        @td_app.Dlg_start.move(:Left, 1)
        true
      rescue Exception => ex
        $test_logger.log_e "Terminal is not connected!", ex, false
        false
      end
    end
    
    def close
     $test_logger.log("Closing QTTAS connection...")
     @sut.disconnect   
     @sut.power_down     
    end
    
    def reinitialize(chk_animation_flag = true)
      $test_logger.log("Initializing QTTAS connection...")

      if @sut
        TDriver.disconnect_sut(:Id => @sut_id)
        @sut.disconnect   
        @sut.power_down
        @sut = nil
      end

      #Connect to SUT
      @sut = TDriver.sut(:Id => @sut_id)
      @sut.power_up                  
      #Connect to App
      @td_app = @sut.application(:applicationName => @app_name)
   
      #Hide mouse cursor (due to BUG, need to remove after it is fixed)
      #@td_app.Dlg_start.move(:Left, 1)

      $test_logger.log("SUT connection - OK", true)

      count = 0
      if chk_animation_flag == true
        # begin
          # begin
            # exit_loop = true
            # ani_ch = @td_app.Dlg_start.QStackedWidget( :name => 'stk_widget' ).QWidget( :name => 'page' ).children({},false)
            # #:type => "QLabel", :name => 'lbl_animation', :isActiveWindow => 'true'
            # ani_ch.each{|ani|
              # if ani.name == "lbl_animation" && ani.type== "QLabel"
                # exit_loop = !(ani["visible"] == "true")
                # #while ani["visible"] == "true"
                # ani.tap
                # if count == 0
                  # $test_logger.log("Waiting for loading animation to complete..", true)
                # else
                  # print "."
                # end
                # count += 1
                # sleep(1)
              # break
              # #end
              # end
            # }
          # end while exit_loop == false 
        # rescue MobyBase::TestObjectNotFoundError => ex
          # $test_logger.log_e("Loading animation label not found!", ex)
        # end
  
        #Close open dialogs, if any
        close_open_dialogs
        
      end
      
    #Check if idle screen is visible
    #idle_logo = @td_app.Dlg_start.QWidget( :name => 'page_2' ).QWidget( :name => 'layoutWidget' ).QLabel(:name => 'lbl_default_message')["isActiveWindow"]
    # #If logo is not visible
    # if idle_logo == "false"
    # #Check for battery backup msg
    # bat_msg = @td_app.Dlg_start.test_object_exists?(:type => 'QLabel', :text => 'Please verify that backup battery has been put into place', :isActiveWindow => 'true')
    #
    # if bat_msg.is_a?(TrueClass)
    # @td_app.Dlg_start.Dlg_msg.QPushButton( :name => 'pbt_msg_ok' ).tap
    # end
    #
    # #Check for FBA
    # fba = @td_app.test_object_exists?(:type => 'First_boot_assist', :text => 'First Boot Assistant', :name => 'Dlg_list', :isActiveWindow => 'true')
    #
    # if fba.is_a?(TrueClass)
    # @td_app.First_boot_assist( :name => 'Dlg_list' ).QPushButton( :name => 'pbt_back' ).tap
    # end
    #
    # end

    end
    
    def ensure_device_status

      $test_logger.log("Inside ensure_device_status for QTTAS")

      max_retry = 5
      retry_count = 0
      @is_reconnected = false
      begin
        begin
          #Increment current retry
          retry_count += 1
          $test_logger.log("Ensure terminal status for QTTAS! trial = '#{retry_count}'")
        
          #Reset connection after second trial onwards or not connected
          if retry_count > 1 || connected? == false
            reinitialize
          end
        
          #Initialize retry flag to false
          to_retry = false
          
          #Handle exception
        rescue Exception => main_ex
        
        @is_reconnected = true
        
        #Raise exception in case of max trials
          raise(main_ex, "Error while re-connecting to QTTAS!\n#{main_ex.message}", main_ex.backtrace) if retry_count >= max_retry
        
          #Log error
          $test_logger.log_e("Could not ensure QTTAS connection! Trial = '#{retry_count}/#{max_retry}'", main_ex)
        
          #Set to_retry flag
          to_retry = true
        
          #Wait for 5 seconds before reconnecting
          sleep 5
        end 

      end while(to_retry)

    end
    
    #Reboot terminal and wait until terminal is up and running
    def reboot_terminal_and_wait(chk_animation_flag = true)
      $test_logger.log("Terminal is Rebooting ...!!!")
      begin
        login_with_pwd "0000"
        tap_tbutton(TDElements::QTB_RBT)
        tap_pbutton(TDElements::QPB_DLG_OK)
      rescue Exception => ex
        $test_logger.log_e "Terminal Rebooting Failed!", ex, false
      end
      wait_for_device(false, CmdManager::DEFAULT_TIMEOUT, chk_animation_flag)
      
      sleep 20
    end
    
    #Reboot terminal and wait until terminal is up and running
    def reboot_and_wait(chk_animation_flag = true)
      @cmd_proc.call_thrift{terminal_reboot}

      wait_for_device(false, CmdManager::DEFAULT_TIMEOUT, chk_animation_flag)
    end

    #Waiting for device from rebooting state
    def wait_for_device(ignore_initial_wait=false, default_timeout=CmdManager::DEFAULT_TIMEOUT, chk_animation_flag = true)

      $test_logger.log("Waiting for QTTAS server from device rebooting state... Timeout=#{default_timeout}!")

      #Delay to ensure device is not re-connected while it is under rebooting process
      sleep 15 if !ignore_initial_wait

      to_retry = true
      connect_counter = 0
      begin
        Timeout::timeout(default_timeout) do
          while(to_retry) do
            begin
              connect_counter += 1
              $test_logger.log("Reconnecting to QTTAS server... try #{connect_counter}", true)
              if connect_counter > 10
                @cmd_proc.call_thrift{terminal_reboot}
              end
              #Connect to device QTTAS
              reinitialize(chk_animation_flag)
              
              $test_logger.log("QTTAS server reconnected successfully on trial #{connect_counter}", true)

              $test_logger.log("Reconnecting distant command manager...", true)
              if chk_animation_flag == true
                 #Connect to device using dist cmd
                 @cmd_proc.wait_for_device(true)
              end
             
              #If no exception then device is connected successfully
              to_retry = false

            rescue Exception=>ex
              err = "QTTAS server not connected! Retrying in 5 seconds..."
              $test_logger.log(err, true)
              $test_logger.log_e(err, ex, false)
              sleep 5
            end
          end
        end
      rescue Timeout::Error
        $test_logger.log("Timeout occured while re-connecting to QTTAS server!", true)
      to_retry = true
      end
      !to_retry
    end

    def close_open_dialogs
      $test_logger.log("Close open dialogs")
      open_dlgs = @td_app.Dlg_start.children({},false)
      open_dlgs.each_with_index {|x, y|

        if x.name != TDElements::DLG_START
          $test_logger.log("Closing dialog '#{x.name}' => #{y}")
          x.call_method("close()")
          sleep(1)
        #else
        #  $test_logger.log("Skipping #{x.name} => #{y}", true)
        end
      }

      #Check for FBA and close
      fba = @td_app.children({},false)
      fba.each{|x|

        if x.type == "First_boot_assist"
          $test_logger.log("FBA detected, making it disable permanently!")
          
          #Disable FBA permanently
          sb = x.QWidget( :name => 'qt_scrollarea_vcontainer', :isActiveWindow => 'true' ).QScrollBar(:name => "")
          #Scroll down
          sb["sliderPosition"] = 50
          #Select permanent
          x.QLabel(:text => "First Boot Configuration Storage Type").tap
          x.QListWidgetItem(:text => "Permanent").select
          #Tap confirm 2 times
          2.times{
          x.QPushButton( :name => TDElements::QPB_CONFIRM, :isActiveWindow => "true" ).tap
          sleep 0.5
          }
          $test_logger.log("FBA disabled permanently!")
                              
          #$test_logger.log("Closing FBA...")
          #x.QPushButton( :name => 'pbt_back' ).tap
          #Wait for few seconds to initialize dist command processing
          sleep(5)
        end
      }

    end

    def update_ip_tdriver_params

      $test_logger.log("update_ip_tdriver_params SUT Id '#{@sut_id}', ip addr '#{@ip_addr}'")
      begin
        td_xml_file = File.join(TDriver.config_dir, FWConfig::TD_PARAMS_XML)

        $test_logger.log("TD XML file path '#{td_xml_file}")

        #Create backup of current xml file
        td_xml_file_rd = td_xml_file + ".autofw"
        Common.copy_file(td_xml_file, td_xml_file_rd)

        #Open xml file for read
        xml_data = File.new td_xml_file_rd
        xml_doc = Document.new xml_data

        xml_nodes = xml_doc.elements["\parameters"]

        to_save = false
        is_found = false
        param_ele = Element.new 'parameter'
        param_ele.add_attributes({'name'=>'qttas_server_ip', 'value'=>@ip_addr})

        #Find matching SUT node
        xml_nodes.elements.each do | cur_node |

          if cur_node && cur_node.name == "sut" && cur_node.has_attributes?
            attr_obj = cur_node.attributes.get_attribute("id")

            #If matching SUT node found
            if attr_obj.value == @sut_id

              #Find matching parameter node
              cur_node.elements.each do | p_node |
                if p_node && p_node.name == "parameter" && p_node.has_attributes?
                  p_attr_nm = p_node.attributes.get_attribute("name")

                  #If qttas_server_ip found, update its attribute with new IP
                  if p_attr_nm.value == "qttas_server_ip"
                    is_found = true

                    p_attr_ip = p_node.attributes.get_attribute("value")
                    if p_attr_ip.value != @ip_addr
                      p_node.add_attribute("value", @ip_addr)
                    to_save = true
                    end
                  break
                  end
                end
              end

              if !is_found
              cur_node << param_ele
              is_found = true
              to_save = true
              end
            end
          end
        end

        if !is_found
          sut_ele = Element.new 'sut'
          sut_ele.add_attributes({'id'=>@sut_id, 'template'=>'qt'})
        sut_ele << param_ele
        xml_nodes << sut_ele
        to_save = true
        end

        if to_save == true
          xml_doc.write(File.new td_xml_file, "w")
          xml_doc = nil
          
          $test_logger.log("TD XML file updated successfully!")
        else
          $test_logger.log("TD XML file is already having terminal IP, hence update skipped!")
        end
        
        #Update IP in current parameter class
        eval("TDriver.parameter[:#{@sut_id}][:qttas_server_ip] = '#{@ip_addr}'")
         
      rescue Exception => ex
        $test_logger.log_e("Error while updating TD XML file with specified IP! (This error might occur when running script for the first time)", ex)
      end

    end
  end
end