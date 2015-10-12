class CBISimuMA500 < BaseTest
  class << self
    def startup
      super(TestType::ILV)

      $test_logger.log("CBI Simu MA500 startup")

    end

    def shutdown
      $test_logger.log("CBI Simu MA500 shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("CBI Simu MA500 setup")
  end

  def teardown
    $test_logger.log("CBI Simu MA500 teardown")
    super
  end

  def test_cbi_delete

    d "Deleting all CBI simu files..."
    cmd_xml = "<CBI>

                <Request>
                  <Identifier>0xE6</Identifier>
                  <Values>
                    <DelAll>
                      <Identifier>0x02</Identifier>
                      <Length>1</Length>
                      <Values>
                        <Data>0x0</Data>
                      </Values>
                    </DelAll>
                  </Values>
                </Request>

                <Reply>
                  <Identifier>0xE6</Identifier>
                  <Length>1</Length>
                  <Values>
                    <RequestStatus size='1'>0x00</RequestStatus>
                  </Values>
                </Reply>

               </CBI>"

    #Send/Receive and verify xml cmd
    @@cmd_proc.send_recv_verify_xml(cmd_xml)

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
      cmd_xml = "<CBI>

                <Request>
                  <Identifier>0xE6</Identifier>
                  <Values>
                    <FileLoad>
                      <Identifier>0x01</Identifier>
                      <Values>
                        <FileType size='1'>#{ind + 1}</FileType>
                        <FilePath type='str'>#{file}</FilePath>
                      </Values>
                    </FileLoad>
                  </Values>
                </Request>

                <Reply>
                  <Identifier>0xE6</Identifier>
                  <Length>1</Length>
                  <Values>
                    <RequestStatus size='1'>0x00</RequestStatus>
                  </Values>
                </Reply>

               </CBI>"

      #Send/Receive and verify xml cmd
      @@cmd_proc.send_recv_verify_xml(cmd_xml)
    }

  end
end
