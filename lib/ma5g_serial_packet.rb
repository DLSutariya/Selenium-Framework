module MA1000AutomationTool
  class MA5GSerialPacket

    #NET_ID = 0
    MAX_BUF_SIZE = 1024
    START_STR = "MA"

    #Net id 2 bytes
    NET_ID_SIZE = 2

    #Checksum 4 bytes
    CHECKSUM_SIZE = 4

    #Data Len 2 bytes
    DATA_LEN_SIZE = 2
    #Fields 0x4D41(MA)(2 bytes),0x41(A),<Net ID>(2 bytes),<Checksum>(4 bytes),<Data size>(2 bytes),<Data>(data size bytes)
    def initialize(net_id, data)

      $test_logger.log("New MA5G Serial Packet, net id='#{net_id}', data size='#{data.size}'")

      @start_str = START_STR
      @net_id = net_id
      @data = data
      @data_size = data.size
      @checksum = MA5GSerialPacket.calculate_checksum(data)

    end

    #Combine packet elements to raw_str
    def to_s
      net_id_str = Common.fixnum_to_rawstr(@net_id, NET_ID_SIZE)
      checksum_str = Common.fixnum_to_rawstr(@checksum, CHECKSUM_SIZE)
      data_len_str = Common.fixnum_to_rawstr(@data_size, DATA_LEN_SIZE)
      @start_str + net_id_str + checksum_str + data_len_str + @data
    end

    #Convert str to readable hexstr
    def to_hexstr
      Common.unpackbytes(to_s)
    end

    #Calculate chunk numbers and final size based on data size
    def self.calculate_chunks_num_size(total_size_required)

      $test_logger.log("Calculate chunk size. Requested size='#{total_size_required}'")

      max_data_chunk_size = MAX_BUF_SIZE

      num_chunks_out = total_size_required / max_data_chunk_size
      new_total_size_out = num_chunks_out * max_data_chunk_size
      last_chunk_size = total_size_required % max_data_chunk_size
      if (last_chunk_size)
      num_chunks_out += 1
      new_total_size_out += last_chunk_size
      end

      new_total_size_out += num_chunks_out * get_header_size

      $test_logger.log("New Size: '#{new_total_size_out}', Num of chunks: '#{num_chunks_out}'")

      return new_total_size_out, num_chunks_out
    end

    #Return serial packet header size
    def self.get_header_size
      START_STR.size + NET_ID_SIZE + CHECKSUM_SIZE + DATA_LEN_SIZE
    end

    #Calculate checksum for specified data
    def self.calculate_checksum(chksum_data)

      $test_logger.log("Calculate checksum for data size='#{chksum_data.size}'")

      chksum = 0
      chksum_data.each_byte{|x|
        chksum += x
      }
      chksum = (0x0 - chksum) & 0xFFFFFFFF

      $test_logger.log("Checksum='0x#{chksum.to_s(16)}'")

      chksum
    end

    #Generate list of packets from raw_str
    #Eg: Input  = data (raw string)
    #    Output = List of Packet<data> (List of MA5GSerialPacket)
    def self.generate_packets(raw_str, net_id)

      #Split raw data into raw chunks
      #d "Total data size #{raw_str.size}"
      raw_chunks = []
      raw_str.chars.each_slice(MAX_BUF_SIZE){|slice|
        raw_chunks << slice.join
      }

      #Convert raw chunks into packets
      pkts = []
      #final_str = ""
      i = 0
      raw_chunks.each{|x|
        i += 1
        pkt = MA5GSerialPacket.new(net_id, x)
        #final_str << pkt.to_s
        pkts << pkt
      }
      #d "packets #{pkts.size}"
      pkts
    #final_str
    end

  end
end