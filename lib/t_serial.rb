require 'serialport'

require_relative 'ma5g_serial_packet'

module Thrift
  class TSerial < BaseTransport
    def initialize(com_port, baud_rate=115200, timeout=2000, net_id=0)
      @com_port = com_port
      #@port_type = port_type
      @baud_rate = baud_rate
      @timeout = timeout 
      @net_id = net_id
      @desc = "COM#{com_port}, Baud:#{baud_rate}"
      @handle = nil
      @read_buf = ""
      @raw_read_buf =""
      @write_buf = ""
    end

    attr_accessor :handle, :timeout, :net_id
    
    def reset_buffers
      @read_buf = ""
      @raw_read_buf =""
      @write_buf = ""
    end

    def open
      begin
      #Open serial port
        @handle = SerialPort.new("COM" + @com_port.to_s, @baud_rate)
        
        #Set com port read/write timeout
        @handle.read_timeout = -1
        #@timeout
        @handle.write_timeout = @timeout
        
        #Reset buffers
        reset_buffers

        #@handle
      rescue StandardError => e
        raise TransportException.new(TransportException::NOT_OPEN, "Could not connect to Serial Channel #{@desc}: #{e}")
      end
    end

    def open?
      !@handle.nil? and !@handle.closed?
    end

    #Thirft - actual write function
    def write_o(str)
      close
      open
      
      raise IOError, "closed stream" unless open?

      str = Bytes.force_binary_encoding(str)
      begin
        # if false
        @handle.write(str)
        # else
          # len = 0
          # start = Time.now
          # while Time.now - start < @timeout
            # rd, wr, = IO.select(nil, [@handle], nil, @timeout)
            # if wr and not wr.empty?
            # len += @handle.write(str[len..-1])
            # break if len >= str.length
            # end
          # end
          # if len < str.length
            # raise TransportException.new(TransportException::TIMED_OUT, "Serial Channel: Timed out writing #{str.length} bytes to #{@desc}")
          # else
          # len
          # end
        # end
      rescue TransportException => e
      # pass this on
        raise e
      rescue StandardError => e
        @handle.close
        @handle = nil
        raise TransportException.new(TransportException::NOT_OPEN, e.message)
      end
    end

    def read_o(sz)
      #d "read req #{sz}, buf size #{@raw_read_buf.size}"
      begin
        @raw_read_buf << @handle.read
      end while @raw_read_buf.size < sz

      raw_data = @raw_read_buf[0, sz]
      @raw_read_buf = @raw_read_buf[sz..-1].to_s
      
      raw_data
    end
    
    #Old read method for reference
    def read_o_ref(sz)

      raise IOError, "closed stream" unless open?
      
      begin
        if @timeout.nil? or @timeout == 0
        data = @handle.readpartial(sz)
        else
        # it's possible to interrupt select for something other than the timeout
        # so we need to ensure we've waited long enough, but not too long
          start = Time.now
          timespent = 0
          rd = loop do
          rd, = IO.select([@handle], nil, nil, @timeout - timespent)
            timespent = Time.now - start
            break rd if (rd and not rd.empty?) or timespent >= @timeout
          end
          if rd.nil? or rd.empty?
            raise TransportException.new(TransportException::TIMED_OUT, "Serial Channel: Timed out reading #{sz} bytes from #{@desc}")
          else
            data = ""
            begin
              data_s = @handle.read(sz)
              
              #d "ori size #{data_s.size if data_s}"
              data << data_s.to_s
              more_data = data.size < sz
              #sleep 0.1 if more_data   
            end while (more_data)
          #data = @handle.readpartial(sz)
          #d "Data size #{data.size}, Req size #{sz}"
          end
        end
      rescue TransportException => e
      # don't let this get caught by the StandardError handler
        raise e
      rescue StandardError => e
        @handle.close   unless @handle.closed?
        @handle = nil
        raise TransportException.new(TransportException::NOT_OPEN, e.message)
      end
      if (data.nil? or data.length == 0)
        raise TransportException.new(TransportException::UNKNOWN, "Serial Channel: Could not read #{sz} bytes from #{@desc}")
        #d "no data"
      end
      data
    end

    def close
      @handle.close unless @handle.nil? or @handle.closed?
      @handle = nil
    end

    def to_io
      @handle
    end

    def read_pkt_to_buf
      $test_logger.log "Start read packet"

      @read_pkt_count += 1

      intBuf = ""

      bufIndex = 0

      begin

      #Read packet start 2 bytes "MA"
      $test_logger.log "Packet[#{@read_pkt_count}]: Reading bytes for MA..."
        itr = 0
        begin

        #Read 'M'
          intBuf << read_o(1)

          if (intBuf[bufIndex] == MA5GSerialPacket::START_STR[0])
            #Read 'A'
            intBuf << read_o(1)
          bufIndex += 2
          else
            
            raise "Start bytes (MA) not received since last 10 bytes!" if itr > 10
            #$test_logger.log "Packet[#{@read_pkt_count}]: Start bytes not matched! Waiting..."
          end
          itr += 1
        end while intBuf[0, 2] != MA5GSerialPacket::START_STR 

        $test_logger.log "Packet[#{@read_pkt_count}]: Start bytes (MA) received!"
      rescue Exception => e
        raise e, "Packet[#{@read_pkt_count}]: Error while reading start bytes!'\n#{e.message}", e.backtrace
      end

      #Read net id
      begin
        nt_id_byts = read_o(MA5GSerialPacket::NET_ID_SIZE)
        net_id = nt_id_byts.unpack("n").first
        intBuf << nt_id_byts
        bufIndex += MA5GSerialPacket::NET_ID_SIZE
        $test_logger.log "Packet[#{@read_pkt_count}]: Net Id '#{net_id}' received!"
      rescue Exception => e
        raise e, "Packet[#{@read_pkt_count}]: Error while reading Net Id bytes!'\n#{e.message}", e.backtrace
      end
      
      raise "Packet[#{@read_pkt_count}]: Net Id mismatch! Received: #{net_id}, Current: #{@net_id}" if net_id != @net_id

      #Read checksum
      rcvd_checksum = 0
      begin
        checksum_byts = read_o(MA5GSerialPacket::CHECKSUM_SIZE)
        intBuf << checksum_byts
        rcvd_checksum = checksum_byts.unpack("N").first
        bufIndex += MA5GSerialPacket::CHECKSUM_SIZE
        $test_logger.log "Packet[#{@read_pkt_count}]: Checksum '#{rcvd_checksum.to_s(16)}' received!"
      rescue Exception => e
        raise e, "Packet[#{@read_pkt_count}]: Error while reading Checksum bytes!'\n#{e.message}", e.backtrace
      end

      #Read data length
      dataLen = 0
      begin
        intBuf << read_o(MA5GSerialPacket::DATA_LEN_SIZE)
      rescue Exception => e
        raise e, "Packet[#{@read_pkt_count}]: Error while reading packet data length!'\n#{e.message}", e.backtrace
      end

      #Parse data length
      begin
        data_byts = intBuf[bufIndex, MA5GSerialPacket::DATA_LEN_SIZE]
        dataLen = data_byts.unpack("n").first
        $test_logger.log "Packet[#{@read_pkt_count}]: Data length '#{dataLen}' received!"
        bufIndex += MA5GSerialPacket::DATA_LEN_SIZE
      rescue Exception => e
        raise e, "Packet[#{@read_pkt_count}]: Error while parsing packet data length!'\n#{e.message}", e.backtrace
      end

      raise "Packet[#{@read_pkt_count}]: Data length parsed as zero!" if (dataLen == 0)

      #Read actual data
      begin
        parsed_data = read_o(dataLen)
        intBuf << parsed_data
        #Copy actual data in to new array and append to class buffer
        @read_buf << parsed_data
        $test_logger.log "Packet[#{@read_pkt_count}]: Data of size '#{parsed_data.size}' received!"
      rescue Exception => e
        raise e, "Packet[#{@read_pkt_count}]: Error while reading and storing actual data!'\n#{e.message}", e.backtrace
      end

      #Copy packed data in to new array (Not used!)
      #begin
      #    #Total packet size
      #    bufIndex += dataLen;
      #    byte[] actPackedData = new byte[bufIndex];
      #    Array.Copy(intBuf, 0, actPackedData, 0, bufIndex);
      #rescue Exception => ex
      #    raise new Exception("Error while parsing packed data!", ex)
      #end

      #d "data size = #{parsed_data.size}"
      #Verify checksum
      act_chksum = MA5GSerialPacket.calculate_checksum(parsed_data)
      if rcvd_checksum != act_chksum
        #$test_logger.log Common.unpackbytes(parsed_data), true
        #$test_logger.log Common.unpackbytes(@raw_read_buf)
      raise "Packet[#{@read_pkt_count}]: Checksum mismatch! Received: '#{rcvd_checksum.to_s(16)}' != Calculated: '#{act_chksum.to_s(16)}'"
      end 

      $test_logger.log "Packet[#{@read_pkt_count}]: Read packet completed!"

    end

    #Overridden read function with packet parsing
    def read(sz)
      #$test_logger.log("TSerial read. Requested size='#{sz}', Read Buffer size='#{@read_buf.size}'")

      #Read MA5g packet
      #Read data in to internal buffer if requested data is more than available
      while @read_buf.size < sz
        read_pkt_to_buf
      end

      raw_data = @read_buf[0, sz]
      @read_buf = @read_buf[sz..-1].to_s

      #$test_logger.log("Thrift read complete. Requested size='#{sz}', Parsed data size '#{raw_data.size}'")

      raw_data
    end

    #Overridden write function with packet parsing
    def write(str)
      #$test_logger.log("TSerial write to buffer. Data size='#{str.size}'")
      @write_buf << str
    end

    def flush
      
      #$test_logger.log("TSerial flush buffer to serial channel. Buffer size='#{@write_buf.size}'")
      
      @read_pkt_count = 0
      @read_buf = ""
      @raw_read_buf =""
      pkts = MA5GSerialPacket.generate_packets(@write_buf, @net_id)
      data_str = ""
      i = 0
      pkts.each{ |p|        
        sleep 0.05 if i > 0        
        i += 1        
        write_o(p.to_s)
        #$test_logger.log("Data: #{p.to_hexstr}")
      }
      @write_buf = ""
      #$test_logger.log("TSerial flush completed!")
    end

  end
end
