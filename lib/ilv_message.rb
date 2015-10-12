module MA1000AutomationTool
  class ILVMessage

    #Tag and attributes
    REP_TAG = "//Reply"
    REQ_TAG = "//Request"
    STX_TAG = "STX"
    PKTID_TAG = "PKTID"
    TID_TAG = "TID"
    RC_TAG = "RC"
    DATA_TAG = "DATA"
    CRC_TAG = "CRC"
    DLE_TAG = "DLE"
    ETX_TAG = "ETX"
    ID_TAG = "Identifier"
    LEN_TAG = "Length"
    SIZE_ATTR = "size"
    TYPE_ATTR = "type"
    AUTO_ATTR = "auto"
    VALUE_TAG = "Values"
    REQ_STAT_TAG = "RequestStatus"
    HEX_PREFIX = "0x"
    LEN_BYTE = "--"
    UNKNOWN_TAG = "UnknownData"
    DEF_XML_DOC = "<DefaultReply><Identifier/><Length/><Values><#{REQ_STAT_TAG} size='1'/></Values></DefaultReply>"
    NULL = "U+0000"

    #constant
    TERMINAL_ID = 1
    SERIAL_MODE = "RS485"

    #checksum table
    CHKSUM_TABLE = [0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
      0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
      0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
      0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
      0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
      0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
      0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
      0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
      0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
      0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
      0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
      0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
      0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
      0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
      0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
      0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
      0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
      0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
      0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
      0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
      0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
      0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
      0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
      0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
      0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
      0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
      0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
      0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
      0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
      0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
      0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
      0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0]

    #Data type for XML data
    module DataType
      STR = "str"
      STR_WITH_NULL = "str_with_null"
      #little-endian [Ruby str.unpack(v)]
      DEC = "dec"
      #big-endian [Ruby str.unpack(n)]
      DEC_BIG = "dec_big"
      HEX = "hex"
    end

    #Input ILV mode for current message
    module InputChannel
      XML = 1
      HEX = 2
      RAW = 3
    end

    #Packet Type
    module PacketType
      Data_PKT = 1
      ACK_PKT = 2
      NACK_PKT = 4
    end

    #Read only class variables
    attr_reader :chk_serial_comm, :xml_file_name, :xml_ilv_tag, :ilv_raw_str, :xml_doc, :ilv_hex_str, :xml_ilv_node, :parse_error_message, :is_parse_error

    #Available options
    #  :xml_file_name => XML file name containing ILV data or XML template, Eg: "enroll.xml"
    #  :xml_ilv_tag   => XML file tag path onwards which ILV is to be considered, Eg: "Root\Request"
    #  :xml_str       => XML ILV as a string, instead of passing file name, Eg: "<Ping><Identifier>0x8</Identifier></Ping>"
    #  :ilv_raw_str   => If this option is specified, it will consider xml as template and fill
    #                    data from this raw ILV string
    #                    Eg: Direct response from device, etc.
    #  :ilv_hex_str   => If this option is specified, it will consider xml as template and fill
    #                    data from this hex ILV string
    #                    Eg: Response from device after converting from raw to hex string, etc.
    def initialize(options=nil)

      $test_logger.log("Initialize message with #{options}")

      #Options available
      #
      #Eg: "enroll.xml"
      @xml_file_name = nil
      #
      #Eg: "<Ping><Identifier>0x8</Identifier></Ping>"
      @xml_str = nil
      #
      #Eg: "Root/Request", "Root/Reply", etc..
      @xml_ilv_tag = nil
      #
      #Eg: Response from device in raw format
      @ilv_raw_str = nil
      #
      #Eg: Response from device in hex format
      @ilv_hex_str = nil

      #Initial values
      @xml_doc = nil
      @xml_ilv_node = nil
      @is_parse_error = false
      @parse_error_message = ""
      @chk_serial_comm = false
      @is_reply_ilv = false

      #intialize default packet type and terminal identifier
      @pkt_type = PacketType::Data_PKT
      @ter_id = TERMINAL_ID
      @s_mode = SERIAL_MODE

      #Assign specified options to class varilables
      if options
        @xml_file_name = options[:xml_file_name] if options[:xml_file_name] != nil
        @xml_ilv_tag = options[:xml_ilv_tag] if options[:xml_ilv_tag] != nil
        @ilv_raw_str = options[:ilv_raw_str] if options[:ilv_raw_str] != nil
        @ilv_hex_str = options[:ilv_hex_str] if options[:ilv_hex_str] != nil
        @xml_str = options[:xml_str] if options[:xml_str] != nil
      end

      #Raise exceptions, if req
      #raise "Option :xml_ilv_tag not specified" if !@xml_ilv_tag
      #raise "Option :xml_file_name not specified" if !@xml_file_name
      raise "Both options :ilv_raw_str and :ilv_hex_str cannot be specified at the same time!" if @ilv_raw_str && @ilv_hex_str
      raise "Both options :xml_file_name and :xml_str cannot be specified at the same time!" if @xml_file_name && @xml_str

      #Process XML template/data
      if @xml_file_name
        #Raise error if xml file not found
        xml_file_path = File.join(FWConfig::DATA_FOLDER_PATH, FWConfig::XML_FOLDER,@xml_file_name)
        raise "XML file does not exist in data folder!\n#{xml_file_path}" if !File.exist?(xml_file_path)

        #XML data from specified file
        xml_data = File.new xml_file_path
      else
      #Specified XML string
        if @xml_str
        xml_data = @xml_str
        #Default XML document
        else
          xml_data = DEF_XML_DOC
        end

        #Replace ruby string null character to XML null character
        if xml_data.include? "\x0"
          xml_data.gsub!("\x0", NULL)
          null_replaced = true
          $test_logger.log("Ruby NULL character replaced with XML NULL char!")
        end
      end

      begin
      #Initialize ILV tag
        @xml_doc = Document.new xml_data

        if @xml_ilv_tag
          xml_ilv_node = @xml_doc.elements[@xml_ilv_tag]
          #If specified ILV tag is not found in xml then create default reply
          if xml_ilv_node == nil
            @xml_doc = Document.new DEF_XML_DOC
          xml_ilv_node = @xml_doc.root
          end
        else

          xml_ilv_node = @xml_doc.elements[REQ_TAG] if !xml_ilv_node
          xml_ilv_node = @xml_doc.elements[REP_TAG] if !xml_ilv_node
          xml_ilv_node = @xml_doc.root if xml_ilv_node == nil
        end

        #Check if current ILV is reply ILV
        @is_reply_ilv = true if REP_TAG[/#{xml_ilv_node.name}/]

        #Update @xml_ilv_node to store only data from ilv node, i.e. discard parent nodes
        @xml_ilv_node = Document.new xml_ilv_node.to_s
      rescue Exception => ex
        $test_logger.log "\nError while parsing input XML data:\n@@@@@@@@@@\n#{xml_data}\n@@@@@@@@@@\n", true
        raise
      end

      #If null character was replaced then replace back the original character
      if null_replaced
        replace_xml_str @xml_ilv_node, NULL, "\x0"
        $test_logger.log("XML NULL character replaced back with ruby NULL char!")
      end

      #Load data for specified input channel
      #RAW ILV str
      if @ilv_raw_str
        notify_change(InputChannel::RAW)
      #HEX ILV str
      elsif @ilv_hex_str
        notify_change(InputChannel::HEX)
      #Data from XML
      else
        notify_change(InputChannel::XML)
      end
    end

    #Replace string in text of all child nodes in xml
    def replace_xml_str(xml_node, old_str, new_str)
      if xml_node.has_elements?
        xml_node.elements.each do | cur_node |
          replace_xml_str(cur_node, old_str, new_str)
        end
      else
        if xml_node.get_text
        xml_node.text = xml_node.get_text.value.gsub(old_str, new_str)
        end
      end
    end

    #convert ilv xml format into serial xml format
    def create_serial_ilv(s_mode = @s_mode, pkt_type = @pkt_type, ter_id = @ter_id, pkt_first = true, pkt_last = true)

      $test_logger.log("Create Serial ILV Packet Format..")
      $test_logger.log("Serial Comm Mode :- #{s_mode}, Packet type:- #{pkt_type}, Terminal Identifier:- #{ter_id}")
      raise "Specify at least one serial protocol RS422/RS485" if s_mode == nil
      raise "Specify at least one Packet type" if pkt_type == nil
      raise "Specify Terminal Identifier" if ter_id == nil

      #set flag to true for serial comunication
      @chk_serial_comm = true

      # create Packet Identifier
      pkt_id = create_packet_idenfier(pkt_first, pkt_last, pkt_type)

      # store all ILV element and hex string of ILV command
      ilv_elem = @xml_doc.elements[REQ_TAG].to_a #Here using xml_doc so there could be issue with null character in future
      hex_str = @ilv_hex_str

      #create Data node assign whole ILV Command into Data Tag element
      add_tag(REQ_TAG, DATA_TAG, "//#{ID_TAG}")
      ilv_elem.each do |elem|
        @xml_ilv_node.root.elements["//#{DATA_TAG}"].add(elem)
      end

      #delete ILV command from Request Tag element
      @xml_ilv_node.root.elements[REQ_TAG].delete_element "/Request/Identifier" if ID_TAG
      @xml_ilv_node.root.elements[REQ_TAG].delete_element "/Request/Length" if LEN_TAG
      @xml_ilv_node.root.elements[REQ_TAG].delete_element "/Request/Values" if VALUE_TAG

      #Add Start text node with value and attributes
      add_tag(REQ_TAG, STX_TAG, "//#{DATA_TAG}")
      set_tag_value("//#{STX_TAG}", "0x02")
      set_tag_attr("//#{STX_TAG}", SIZE_ATTR, "1")

      #Add Packet Identifier Node with value and attributes
      add_tag(REQ_TAG, PKTID_TAG, "//#{DATA_TAG}")
      set_tag_value("//#{PKTID_TAG}", pkt_id)
      set_tag_attr("//#{PKTID_TAG}", SIZE_ATTR, "1")

      #Add Terminal Identifier Node or Request counter Node based on serial communication RS485/RS422
      ter_id = ter_id.to_s(16)
      if(s_mode == "RS485")
        add_tag(REQ_TAG, TID_TAG, "//#{DATA_TAG}")
        set_tag_value("//#{TID_TAG}", "0x" + ter_id)
        set_tag_attr("//#{TID_TAG}", SIZE_ATTR, "1")
      elsif (s_mode == "RS422")
        add_tag(REQ_TAG, RC_TAG, "//#{DATA_TAG}")
        set_tag_value("//#{RC_TAG}", "0x" + ter_id)
        set_tag_attr("//#{RC_TAG}", SIZE_ATTR, "1")
      else
        $test_logger.log("Please provide Serial Protocol mode RS485/RS422")
        raise "Specify at least one Serial Protocol mode RS485/RS422"
      end

      #Add End Text Node with value and attributes
      add_tag(REQ_TAG, ETX_TAG, "//#{DATA_TAG}", false)
      set_tag_value("//#{ETX_TAG}", "0x02")
      set_tag_attr("//#{ETX_TAG}", SIZE_ATTR, "1")

      #Add Data Link Escape Node with value and attributes
      add_tag(REQ_TAG, DLE_TAG, "//#{DATA_TAG}", false)
      set_tag_value("//#{DLE_TAG}", "0x1b")
      set_tag_attr("//#{DLE_TAG}", SIZE_ATTR, "1")

      #Calculate checksum and Add CRC Node with value and attributes
      crc = calc_checksum(hex_str)
      add_tag(REQ_TAG, CRC_TAG, "//#{DATA_TAG}", false)
      set_tag_value("//#{CRC_TAG}", "0x" + crc)
      set_tag_attr("//#{CRC_TAG}", SIZE_ATTR, "2")
      #puts to_s
      #Notify changes to load other formats like RAW and HEX
      notify_change(InputChannel::XML)
      #puts "hex:-#{@ilv_hex_str}"
      @ilv_hex_str
    end

    #create packet identifier
    def create_packet_idenfier(pkt_first, pkt_last, pkt_type)
      $test_logger.log("Create Packet Identifier....Pkt First bit :- #{pkt_first} ,Pkt last bit :- #{pkt_last} ,Pkt type :- #{pkt_type}")

      raise "During creating Packet Identifier, Packet type is not found" if pkt_type == nil
      pkt_id = "0__0"
      if pkt_first
        pkt_id.sub!(/_/, '1')
      else
        pkt_id.sub!(/_/, '0')
      end
      if pkt_last
        pkt_id.sub!(/_/, '1')
      else
        pkt_id.sub!(/_/, '0')
      end
      pkt_id = "0x" + pkt_id.to_i(2).to_s(16) + pkt_type.to_s
      pkt_id
    end

    #calculate checksum

    def calc_checksum(data, crc=0)

      $test_logger.log("Calculate checksum of this ilv :- #{data}")

      raise "During calculating checksum, ILV data is not found" if data == nil

      data = Common.packbytes(data)
      data.each_byte do |b|
        crc = ((CHKSUM_TABLE[((crc >> 8) ^ b) & 0xff] ^ (crc << 8)) & 0xffff)
      end
      crc = crc.to_s(16)
      crc
    end

    #Get XML tag node

    def get_tag_node (tag_path)

      $test_logger.log("Get tag node #{tag_path}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      #Get target tag
      target_tag = @xml_ilv_node.root.elements[tag_path]
      target_tag
    end

    #Add XML tag node

    def add_tag_node (tag_path, tag_node_or_name, tag_value = nil, data_type = nil)

      $test_logger.log("Add tag node #{tag_path}")

      #Get target node
      target_node = get_tag_node(tag_path)

      if tag_node_or_name.is_a?(REXML::Element)
        raise "Tag node and tag value cannot be specified at the same time!" if tag_value != nil
      node_to_add = tag_node_or_name
      else
        node_to_add = Element.new(tag_node_or_name)
        node_to_add.text = tag_value if tag_value != nil
      end

      #Add data type to node if required
      if data_type != nil
        node_to_add.add_attribute(TYPE_ATTR, data_type)
      end

      #Add child node to target path
      target_node << node_to_add

      #Notify changes to load other formats like RAW and HEX
      notify_change(InputChannel::XML)
    end

    #Insert XML tag node

    def insert_tag_node (tag_path, tag_node_or_name, to_insert_before = false, tag_value = nil)

      $test_logger.log("Add tag node #{tag_path}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      if tag_node_or_name.is_a?(REXML::Element)
      node_to_add = tag_node_or_name
      else
        node_to_add = Element.new(tag_node_or_name)
      node_to_add.text = tag_value.to_s
      end

      if to_insert_before
      @xml_ilv_node.insert_before(tag_path, node_to_add)
      else
      @xml_ilv_node.insert_after(tag_path, node_to_add)
      end

      #Notify changes to load other formats like RAW and HEX
      notify_change(InputChannel::XML)

    end

    #Remove XML tag node

    def remove_tag_node (tag_path)

      $test_logger.log("Remove tag node #{tag_path}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      #Remove node
      @xml_ilv_node.root.elements.delete tag_path

    end

    #Set XML tag value

    def set_tag_value(tag_path, tag_value, is_size_updated = false)

      $test_logger.log("Set tag value #{tag_path}, #{tag_value}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      #Get target tag
      target_tag = @xml_ilv_node.root.elements[tag_path]

      #Raise exception if no tag is found
      raise "XML path '#{tag_path}' not found!" if !target_tag

      #Assign specified value to XML tag
      target_tag.text = tag_value

      if is_size_updated
        attr_obj = target_tag.attributes.get_attribute(SIZE_ATTR)
      target_tag.attributes.delete(attr_obj)
      end

      #Notify changes to load other formats like RAW and HEX
      notify_change(InputChannel::XML)
    end

    #Get XML tag value

    def get_tag_value (tag_path, fetch_datatype=false)

      $test_logger.log("Get tag value #{tag_path}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      #Get target tag
      target_tag = @xml_ilv_node.root.elements[tag_path]

      #Fetch target value
      val = ""
      val = target_tag.get_text.value if target_tag && target_tag.get_text

      #Get data type for element
      if fetch_datatype
        data_type = ILVMessage.get_type_for_ele(target_tag)
      return val, data_type
      else
      return val
      end
    end

    #Get XML tag value in integer format
    def get_tag_value_int (tag_path)

      $test_logger.log("Get tag value in integer #{tag_path}")

      #Get tag text and data type
      tag_val, data_type = get_tag_value tag_path, true

      #Parse int value
      int_val = 0
      if data_type == DataType::HEX
      int_val = tag_val.hex
      elsif data_type == DataType::DEC || data_type == DataType::DEC_BIG
      int_val = tag_val.to_i
      end

      #Return int value
      int_val
    end

    #Get XML tag value in integer format
    def get_tag_value_ascii (tag_path)

      $test_logger.log("Get tag value in ASCII #{tag_path}")

      #Get tag text and data type
      tag_val, data_type = get_tag_value tag_path, true

      #Parse int value
      ascii_val = ""
      if data_type == DataType::HEX
        ascii_val = ILVMessage.hex_to_raw(tag_val.gsub(HEX_PREFIX, "")).reverse
      else
      ascii_val = tag_val
      end

      #Return ASCII value
      ascii_val
    end

    #Get request status integer
    def get_request_status
      $test_logger.log("Get request status in integer")
      get_tag_value_int("//#{VALUE_TAG}/#{REQ_STAT_TAG}")
    end

    #Check request status OK or not
    def is_request_status_ok
      get_request_status == MA500Functions::MA500::ILV_OK.hex
    end

    #Get XML tag attribute value
    def get_tag_attr (tag_path, attr_name)

      $test_logger.log("Get XML tag attribute #{tag_path}, #{attr_name}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      #Get target tag
      target_tag = @xml_ilv_node.elements[tag_path]

      #Raise exception if no tag is found
      raise "XML path '#{tag_path}' not found!" if !target_tag

      #Get value from attribute, if exists
      attr_value = nil
      if target_tag.has_attributes?
        attr_obj = target_tag.attributes.get_attribute(attr_name)
        attr_value = attr_obj.value if attr_obj != nil
      end

      attr_value
    end

    #Set XML tag attribute value
    def set_tag_attr (tag_path, attr_name, attr_value)

      $test_logger.log("Set XML tag attribute #{tag_path}, #{attr_name}, #{attr_value}")

      raise "XML doc not loaded" if @xml_ilv_node == nil

      #Get target tag
      target_tag = @xml_ilv_node.root.elements[tag_path]

      #Raise exception if no tag is found
      raise "XML path '#{tag_path}' not found!" if !target_tag

      attr_obj = target_tag.add_attribute(attr_name, attr_value)

      #Notify changes to load other formats like RAW and HEX
      notify_change(InputChannel::XML)
    end

    #Set ILV data from RAW str

    def set_raw_str(ilv_raw_str)
      $test_logger.log("Set raw str")
      @ilv_raw_str = ilv_raw_str
      notify_change(InputChannel::RAW)
    end

    #Set ILV data from HEX str
    def set_hex_str(ilv_hex_str)
      $test_logger.log("Set hex str")
      @ilv_hex_str = ilv_hex_str
      notify_change(InputChannel::HEX)
    end

    #Override object to_s method
    def to_s
      $test_logger.log("to_s")
      outp = "ILV Hex = #{@ilv_hex_str}\n"
      formatter = REXML::Formatters::Pretty.new(2)
      formatter.compact = true
      formatter.write(@xml_ilv_node, outp)
      outp.to_s
    end

    #Convert raw str to hex str
    def self.raw_to_hex(raw_str)
      $test_logger.log("Raw to Hex")
      Common.unpackbytes(raw_str) if raw_str
    end

    #Convert hex str to raw str
    def self.hex_to_raw(hex_str)
      $test_logger.log("Hex to Raw")
      Common.packbytes(hex_str) if hex_str
    end

    #Get raw data from file

    def self.read_file_data(file_path)
      $test_logger.log("Read data from file '#{file_path}'")
      data_str = Common.read_all_bytes(file_path)
      data_str.reverse!
      Common.unpackbytes(data_str)
    end
    # #get full Path of element
    # def self.get_full_path(elem)
    # act_path=""
    # while elem.parent != nil
    # act_path = elem.parent.name + "/" + act_path
    # elem = elem.parent
    # end
    # act_path
    # end

    private

    #Notify change and update ILV data in other than input channel
    def notify_change(input_channel)

      $test_logger.log("Notify change #{input_channel}")

      case input_channel

      #If XML is changed
      when InputChannel::XML

        if @is_reply_ilv == true
          $test_logger.log("XML to hex/raw not processed as current ILV is reply ILV!")
        else
          @ilv_hex_str = xml_to_hex(@xml_ilv_node)
          @ilv_raw_str = ILVMessage.hex_to_raw(@ilv_hex_str)
        end

      #If HEX string is changed
      when InputChannel::HEX
        @ilv_raw_str = ILVMessage.hex_to_raw(@ilv_hex_str)
        raw_to_xml(@xml_ilv_node, @ilv_raw_str)

      #If RAW string is changed
      when InputChannel::RAW
        @ilv_hex_str = ILVMessage.raw_to_hex(@ilv_raw_str)
        raw_to_xml(@xml_ilv_node, @ilv_raw_str)

      else
      raise "Invalid channel specified '#{input_channel}'!"
      end
    end

    #Get byte str for putting into XML
    def get_byte_str(byt, byte_size=nil)
      byt_str = ""

      # case byt.class.name
      # when "Fixnum"

      # byt_str = byt.to_s(16)
      # byte_size = 1 if !byte_size && byt <= 0xf
      # when "String"

      byt.reverse!
      byt_str = byt.unpack('H*h*').collect {|x| x.to_s}.join
      #end

      #Pad 0s upto byte_size
      byt_str = byt_str.rjust(byte_size*2, "0") if byte_size

      #Prefix with hex string '0x'
      byt_str = HEX_PREFIX + byt_str

      byt_str
    end

    #Get hex str from XML
    def xml_to_hex(xml_doc_root)
      temphex_str, size = xml_to_temphex(xml_doc_root, 0)

      $test_logger.log("TempHEX Str (ILVSize: #{size}) = #{temphex_str}")
      strt_pkt = ""
      end_pkt = ""
      ilv_pkt = ""
      if @chk_serial_comm
      strt_pkt = temphex_str[0,6]
      end_pkt = temphex_str[-8,8]
      ilv_pkt = temphex_str[6..-9]
      #ilv_hex_str = calc_length(ilv_pkt)
      ilv_hex_str = strt_pkt + ilv_hex_str + end_pkt
      else
      ilv_hex_str = temphex_str
      end
      ilv_hex_str
    end

    #Fills the specified xml_ilv with data from raw_str
    #It sets error message and parse error bit if any
    #error occurs while parsing
    def raw_to_xml(xml_ilv, raw_str)

      $test_logger.log("Raw to XML")

      #Initialize class variables
      @nodes_to_delete = nil
      @is_parse_error = false
      @unknown_flag = false
      @parse_error_message = ""

      if raw_str
        raw_str_cpy = String.new(raw_str)
        fill_xml(xml_ilv, raw_str_cpy)

        if @unknown_flag
          @is_parse_error = true
          @parse_error_message = "Unexpected ILV data received for filling XML!"
        end
      else
        @is_parse_error = true
        @parse_error_message = "No ILV data received for processing!"
      end

    ##Log parsed data in XML format
    #$test_logger.log(to_s)

    end

    #Conversion of raw_data to xml_data
    def fill_xml(xml_node, raw_ilv, ilv_len=nil)

      @stack_counter = 0 if !@stack_counter

      #Get Element text
      tag_name = xml_node.name
      tag_value = xml_node.get_text
      tag_value = tag_value != nil ? tag_value.value : ""
      xml_node.text = ""

      $test_logger.log("Fill XML #{tag_name}")

      #If data is unknown initialize length as calc from packet
      if tag_value == CmdManager::DONT_CARE
      attr_str_len = ilv_len
      else
      #if attr_str_len == nil
      attr_str_len = 1
      end

      data_type = nil
      if xml_node.has_attributes?

        #Get element attribute "data type"
        data_type = xml_node.attributes.get_attribute(TYPE_ATTR).value if xml_node.attributes.get_attribute(TYPE_ATTR)

        #Get element attribute "size"
        attr_str_len = xml_node.attributes.get_attribute(SIZE_ATTR).value if xml_node.attributes.get_attribute(SIZE_ATTR)

        if attr_str_len == CmdManager::DONT_CARE
          if data_type == DataType::STR_WITH_NULL && raw_ilv.index(/\x00/)
            null_char_pos = raw_ilv.index(/\x00/) + 1
            xml_node.attributes[SIZE_ATTR] = null_char_pos
          attr_str_len = null_char_pos
          else
            xml_node.attributes[SIZE_ATTR] = ilv_len
          attr_str_len = ilv_len
          end
        else
        attr_str_len = attr_str_len.to_i
        end

      end

      if raw_ilv.length <= 0

        @nodes_to_delete = Array.new if !@nodes_to_delete
        @nodes_to_delete << xml_node

        if !@is_parse_error
          @is_parse_error = true
          @parse_error_message = "Not enough data received for filling XML tag '#{tag_name}' and onwards!"
        end

      else

        if xml_node.has_elements?
          old_ilv_len = ilv_len
          xml_node.elements.each do | next_node |
            @stack_counter += 1
            old_ilv_len = fill_xml(next_node, raw_ilv, old_ilv_len)
            @stack_counter -= 1
          end

          #Delete unfilled nodes in XML
          if @nodes_to_delete
            @nodes_to_delete.each{|ele|
              xml_node.delete ele
            #ele.elements.delete_all '*'
            }
          @nodes_to_delete.clear
          #!xml_node.elements.each {|ele| xml_node.delete ele if ele.get_text!=nil && ele.get_text.value.to_s.empty? }
          end

          #Add Unknown Data, if present
          if @stack_counter == 0 && raw_ilv.length > 0
            unknown_ele = xml_node.root.add_element UNKNOWN_TAG
            unknown_ele.text = get_byte_str(raw_ilv)
            @unknown_flag = true
            raw_ilv = ""
          old_ilv_len = 0
          end

        else

          if (tag_name == ID_TAG)

            actual_id = raw_ilv.slice!(0, 1)

            ilv_len -= 1 if ilv_len != nil

            xml_node.text = get_byte_str(actual_id,1)

          elsif tag_name == LEN_TAG && xml_node.previous_element.name == ID_TAG
            #Get length from specified ilv
            len_bytes = 2
            pkt_len_raw = raw_ilv.slice!(0, len_bytes)
            pkt_len = pkt_len_raw.unpack("v").first
            ilv_len -= 2 if ilv_len != nil

            #Check if length is greater than 2 bytes
            if pkt_len == 0xffff
              len_bytes += 2

              pkt_len_raw = raw_ilv.slice!(0, len_bytes)
              pkt_len = pkt_len_raw.unpack("n").first

              ilv_len -= 4 if ilv_len != nil
            end

            ilv_len = pkt_len

            if tag_value.include?(HEX_PREFIX) || data_type == DataType::HEX
              xml_node.text = get_byte_str(pkt_len_raw, 2)
            else
            xml_node.text = pkt_len
            end

          else
            ilv_bytes_count = raw_ilv.bytes.count
            if attr_str_len > ilv_bytes_count
              @is_parse_error = true
              @parse_error_message = "Not enough ILV data received for filling XML tag '#{tag_name}'!\nExpected size=#{attr_str_len}\nActual size=#{ilv_bytes_count}"
            end

            ilv_len -= attr_str_len if ilv_len != nil
            data_str = raw_ilv.slice!(0, attr_str_len)

            #if data_type attribute is not present
            #identify data type based on value
            data_type = ILVMessage.get_type_for_data(tag_value) if data_type == nil

            #Parse data based on data type
            xml_node.text = parse_data(data_str, data_type, attr_str_len)

          end

        end
      end
      # return of actual reply element
      ilv_len
    end

    #Identify type based on data
    def self.get_type_for_data(value)
      $test_logger.log("get_type_for_data")

      data_type = nil

      #If hex prefix found
      if value.include?(HEX_PREFIX)
        data_type = DataType::HEX
      end

      #Perform fixnum check
      if data_type == nil && value.to_i.to_s == value
        data_type = DataType::DEC
      end

      #Perform hex check based on value
      if data_type == nil && value.hex.to_s(16) == value.downcase
        data_type = DataType::HEX
      end

      data_type
    end

    #Get data type either from attribute or data
    def self.get_type_for_ele(xml_element)

      $test_logger.log("get_type_for_ele")
      data_type = nil

      if xml_element && xml_element.is_a?(REXML::Element)

        #Check if tag contains attributes
        if xml_element.has_attributes?

          #Get element attribute "data type"
          data_type = xml_element.attributes.get_attribute(TYPE_ATTR).value if xml_element.attributes.get_attribute(TYPE_ATTR)
        end

        #If data_type is nil find data type based on data
        if !data_type

          #Get value
          exp_value = xml_element.get_text.value if xml_element.get_text

          #Find data type based on data
          data_type = get_type_for_data(exp_value.to_s)
        end
      end

      data_type
    end

    #Parse data based on data type and byte size
    def parse_data(raw_str, data_type, byte_size=nil)

      $test_logger.log("Parse data")

      data_value = nil
      #d "Parse \nraw=#{raw_str}\ntype=#{data_type}\nsize=#{byte_size}"

      #Hex data
      if data_type == DataType::HEX
        data_value = get_byte_str raw_str

      #String (ASCII) data
      elsif data_type == DataType::STR || data_type == DataType::STR_WITH_NULL
      #Removed strip as null character at the end of string is OK to have in XML
      data_value = raw_str

      #Decimal data (Little endian)
      elsif data_type == DataType::DEC
        case byte_size
        when 1
          data_value  = raw_str.bytes.first
        when 2
          #v=little-endian
          data_value = raw_str.unpack("v").first
        when 3..4
          #Changed to V from N on 21Jan13
          data_value = raw_str.unpack("V").first
        else
        data_value = raw_str.unpack("Q").first
        end

      #Decimal data (Big endian)
      elsif data_type == DataType::DEC_BIG
        case byte_size
        when 1
          data_value  = raw_str.bytes.first
        when 2
          #n=big-endian
          data_value = raw_str.unpack("n").first
        when 3..4
          #Changed to V from N on 21Jan13
          data_value = raw_str.unpack("N").first
        else
        data_value = raw_str.unpack("Q").first
        end
      #Not matching with any data types then get hex
      else
        data_value = get_byte_str(raw_str)
      end

      data_value
    end

    #Format data based on type for sending to device
    def format_tag_value (tag_value, size_attr=nil, data_type=nil)
      value_num = 0

      data_type = ILVMessage.get_type_for_data(tag_value) if data_type == nil
      data_type = DataType::STR if data_type == nil

      case data_type
      when DataType::HEX

        #Get hex data
        value_num = tag_value.hex

        #Calculate size for hex based on data
        size_attr = (value_num.to_s(16).size/2.0).ceil if size_attr == nil

        #Convert bignum to hex str
        hex_str = hex_to_str(value_num, size_attr)
      when DataType::DEC, DataType::DEC_BIG

        #Get integer data
        value_num = tag_value.to_i

        #Get size of integer if specified size is nil
        size_attr = value_num.size if size_attr == nil

        #Convert bignum to hex str
        hex_str = hex_to_str(value_num, size_attr)
      when DataType::STR
        hex_str =""

        #Remove XML escaped characters
        tag_value = $test_logger.de_escape_xml_chars(tag_value)

        #Get size of string data if specified size is nil
        size_attr = tag_value.size if size_attr == nil

        #Replace xml null character to ruby null character
        #tag_value.gsub!(NULL, "\x0")

        tag_value.each_byte {|c|
          cur_hex_byte = c.to_s(16)
          if cur_hex_byte.size == 1
            hex_str << "0"
          end
          hex_str << cur_hex_byte}
      end

      return hex_str, size_attr
    end

    #Get str from HEX number
    def hex_to_str(hex_num, byte_size=nil)

      hex_str = ""
      byt_count = 0
      begin
        byt = hex_num & 0xff
        hex_num >>= 8
        hex_str << (byt <= 0xf ? "0" : "") + byt.to_s(16)
      byt_count += 1
      end while hex_num != 0 && (byte_size == nil || byt_count < byte_size)

      hex_str = hex_str.ljust(byte_size*2, "0") if byte_size != nil
      hex_str
    end

    #Conversion of xml_data to hex_str
    def xml_to_temphex(xml_node, cur_ilv_size)

      #Cmd str in hex
      cmd_hexstr = ""

      attr_str_len = nil
      data_type = nil

      #Check if tag contains attributes
      if xml_node.has_attributes?

        #Get element attribute "size"
        attr_str_len = xml_node.attributes.get_attribute(SIZE_ATTR).value if xml_node.attributes.get_attribute(SIZE_ATTR)
        attr_str_len = attr_str_len.to_i if attr_str_len

        #Get element attribute "data type"
        data_type = xml_node.attributes.get_attribute(TYPE_ATTR).value if xml_node.attributes.get_attribute(TYPE_ATTR)

        #Get auto attribute
        is_auto = xml_node.attributes.get_attribute(AUTO_ATTR).value if xml_node.attributes.get_attribute(AUTO_ATTR)

      end

      #Get tag name
      tag_name = xml_node.name
      $test_logger.log("XML to temphex #{tag_name}")

      #If specified node has child nodes
      if xml_node.has_elements?

        #Initialize current ivl size to zero
        cur_ilv_size_temp = 0

        #Iterate each child element in current node
        xml_node.elements.each do | node |

        #Recursive call to this function
          cur_hexstr, cur_node_size = xml_to_temphex(node, cur_ilv_size)

          #Append child node hex str to main hex str
          cmd_hexstr << cur_hexstr

          #Add size for all child notes
          cur_ilv_size_temp += cur_node_size
        end

        #If exit from value tag
        if tag_name == VALUE_TAG

          #If previous tag is not length tag then create it
          if xml_node.previous_element.name != LEN_TAG
            node_to_add = Element.new(LEN_TAG)

            #Add attribute to notify user about length tag is inserted by framework
            node_to_add.add_attribute(AUTO_ATTR, "true")

          @xml_ilv_node.insert_after(xml_node.previous_element.xpath, node_to_add)
          end

          #If length tag is nil update the calculated value
          if !xml_node.previous_element.has_text?
            xml_node.previous_element.text = cur_ilv_size_temp

            #If length is more than 65535 (0xFFFF)
            #then size of length tag would be 6 bytes
            #   2 bytes = 0xFFFF
            #   4 bytes = big length
            if cur_ilv_size_temp >= 0xFFFF
              len_tag_size = 6
              len_hex_str = "FFFF" + hex_to_str(cur_ilv_size_temp, 4)
            else
              len_tag_size = 2
              len_hex_str = hex_to_str(cur_ilv_size_temp, len_tag_size)
            end

            #Add length hex str to main hex string
            cmd_hexstr = len_hex_str + cmd_hexstr

            #Update current ilv size with length tag size
            cur_ilv_size_temp += len_tag_size

            #Update correct size for length into XML attribute
            xml_node.previous_element.add_attribute(SIZE_ATTR, len_tag_size)

          elsif xml_node.previous_element.text.to_i != cur_ilv_size_temp
            raise "Specified length as '#{xml_node.previous_element.text}' mismatch with calculated length as '#{cur_ilv_size_temp}'\n\tfor path '#{xml_node.previous_element.xpath}'"
          end
        end

      #Return calculated ilv size
      attr_str_len = cur_ilv_size_temp

      else

      #If size attribute is nil
        if attr_str_len == nil
          to_update_size = true

          #If tag is length tag then define size as 2
          #TBD for size greater than 65535
          if tag_name == LEN_TAG
          attr_str_len = 2

          #If tag is Id then length should be 1
          elsif tag_name == ID_TAG
          attr_str_len = 1
          end
        else
        to_update_size = false
        end

        #If current tag is len and is auto then make it nil
        if (tag_name == LEN_TAG) && (is_auto == "true")
          xml_node.text = nil
        end

        #Fetch value of tag
        txt = xml_node.get_text

        #Process tag text if its not nil
        if txt != nil
          #Format tag value based on size and data type
          cur_hex_str, attr_str_len = format_tag_value(txt.to_s, attr_str_len, data_type)

          #If size is to be updated then add attribute
          xml_node.add_attribute(SIZE_ATTR, attr_str_len) if to_update_size

        #Append processed string to hex command
        cmd_hexstr << cur_hex_str.to_s
        else
        attr_str_len = 0
        end
      end

      #Return hex string and size
      return cmd_hexstr, attr_str_len
    end
  end
end
