class SampleDatadriven < BaseTest
  #load_data("datadriven.csv")
  class << self
    def startup
      super(TestType::SAMPLE)
      $test_logger.log("SampleDataDrivenTest1 startup")
    end

    def shutdown
      $test_logger.log("SampleDataDrivenTest1 shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("SampleDatadrivenTest1 test setup")
  end

  def teardown
    $test_logger.log("SampleDataDrivenTest1 test teardown")
    super
  end

  @@expected_str = {"Data 1" => "abc", "Data 2" => "def", "Data 3" => "pqr"}
  @@expected_num1 = {"Data 1" => 11, "Data 2" => 12, "Data 3" => 13}
  load_data(Common.get_data_path("data_sample.csv"))
  
  def test_datadriven_test_one(data)
    assert_equal(@@expected_str[data_label], data["SampleString"], "Something wrong with string!")
    assert_equal(@@expected_num1[data_label], data["SampleNumber"], "Something wrong with number!")
  end

  #Intentional failure for Data 2
  @@expected_num2 = {"Data 1" => 11, "Data 2" => 999, "Data 3" => 13}
  load_data(Common.get_data_path("data_sample.csv"))

  def test_datadriven_test_two(data)
    assert_equal(@@expected_str[data_label], data["SampleString"], "Something wrong with string!")
    assert_equal(@@expected_num2[data_label], data["SampleNumber"], "Something wrong with number!")
  end
end
