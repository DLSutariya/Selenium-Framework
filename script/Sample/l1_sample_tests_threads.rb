class L1SampleTestsThreads < BaseTest
  class << self
    def startup
      super(TestType::SERIALCMD)

      $test_logger.log("L1SampleTestsThreads startup")

      #Get device IP and port from test configuration file
      @@device1 = $test_config.get("L1Device1.IPAddress")
      @@port1 = $test_config.get("L1Device1.Port")
      @@device2 = $test_config.get("L1Device2.IPAddress")
      @@port2 = $test_config.get("L1Device2.Port")

      #Print onscreen test script information
      $test_logger.log("Tests will be carried out on two devices.\nPlace finger on sensor when asked.\n\tDevice 1: IP='#{@@device1}', Port='#{@@port1}'\n\tDevice 2: IP='#{@@device2}', Port='#{@@port2}'", true)

    end

    def shutdown
      $test_logger.log("L1SampleTestsThreads shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("L1SampleTestsThreads setup")

  end

  def teardown
    $test_logger.log("L1SampleTestsThreads teardown")

    #Wait till device completes the processing for last command
    sleep(2)
    super
  end

  def enroll_verify_hex(hostname, port)

    #Open socket connection to device
    cmd_proc = SerialCmd.new(:device_ip=>hostname, :tcp_port=>port)

    #Parse enroll packet from hex string - template id '1' (0x0460)
    enroll_pkt = BioPacket.parse_packet_hex("40286BFE00000A006034050001000000000000005CFFFFFF")

    #Send command and receive ACK packet
    $test_logger.result_log "#{hostname}: Sending enroll and store command 0x0460 with template id '1'"
    ack_pkt = cmd_proc.send_packet(enroll_pkt)
    assert_not_nil(ack_pkt, "Ack not received for cmd 460")

    #Get command response
    $test_logger.result_log "#{hostname}: Receiving response for command 0x0460"
    res_pkt = cmd_proc.receive_packet()
    assert_not_nil(res_pkt, "Response not received for cmd 460")
    assert_false(res_pkt.err_bit, "Packet error #{res_pkt.error_desc}")

    #Parse verify template command (0x0412)
    verify_pkt = BioPacket.parse_packet_hex("40286BFE00000B00123405000100000000000000A9FFFFFF")

    #Send verify packet and wait for ACK packet
    $test_logger.result_log "#{hostname}: Sending verify command with template id '1' (0x0412)"
    ack_pkt = cmd_proc.send_packet(verify_pkt)
    assert_not_nil(ack_pkt, "Ack not received for cmd 412")

    #Get command response
    $test_logger.result_log "#{hostname}: Receiving response for command 0x0412"
    res_pkt = cmd_proc.receive_packet()
    assert_not_nil(res_pkt, "Response not received for cmd 412")
    assert_false(res_pkt.err_bit, "Packet error #{res_pkt.error_desc}")

    #Close command processor
    cmd_proc.close

  end

  #Test - Enroll/Verify on two devices using threads
  def test_enroll_verify_thread

    #Create new threads with parameters
    new_thread("enroll_verify_hex", @@device1, @@port1)
    new_thread("enroll_verify_hex", @@device2, @@port2)

  end

  #Device status thread
  def thread_device_status(thread_no, ser_cmd)

    @semaphore.synchronize{
      $test_logger.result_log "Thread[#{thread_no}]: Sending get status command 0x300"

      status_cmd = BioPacket.new(:net_id => 0,
      :pkt_no => thread_no,
      :cmd_id => 0x300,
      :ack_req => true,
      :res_req => true)

      no_new_pkt = ser_cmd.send_packet(status_cmd, false)
      assert_nil(no_new_pkt, "Thread[#{thread_no}]: Some packet received from device")
    }

  end

  #Test - Send/Receive device status command using threads
  def test_thread_device_status

    #Open socket connection to device
    cmd_proc = SerialCmd.new(:device_ip => @@device2, :tcp_port=>@@port2)

    #Verify connection is open
    assert_true(cmd_proc.is_connected, "Device not connected to IP #{@@device2}!")

    @@received_pkts = Array.new

    @semaphore = Mutex.new
    thread_count = 100
    for i in 1..thread_count
      #Create new thread
      new_thread("thread_device_status", i, cmd_proc)
    end

    #wait till all threads completes its execution
    join_all_threads

    #Receive all sent packets at once
    @@received_pkts.concat cmd_proc.receive_packets

    #Check received number of packets is same as sent
    assert_equal(thread_count, @@received_pkts.length, "Not all packets received!")

    #Close socket connection
    cmd_proc.close
  end

end
