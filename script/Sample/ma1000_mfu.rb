class MA1000MFU < BaseTest

  #Constants
  USER1_ID = "111"
  USER2_ID = "222"
  class << self
    def startup
      super(TestType::THRIFT)
      $test_logger.log("MA1000 MFU test startup")

    end

    def shutdown
      $test_logger.log("MA1000 MFU test shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("MA1000 MFU test setup")
  end

  def teardown
    $test_logger.log("MA1000 MFU test teardown")
    super
  end

  #Method to load users
  def load_users

    $test_logger.log("Loading users...")

    #Delete all users from terminal DB
    @@cmd_proc.delete_all_uers

    #Fetch finger images from resource
    finger1 = Resource.get_content("N1.pklite", true)
    finger2 = Resource.get_content("N2.pklite", true)

    #Create required user records on terminal DB
    user_map = {
      USER1_ID => User_DB_record.new({:name_UTF8 => "Test MFU User 1", :PIN_code_UTF8 => "4455",
        :first_finger_nb => 1,
        :templates => [User_templates.new(:template_type => Biofinger_template_type::Pklite,
          :template_data => finger1)]}),
      USER2_ID => User_DB_record.new({:name_UTF8 => "Test MFU User 2", :PIN_code_UTF8 => "6677",
        :first_finger_nb => 1,
        :templates => [User_templates.new(:template_type => Biofinger_template_type::Pklite,
          :template_data => finger2)]})
    }

    # USER_BAD_ID => User_DB_record.new({:name_UTF8 => "Test bad quality id",
    # :templates => [User_templates.new(:template_type => Biofinger_template_type::Pklite,
    # :template_data => bad_qual_finger)]})

    @@cmd_proc.call_thrift{user_DB_set_users(user_map, false)}
    
  end

  def test_mfu_set_stats_valid_user_ids

    #Load users on terminal
    load_users

    #Test data
    db_idx = 0
    exp_uid_stats = {USER1_ID => 67, USER2_ID => 0}

    #Call API to load MFU stats
    @@cmd_proc.call_thrift{mfu_set_stats(db_idx, exp_uid_stats)}

    #Call API to get MFU stats
    act_uid_stats = @@cmd_proc.call_thrift{mfu_get_stats(db_idx, Set.new([USER1_ID, USER2_ID]))}

    #Make an assert
    assert_equal exp_uid_stats.inspect, act_uid_stats.inspect, "MFU stats set for user Ids '#{USER1_ID}, #{USER2_ID}' mismatch!"
  end

  def test_mfu_set_stats_invalid_inexistent_user_id

    #Load users on terminal
    load_users

    #Test data
    user_id = "123"
    db_idx = 0
    exp_uid_stats = {user_id => 67}

    #Call API to load MFU stats and expect inexistent err
    @@cmd_proc.call_thrift(Inexistent_user_id_error.new){mfu_set_stats(db_idx, exp_uid_stats)}

  end

  def test_mfu_set_stats_invalid_db_empty

    #Delete all users from terminal
    @@cmd_proc.delete_all_uers

    #Test data
    user_id = "555"
    db_idx = 0
    exp_uid_stats = {user_id => 67}

    #Call API to load MFU stats and expect user not found error
    exp_db_empty = Thrift::ApplicationException.new(0, "[bool Sensor_manager_namespace::Sensor_manager::user_exists(uint8_t*, uint8_t, C_MORPHO_User&):1558:-11]\nException detail:\nError in m_x_database.DbQueryFirst MORPHOERR_DB_EMPTY interal code=0")
    @@cmd_proc.call_thrift(exp_db_empty){mfu_set_stats(db_idx, exp_uid_stats)}

  end

  def test_mfu_get_stats_valid_user_ids

    #Load users on terminal
    load_users

    #Test data
    db_idx = 0
    exp_uid_stats = {USER1_ID => 0, USER2_ID => 0}

    #Call API to load MFU stats
    #@@cmd_proc.call_thrift{mfu_set_stats(db_idx, exp_uid_stats)}

    #Call API to get MFU stats
    act_uid_stats = @@cmd_proc.call_thrift{mfu_get_stats(db_idx, Set.new([USER1_ID, USER2_ID]))}

    #Make an assert
    assert_equal exp_uid_stats.inspect, act_uid_stats.inspect, "MFU stats set for user Ids '#{USER1_ID}, #{USER2_ID}' mismatch!"
  end

  #Bug 1374
  # Execute the 
  def test_mfu_set_stats_mfu1K
     
    user_id = 1
    db_idx = 0
    
    #update 100 users in database to set stats in order to add them in MFU
    for j in 1..10 do
      $test_logger.result_log("Adding user chunk='#{j}'")
      exp_uid_stats = Hash.new
      for i in 1..10 do
        exp_uid_stats[user_id.to_s] = 5555
        user_id += 1
      end

      #Call API to load MFU stats
      @@cmd_proc.call_thrift{mfu_set_stats(db_idx, exp_uid_stats)}
      
      exp_uid_stats.clear

    end
   
  end
end
