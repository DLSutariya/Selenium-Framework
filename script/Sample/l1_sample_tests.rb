class L1SampleTests < BaseTest
  class << self
    def startup
      super(TestType::SERIALCMD)

      $test_logger.log("L1SampleTests startup")

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

      $test_logger.log("L1SampleTests shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("L1SampleTests setup")
  end

  def teardown
    $test_logger.log("L1SampleTests teardown")
    super
  end

  def test_full_version_serial

    #Assert device connection
    assert_not_nil(@@serial_cmd_proc, "Device not connected at serial port!")

    #Create 4G packet for 0x4b1 (Get full version)
    full_ver_cmd = BioPacket.new(:cmd_id => 0x4b1)

    #Send receive delayed command
    ack_ver, res_ver = @@serial_cmd_proc.send_recv_del(full_ver_cmd)

    #Assert version string
    assert_equal(".01KC_2121765A D_21.176CP D205.1", res_ver.get_str_data, "Version mismatch")

  end

  def test_full_version_eth

    #Assert device connection
    assert_not_nil(@@eth_cmd_proc, "Device not connected at TCP/IP!")

    #Create 4G packet for 0x4b1 (Get full version)
    full_ver_cmd = BioPacket.new(:cmd_id => 0x4b1)

    #Send receive delayed command
    ack_ver, res_ver = @@eth_cmd_proc.send_recv_del(full_ver_cmd)

    #Assert version string
    assert_equal(".01KC_2121765A D_21.176CP D205.1", res_ver.get_str_data, "Version mismatch")

  end

  def test_verify_template_serial

    #Assert device connection
    assert_not_nil(@@serial_cmd_proc, "Device not connected at serial port!")

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

    #Send and receive ACK
    ack_pkt = @@serial_cmd_proc.send_packet(verify_cmd)

    #Assert ACK
    assert_not_nil(ack_pkt, "ACK not received from device")
    assert_true(ack_pkt.ack_bit, "ACK packet not received from device")
    assert_false(ack_pkt.err_bit, "Packet error #{ack_pkt.error_desc}")

    #Assert whole Acknowledge of Command on serial communication
    @@serial_cmd_proc.assert_command(verify_ack, ack_pkt)

    #Receive RES
    res_pkt = @@serial_cmd_proc.receive_packet

    #Assert RES
    assert_not_nil(res_pkt, "RES not received from device")
    assert_false(res_pkt.err_bit, "Packet error #{res_pkt.error_desc}")
    assert_equal(1, res_pkt.get_int_data(0), "Template verification failed")
    #assert_equal(115, res_pkt.get_int_data(1), "Score mismatch")

    #Assert whole Response of Command on serial communication
    @@serial_cmd_proc.assert_command(verify_res, res_pkt)

  end

  def test_verify_template_eth

    #Assert device connection
    assert_not_nil(@@eth_cmd_proc, "Device not connected at TCP/IP!")

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

    #Send and receive ACK
    ack_pkt = @@eth_cmd_proc.send_packet(verify_cmd)

    #Assert ACK
    assert_not_nil(ack_pkt, "ACK not received from device")
    assert_true(ack_pkt.ack_bit, "ACK packet not received from device")
    assert_false(ack_pkt.err_bit, "Packet error #{ack_pkt.error_desc}")

    #Assert whole Acknowledge of Command on ethernet communication
    @@serial_cmd_proc.assert_command(verify_ack, ack_pkt)

    #Receive RES
    res_pkt = @@eth_cmd_proc.receive_packet

    #Assert RES
    assert_not_nil(res_pkt, "RES not received from device")
    assert_false(res_pkt.err_bit, "Packet error #{res_pkt.error_desc}")
    assert_equal(1, res_pkt.get_int_data(0), "Template verification failed")
    #assert_equal(115, res_pkt.get_int_data(1), "Score mismatch")

    #Assert whole Response of Command on ethernet communication
    @@eth_cmd_proc.assert_command(verify_res, res_pkt)

  end
end
