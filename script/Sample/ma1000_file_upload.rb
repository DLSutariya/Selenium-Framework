class MA1000FileUpload < BaseTest
  class << self
    def startup
      super(TestType::THRIFT)
      $test_logger.log("MA1000 file upload test startup")

    end

    def shutdown
      $test_logger.log("MA1000 file upload test shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("MA1000 file upload test setup")
  end

  def teardown
    $test_logger.log("MA1000 file upload test teardown")
    super
  end

  def test_upload_audio

    #Test data
    file_path = Resource.get_path("test_tamper.flac")
    file_type = File_type::Audio
    file_subtype = File_subtype::Audio_tamper
    file_name = "tamp.flac"
    file_action = File_action::Play

    @@cmd_proc.upload_file file_path, file_type, file_subtype, file_name, file_action

  end

end
