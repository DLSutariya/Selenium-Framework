class CBISimuMA1000 < BaseTest
  class << self
    def startup
      super(TestType::THRIFT)

      $test_logger.log("CBI Simu MA1000 startup")

    end

    def shutdown
      $test_logger.log("CBI Simu MA1000 shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("CBI Simu MA1000 setup")
  end

  def teardown
    $test_logger.log("CBI Simu MA1000 teardown")
    super
  end

  def test_cbi_load

    path = $simu_path

    files = Cbi_simulation_files.new
    files.raw_image_file_name = path + "no_finger[1048x0764x00].raw"
    files.eeprom_file_name = path + "CBI_1048x0764x00.eeprom"
    files.uniformity_file_name = path + "CBI_1056x784.UniRef"
    files.deconvolution_file_name = path + "CBI_1056x784.Deconv"

    @@cmd_proc.call_thrift{cbi_simulation_files_load(files)}

    #Call terminal reboot API
    @@cmd_proc.call_thrift{terminal_reboot}

    #Wait for terminal to reboot
    sleep 10

    #Verify terminal is no longer online and make sure it is under reboot process
    result = @@cmd_proc.ping
    assert_false result, "Verify terminal reboot failed!"

    #Send receive immediate command
    to_retry = @@cmd_proc.wait_for_device
    assert_true(to_retry, "Device not connected successfully")

    $test_logger.log("CBI simulation files loaded successfully!!!", true)

  end

  def test_cbi_delete

    pend "Need to comment this line to delete CBI simulation files"

    @@cmd_proc.call_thrift{cbi_simulation_files_delete_all}

  end

  def test_copy_files

    pend "Need to comment this copy CBI simulation files to rootfs_data"

    files = Cbi_simulation_files.new
    files.raw_image_file_name = $simu_path + "no_finger[1048x0764x00].raw"
    files.eeprom_file_name = $simu_path + "CBI_1048x0764x00.eeprom"
    files.uniformity_file_name = $simu_path + "CBI_1056x784.UniRef"
    files.deconvolution_file_name = $simu_path + "CBI_1056x784.Deconv"

    @@cmd_proc.call_thrift{cbi_simulation_files_load(files)}

    td_proc.td_app.sut.execute_shell_command("cp -r #{$simu_path} /rootfs_data/SimuFiles/", {:detached => 'true', :wait => 'true', :timeout =>2000})

    @@cmd_proc.call_thrift{cbi_simulation_files_load(files)}
  end
end
