class ILVMultipleCMDSampleTest < BaseTest
  class << self
    def startup
      super(TestType::ILV)

      $test_logger.log("ILVMultipleCMD Send/Receive SampleTest startup")
      @@hostname = $test_config.get("Terminal.IPAddress")
      @@port = $test_config.get("Terminal.Port")

      $test_logger.log("Tests running for terminal IP=#{@@hostname}:#{@@port}\nPlace finger on sensor when asked!", true)
    end

    def shutdown
      $test_logger.log("ILVMultipleCMD Send/Receive shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("ILVMultipleCMD Send/Receive setup")
  end

  def teardown
    $test_logger.log("ILVMultipleCMD Send/Receive teardown")
    super
  end

  #Test to check send/receive multiple ILVMessage
  def test_multiple_ilv_send_receive

    #Create Command List
    cmd_list = Array.new

    #Create command processor
    cmd_processor = ILVCmd.new(:device_ip => @@hostname,
    :tcp_port => @@port )

    # 1) Add first command to ILV command List

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "display_message.xml"

    #Create Command holder list
    cmd_hold_elem = CmdHolderObj.new(:ilv_req_pkt => ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG), :ilv_rep_pkt => ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG))

    #add command to list
    cmd_list << cmd_hold_elem

    # 2) Add second command to ILV command List

    xml_file_name = "enroll.xml"
    #Create Command holder list
    cmd_hold_elem = CmdHolderObj.new(:ilv_req_pkt => ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG), :ilv_rep_pkt => ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG))

    #add command to list
    cmd_list << cmd_hold_elem

    # 3) Add third command to ILV command List

    cmd_hold_elem = CmdHolderObj.new(:ilv_req_pkt => ILVMessage.new(:ilv_hex_str=>"210c00006400000001000004010002"), :ilv_rep_pkt => ILVMessage.new(:ilv_hex_str=>"2106000000ffffffff"))
    #add command to list
    cmd_list << cmd_hold_elem

    # 4) Add fourth command to ILV command List

    xml_str = "<Reboot><Request><Identifier>0x04</Identifier></Request><Reply><Identifier>0x04</Identifier><Length>1</Length><Values><Request_status size='1'>0</Request_status></Values></Reply></Reboot>"
    cmd_hold_elem = CmdHolderObj.new(:ilv_req_pkt => ILVMessage.new(:xml_str => xml_str,
    :xml_ilv_tag => ILVMessage::REQ_TAG), :ilv_rep_pkt => ILVMessage.new(:xml_str => xml_str,
    :xml_ilv_tag => ILVMessage::REP_TAG))
    cmd_list << cmd_hold_elem

    #send and verify all above command through list
    cmd_processor.send_ilv_cmd_list(cmd_list)

  end

end