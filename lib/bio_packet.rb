module MA1000AutomationTool
  class BioPacket
    DEFAULT_SYNC = 0xFE6B2840
    PKT_HDR_LEN = 4
    ERR_CSV = "error_codes_4g.csv"

    #Getter methods
    attr_reader :net_id, :pkt_no, :cmd_id, :ack_req, :res_req, :err_bit, :ack_bit, :cmd_pkt, :error_no, :error_desc

     #BioPacket constructor
     #Following serial command elements are available
     #     :net_id, :pkt_no, :cmd_id, :ack_req, :res_req, :err_bit, :ack_bit, :data, :verify_checksum
     def initialize(options)

      opt_str = ""

      #Get specified options in printable form
      options.each {|a,b|
          
          if b.is_a?(Array)
            ##print "#{a} => "
            #opt_str << "#{a}=>"
            #b.each{|x| print "#{x.to_s(16)} "}
            #puts "" 
            opt_str << "#{a}=>Array[#{b.size}], "
          elsif b.is_a?(Fixnum) or b.is_a?(Bignum)
            opt_str << "#{a}=>#{b.to_s(16)}, "
          else
            opt_str << "#{a}=>#{b}, "
          end
         }
      
      #Make debug log for options
      $test_logger.log("Initialize packet with options '#{opt_str[0..-3]}'") # Print Packet with opt 0..-3 for removing comma and space
      #Initial values 
      verify_checksum = nil
      @net_id = 0
      @pkt_no = 0
      @cmd_id = nil
      @res_req = true
      @ack_req = true
      @ack_bit = false
      @err_bit = false
      @data = nil
      @cmd_pkt = nil
      @cmd_str = nil
      @error_no = 0
      @error_desc = "<NO ERROR>"
      @sync_dword = DEFAULT_SYNC
      @reserved_dword = 0
      
      #Load variables from parameter options            
      @net_id = options[:net_id] if options[:net_id]!=nil
      @pkt_no = options[:pkt_no] if options[:pkt_no]!=nil
      @cmd_id = options[:cmd_id] if options[:cmd_id]!=nil
      @res_req = options[:res_req] if options[:res_req]!=nil
      @ack_req = options[:ack_req] if options[:ack_req]!=nil
      @ack_bit = options[:ack_bit] if options[:ack_bit]!=nil
      @err_bit = options[:err_bit] if options[:err_bit]!=nil
      @data = Common.get_obj_copy(options[:data]) if options[:data]!=nil
      @sync_dword = options[:sync_dword] if options[:sync_dword]!=nil
      @reserved_dword = options[:reserved_dword] if options[:reserved_dword]!=nil
      
      verify_checksum = options[:verify_checksum] if options[:verify_checksum]!=nil           
      if options[:ignore_chksum]!=nil 
         ignore_chksum = options[:ignore_chksum] 
      else
         ignore_chksum = false
      end      
     
      #Swap for endianess on data
      if @data && @data.is_a?(Array) 
        for i in 0..(@data.size - 1)
          @data[i] =  BioPacket.swap_dword(@data[i]) if @data[i] && @data[i].to_s != CmdManager::DONT_CARE
        end
      end
      
      #Build cmd
      if ((@net_id.to_s.include? CmdManager::DONT_CARE) || (@pkt_no.to_s.include? CmdManager::DONT_CARE) || (@cmd_id.to_s.include? CmdManager::DONT_CARE) || (@ack_bit.to_s.include? CmdManager::DONT_CARE) || (@data.to_s.include? CmdManager::DONT_CARE) || (@err_bit.to_s.include? CmdManager::DONT_CARE))  
           $test_logger.log("Command Includes 'Dont care' #{CmdManager::DONT_CARE} so Command can't be build !")
      else
           $test_logger.log("Buliding Command...!")             
               
             begin
                #Check for error
                 check_error_no
                build_cmd(verify_checksum, ignore_chksum)
             rescue Exception=>ex
                 raise ex, ex.message + "\nError while creating command!", ex.backtrace
             end
      end     
    end
    
    #Return cmd_id in hex string
    def hex_cmd_id
      "0x" + @cmd_id.to_s(16)
    end
    
    #Get error description based on number from CSV file
    def self.get_error_desc(err_code)
      $test_logger.log("Get error desc for #{err_code}")
      desc = ""
      err_csv_file = File.join(FWConfig::DATA_FOLDER_PATH, FWConfig::L1_LEGACY_FOLDER, ERR_CSV)
      CSV.foreach(err_csv_file, :headers => true) do |row|
        if err_code == row[0].to_i
          desc = row[1]
          break
        end
      end
      desc
    end
    
    #Convert string to word array
    def self.str_to_word_arr(raw_str)
      rem_chr = 4 - raw_str.size%4
      if rem_chr > 0 && rem_chr < 4
        raw_str << "\x00" * rem_chr
      end
      raw_str.unpack("V*")
    end
    
    #Get raw data from file
    def self.read_file_data(file_path)
      $test_logger.log("Read data from file '#{file_path}'")
      data_str = Common.read_all_bytes(file_path)
      str_to_word_arr(data_str)
    end
    
    #Swap endianness of DWord  
    def self.swap_dword(dword)
      (dword & 0xff) << 24 | (dword & 0xff00) << 8 | (dword & 0xff0000) >> 8 | (dword & 0xff000000) >> 24
    end

    #Align DWord
    def self.align_dword(dword_str)
      dword_str.rjust(8,"0")
    end
    
    #Parse Bioscrypt 4G serial command packet based on hex str
    def self.parse_packet_hex(hex_str, ignore_chksum = nil)
      raw_str = Common.packbytes(hex_str)
      parse_packet(raw_str, ignore_chksum)
    end
   
    #Parse Bioscrypt 4G serial command packet based on raw bytes
    def self.parse_packet(cmd_bytes, ignore_chksum = nil)
      begin
      
        $test_logger.log("Parse Packet")
      
        #Initialize variables
        count = 0
        net_pkt_dw = nil
        cmd_len_dw = nil
        resv_dw = nil
        checksum_dw = nil
        data = Array.new
        pkt_len = nil
        cmd_id = nil
        net_id = nil
        pkt_no = nil
        ack_req = nil
        res_req = nil
        err_bit = nil
        ack_bit = nil
        syncword = nil
        
        #Unpack string to new packet
        cmd_bytes.unpack("V*").collect {|x|
        #cmd_bytes.each {|x|
            
            if pkt_len == nil
              case count
              when 0               
                  syncword = x                            
              when 1
                net_pkt_dw = x
                pkt_no = (net_pkt_dw & 0xffff0000) >> 16
                net_id = net_pkt_dw & 0x0000ffff
              when 2
                cmd_len_dw = x
                pkt_len = (cmd_len_dw & 0xffff0000) >> 16
                
                cmd_w = cmd_len_dw & 0x0000ffff
                
                cmd_id = cmd_w & 0x0fff 
                ack_req = ((cmd_w & 0x1000) >> 12) == 1
                res_req = ((cmd_w & 0x2000) >> 12) == 2
                err_bit = ((cmd_w & 0x4000) >> 12) == 4
                ack_bit = ((cmd_w & 0x8000) >> 12) == 8
                
              else
                raise "Count was not initialized to zero!"    
              end 
              count += 1
            else
              case pkt_len
              when 4
                resv_dw = x
              when 3
                checksum_dw = x
              when 2
                raise "Packet length mismatched with computed length!"
              else
                #data << swap_dword(x)
                data << x
              end
              pkt_len -= 1
            end
            #puts x
          }
        
        #Validate data array
        #raise "No data found!" if data.length == 0
        raise "Command Id not identified" if cmd_id == nil
        raise "Net Id not identified" if net_id == nil
        raise "Reserved word not identified" if resv_dw == nil
        raise "Checksum not identified" if checksum_dw == nil
                
        #New packet object      
        new_pkt = BioPacket.new(:net_id => net_id, 
                                :pkt_no => pkt_no, 
                                :cmd_id => cmd_id, 
                                :ack_req => ack_req, 
                                :res_req => res_req, 
                                :err_bit => err_bit, 
                                :ack_bit => ack_bit, 
                                :data => data, 
                                :sync_dword => syncword,
                                :verify_checksum => checksum_dw,
                                :ignore_chksum => ignore_chksum,
                                :reserved_dword => resv_dw)
      
      rescue Exception => e
        $test_logger.log_e("Error while parsing packet from raw data!", e)
        raise e, e.message + "\nError while parsing packet from raw bytes!", e.backtrace
      end
      
      new_pkt
    end 
    
    #Get raw data at location
    def get_data
      $test_logger.log("Get data")

      if @data.is_a?(Array)            
        data_copy = Array.new(@data.size)
        @data.each_with_index{|d, i|
            if !d.to_s.include? CmdManager::DONT_CARE
              data_copy[i] =  BioPacket.swap_dword(d)
            else
              data_copy[i] =  d
            end 
          }   
      else
        data_copy = Common.get_obj_copy(@data)
      end      
      data_copy
    end
       
    #Get raw data at location
    def get_data_at(index)
      $test_logger.log("Get data from location #{index}")
      raise "No data available" if !@data
      raise "No data found at index '#{index}'" if @data.length<index+1 
      BioPacket.swap_dword(@data[index])
    end
    
    #Set raw data at location
    def set_data_at(index,raw_data)
      $test_logger.log("Set data at location #{index}")
      @data[index] = BioPacket.swap_dword(raw_data)
      build_cmd
    end
    
    #append raw data array
    def append_data_array(raw_data)
      $test_logger.log("Append data array #{raw_data}")
      raw_array = []
      raw_data.each_with_index{|x, i| raw_array[i] = BioPacket.swap_dword(x) }
      @data.concat(raw_array)
      build_cmd
    end
    
    #append raw data
    def append_data(raw_data)
      $test_logger.log("Append data #{raw_data}")
      @data << BioPacket.swap_dword(raw_data)
      build_cmd
    end
    
    #Set raw data from start word index to end
    def set_data_from(strt_index,raw_arr)
      $test_logger.log("Set data from location #{strt_index}")
      @data.fill(strt_index,raw_arr.size) {|i|
        
        @data[i] = BioPacket.swap_dword(raw_arr[i-strt_index]) 
      }
      #@data.concat(raw_arr)
      build_cmd
    end
    
    #Get 32 bit signed int data 
    def get_int_data(index)
      $test_logger.log("Get int data from location #{index}")
      byt_data = get_data_at(index)
      
      #Convert to signed 32-bit integer from unsigned integer 
      byt_data = Common.uint32_to_int32(byt_data)
      
      byt_data
    end   
    
    #Get 32 bit unsigned int data 
    def get_uint_data(index)
      $test_logger.log("Get int data from location #{index}")
      byt_data = get_data_at(index)
      byt_data
    end
    
    #get byte from data word
    def get_byte(word_index,byte_offset)
      $test_logger.log("Get byte from data word at index #{word_index} and byte offset #{byte_offset}")
      raise "No data available" if !@data     
      byt_data = get_data_at(word_index)
      byt =  (byt_data >> (byte_offset * 8)) & 0xFF
      byt          
    end
    
    #Get string data
    def get_str_data(word_index, byte_offset, byte_size=nil)
      
      $test_logger.log("Get string data from word at index #{word_index} and byte offset #{byte_offset}")
      raise "No data available" if !@data     
      str = ""
	  
      raise "Actual data is not available at expected word index '#{word_index}'!" if (@data.size - 1) < word_index
	  raise "Actual data size is less than expected data size!" if (byte_size!= nil) && ((@data.size) < (word_index + (byte_size / 4)))
	  
      @data[word_index..-1].each_with_index {|x, i|
          word_str = ""
          4.times{ 
                   word_str << (x & 0xFF).chr
                   x = x >> 8
             }
             
          str << word_str.reverse
          str = str[byte_offset..-1] if i == 0
          
          null_char_pos = str.index(/\x00/)
          if null_char_pos != nil && (byte_size == nil)
            str = str[0..null_char_pos][0..-2]
            break
          elsif byte_size != nil && (str.size >= byte_size)
            str = str[0,byte_size]
            break
          end
          }
      str           
    end
     
    #Set string data
    def set_str_data(start_index=0, word_count, str_val)
      $test_logger.log("Set string data #{str_val} from position no #{start_index} to this size #{word_count} ")
      #raise "No data available" if !@data
      str = Common.get_obj_copy(str_val)      
     if(word_count * 4) >= str.size            
          rem_chr = 4 - str.size%4
         if rem_chr > 0 && rem_chr < 4
          str << "\x00" * rem_chr      
         end              
      act_arr = str.unpack('N*')     
      act_siz = act_arr.size          
      #@data.insert(start_index, *act_arr)    
      l=0
      rem_strt_indx = 0
      for i in start_index .. (start_index + act_siz -1) do
       @data[i] = act_arr[l]
       l =l+1   
       rem_strt_indx = i   
      end
      rem_strt_indx = rem_strt_indx + 1
      for p in rem_strt_indx .. (start_index + word_count-1) do
       @data[p] = 0             
      end
      #(word_count - act_siz).times {@data << 0}      
      #d @data.to_s
      build_cmd
     
     else 
      raise "Given Parameter is not Valid Parameter"  
     end
    end
          
    #Override object to_s method
    def to_s
      msg_str = "Command Packet Hex Str: #{@cmd_str.to_s}\n"
      msg_str << "net_id: #{@net_id}\n"
      msg_str << "pkt_no: #{@pkt_no}\n"
      msg_str << "cmd_id: #{@cmd_id.to_s(16)}\n"
      msg_str << "res_req: #{@res_req}\n"
      msg_str << "ack_req: #{@ack_req}\n"
      msg_str << "ack_bit: #{@ack_bit}\n"
      msg_str << "err_bit: #{@err_bit}\n"
      if @data != nil
        data_str = ""
         if @data == CmdManager::DONT_CARE
           data_str = CmdManager::DONT_CARE
         else 
            @data.each{|x| 
          if x == CmdManager::DONT_CARE
             data_str << CmdManager::DONT_CARE
          else
             data_str << "#{x.to_s(16)} "
          end
         }
         end
        
        msg_str << "data: [#{data_str.chop}]\n"
      end
      if @error_no != 0
        msg_str << "error_desc: #{@error_desc}\n"
      end
       
      msg_str
    end
   
    #Private methods
    private
    #Build packet in device format
    #def build_packet(net_id, pkt_no, cmd_id, res_req, ack_req, data=nil)
    def build_cmd(verify_checksum = nil, ignore_chksum = false)      
      
      $test_logger.log("Build Cmd, VerifyChecksum=#{verify_checksum.to_s}")
      
      #Initialize
      pkt_len = PKT_HDR_LEN
      #reserved_dword = 0x0
      pkt_arr = Array.new
    
      #Push first dword  - sync
      pkt_arr.push(BioPacket.swap_dword(@sync_dword))
    
      #Push second dword - net id & pkt no
      pkt_arr.push(BioPacket.swap_dword(@pkt_no << 16 | @net_id))
      
      #Set class data to local variable
      data = @data
    
      #calculate packet length
      if data 
        data = Array.new(1) {data} if data.is_a?(Fixnum)
        pkt_len += data.length
      
        #Swap for endianess on data
        # for i in 0..data.size
          # data[i] =  BioPacket.swap_dword(data[i]) if data[i]
        # end
      end
    
      #Update cmd id with ack_req and response_req
      cmd_id = @cmd_id & 0x00000fff
      cmd_id |= 0x00001000 if @ack_req
      cmd_id |= 0x00002000 if @res_req
      cmd_id |= 0x00004000 if @err_bit
      cmd_id |= 0x00008000 if @ack_bit
          
      #Push third dword - cmd id & pkt len
      pkt_arr.push(BioPacket.swap_dword(pkt_len << 16 | cmd_id))
      
      #Push data words, if any
      pkt_arr.concat(data) if data
      
      #push reserved
      pkt_arr.push(@reserved_dword)
      
      #calculate checksum
      checksum = 0
      pkt_arr.each_with_index{|a, j| 
        if j!=0
          begin
            checksum += (a & 0xff)
            a >>= 8
          end while a > 0 
        end
        }
      checksum = (0x0 - checksum) & 0xFFFFFFFF
      
      #push checksum
      if !ignore_chksum
        pkt_arr.push(BioPacket.swap_dword(checksum))
      else
        pkt_arr.push(BioPacket.swap_dword(verify_checksum))
      end
      #build packet
      cmd_pkt = ""
      pkt_arr.each{|a| 
        tmp_dword = []
        4.times{
            tmp_dword << (a & 0xff).chr
            a >>= 8
        }
          cmd_pkt << tmp_dword.reverse.join 
        }
      
      #Assign local packet to class member
      @cmd_pkt = cmd_pkt
        
      #convert binary packet to printable hex string and log
      @cmd_str = cmd_pkt.unpack("H8"*((@cmd_pkt.length)/4)).collect {|a| a.upcase + " "}.join
      $test_logger.log("Packet: " + @cmd_str)
      
       #Verify checksum
          if verify_checksum and checksum != verify_checksum && !ignore_chksum
            #puts @cmd_str
            @cmd_pkt = nil
            @cmd_str = nil
            raise "Checksum mismatched! Expected=#{verify_checksum.to_s(16)} Actual=#{checksum.to_s(16)}"
          end     
        
      #return binary packet
      @cmd_pkt
    end
    
    #Get formatted error desc
    def self.format_err_desc(err_no)
      err_no.to_s + " " + BioPacket.get_error_desc(err_no)
    end
    
    #Check error bit in packet and set error_no and error_desc class variables
    def check_error_no
      @error_no = 0
      if @err_bit
        if @data != nil && @data.size > 0
           @error_no = (0x0 - 0xFFFFFFFF + (BioPacket.swap_dword(@data.first) - 1)).to_i
           @error_desc = BioPacket.format_err_desc(@error_no)
           $test_logger.log("Error#{(" in ACK" if @ack_bit)}: #{@error_no} #{@error_desc}")
        else        
         $test_logger.log("Error bit is set but error code not found!!")
        end
      end
    end
  end
end
