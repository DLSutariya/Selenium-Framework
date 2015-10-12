class L1Bulk < BaseTest
  class << self
    def startup
      super(TestType::SERIALCMD)
      $test_logger.log("L1Bulk startup")
    end

    def shutdown
      $test_logger.log("L1Bulk shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("L1Bulk setup")
  end

  def teardown
    $test_logger.log("L1Bulk teardown")
    super
  end

  def test_create_no_of_transcation_logs_entries
      @@cmd_proc.create_transcation_log_on_device(50)
  end 

  def test_erase_all_logs
      @@cmd_proc.erase_transcation_log_from_device      
  end

  def test_get_log_status
      
    #Create packet for counting transactionlog from device (NUM_TRANSACTION_LOG 0x0742)
    cmd = BioPacket.new(:cmd_id => 0x0742,:ack_req => true,:res_req => true,:data => [0x0])
    #Send receive command
    ack_pkt,res_pkt = @@cmd_proc.send_recv_del(cmd)
    
    $test_logger.log("\n\n####### Total no of logs on teminal: #{res_pkt.get_int_data(0)} ##########\n", true)
    
    #Create packet for counting transactionlog from device (NUM_TRANSACTION_LOG 0x0742)
    cmd = BioPacket.new(:cmd_id => 0x0742,:ack_req => true,:res_req => true,:data => [0x1])
    #Send receive command
    ack_pkt,res_pkt = @@cmd_proc.send_recv_del(cmd)
    
    $test_logger.log("####### Total no of unread logs on teminal: #{res_pkt.get_int_data(0)} ##########\n\n", true)
            
  end 
   

end
