class ILVSerialSampleTest < BaseTest
  class << self
    def startup
      super(TestType::ILV)

      $test_logger.log("ILVSerialSampleTests startup")

      #Fetch device communication details from test config file
      @@device1_comport = $test_config.get("Device1.ComPort")
      @@device1_baud = $test_config.get("Device1.BaudRate")
      device2_ip = $test_config.get("Device2.IPAddress")
      device2_port = $test_config.get("Device2.Port")
      @@mode = $test_config.get("Terminal.Mode")

    #Print onscreen test script information
    #$test_logger.log("Tests will be carried out on two devices.\nPlace finger on sensor when asked.\n\tDevice 1: Port='COM#{device1_comport}', Baud='#{device1_baud}'\n\tDevice 2: IP='#{device2_ip}', Port='#{device2_port}'", true)

    #Open Bioscrypt 4G serial command processor
    # @@serial_cmd_proc = nil
    #begin
    #For serial comm channel
    #  @@serial_cmd_proc = SerialCmd.new(:com_port => device1_comport, :baud_rate => device1_baud)
    # rescue
    #  $test_logger.log("Error while opening serial connection at com port '#{device1_comport}'", true)
    #end

    end

    def shutdown
      #Close cmd processors
      #@@serial_cmd_proc.close if @@serial_cmd_proc
      #@@eth_cmd_proc.close if @@eth_cmd_proc

      $test_logger.log("ILVSerialSampleTests shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("ILVSerialSampleTests setup")
  end

  def teardown
    $test_logger.log("ILVSerialSampleTests teardown")
    super
  end

  def test_reboot_device_serial

    #Create command processor
    cmd_processor = ILVCmd.new(:com_port=>@@device1_comport, :baud_rate=>@@device1_baud)

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "reboot.xml"

    #Create ILV request command from xml file
    ilv_msg = ILVMessage.new(:xml_file_name => xml_file_name)
    ilv_req = ilv_msg.create_serial_ilv
    d ilv_req
    #Send ILV cmd to terminal
    cmd_processor.send_ilv_msg(ilv_req, false)

  end
end
