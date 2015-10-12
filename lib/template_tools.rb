module MA1000AutomationTool
  class TemplateTools

    #BUR constants
    UR_CHECKSUM_OFFSET_BYTE1 = 4
    UR_CHECKSUM_OFFSET_BYTE2 = 5
    UR_CHECKSUM_OFFSET_START = 6
    UR_ID_START = 8
    #BUR get checksum bytes
    def self.bur_get_checksum_bytes(byt_arr)

      p = byt_arr
      plen = byt_arr.size
      cs = 0
      ti = UR_CHECKSUM_OFFSET_START
      pi = 0
      t = p

      while(ti-pi < plen)
        cs += t[ti]
        ti += 1
      end

      byte_arr = [((cs/256) & 0xff), ((cs%256) & 0xff)]

      byte_arr
    end

    #Change BUR template id
    def self.update_bur_id(bur_raw_str, id)
      
      #Unpack string to byte array
      data = bur_raw_str.unpack("C*")

      #Assign id to template byte
      data[UR_ID_START] = id & 0xff
      data[UR_ID_START + 1] = (id >> 8) & 0xff
      data[UR_ID_START + 2] = (id >> 16) & 0xff
      data[UR_ID_START + 3] = (id >> 24) & 0xff

      #Get checksum bytes
      cs_byt_arr = TemplateTools.bur_get_checksum_bytes(data)

      #Assign calculated checksum to template
      data[UR_CHECKSUM_OFFSET_BYTE1] = cs_byt_arr[0]
      data[UR_CHECKSUM_OFFSET_BYTE2] = cs_byt_arr[1]

      #Pack array to raw str
      data.pack("C*")
    end
 
    #Get BUR template id
    def self.get_bur_id(bur_raw_str)
     
      #Unpack string to byte array
      data = bur_raw_str.unpack("C*")     
       
      #Get id from template
      id = (data[UR_ID_START + 3] << 24) | (data[UR_ID_START + 2] << 16) | (data[UR_ID_START + 1] << 8) | data[UR_ID_START]
      id
    end
 
  end
end