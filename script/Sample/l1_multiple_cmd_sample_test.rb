class L1MultipleCMDSampleTest < BaseTest
  class << self
    def startup
      super(TestType::SERIALCMD)

      $test_logger.log("L1 Multiple Command send/receive SampleTests startup")

      #Fetch device communication details from test config file
      device1_comport = $test_config.get("L1Device1.ComPort")
      device1_baud = $test_config.get("L1Device1.BaudRate")
      device2_ip = $test_config.get("L1Device2.IPAddress")
      device2_port = $test_config.get("L1Device2.Port")

      #Print onscreen test script information
      $test_logger.log("Tests will be carried out on two devices.\nPlace finger on sensor when asked.\n\tDevice 1: Port='COM#{device1_comport}', Baud='#{device1_baud}'\n\tDevice 2: IP='#{device2_ip}', Port='#{device2_port}'", true)

      #Open Bioscrypt 4G serial command processor
      @@serial_cmd_proc = nil
      @@eth_cmd_proc = nil
      begin
      #For serial comm channel
        @@serial_cmd_proc = SerialCmd.new(:com_port => device1_comport, :baud_rate => device1_baud)
      rescue
        $test_logger.log("Error while opening serial connection at com port '#{device1_comport}'", true)
      end
      begin
      #For ethernet comm channel
        @@eth_cmd_proc = SerialCmd.new(:device_ip => device2_ip, :tcp_port => device2_port)
      rescue
        $test_logger.log("Error while opening ethernet connection at IP '#{device2_ip}'", true)
      end
    end

    def shutdown
      #Close cmd processors
      @@serial_cmd_proc.close if @@serial_cmd_proc
      @@eth_cmd_proc.close if @@eth_cmd_proc

      $test_logger.log("L1 Multiple Command send/receive shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("L1 Multiple Command send/receive SampleTests setup")
  end

  def teardown
    $test_logger.log("L1 Multiple Command send/receive SampleTests teardown")
    super
  end

  #Test to check send/receive multiple ILVMessage on ethernet communication
  def test_multiple_bio_cmd_send_receive_eth

    #Create Command List
    cmd_list = Array.new

    #Assert device connection
    assert_not_nil(@@eth_cmd_proc, "Device not connected at TCP/IP!")

    # 1) Add first command to Bio command List

    #Read data from template file in resource folder
    data = BioPacket.read_file_data(Resource.get_path("sbv_sample.tem"))

    #Create verify template command
    verify_cmd = BioPacket.new(:net_id => 0,
    :pkt_no => 0x150,
    :cmd_id => 0x411,
    :ack_req => true,
    :res_req => true,
    :data => data)

    #Create acknowledgement of verify command
    verify_ack = BioPacket.new(:net_id => 0,
    :pkt_no => 0x150,
    :cmd_id => 0x411,
    :ack_bit => true)

    #Create responce of verify command
    verify_res = BioPacket.new(:net_id => 0,
    :pkt_no => 0x150,
    :cmd_id => 0x411,
    :ack_bit => false,
    :data => [1,"?"])

    #Create Command holder list
    cmd_hold_elem = CmdHolderObj.new(:bio_req_pkt => verify_cmd, :bio_ack_pkt => verify_ack, :bio_res_pkt =>verify_res)

    #add command to list
    cmd_list << cmd_hold_elem

    # 2) Add second command to Bio command List

    #Read data from template file in resource folder
    data = BioPacket.read_file_data(Resource.get_path("sbv_sample.tem"))

    #Create verify template command
    verify_cmd = BioPacket.new(:net_id => 0,
    :pkt_no => 0x150,
    :cmd_id => 0x411,
    :ack_req => true,
    :res_req => true,
    :data => data)

    #Create acknowledgement of verify command
    verify_ack = BioPacket.new(:net_id => 0,
    :pkt_no => 0x150,
    :cmd_id => 0x411,
    :ack_bit => true)

    #Create responce of verify command
    verify_res = BioPacket.new(:net_id => 0,
    :pkt_no => 0x150,
    :cmd_id => 0x411,
    :ack_bit => false,
    :data => [1, "?"])

    #Create Command holder list
    cmd_hold_elem = CmdHolderObj.new(:bio_req_pkt => verify_cmd, :bio_ack_pkt => verify_ack, :bio_res_pkt =>verify_res)

    #add command to list
    cmd_list << cmd_hold_elem

    #send one by one command from list on serial communication
    @@serial_cmd_proc.send_bio_cmd_list(cmd_list)

    #send one by one command from list on serial communication
    @@eth_cmd_proc.send_bio_cmd_list(cmd_list)

  end
end
