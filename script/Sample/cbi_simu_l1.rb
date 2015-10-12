class CBISimuL1 < BaseTest
  class << self
    def startup
      super(TestType::SERIALCMD)

      $test_logger.log("CBI Simu L1 startup")

    end

    def shutdown
      $test_logger.log("CBI Simu L1 shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("CBI Simu L1 setup")
  end

  def teardown
    $test_logger.log("CBI Simu L1 teardown")
    super
  end

  def test_cbi_load

    d "Loading all files..."

    path = $test_config.get("FingerSimulationConfig.SimuFilesPath")

    files = [path + "no_finger[1048x0764x00].raw",
      path + "CBI_1048x0764x00.eeprom",
      path + "CBI_1056x784.UniRef",
      path + "CBI_1056x784.Deconv"]

    files.each_with_index{|file, ind|
      d "Loading '#{file}'..."
      cmd = BioPacket.new(:cmd_id => 0x04c4, :data => [1, ind + 1])
      cmd.set_str_data(2, file.size, file)

      ack, res = @@cmd_proc.send_recv_del(cmd)
      d "RES:"
      d ack
      d res
    }

  end

  def test_cbi_delete

    d "Deleting all CBI simu files..."
    del_cmd = BioPacket.new(:cmd_id => 0x04c4, :data => [2])
    ack, res = @@cmd_proc.send_recv_del(del_cmd)
    d "RES:"
    d ack
    d res

  end
end
