require 'socket'
require 'serialport'
require 'openssl'
require 'timeout'
require 'thrift'

#Custom wrapper for Thrift SSL socket
require_relative 'ssl_socket'

#Custom client side code for Thrift serial transport
require_relative 't_serial'

module MA1000AutomationTool
  class CmdManager

    #Constants
    ACK_RECV_TIMEOUT = 5  #Time in seconds
    RES_RECV_TIMEOUT = 30 #Time in seconds
    DEFAULT_TCP_PORT = 10001
    DEFAULT_BAUD = 57600
    DONT_CARE = "?"
    DEFAULT_TIMEOUT = 120

    #Read only class variables
    attr_reader :secured_conn, :protocol_mode, :is_reconnected, :sec_cmd_proc
    #Command manager constructor
    #Available options:
    #     :device_ip => Device IP Address, Eg: "10.99.10.1"
    #     :tcp_port  => Device TCP port, Eg: 10001
    #     :com_port  => Serial com port, Eg: 1
    #     :baud_rate => Serial port baud rate, Eg: 57600
    def initialize(options)

      #Assign Protocol Mode
      @protocol_mode = ProtocolMode::UNKNOWN
      @protocol_mode =  self.class.name.split("::")[1]
      if self.class.name.include? "ThriftProtocol"
        @protocol_mode = ProtocolMode::MA1000
      elsif self.class.name.include? "ILVCmd"
        @protocol_mode = ProtocolMode::MA500
      elsif self.class.name.include? "SerialCmd"
        @protocol_mode = ProtocolMode::L1
      else
        @protocol_mode = ProtocolMode::UNKNOWN
        raise "No Protocol specified!"
      end

      $test_logger.log("Initialize cmd manager with #{options} in #{protocol_mode_name(@protocol_mode)} mode")

      if (options[:device_ip] or options[:tcp_port]) and (options[:com_port] or options[:baud_rate])
        raise ":device_ip/:tcp_port and :com_port/:baud_rate cannot be specified at the same time!"
      end

      #Assign Communication type
      @comm_type = CommType::UNKNOWN
      if !options[:device_ip] and !options[:com_port]
        raise "Specify at least one communication type :device_ip or com_port"
      elsif options[:device_ip]
        @comm_type = CommType::ETHERNET
      elsif options[:com_port]
        @comm_type = CommType::SERIAL
      end

      @th_client = Array.new
      @transport = nil
      @s = nil
      ignore_check = false
      @tcp_port = DEFAULT_TCP_PORT
      @baud_rate = DEFAULT_BAUD
      @device_ip = options[:device_ip]
      @tcp_port = options[:tcp_port] if options[:tcp_port]
      @com_port = options[:com_port]
      @baud_rate = options[:baud_rate] if options[:baud_rate]
      @use_ssl = options[:use_ssl] if options[:use_ssl]
      @cert_file = options[:cert_file] if options[:cert_file]
      @ca_file = options[:ca_file] if options[:ca_file]
      @ssl_ver = options[:ssl_ver] if options[:ssl_ver]
      @ssl_cipher = options[:ssl_cipher] if options[:ssl_cipher]
      ignore_check = options[:ignore_check] if options[:ignore_check]
      @is_reconnected = false

      #connect to device on current communication
      connect_to_device ignore_check

    end

    #connect to device
    def connect_to_device(ignore_check = false, sock_timeout = 30)
      $test_logger.log("Connect to device!")
      case @comm_type
      when CommType::ETHERNET
        connect_ethernet ignore_check, @use_ssl, sock_timeout
      when CommType::SERIAL
        connect_serial
      else
      raise "No communication type specified!"
      end

    end
    
    #change ssl type 
    def change_ssl_type(ssl_type) 
      @use_ssl = ssl_type
    end    
    
    #Reset connection
    def reset_connection(ignore_check=false)
      $test_logger.log("Reset connection!")

      #Close existing connection
      close

      #Connect to device again
      connect_to_device ignore_check

    end

    #Reset connection with new TCP port
    def reset_with_new_port(port)

      $test_logger.log("Change port to '#{port}'")

      @tcp_port = port

      reset_connection

    end

    #Check if socket is not nil
    def is_connected
      if ((@protocol_mode == ProtocolMode::L1) || (@protocol_mode == ProtocolMode::MA500))
        @s!=nil
      elsif @protocol_mode == ProtocolMode::MA1000
        @transport!=nil
      else
        raise "No Protocol Mode specified!"
      end
    end

    #Check if communication type is Ethernet
    def is_eth
      @comm_type == CommType::ETHERNET
    end

    #Check if communication type is Serial
    def is_serial
      @comm_type == CommType::SERIAL
    end

    #Close connection
    def close
      $test_logger.log("Close comm connection")
      #raise "Connection not open!" if !is_connected
      if ((@protocol_mode == ProtocolMode::L1) || (@protocol_mode == ProtocolMode::MA500))
        begin
          if @s
            @s.close
            $test_logger.log("Socket closed!")
          else
            $test_logger.log("Socket already closed!")
          end
        rescue Exception => ex
          $test_logger.log_e("Error while closing socket!", ex)
        #Ignore error if cannot close socket
        end
        @s = nil
      elsif @protocol_mode == ProtocolMode::MA1000
        begin
          if @transport
            @transport.close()
            $test_logger.log("Thrift transport socket closed!")
          else
            $test_logger.log("Thrift transport socket already closed!")
          end
        rescue Exception => ex
          $test_logger.log_e("Error while closing thrift transport socket!", ex)
        #Ignore error if cannot close thrift socket
        end

        @transport = nil
        @th_client = Array.new
      else
        raise "No Protocol Mode specified!"
      end
    end

    #Waiting for device from rebooting state
    def wait_for_device(ignore_initial_wait=false, default_timeout=DEFAULT_TIMEOUT)

      $test_logger.log("Waiting for device up from rebooting state... Timeout=#{default_timeout}!")

      #Close existing connection
      close

      #Delay to ensure device is not re-connected while it is under rebooting process
      sleep 15 if !ignore_initial_wait

      to_retry = true
      connect_counter = 0
      begin
        Timeout::timeout(default_timeout) do
          while(to_retry) do
            begin
              connect_counter += 1
              $test_logger.log("Reconnecting to device... try #{connect_counter}", true)

              #Open device connection
              connect_to_device

              #Ensure device responds correctly
              ensure_device_status

              #If no exception then device is connected successfully
              to_retry = false
              $test_logger.log("Device reconnected successfully on trial #{connect_counter}", true)
            rescue Exception=>ex
            #Close existing connection
              close
              $test_logger.log_e("Device not connected! Retrying...",ex)
              sleep 5
            end
          end
        end
      rescue Timeout::Error
        $test_logger.log("Timeout occured while re-connecting to device!", true)
      to_retry = true
      end
      !to_retry
    end

    #Setter for assigning secondary command processor
    def sec_cmd_proc=x
      if x
        $test_logger.log("Assign secondary cmd proc to main cmd proc...",true)
        @sec_cmd_proc = x
      else
        $test_logger.log("Assign self cmd proc to main cmd proc...",true)
        @sec_cmd_proc = self
      end
    end

    private

    #Connect to socket IP and port
    def connect_ethernet(ignore_check = false, use_ssl = nil, sock_timeout = 30)
      $test_logger.log("Connect to socket: IP=#{@device_ip}, Port=#{@tcp_port}")
      @device_id  = "#{@device_ip}:#{@tcp_port}"

      #Open socket connection to device
      if (@protocol_mode == ProtocolMode::L1)
        @s = TCPSocket.new(@device_ip, @tcp_port)

        #Initialize secure_conn flag with false
        @secured_conn = false

        #Check connection if required
        if ignore_check == false

          #Ping and check device presense
          conn_ok = ping

          #If connection is not ok, try SSL
          if conn_ok == false && (!use_ssl || use_ssl == true)

            #Close existing connection
            close

            #Re-open connection
            @s = TCPSocket.new(@device_ip, @tcp_port)

            #Try connecting via SSL
            conn_ok = check_ssl

            if conn_ok == true
              #If ssl status is ok, it is secured connection
              @secured_conn = true

              #Local Host address for SSLSocket
              $local_ip = Common.get_cur_local_ip(@s.to_io)
            end

          else

          #Local Host address
            $local_ip = Common.get_cur_local_ip(@s)
          end

          #Raise exception if device connection is not ok
          raise "Device ping failed!" if conn_ok == false
        elsif use_ssl && use_ssl == true
          #Close existing connection
          close

          #Re-open connection
          @s = TCPSocket.new(@device_ip, @tcp_port)

          #Try connecting via SSL
          conn_ok = check_ssl

          if conn_ok == true
            #If ssl status is ok, it is secured connection
            @secured_conn = true

            #Local Host address for SSLSocket
            $local_ip = Common.get_cur_local_ip(@s.to_io)
          else
            raise "Device ping failed with SSL flag!"
          end
        end
      elsif (@protocol_mode == ProtocolMode::MA500)

        #Check connection if required
        if ignore_check == false

          #Ping and check device presense
          conn_ok = ping

          #Raise exception if device connection is not ok
          raise "Device ping failed!" if conn_ok == false
        else
          @s = TCPSocket.new(@device_ip, @tcp_port)

          #Local Host address
          $local_ip = Common.get_cur_local_ip(@s)
        end

      elsif @protocol_mode == ProtocolMode::MA1000
        $test_logger.log("Connection for MA1000")

        #TCP socket timeouts
        #actual_socket_timeout = 30

        #Initialize conn_ok flag
        conn_ok = false

        #If SSL connection
        if use_ssl && use_ssl == true
          #Open secured socket
          thrift_socket = Thrift::SSLSocket.new(@device_ip, @tcp_port, sock_timeout, Resource.get_path(@cert_file), @ssl_ver, @ssl_cipher)
          #Initialize secure_conn flag with true
          @secured_conn = true
        else
        #Open non-secured socket
          thrift_socket = Thrift::Socket.new(@device_ip, @tcp_port, sock_timeout)
          #Initialize secure_conn flag with false
          @secured_conn = false
        end

        @transport = Thrift::BufferedTransport.new(thrift_socket)
        @transport.open()

        #Assign transport to client
        protocol = Thrift::BinaryProtocol.new(@transport)
        @th_client[0] = Internal_commands::Client.new(protocol)
        @th_client[1] = Factory_commands::Client.new(protocol)
        @th_client[2] = QA_commands::Client.new(protocol)

        #Check connection if required
        if ignore_check == false
          #Ping and check device presense
          conn_ok = ping
        else
        conn_ok = true
        end

        if conn_ok == false
          #Raise exception if device connection is not ok
          raise "Terminal ping failed!"
        else
          if use_ssl && use_ssl == true
          tcp_soc = thrift_socket.to_io.to_io
          else
          tcp_soc = thrift_socket.to_io
          end
          $local_ip = Common.get_cur_local_ip(tcp_soc)
        end

      else
        raise "No Protocol Mode specified!"
      end
      $test_logger.log("Ethernet connected!")
    end

    #Connect to serial com port
    def connect_serial
      $test_logger.log("Connect to serial port: No=#{@com_port}, Baud=#{@baud_rate}")
      @device_id  = "COM#{@com_port}:#{@baud_rate}"

      #open serial connetion to device
      if ((@protocol_mode == ProtocolMode::L1) || (@protocol_mode == ProtocolMode::MA500))

        #Close old connection
        close if is_connected

        $test_logger.log("Open serial port")

        begin

        #Open serial port
          @s = SerialPort.new("COM" + @com_port.to_s, @baud_rate)

          #Set com port read/write timeout as 2 seconds
          @s.read_timeout = 2000
          @s.write_timeout = 2000

        rescue Exception => ex
          close
          raise ex, "Cannot open serial port! Error: #{ex.message}", ex.backtrace
        end

      elsif @protocol_mode == ProtocolMode::MA1000
        #Thrift serial communication transport
        @transport = Thrift::TSerial.new(@com_port.to_s, @baud_rate)
        #@transport = Thrift::BufferedTransport.new(thrift_serial)
        @transport.open()

        #Assign transport to client
        protocol = Thrift::BinaryProtocol.new(@transport)
        @th_client[0] = Internal_commands::Client.new(protocol)
        @th_client[1] = Factory_commands::Client.new(protocol)

      #Ping and check device presense
      #conn_ok = ping

      else
        raise "Protocol mode '#{@protocol_mode}' not supported!"
      end
    end

    #Check if device requires SSL connection
    def check_ssl_conn
      #Refer to child class method
      # => serial_cmd->check_ssl_conn
      # TBD:: => ilv_cmd->check_ssl_conn
    end

    #Ensure device is up and running
    def ensure_device_status
      #Refer to child class method
      # => serial_cmd->ensure_device_status
      # TBD:: => ilv_cmd->ensure_device_status
    end

    #Fetch device info
    def fetch_device_info
      #Refer to child class method
      # => serial_cmd->fetch_device_info
      # TBD:: => ilv_cmd->fetch_device_info
    end
  end
end