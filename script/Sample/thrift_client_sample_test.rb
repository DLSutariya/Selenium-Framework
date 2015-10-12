class ThriftClientSampleTest < BaseTest
  class << self
    def startup
      super(TestType::THRIFT)
      $test_logger.log("Thrift SampleTests startup")
    end

    def shutdown
      $test_logger.log("Thrift SampleTests shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("Thrift SampleTests setup")
  end

  def teardown
    $test_logger.log("Thrift SampleTests teardown")
    super
  end

  def test_thrift_command

    #Create tamper parameter and set value
    v = Variant.new()
    param_map = {}
    v.int32_value = 1
    param_map['tamper.state'] = v

    #Set tamper state parameter
    @@cmd_proc.call_thrift{config_set_params(param_map)}

    #Get tamper state parameter
    param_list = ["tamper.state"]
    val = @@cmd_proc.call_thrift{config_get_params(param_list)}

    #Assert version string
    assert_equal("[<Variant int32_value:1>]", val.to_s, "Parameter value  mismatch")

  end

end