require 'socket'

module Thrift
  class SSLSocket < BaseTransport
    def initialize(host, port, timeout=nil, cert_path="", ssl_ver="SSLv23", ssl_cipher="")
      @host = host
      @port = port
      @timeout = timeout
      @desc = "#{host}:#{port}"
      @handle = nil

      @cert_path = cert_path
      @ssl_ver = ssl_ver
      @ssl_cipher = ssl_cipher
    end

    attr_accessor :handle, :timeout

    def open
      begin

        context = OpenSSL::SSL::SSLContext.new(@ssl_ver)
        store = OpenSSL::X509::Store.new
        context.verify_mode = OpenSSL::SSL::VERIFY_PEER
        context.cert = OpenSSL::X509::Certificate.new(File.open(@cert_path))
        context.key  = OpenSSL::PKey::RSA.new(File.open(@cert_path))
        store.add_file(@cert_path)
        context.cert_store = store
        #context.ciphers = @ssl_cipher
        # context.verify_callback = proc do |preverify, ssl_context|
        # raise OpenSSL::SSL::SSLError.new unless preverify && ssl_context.error == 0
        #end
        tcp_socket = TCPSocket.new(@host, @port)
        @handle = OpenSSL::SSL::SSLSocket.new(tcp_socket, context)
        @handle.connect

        @handle
      rescue StandardError => e
        raise TransportException.new(TransportException::NOT_OPEN, "Could not connect to #{@desc}: #{e}")
      end
    end

    def open?
      !@handle.nil? and !@handle.closed?
    end

    def write(str)
      raise IOError, "closed stream" unless open?
      str = Bytes.force_binary_encoding(str)
      begin
        if @timeout.nil? or @timeout == 0
        @handle.write(str)
        else
          len = 0
          start = Time.now
          while Time.now - start < @timeout
            rd, wr, = IO.select(nil, [@handle], nil, @timeout)
            if wr and not wr.empty?
            len += @handle.write_nonblock(str[len..-1])
            break if len >= str.length
            end
          end
          if len < str.length
            raise TransportException.new(TransportException::TIMED_OUT, "Socket: Timed out writing #{str.length} bytes to #{@desc}")
          else
          len
          end
        end
      rescue TransportException => e
      # pass this on
        raise e
      rescue StandardError => e
        @handle.close
        @handle = nil
        raise TransportException.new(TransportException::NOT_OPEN, e.message)
      end
    end

    def read(sz)
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
            raise TransportException.new(TransportException::TIMED_OUT, "Socket: Timed out reading #{sz} bytes from #{@desc}")
          else
          data = @handle.readpartial(sz)
          end
        end
      rescue TransportException => e
      # don't let this get caught by the StandardError handler
        raise e
      rescue StandardError => e
        @handle.close unless @handle.closed?
        @handle = nil
        raise TransportException.new(TransportException::NOT_OPEN, e.message)
      end
      if (data.nil? or data.length == 0)
        raise TransportException.new(TransportException::UNKNOWN, "Socket: Could not read #{sz} bytes from #{@desc}")
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
  end
end
