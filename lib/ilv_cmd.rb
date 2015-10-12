module MA1000AutomationTool
  class ILVCmd < CmdManager
    def initialize(options)

      #Extend MA500 user functions
      extend MA500Functions

      super(options)
    end

    #Send ILVMessage object to terminal
    #If wait_for_res is set, it will return response from terminal in raw string
    def send_ilv_msg(ilv_msg, wait_for_res=true, res_timeout=RES_RECV_TIMEOUT)

      $test_logger.log("Send ILV Msg: Wait=#{wait_for_res}, Timeout=#{res_timeout}\n#{ilv_msg.to_s}")

      raw_rep = send_raw_cmd(ilv_msg.ilv_raw_str, wait_for_res, res_timeout)
      raw_rep
    end

    #Send ILVMessage object to terminal
    #If wait_for_res is set, it will return response from terminal as an ILVMessage object
    def send_recv_ilv_msg(ilv_msg, exp_ilv_msg, wait_for_res=true, res_timeout=RES_RECV_TIMEOUT)

      $test_logger.log("Send/Recv ILV Msg: Wait=#{wait_for_res}, Timeout=#{res_timeout}\n#{ilv_msg.to_s}")
      raw_rep = send_raw_cmd(ilv_msg.ilv_raw_str, wait_for_res, res_timeout)
      actual_ilv_msg = Common.get_obj_copy exp_ilv_msg
      actual_ilv_msg.set_raw_str(raw_rep)

      #d "REQ: #{ilv_msg}"
      #d "REP: #{actual_ilv_msg}"

      #Log received ILV
      $test_logger.log("Received ILV parse complete: #{actual_ilv_msg.to_s}")

      actual_ilv_msg
    end

    #send and receive multiple ilv command
    def send_ilv_cmd_list(ilv_cmd_list)

      wait_for_res=false
      res_timeout=RES_RECV_TIMEOUT
      expected_rep = Array.new
      actual_rep = Array.new
      $test_logger.log("Send Multiple ILV Command: ")

      #send one by one command from list
      ilv_cmd_list.each do |cm|
      #connect_ethernet if !is_connected   # check connetion
      # get ilv request from cmd which is stored in list
        ilv_raw_str = cm.ilv_req_pkt

        # get expected ilv reply from cmd which is stored in list
        expec_rep = cm.ilv_rep_pkt

        # add expected reply in array
        expected_rep.push(expec_rep)

        # send cmd
        act_msg = send_recv_ilv_msg(ilv_raw_str, expec_rep)

        #actu_rep = receive_ilv_message(expec_rep) # receive actual reply
        # add actual reply in array
        actual_rep.push(act_msg)
      #close  # close connetion
      end

      # assert each command one by one
      expected_rep.zip(actual_rep).each do |expc, actl|
      #$test_logger.log("Expceted #{expc}  with Actual #{actl}")
        assert_command(expc, actl)
      end

    end

    #Send/receive ILV from XML file or XML data; And verify actual ILV data with expected data specified in same XML
    #xml_file_name_or_str = XML file name or XML ILV string
    #res_timeout = timeout in seconds to wait for reply from terminal
    def send_recv_verify_xml(xml_file_name_or_str, msg_prefix="", res_timeout=RES_RECV_TIMEOUT)

      $test_logger.log("Send Recv Verify Xml: Timeout=#{res_timeout}")

      #Send/Receive xml cmd
      exp_rep, act_rep = send_recv_xml xml_file_name_or_str, res_timeout

      #Set msg_prefix as xml root name if its not specified
      msg_prefix = exp_rep.xml_doc.root.name if msg_prefix == ""

      #Assert whole command
      assert_command(exp_rep, act_rep, msg_prefix)

      #Return expected and actual replies
      return exp_rep, act_rep
    end

    #Send and receive XML file or XML data
    #xml_file_name_or_str = XML file name or XML ILV string
    def send_recv_xml(xml_file_name_or_str, res_timeout=RES_RECV_TIMEOUT)

      $test_logger.log("Send Recv Xml: Timeout=#{res_timeout}")

      req_opts = nil
      rep_opts = nil
      if xml_file_name_or_str.downcase.end_with?(".xml")
        req_opts = {:xml_file_name => xml_file_name_or_str, :xml_ilv_tag => ILVMessage::REQ_TAG}

        rep_opts = {:xml_file_name => xml_file_name_or_str, :xml_ilv_tag => ILVMessage::REP_TAG}
      else
        req_opts = {:xml_str => xml_file_name_or_str.clone, :xml_ilv_tag => ILVMessage::REQ_TAG}

        rep_opts = {:xml_str => xml_file_name_or_str.clone, :xml_ilv_tag => ILVMessage::REP_TAG}
      end

      ilv_req = ILVMessage.new(req_opts)

      expected_ilv = ILVMessage.new(rep_opts)
      #d "Request: #{ilv_req}"
      actual_ilv = send_recv_ilv_msg(ilv_req, expected_ilv, true, res_timeout)
      #d "Reply: #{actual_ilv}"

      return expected_ilv, actual_ilv
    end

    #Receive ILV message from terminal
    def receive_ilv_message(exp_ilv_msg, read_timeout=RES_RECV_TIMEOUT)

      $test_logger.log("Recv ILV Msg: Timeout=#{read_timeout}")

      actual_ilv_msg = Common.get_obj_copy exp_ilv_msg
      resp_raw = receive_response(1, read_timeout)

      actual_ilv_msg.set_raw_str(resp_raw.first)

      $test_logger.log("Received ILV parse complete: #{actual_ilv_msg.to_s}")

      actual_ilv_msg
    end

    #Compare actual_reply with expected_reply with all elements
    def assert_command(exp_repl, act_repl, msg_prefix)
      $test_logger.log("Asserting Expected Element:- #{exp_repl} with Actual Element #{act_repl}")

      if msg_prefix.strip != ""
        msg_prefix = msg_prefix.strip + ": "
      end

      begin
      #Assert for errors
        $test_ref.assert_false(act_repl.is_parse_error, "#{msg_prefix}Error while parsing ILV data!\n#{act_repl.parse_error_message}")

        act_repl = act_repl.xml_ilv_node.root
        exp_repl = exp_repl.xml_ilv_node.root

        comp_actc_expc_repl(act_repl, exp_repl, msg_prefix)
      rescue Test::Unit::AssertionFailedError
        $test_logger.summary_add_remarks "***#{msg_prefix}Assertion failed in assert_command!\nExpected:\n#{exp_repl}\n\nActual:\n#{act_repl}\n"
        raise
      end
    end

    #compare actual reply with expected reply of command
    def comp_actc_expc_repl(act_repl, exp_repl, msg_prefix)
      $test_logger.log("#{msg_prefix}Compare Expected Element:- #{exp_repl.name} with Actual Element")

      if exp_repl.has_elements?
        exp_repl.elements.each do | exp_elem |
          comp_actc_expc_repl(act_repl, exp_elem, msg_prefix)
        end
      else
        act_pth = exp_repl.xpath
        act_elem = act_repl.elements[act_pth]
        $test_logger.log("#{msg_prefix}Actual Element '#{act_pth}: #{act_elem}'")
        exp_size_obj = exp_repl.attributes.get_attribute("size")
        exp_size_obj = exp_size_obj.to_s
        exp_type_obj = exp_repl.attributes.get_attribute("type")
        exp_type_obj = exp_type_obj.to_s

        if exp_repl
          exp_value = ""
          exp_value = exp_repl.get_text.value if exp_repl.get_text
          act_value = ""
          act_value = act_elem.get_text.value if act_elem.get_text
          if (exp_value == DONT_CARE )
            $test_logger.log("#{msg_prefix}Expected Element Includes #{DONT_CARE} in #{exp_repl}")
          else
            if (exp_size_obj.include? DONT_CARE )
              act_size_obj = act_elem.attributes.get_attribute("size")
              exp_repl.add_attribute("size", act_size_obj)
            end
            if (exp_type_obj.include? DONT_CARE )
              act_type_obj = act_elem.attributes.get_attribute("type")
              exp_repl.add_attribute("type", act_type_obj)
            end
            #Parse data based on data type
            data_type = ILVMessage.get_type_for_ele exp_repl
            case data_type
            when ILVMessage::DataType::DEC
              exp_value = exp_value.to_i
              act_value = act_value.to_i
            when ILVMessage::DataType::HEX
              exp_value = "#{ILVMessage::HEX_PREFIX}#{exp_value.hex.to_s(16)}"
              act_value = "#{ILVMessage::HEX_PREFIX}#{act_value.hex.to_s(16)}"
            else
            exp_value = exp_value.to_s
            act_value = act_value.to_s

            #Check for regex
            if exp_value[0] == "/" && exp_value[-1] == "/"
            exp_value_regex = exp_value[1..-2] #Remove regex boundary

            if act_value[/#{exp_value_regex}/] != nil
            $test_logger.log("Regex '#{exp_value}' matched with actual value '#{act_value}'")
            exp_value = act_value #As regex is matched, replace expected res with actual res
            end
            end
            end

            #Update parsed values back to element
            exp_repl.text = exp_value
            act_elem.text = act_value

            #Assert xml element
            $test_ref.assert_equal exp_repl.to_s, act_elem.to_s, "#{msg_prefix}Expected reply element doesn't match with actual reply element\n    at path '#{act_pth}'!"
          end
        exp_repl = exp_repl.next_element
        else
          $test_logger.log("#{msg_prefix}Actual element text doesn't found!")
        end
      end
    end

    #Send ILV to terminal with hex string
    def send_hex_cmd(hex_str, wait_for_res=true, res_timeout=RES_RECV_TIMEOUT)

      $test_logger.log("Send HEX Cmd: Wait=#{wait_for_res}, Timeout=#{res_timeout}")

      raw_str = ILVMessage.hex_to_raw(hex_str)
      resp_single = send_raw_cmd(raw_str, wait_for_res, res_timeout)
      resp_single = ILVMessage.raw_to_hex(resp_single) if resp_single
      resp_single.to_s
    end

    private

    #Send ILV to terminal with raw string
    def send_raw_cmd(raw_ilv, wait_for_res=true, res_timeout=RES_RECV_TIMEOUT)
      #Make debug log
      $test_logger.log "Sending ILV: #{ILVMessage.raw_to_hex(raw_ilv)}"

      #Reset connection and ignore check
      #reset_connection true
      connect_to_device true

      #Raise exception if connection not opened
      raise "Connection not open!" if !is_connected

      #Write packet to device socket/serial
      @s.write(raw_ilv)

      resp_single = nil
      if wait_for_res
        resp = receive_response(-1, res_timeout)
        resp_single = resp.first
        close
      end
      resp_single
    end

    #Receive response from comm channel
    # => packet_count:  1..n = Number of cmd packets to receive
    # =>               -1 = Receive all available packets at instance of time
    def receive_response(packet_count=-1, read_timeout)

      $test_logger.log("Receive response Count=#{packet_count}, Timeout=#{read_timeout}")

      raise "Specify valid packet_count as 1 to n!" if packet_count !=-1 and packet_count < 1

      response_arr = Array.new
      begin

        timeout(read_timeout) do
        #Read all from comm channel
          if packet_count == -1
            ready = nil
            begin
              single_resp = receive_single_response(true)
            ready = (!single_resp.empty?)
            response_arr << single_resp if ready
            end while ready
          else
            packet_count.times {
              single_resp = receive_single_response(false)
              response_arr << single_resp if !single_resp.empty?
            }
          end
        end
      rescue Timeout::Error => e
        $test_logger.log_e("Timeout while receiving response from device!", e)
      end
      response_arr
    end

    #Receive raw bytes from communication channel
    def raw_receive(byte_count, no_wait=false)

      $test_logger.log("Raw receive: Count=#{byte_count}, NoWait=#{no_wait}")

      data = nil
      begin
      #Ethernet
        if is_eth
        data = @s.recv(byte_count)
        #Serial
        else
        data = @s.read(byte_count)
        end
        to_wait = !no_wait && (data==nil || data.empty?)
        sleep(1) if to_wait
      end while to_wait
      data
    end

    #Receive single ILV from communication channel
    def receive_single_response(no_wait=false)

      $test_logger.log("Receive single response: NoWait=#{no_wait}")

      #Receive id byte
      response = raw_receive(1, no_wait)

      if !response.empty?
        #Receive two bytes cmd length
        response << raw_receive(2)
        int_len = response[-2..-1].unpack("v").first

        #Check if length is greater than 2 bytes
        if int_len == 0xffff
          #Receive four bytes cmd length
          response << raw_receive(4)
          int_len = response[-4..-1].unpack("n").first
        end
        #Receive computed number of bytes
        response << raw_receive(int_len)
      end

      #Make debug log
      $test_logger.log "Received ILV: #{ILVMessage.raw_to_hex(response)}"

      response
    end

    public

    #Ensure terminal is up and running
    def ensure_device_status

      max_retry = 5
      retry_count = 0
      begin #while
        begin #main exception handler

        #Increment current retry
          retry_count += 1

          $test_logger.log "Ensure terminal status for ILV command! trial = '#{retry_count}'"

          #Reset connection after second trial onwards
          reset_connection if retry_count > 1

          #Initialize retry flag to false
          to_retry = false

          #Sending ping cmd
          begin

          #Define Ping XML
            ping_xml = "<Ping>
                      <Request>
                        <Identifier>0x08</Identifier>
                        <Values>
                          <TestData>0x1F</TestData>
                        </Values>
                      </Request>
                      <Reply>
                        <Identifier>0x08</Identifier>
                        <Length>2</Length>
                        <Values>
                          <RequestStatus>0</RequestStatus>
                          <TestData>0x1F</TestData>
                        </Values>
                      </Reply>
                    </Ping>"

            #Build ILV request message for ping
            ilv_req = ILVMessage.new(:xml_str => ping_xml, :xml_ilv_tag => ILVMessage::REQ_TAG)

            #Send ping command
            send_ilv_msg ilv_req, false
          rescue Exception => ex
            raise ex, "Error while sending ping command request to terminal\n#{ex.message}", ex.backtrace
          end

          #Receive ping reply
          begin

          #Build expected ILV reply message for ping
            exp_rep = ILVMessage.new(:xml_str => ping_xml, :xml_ilv_tag => ILVMessage::REP_TAG)

            #Receive ILV ping reply from terminal
            act_rep = receive_ilv_message exp_rep

            #Raise error if no reply received
            raise "Ping reply not received!" if !act_rep

            #Raise error if request status invalid
            req_status = act_rep.get_request_status
            raise "Ping request status invalid! Expected: 0 and Actual: #{req_status}" if req_status != 0

            #Raise error if data check mismatch
            act_data = act_rep.get_tag_value_int("//Values/TestData")
            exp_data = exp_rep.get_tag_value_int("//Values/TestData")
            raise "Ping test data mismatch! Expected: #{exp_data} and Actual: #{act_data}" if exp_data != act_data

          rescue Exception => ex
            raise ex, "Error while receiving reply for ping command!\n#{ex.message}", ex.backtrace
          end

          #Handle exception
        rescue Exception => main_ex
        #Raise exception in case of max trials
          raise main_ex, "Error while re-connecting to device!\n#{main_ex.message}", main_ex.backtrace if retry_count >= max_retry

          #Log error
          $test_logger.log_e "Could not ensure device connection! Trial = '#{retry_count}/#{max_retry}'", main_ex

          #Set to_retry flag
          to_retry = true

          #Wait for 5 seconds before reconnecting
          sleep 5
        end #Main ex

      end while(to_retry)

    end

    #Fetch device info
    def fetch_device_info

      begin
        $test_logger.log("Fetching terminal info...")

        #Define get terminal info
        version_xml = "<Version>
                      <Request>
                        <Identifier>#{MA500Functions::MA500::CMD_GET_VERSION}</Identifier>
                        <Values>
                          <TerminalDesc>#{MA500Functions::MA500::ID_TERMINAL_DESCRIPTION}</TerminalDesc>
                          <ContactlessId>#{MA500Functions::MA500::ID_CLSS_IDENTIFIER}</ContactlessId>
                        </Values>
                      </Request>
                      <Reply>
                        <Identifier>#{MA500Functions::MA500::CMD_GET_VERSION}</Identifier>
                        <Length>#{DONT_CARE}</Length>
                        <Values>
                          <RequestStatus>0</RequestStatus>
                          <TerminalDesc>
                            <Identifier>#{MA500Functions::MA500::ID_TERMINAL_DESCRIPTION}</Identifier>
                            <Length>#{DONT_CARE}</Length>
                            <Values>
                              <Desc type='str'>#{DONT_CARE}</Desc>
                            </Values>
                          </TerminalDesc>
                          <ContactlessId>
                            <Identifier>#{MA500Functions::MA500::ID_CLSS_IDENTIFIER}</Identifier>
                            <Length>5</Length>
                            <Values>
                              <ReaderType size='1'>#{DONT_CARE}</ReaderType>
                              <Version size='4'>#{DONT_CARE}</Version>
                            </Values>
                          </ContactlessId>
                        </Values>
                      </Reply>
                    </Version>"

        #Send/Receive xml
        exp_rep, act_rep = send_recv_xml(version_xml)

        #Raise exception if ping response not received
        raise "Version response not received!" if !act_rep

        #Raise if request status not valid
        req_status = act_rep.get_request_status
        raise "Version request status invalid! Expected: 0 and Actual: #{req_status}" if req_status != 0

        #Raise exception if parse error
        raise "Error while parsing version ILV data!\n#{act_rep.parse_error_message}" if act_rep.is_parse_error

        #Parse required data
        ter_desc = act_rep.get_tag_value("//TerminalDesc/Values/Desc").strip #strip null character
        product = ter_desc[/TX_NAME=([^;]*)/, 1]
        srno = ter_desc[/TX_SN=([^;]*)/, 1]
        fw_ver = ter_desc[/FW_VERSION=([^;]*)/, 1]
        rdr_typ = act_rep.get_tag_value_int("//ContactlessId/Values/ReaderType")

        #Skip wifi check on MA500 legacy terminal, due to reboot issue
        if product != "MA 520+ D"
          #Fetch WiFi IP address from terminal
          wifi_ip_addr = get_reg_value("/wifi/properties/network address", true)

          #Check WiFi or Wired communication based on current IP address
          if wifi_ip_addr[/#{$comm_ip_address}/]
            #Set comm type as wired
            comm_type = DeviceCommType::ETH_WIFI
          else
          #Set comm type as WiFi
            comm_type = DeviceCommType::ETH_WIRED
          end
        end

        #Get sensor info
        version_xml = "<Version>
                      <Request>
                        <Identifier>#{MA500Functions::MA500::CMD_GET_VERSION}</Identifier>
                        <Values>
                          <SensorId>#{MA500Functions::MA500::ID_SENSOR_IDENTIFIER}</SensorId>
                        </Values>
                      </Request>
                      <Reply>
                        <Identifier>#{MA500Functions::MA500::CMD_GET_VERSION}</Identifier>
                        <Length>#{DONT_CARE}</Length>
                        <Values>
                          <RequestStatus>0</RequestStatus>
                          <SensorId>
                            <Identifier>#{MA500Functions::MA500::ID_SENSOR_IDENTIFIER}</Identifier>
                            <Length>#{DONT_CARE}</Length>
                            <Values>
                              <BioSensorState size='1'>#{DONT_CARE}</BioSensorState>
                              <Identifier>#{MA500Functions::MA500::ID_DESC_PRODUCT}</Identifier>
                              <Length>#{DONT_CARE}</Length>
                              <Values>
                                <Desc type='str'>#{DONT_CARE}</Desc>
                              </Values>
                              <Identifier>#{MA500Functions::MA500::ID_DESC_SENSOR}</Identifier>
                              <Length>#{DONT_CARE}</Length>
                              <Values>
                                <Desc type='str'>#{DONT_CARE}</Desc>
                              </Values>
                              <Identifier>#{MA500Functions::MA500::ID_DESC_SOFTWARE}</Identifier>
                              <Length>#{DONT_CARE}</Length>
                              <Values>
                                <Desc type='str'>#{DONT_CARE}</Desc>
                              </Values>
                              <Identifier>#{MA500Functions::MA500::ID_FORMAT_BIN_VERSION}</Identifier>
                              <Length>7</Length>
                              <Values>
                                <Version size='7'>#{DONT_CARE}</Version>
                              </Values>
                              <Identifier>#{MA500Functions::MA500::ID_FORMAT_BIN_NB_BASE}</Identifier>
                              <Length>1</Length>
                              <Values>
                                <Bases size='1'>#{DONT_CARE}</Bases>
                              </Values>
                              <Identifier>#{MA500Functions::MA500::ID_FORMAT_BIN_MAX_USER}</Identifier>
                              <Length>2</Length>
                              <Values>
                                <Users size='2'>#{DONT_CARE}</Users>
                              </Values>
                            </Values>
                          </SensorId>
                        </Values>
                      </Reply>
                    </Version>"

        #Send/Receive xml
        exp_rep, act_rep = send_recv_xml(version_xml)

        #Raise exception if ping response not received
        raise "Version response not received!" if !act_rep

        #Raise if request status not valid
        req_status = act_rep.get_request_status
        raise "Version request status invalid! Expected: 0 and Actual: #{req_status}" if req_status != 0

        #Raise exception if parse error
        #raise "Error while parsing version ILV data!\n#{act_rep.parse_error_message}" if act_rep.is_parse_error

        sensor_type = SensorType::UNKNOWN
        if act_rep.is_parse_error == false
          #Parse required data
          sen_desc = act_rep.get_tag_value("//SensorId/Values/Values/Desc")

          #Parse sensor type
          if sen_desc[/Product Name:\s*MSO/]
            sensor_type = SensorType::MSO
          end
        end

        #Parse card reader type 0x00: NONE, 0x01: MIFARE, 0x02: HID
        case rdr_typ
        when 0x0
          card_reader_type = CardReaderType::NONE
        when 0x1
          card_reader_type = CardReaderType::MIFARE
        #HID == ICLASS
        when 0x2
          card_reader_type = CardReaderType::ICLASS
        else
        card_reader_type = CardReaderType::UNKNOWN
        end

        $test_logger.log("Terminal info fetched successfully!")
      rescue Exception => ex
        $test_logger.log_e "Error while fetching terminal info!", ex
      end

      return product, srno, fw_ver, comm_type, sensor_type, card_reader_type
    end

    #Check device responds or not with immediate command
    def ping(response_timeout=2)
      #Initialize ping result as false
      ping_ok = false

      begin

        $test_logger.log "ILV Ping"

        #Define Ping XML
        ping_xml = "<Ping>
                      <Request>
                        <Identifier>0x08</Identifier>
                        <Values>
                          <TestData>0x44</TestData>
                        </Values>
                      </Request>
                      <Reply>
                        <Identifier>0x08</Identifier>
                        <Length>2</Length>
                        <Values>
                          <RequestStatus>0x0</RequestStatus>
                          <TestData>0x44</TestData>
                        </Values>
                      </Reply>
                    </Ping>"

        #Send/Receive xml
        exp_rep, act_rep = send_recv_xml(ping_xml)

        #Raise exception if ping response not received
        raise "Ping response not received!" if !act_rep

        #Raise if request status not valid
        req_status = act_rep.get_request_status
        raise "Ping request status invalid! Expected: 0 and Actual: #{req_status}" if req_status != 0

        #Raise exception if ping response not matched
        act_data = act_rep.get_tag_value_int("//Values/TestData")
        exp_data = exp_rep.get_tag_value_int("//Values/TestData")
        raise "Ping test data mismatch! Expected: #{exp_data.to_s(16)} and Actual: #{act_data.to_s(16)}" if exp_data != act_data

        #Set ping result as true
        ping_ok = true
      rescue Exception => ex
        $test_logger.log_e "Error in ILV ping!", ex, false
      end

      #Return ping result
      ping_ok
    end

    #Check and return SSL socket
    def check_ssl
      #Initialize ssl result as false
      ssl_ok = false
      begin

      #Raise not implemented
        raise "SSL check not implemented for MA500 device!"

        #Ping and check if device ssl connection is enabled
        ssl_ok = ping
      rescue Exception => ex
        $test_logger.log_e "Error in check_ssl!", ex, false
      end

      #Return ssl result
      ssl_ok
    end

  end
end
