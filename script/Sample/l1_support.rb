class L1Bulk < BaseTest
  class << self
    def startup
      super(TestType::SERIALCMD)
      $test_logger.log("L1 Support startup")
    end

    def shutdown
      $test_logger.log("L1 Support shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("L1 Support setup")
  end

  def teardown
    $test_logger.log("L1 Support teardown")
    super
  end

  def test_test
  
  pend "Not used"
    
    0x100.upto(0x999){|i|
    cmd = BioPacket.new(:cmd_id => i,:ack_req => true,:res_req => false)
    ack_pkt = @@cmd_proc.send_packet(cmd, true)
    
    if ack_pkt == nil
      $test_logger.result_log("\t0x#{i.to_s(16)},No response,", true)
    elsif ack_pkt.error_no == -1
      $test_logger.result_log("\t0x#{i.to_s(16)},Not Supported,", true)
    else
      $test_logger.result_log("\t0x#{i.to_s(16)},Supported,#{ack_pkt.err_bit}", true)
    end
    }  
    
            
  end 
  
  load_data(Common.get_data_path("AllCommands3DF.csv"))
  
  def test_datadriven(data)
    
    
	i = data["CommandID"].to_i
	
    cmd = BioPacket.new(:cmd_id => i ,:ack_req => true,:res_req => true)
    ack_pkt = @@cmd_proc.send_packet(cmd, true, 5)
    
    assert_not_nil ack_pkt, "No response received!"
	
	if ack_pkt.err_bit
		assert_not_equal -1, ack_pkt.error_no, "Command not supported!"
	end
	
	
	#if ack_pkt == nil
      #$test_logger.result_log("\t0x#{i.to_s(16)},No response,", true)
    #elsif ack_pkt.error_no == -1
      #$test_logger.result_log("\t0x#{i.to_s(16)},Not Supported,", true)
    #else
    #  $test_logger.result_log("\t0x#{i.to_s(16)},Supported,#{ack_pkt.err_bit}", true)
    #end
      
    
            
  end 
   
   

end
