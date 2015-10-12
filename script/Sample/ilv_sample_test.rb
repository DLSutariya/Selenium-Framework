class ILVSampleTest < BaseTest
  class << self
    def startup
      super(TestType::ILV)

      $test_logger.log("ILVSampleTest startup")
      @@hostname = $test_config.get("Terminal.IPAddress")
      @@port = $test_config.get("Terminal.Port")

      $test_logger.log("Tests running for terminal IP=#{@@hostname}:#{@@port}\nPlace finger on sensor when asked!", true)
    end

    def shutdown
      $test_logger.log("ILVSampleTest shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("ILVSampleTest setup")
  end

  def teardown
    $test_logger.log("ILVSampleTest teardown")
    super
  end

  #Data driven test which will call ILV commands one by one from ilv_xml_cmds.csv
  load_data(Common.get_data_path("ilv_xml_cmds.csv"))
  
  def test_xml_cmd_data_driven(data)

    #Make result log
    $test_logger.result_log("Processing data='#{data_label}'")

    #Create command processor
    cmd_processor = ILVCmd.new(:device_ip=>@@hostname, :tcp_port =>@@port)

    #cmd_xml = "display_message.xml"
    #cmd_xml = "<Ping><Identifier>0x8</Identifier></Ping>"
    cmd_xml = data["ILV_XML_Cmd"]

    #Send/Receive xml
    expected_reply, actual_reply = cmd_processor.send_recv_xml(cmd_xml)

    #Assert for error in reply
    assert_false(actual_reply.is_parse_error, "Error while parsing ILV data!\n#{actual_reply.parse_error_message}")

    #Assert whole command
    cmd_processor.assert_command(expected_reply, actual_reply)

    #Close command processor
    cmd_processor.close

  end

  #Test to check set tag value function of ILVMessage
  def test_display_message_set_tag_value

    #Create command processor
    cmd_processor = ILVCmd.new(:device_ip => @@hostname,
    :tcp_port => @@port )

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "display_message.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)

    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Update data values in request command parsed from XML
    ilv_req.set_tag_value("//Values/Message", "Updated Message")
    ilv_req.set_tag_value("//Values/Timeout", "5")

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = cmd_processor.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert to check request status
    assert_equal "0", actual_rep.get_tag_value("//Values/RequestStatus"), "Request status mismatch!"
    cmd_processor.assert_command(expected_rep, actual_rep)

    #Close cmd processor
    cmd_processor.close
  end

  #Test to check get tag value function of ILVMessage
  def test_enroll_get_tag_value

    #Create command processor
    cmd_processor = ILVCmd.new(:device_ip => @@hostname,
    :tcp_port => @@port )

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "enroll.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)

    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = cmd_processor.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert request status
    assert_equal 0, actual_rep.get_tag_value("//Values/RequestStatus").hex, "Request status mismatch!"

    #Assert that value in Minutiae tag is not empty
    assert_not_empty actual_rep.get_tag_value("//Values/Minutiae"), "Minutiae not received"

    #Assert that attribute size in Minutiae tag is non-zero
    assert_not_equal 0, actual_rep.get_tag_attr("//Values/Minutiae", "size").to_i, "Minutiae size mismatch"

    #Assert Whole Command
    cmd_processor.assert_command(expected_rep, actual_rep)

    #Close cmd processor
    cmd_processor.close
  end

  #Test to test ILV command in HEX string
  def test_enroll_hex_cmd
    #Create command processor
    cmd_processor = ILVCmd.new(:device_ip => @@hostname,
    :tcp_port => @@port )

    #Create enroll ILV request based on HEX string
    ilv_req = ILVMessage.new(:ilv_hex_str=>"210c00006400000001000004010002")

    #Expected repy HEX string
    expected_reply = "2106000000ffffffff"

    #Send ILV and receive RAW reply
    raw_reply = cmd_processor.send_ilv_msg(ilv_req)

    #Convert actual RAW reply to HEX
    actual_reply = ILVMessage.raw_to_hex(raw_reply)

    #Assert reply
    assert_equal(expected_reply, actual_reply, "Reply mismatch!")

    #Close cmd processor
    cmd_processor.close
  end

  #Test to reboot terminal using user function
  def test_reboot_user_function
    #Call reboot terminal user function located in file
    reboot_terminal @@hostname

    #Wait till device completes rebooting
    sleep(15)
  end

end