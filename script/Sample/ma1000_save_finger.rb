class MA1000SaveFinger < BaseTest
  class << self
    def startup
      super(TestType::THRIFT)
      $test_logger.log("MA1000 save finger test startup")

    end

    def shutdown
      $test_logger.log("MA1000 save finger test shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("MA1000 save finger test setup")
  end

  def teardown
    $test_logger.log("MA1000 save finger test teardown")
    super
  end

  def test_enroll_save

    #Delete all users from terminal DB
    @@cmd_proc.delete_all_uers

    #Test data
    dbid = 1
    timeout = 30
    enr_type = Enrolment_type::Transfer
    #enr_type = Enrolment_type::Both
    fingers = 3
    userid = "444"
    user_flds = nil
    inter_rep = false
    op_param = Biofinger_enrol_optional_param.new(:fp_template_format => Biofinger_template_type::Cfv)

    enr_res = @@cmd_proc.call_thrift(nil, 120){biofinger_enrol(dbid, timeout, enr_type, fingers, userid, user_flds, inter_rep, op_param)}

    enr_res.final_result.fp_templates.each_with_index{|temp, i|
      if temp && temp.size > 0
        fil_path = "c:\\fingers\\ma1000_finger#{i+1}.cfv"
        byts = Common.write_all_bytes(fil_path, temp)
        $test_logger.result_log "Bytes '#{byts}' written at '#{fil_path}'", true
      end
    }

  end

  def test_get_db_save
    userid = "444"
    users = @@cmd_proc.call_thrift{user_DB_get_users(Set.new([userid]), Set.new([User_DB_fields::Templates]))}
    #d users
    fingers = []
    users[userid].templates.each_with_index{|temp, i|
      if temp.template_data && temp.template_data.size > 0
        #d temp.template_type
        fil_path = "c:\\fingers\\ma1000_finger#{i+1}.bin"
        byts = Common.write_all_bytes(fil_path, temp.template_data)
        $test_logger.result_log "Bytes '#{byts}' written at '#{fil_path}'", true
      end
    }

  end

  def test_verify_user

    userid = "444"

    #Set test data
    db_id = 0
    timeout = 10
    thres = 5
    user_id = "444"
    inter_rep = true
    op_param = Biofinger_control_optional_param.new(:events => [Biofinger_async_event::Low_resol_live_images])

    #Call API for finger authentication
    res = @@cmd_proc.call_thrift{biofinger_authenticate_db(db_id, timeout, thres, user_id, inter_rep, op_param)}

    assert_true res.final_result.success, "Auth fail!"

  end

end
