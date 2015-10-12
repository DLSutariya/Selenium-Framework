module MA1000AutomationTool
  class SerialCmd < CmdManager
    
    #Constants
    BUFF_SIZE = 50 #Data write buffer size over serial port
    SSL_CLIENT_PWD = "F435A2FE6EA469B3730AC9D113E8B281" #SSL client password storedPasswd[] = { 0xFEA235F4,0xB369A46E, 0xD1C90A73, 0x81B2E813};
    
    def initialize(options)
      
      #Extend L1 user functions
      extend L1Functions
      
      super(options)
    end
    
    #Send delayed command, receive ACK packet and one RES packet
    def send_recv_del(cmd_packet, exp_err=nil, recv_ack=true, res_timeout=RES_RECV_TIMEOUT)
      $test_logger.log("CmdId='#{cmd_packet.hex_cmd_id}': Sending packet and waiting for ACK for #{@device_id}")
      ack_pkt = send_packet(cmd_packet, recv_ack, res_timeout)
      
      if $test_ref 
        $test_ref.assert_not_nil(ack_pkt, "CmdId='#{cmd_packet.hex_cmd_id}': ACK packet not received from device(#{@device_id})") 
        
        if exp_err != nil && recv_ack == false
            $test_ref.assert_true(ack_pkt.err_bit, "CmdId='#{ack_pkt.hex_cmd_id}': Error bit not set in ACK, expected error #{exp_err} '#{BioPacket.get_error_desc(exp_err)}'!")
            $test_ref.assert_equal BioPacket.format_err_desc(exp_err), ack_pkt.error_desc, "Error code mismatch with actual error code for CmdId='#{ack_pkt.hex_cmd_id}'!"
        else
          $test_ref.assert_false(ack_pkt.err_bit, "CmdId='#{ack_pkt.hex_cmd_id}': ACK packet error #{ack_pkt.error_desc}")
          
          $test_logger.log("CmdId='#{cmd_packet.hex_cmd_id}': Waiting for RES")
          res_pkt = receive_packet(res_timeout)
          $test_ref.assert_not_nil(res_pkt, "CmdId='#{cmd_packet.hex_cmd_id}': RES packet not received from device(#{@device_id})")
        
          if exp_err
            $test_ref.assert_true(res_pkt.err_bit, "CmdId='#{cmd_packet.hex_cmd_id}': Error bit not set in RES, expected error #{exp_err} '#{BioPacket.get_error_desc(exp_err)}'!")
            $test_ref.assert_equal BioPacket.format_err_desc(exp_err), res_pkt.error_desc, "Error code mismatch with actual error code in RES for CmdId='#{res_pkt.hex_cmd_id}'!"
          else
            $test_ref.assert_false(res_pkt.err_bit, "CmdId='#{res_pkt.hex_cmd_id}': RES packet error #{res_pkt.error_desc}")
          end
        end
      else
        raise "ACK packet not received from device" if !ack_pkt
        raise "ACK packet error #{ack_pkt.error_desc}" if ack_pkt.err_bit
        
        $test_logger.log("Waiting for RES")
        res_pkt = receive_packet(res_timeout)
        raise "RES packet not received from device" if !res_pkt
        raise "RES packet error #{res_pkt.error_desc}" if res_pkt.err_bit
      end 
        
      return ack_pkt, res_pkt
    end
    
    #Send immediate command, receive RES packet
    def send_recv_imd(cmd_packet, exp_err=nil, res_timeout=RES_RECV_TIMEOUT)
      $test_logger.log("Sending packet and waiting for Response of #{@device_id}")
      $test_logger.log("Send packet, Timeout=#{res_timeout}")      
      raise "Connection not open!" if !is_connected

      #Write packet to device socket/serial
      @s.write(cmd_packet.cmd_pkt)
      $test_logger.log("Waiting for RES")
      res_pkt = receive_packet(res_timeout)
       if $test_ref
          $test_ref.assert_not_nil(res_pkt, "CmdId='#{cmd_packet.hex_cmd_id}': RES packet not received from device(#{@device_id})")
        if (exp_err != nil) 
            $test_ref.assert_true(res_pkt.err_bit, "CmdId='#{cmd_packet.hex_cmd_id}': Error bit not set in RES, expected error #{exp_err} '#{BioPacket.get_error_desc(exp_err)}'!")
            $test_ref.assert_equal BioPacket.format_err_desc(exp_err), res_pkt.error_desc, "Error code mismatch with actual error code in RES for CmdId='#{res_pkt.hex_cmd_id}'!"
        else
            $test_ref.assert_false(res_pkt.err_bit, "CmdId='#{res_pkt.hex_cmd_id}': Error in RES packet #{res_pkt.error_desc}")
        end      
       else
          raise "RES packet not received from device" if !res_pkt
          raise "RES packet error #{res_pkt.error_desc}" if res_pkt.err_bit
       end       
      return res_pkt
    end
       
    #Send Bioscrypt serial command packet to device
    def send_hex(cmd_hex, wait_ack=true, ack_timeout=ACK_RECV_TIMEOUT)
      
      $test_logger.log("Send hex, WaitAck=#{wait_ack}, Timeout=#{ack_timeout}")      
      raw_data = Common.packbytes(cmd_hex)
      send_raw(raw_data, wait_ack, ack_timeout)
    end
    
    #Send Bioscrypt serial command packet to device
    def send_packet(cmd_packet, wait_ack=true, ack_timeout=ACK_RECV_TIMEOUT)
      
      $test_logger.log("Send packet, WaitAck=#{wait_ack}, Timeout=#{ack_timeout}")
      
      send_raw(cmd_packet.cmd_pkt, wait_ack, ack_timeout)
    end
    
    #Send Bioscrypt serial command packet to device
    def send_raw(raw_data, wait_ack=true, ack_timeout=ACK_RECV_TIMEOUT)
      
      $test_logger.log("Send raw, WaitAck=#{wait_ack}, Timeout=#{ack_timeout}")
      
      if is_serial
        #Reset connection
        connect_to_device
      end
      
      raise "Connection not open!" if !is_connected
      
      if raw_data.size > BUFF_SIZE && $comm_type == CommType::SERIAL
        $test_logger.log("Data size '#{raw_data.size}' greater than '#{BUFF_SIZE}', writing data on serial port using buffer.")
        buf_ctr = 0
        begin
          buffer = raw_data[buf_ctr, BUFF_SIZE]
          if buffer
            @s.write(buffer)
            sleep 0.001
          end 
          buf_ctr += BUFF_SIZE
          
        end while buffer != nil
        $test_logger.log("Writing data on serial port using buffer completed!")
      else
        #Write packet to device socket/serial connection
        @s.write(raw_data)
      end
        
      
      ack_pkt = nil
      if wait_ack
        ack_pkt = receive_packet(ack_timeout)
      end

      ack_pkt
    end

    #Send Mutiple Bioscrypt serial command packet to device
    def send_bio_cmd_list(bio_cmd_list)
      act_ack = Array.new
      act_res = Array.new
      exp_ack = Array.new
      exp_res = Array.new
      $test_logger.log("Send Multiple Bioscrypt serial command: ")

      #send multiple bio command from list 
      bio_cmd_list.each do |cm|                      
             
        exp_ack.push(cm.bio_ack_pkt)    #store expected acknowledgement in array
        exp_res.push(cm.bio_res_pkt)    #store expected responce in array        
        cmd_packet = cm.bio_req_pkt     #get request packet of command           
                
        #Receive acknowledgement               
        ack_pkt = send_packet(cmd_packet)    #receive acknowledgement from device
        act_ack.push(ack_pkt)                #store acknowledgement into array
               
        #Receive Responce  
        res_pkt = receive_packet  #receive responce from device
        act_res.push(res_pkt)     #store responce into array
      end    
      
      #assert ack of command one by one
      exp_ack.zip(act_ack).each do |expc, actl|
        assert_command(expc, actl)
      end
      
      #assert Response of command one by one
      exp_res.zip(act_res).each do |expc, actl|
        assert_command(expc, actl)
      end
    end
    
    #Assert whole command with all parameters
    def assert_command (exp, act, msg_prefix = "")
    
      if msg_prefix.strip != ""
        msg_prefix = msg_prefix.strip + ": "
      end
    
      $test_logger.log("#{msg_prefix}Asserting Expected Element for CmdId='#{exp.hex_cmd_id}':- #{exp.to_s} with Actual Element #{act.to_s}")
    
      $test_ref.assert_not_nil act, "#{msg_prefix}Actual response not received from device for CmdId='#{exp.hex_cmd_id}'!"
      $test_ref.assert_not_nil exp, "#{msg_prefix}Expected response not specified for CmdId='#{exp.hex_cmd_id}'!"
    
      $test_ref.assert_equal exp.err_bit, act.err_bit, "#{msg_prefix}Packet error mismatch for CmdId='#{exp.hex_cmd_id}'!\nExpected error: #{exp.error_desc}\nActual error: #{act.error_desc}" if !(exp.err_bit.to_s.include? DONT_CARE)
      $test_ref.assert_equal exp.net_id, act.net_id, "#{msg_prefix}Expected net_id doesn't match with actual net_id for CmdId='#{exp.hex_cmd_id}'!" if !(exp.net_id.to_s.include? DONT_CARE)
      $test_ref.assert_equal exp.pkt_no, act.pkt_no, "#{msg_prefix}Expected pkt_no doesn't match with actual pkt_no for CmdId='#{exp.hex_cmd_id}'!" if !(exp.pkt_no.to_s.include? DONT_CARE)
      $test_ref.assert_equal exp.cmd_id.to_s(16), act.cmd_id.to_s(16), "#{msg_prefix}Expected cmd_id doesn't match with actual cmd_id!" if !(exp.cmd_id.to_s.include? DONT_CARE)
      $test_ref.assert_equal exp.ack_bit, act.ack_bit, "#{msg_prefix}Expected ack_bit doesn't match with actual ack_bit for CmdId='#{exp.hex_cmd_id}'!" if !(exp.ack_bit.to_s.include? DONT_CARE)
    
      
      if exp.get_data.is_a?(Array)
        # assert size of actual data with expected data
        exp_size = 0
        act_size = 0
        exp_size = exp.get_data.size if exp.get_data
        act_size = act.get_data.size if act.get_data
        $test_ref.assert_equal exp_size, act_size, "#{msg_prefix}Expected data size doesn't match with actual data size for CmdId='#{exp.hex_cmd_id}'!" if !(exp.get_data.to_s.include? DONT_CARE)
    
        # assert Data one by one parameter
        if exp_size != 0
          counter = 0
          (exp.get_data).zip(act.get_data).each do |exp_dt, act_dt|
            
            if !(exp_dt.to_s.include? DONT_CARE)
              if act.err_bit
                #Assert as signed integer
                $test_ref.assert_equal exp.error_desc, act.error_desc, "#{msg_prefix}Error code mismatch with actual error code for CmdId='#{exp.hex_cmd_id}'!" 
              else
                #Assert as hex
                $test_ref.assert_equal exp_dt.to_s(16), act_dt.to_s(16), "#{msg_prefix}Expected data word at index #{counter} doesn't match with actual data word for CmdId='#{exp.hex_cmd_id}'!"
              end
            end
            counter = counter + 1
          end
        end
      end
    end   
    
    #Receive single packet
    def receive_packet(read_timeout=RES_RECV_TIMEOUT)
      $test_logger.log("Receive packet, timeout=#{read_timeout} for #{@device_id}")
      resp = receive_packets(1, read_timeout)
      single_pkt = nil
      if resp and resp.length == 1
      single_pkt = resp.first
      elsif resp and resp.length > 1
        raise "More than one packets received!"
      end
      single_pkt
    end

    #Receive multiple packets
    def receive_packets(packet_count=-1, res_timeout=RES_RECV_TIMEOUT)
      $test_logger.log("Receive multiple packets: Count=#{packet_count}, Timeout=#{res_timeout}")
      raise "Connection not open!" if !is_connected
      response_arr = receive_response(packet_count, res_timeout)
      resp_pkts = Array.new
      response_arr.each {|x| resp_pkts << BioPacket.parse_packet(x)}
      resp_pkts
    end
    
    private
    #Receive single packet from device
    def receive_single_response

      $test_logger.log("Receive single response from device")
      
      #Receive sync word
      response = raw_receive(4)
      act_sync = response.unpack("V")[0]
      is_sync = act_sync == BioPacket::DEFAULT_SYNC
      raise "Sync word not found at first 4 bytes as '#{act_sync.to_s}'! expected '#{BioPacket::DEFAULT_SYNC.to_s(16)}'" if !is_sync

      #Read next two words to find packet length
      response << raw_receive(8)
      pkt_len = (response[-4..-1].unpack("V")[0] & 0xffff0000) >> 16

      #Read rest of the packet (as per the length)
      response << raw_receive(pkt_len*4 - 8)

      response
    end
    
    #Receive response from comm channel
    # => packet_count:  1..n = Number of cmd packets to receive
    # =>               -1 = Receive all available packets at instance of time
    def receive_response(packet_count=-1, read_timeout)
      
      $test_logger.log("Receive response from device. Count=#{packet_count}, Timeout=#{read_timeout}")
      
      raise "Specify valid packet_count as 1 to n!" if packet_count !=-1 and packet_count < 1
      
      response_arr = Array.new
      begin
        
        Timeout::timeout(read_timeout) do
          #Read all from comm channel
          if packet_count == -1
              ready = nil
              begin
                response_arr << receive_single_response
                ready = IO.select([@s], nil, nil, 1)
              end while ready
          else
            packet_count.times {
              
              #Check if data available
              ready = IO.select([@s], nil, nil, read_timeout)
              
              if ready
                #puts "count = #{packet_count}"
                response_arr << receive_single_response
              else
                raise Timeout::Error, "Packet receive timeout!"
              end
            }
          end
        end    
      rescue Timeout::Error => ex
        $test_logger.log_e("Receive_response timeout!", ex, false)
      end
      response_arr
    end

    #Receive raw bytes from communication channel
    def raw_receive(byte_count)
   
      $test_logger.log("Receiving data... #{byte_count} byte(s)")
   
      data = ""
      begin
        if is_eth #Ethernet
          
          #Read based on socket object
          if @s.is_a?(OpenSSL::SSL::SSLSocket)
            data << @s.sysread(byte_count)
          elsif @s.is_a?(TCPSocket)
            data << @s.recv(byte_count)
          end
          
        else #Serial
            begin
              data_s = @s.read(byte_count)
              if !data_s
                $test_logger.log "No data received from serial channel within specified timeout, reconnecting to serial channel..."
                connect_to_device
              end 
            end while !data_s
            data << data_s
        end
        more_data = data.size < byte_count
        sleep 0.1 if more_data  
      end while (more_data)
      data
    end
    
    #Ensure device is up and running
    #Sync communication channel for responses
    # - receive all pending response packets for last run
    # - verify device is up and running
    public
    def ensure_device_status
      
      max_retry = 5
      retry_count = 0
      begin #end while
        begin #main exception handler
          
          #Increment current retry
          retry_count += 1
          
          $test_logger.log "Ensure device status for serial command! trial = '#{retry_count}'"
          
          #Reset connection after second trial onwards
          reset_connection if retry_count > 1
          
          #Initialize retry flag to false
          to_retry = false
          
          #Sending check status cmd
          begin 
            #Verify device is up and running by sending 0x4d4 delayed command
            status_cmd = BioPacket.new(:cmd_id => 0x4d4, :pkt_no => 0x123 )
        
            #Send status command
            send_packet(status_cmd, false)
          rescue Exception => ex
            raise ex, "Error while sending check status packet to device!\n#{ex.message}", ex.backtrace
          end
        
          #Receive ACK
          begin        
            #Loop to receive acknowledgement packet for 0x4d4
            exit_loop = false
            status_count = 0
            begin
              
              status_count += 1
              
              status_res_pkt = receive_packet
              
              raise "Acknowledgement for 0x4d4 not received from device!" if !status_res_pkt
              
              #Matching packet found
              if status_res_pkt.cmd_id == 0x4d4 && status_res_pkt.pkt_no == 0x123
                raise "Packet error! #{status_res_pkt.error_desc}" if status_res_pkt.err_bit
                raise "ACK bit not set!" if !status_res_pkt.ack_bit
                exit_loop = true
              else
                exit_loop = false
              end
              
            end while(!exit_loop)
            
            $test_logger.log "@@@@ RECOVERY ACK: '#{status_count - 1}' unknown response(s) received from device!" if status_count > 1
          rescue Exception => ex
            raise ex, "Error while receiving ACK for status packet from device!\n#{ex.message}", ex.backtrace
          end
        
          #Receive RES
          begin
            #Loop to receive response packet for 0x4d4
            exit_loop = false
            status_count = 0
            begin
              
              status_count += 1
              
              status_res_pkt = receive_packet
              
              raise "Response for 0x4d4 not received from device!" if !status_res_pkt
              
              #exit_loop = (status_res_pkt.cmd_id == 0x4d4 && status_res_pkt.pkt_no == 0x123 && status_res_pkt.ack_bit == false && status_res_pkt.err_bit == false)
              
              #Matching packet found
              if status_res_pkt.cmd_id == 0x4d4 && status_res_pkt.pkt_no == 0x123
                raise "Packet error! #{status_res_pkt.error_desc}" if status_res_pkt.err_bit
                raise "ACK found instead of RES!" if status_res_pkt.ack_bit
                exit_loop = true
              else
                exit_loop = false
              end
               
            end while(!exit_loop)
            
            $test_logger.log "@@@@ RECOVERY RES: '#{status_count - 1}' unknown response(s) received from device!" if status_count > 1
          rescue Exception => ex
            raise ex, "Error while receiving RES for status packet from device!#{ex.message}", ex.backtrace
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
        $test_logger.log("Fetching device info...")
        
        #Fetch versions
        info_cmd = BioPacket.new(:cmd_id => 0x706)
      
        #Send command and receive ACK
        ack_pkt = send_packet(info_cmd, true)
        raise "ACK for get device info not received!" if !ack_pkt
        raise "ACK packet error for get device info! #{ack_pkt.error_desc}" if ack_pkt.err_bit
        
        #Receive response
        res_pkt = receive_packet()  
        raise "RES not received for get device info!" if !res_pkt 
        raise "RES packet error for get device info! #{res_pkt.error_desc}" if res_pkt.err_bit
        
        #Fetch info from response
        dev_type = res_pkt.get_int_data(0) # 0=Verification, 1=Identification
        product = res_pkt.get_int_data(1)
        srno = res_pkt.get_str_data(3,0,80).strip
        fw_ver = res_pkt.get_str_data(23,0,80).strip.split(" ").first
        sensor_no = res_pkt.get_int_data(54)
        
        #Set device mode
        case dev_type
        when 0
          device_mode = DeviceMode::VERIFY
        when 1
          device_mode = DeviceMode::IDENTIFY
        else
          device_mode = DeviceMode::UNKNOWN
        end
        
        #Set sensor type
        case sensor_no
        when 149, 150, 151, 152
          sensor_type = SensorType::SECUGEN
        when 136, 137, 102
          sensor_type = SensorType::UPEK1
        when 154, 155
          sensor_type = SensorType::UPEK2
        when 170, 171, 172
          sensor_type = SensorType::VENUS
        when 1000, 1001
          sensor_type = SensorType::CBI
        else
          sensor_type = SensorType::UNKNOWN
        end
        
        #BASE:   120 V-Flex 4G (U), 140 V-Flex 4G (S), 150 V-Station 4G (U), 151 V-Station 4G (U), 170 V-Station 4G (S), 171 V-Station 4G (S)
        #PROX:   121 V-Flex 4G (U, P), 141 V-Flex 4G (S, P), 152 V-Station 4G (U, P), 155 V-Station 4G (U, P), 172 V-Station 4G (S, P), 175 V-Station 4G (S, P)
        #MIFARE: 122 V-Flex 4G (U, G), 142 V-Flex 4G (S, G), 153 V-Station 4G (U, G), 173 V-Station 4G (S, G), 
        #ICLASS: 123 V-Flex 4G (U, H), 143 V-Flex 4G (S, H), 154 V-Station 4G (U, H), 174 V-Station 4G (S, H) 
        
        #Parse card reader info based on product number
        case product
        when 120, 140, 150, 151, 170, 171, 1000, 1012
          card_reader_type = CardReaderType::NONE
        when 121, 141, 152, 155, 172, 175, 1006, 1015
          card_reader_type = CardReaderType::PROX
        when 122, 142, 153, 173, 1004, 1014
          card_reader_type = CardReaderType::MIFARE
        when 123, 143, 154, 174, 1002, 1013
          card_reader_type = CardReaderType::ICLASS
        else
          card_reader_type = CardReaderType::UNKNOWN
        end
        
        #Fetch current device communication type using command get port
        send_packet(BioPacket.new(:cmd_id => 0x303), false)
        
        #Receive res for get port
        res_pkt = receive_packet()  
        raise "RES not received for get port!" if !res_pkt 
        raise "RES packet error for get port! #{res_pkt.error_desc}" if res_pkt.err_bit
        
        #Set device comm type
        case res_pkt.get_int_data(0)
        when 0
          device_comm = DeviceCommType::RS232
        when 1
          device_comm = DeviceCommType::USB
        when 13
          device_comm = DeviceCommType::RS485
        when 11
          #Fetch wireless ip address
          nw_param_cmd = BioPacket.new(:cmd_id => 0x8c3,:data => [0x1])
          #Send command and receive ACK
          ack_pkt = send_packet(nw_param_cmd, true)
          raise "ACK for get wireless ip not received!" if !ack_pkt
          raise "ACK packet error for get wireless ip! #{ack_pkt.error_desc}" if ack_pkt.err_bit
          #Receive response
          res_pkt = receive_packet()  
          raise "RES not received for get wireless ip!" if !res_pkt 
          if !(res_pkt.err_bit && res_pkt.error_no == -888)
            wifi_ip = res_pkt.get_byte(0,3).to_s + "." + res_pkt.get_byte(0,2).to_s + "." + res_pkt.get_byte(0,1).to_s + "." + res_pkt.get_byte(0,0).to_s
            $test_logger.log("Parsed Wifi ipaddress: #{wifi_ip}")
            if wifi_ip == $comm_ip_address
              device_comm = DeviceCommType::ETH_WIFI
            end  
          end
          device_comm = DeviceCommType::ETH_WIRED if !device_comm  
        else
          device_comm = DeviceCommType::UNKNOWN
        end
        
        $test_logger.log("Device info fetched successfully!")
      rescue Exception => ex
        $test_logger.log_e "Error while fetching device info!", ex
      end
      
      return product, srno, fw_ver, device_comm, sensor_type, device_mode, card_reader_type
    end
    
    #Check device responds or not with immediate command
    def ping(response_timeout=2)
      #Initialize ping result as false
      ping_ok = false 
      
      begin
        
        $test_logger.log "Ping"
        
        #Send ping (get status immediate) command
        status_im_cmd = BioPacket.new(:cmd_id => 0x300, :pkt_no => 0x321)
        ping_res = send_packet(status_im_cmd, true, response_timeout)
        
        #Raise exception if ping response not received
        raise "Ping response not received!" if !ping_res
        
        #Raise exception if ping response not matched
        raise "Ping response not matched!" if ping_res.pkt_no != 0x321
        
        #Set ping result as true
        ping_ok = true
        $test_logger.log "Ping succeeded"
      rescue Exception => ex
        $test_logger.log_e "Error in ping!", ex, false
      end
      
      #Return ping result
      ping_ok
    end
    
    #Check and return SSL socket
    def check_ssl
      #Initialize ssl result as false
      ssl_ok = false
      begin
        #Establish SSL socket
        context = OpenSSL::SSL::SSLContext.new
        context.verify_mode = OpenSSL::SSL::VERIFY_NONE
        ssl_socket = OpenSSL::SSL::SSLSocket.new(@s, context)
        ssl_socket.sync_close = true
        ssl_socket.connect
        
        #Write SSL password
        ssl_socket.write Common.packbytes(SSL_CLIENT_PWD)
        
        #WARNING: Timeout not handled
        #Receive password status
        pwd_status = ssl_socket.sysread(4)
        
        #Raise if password status not valid
        raise "Password status not received!" if !pwd_status 
        raise "Password status not OK!" if pwd_status == false
        
        #Assign ssl socket to existing class variable
        @s = ssl_socket
        
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
