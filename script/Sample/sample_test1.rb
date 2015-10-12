class SampleTest1 < BaseTest
  class << self
    def startup
      super(TestType::SAMPLE)
      $test_logger.log("SampleTest1 startup")
    end

    def shutdown
      $test_logger.log("SampleTest1 shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("SampleTest1 test setup")
  end

  def teardown
    $test_logger.log("SampleTest1 test teardown")
    super
  end

  def test_mytest_one
    $test_logger.log("SampleTest1 -> test_mytest_one")
    assert_true(true,"In case of true failure")
    assert_false(false,"In case of false failure")
    assert_equal(true,true,"In case of equal failure")
  end

  def test_mytest_two
    $test_logger.log("SampleTest1 -> test_mytest_two")
    assert_true(true,"In case of true failure")
    assert_false(false,"In case of false failure")
    #Intentional failure
    assert_equal(true,false,"In case of equal failure")
  end
end
