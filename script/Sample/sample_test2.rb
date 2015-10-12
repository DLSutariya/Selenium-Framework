class SampleTest2 < BaseTest
  class << self
    def startup
      super(TestType::SAMPLE)
      $test_logger.log("SampleTest2 startup")
    end

    def shutdown
      $test_logger.log("SampleTest2 shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("SampleTest2 test setup")
  end

  def teardown
    $test_logger.log("SampleTest2 test teardown")
    super
  end

  def test_sampletest_two_other
    $test_logger.log("Test case test_sampletest_two_other")
    assert true
  end
end