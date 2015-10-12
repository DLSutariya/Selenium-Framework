class NoTermImgCmpSample < BaseTest
  class << self
    def startup
      super(TestType::SAMPLE)
      $test_logger.log("Image comparison sample test startup")
    end

    def shutdown
      $test_logger.log("Image comparison sample test shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("Image comparison sample test setup")
  end

  def teardown
    $test_logger.log("Image comparison sample test teardown")
    super
  end

  def test_image_compare_1

    #Get path for actual image file from data folder
    png_img_path = Common.get_data_path("test_image_compare_1.png")

    #Get path for expected/reference image file from data folder
    exp_img_path = Common.get_data_path("test_image_compare_1.png")

    #Compare and assert images
    assert_gui(exp_img_path, png_img_path, "Unchanged login screen.")

  end

  def test_image_compare_2

    png_img_path = Common.get_data_path("test_image_compare_1.png")

    #Get path for expected/reference image file from data folder
    exp_img_path = Common.get_data_path("test_image_compare_2.png")

    #Compare and assert images
    assert_gui(exp_img_path, png_img_path, "Login screen with slightly bigger input box.")

  end

  def test_image_compare_3

    png_img_path = Common.get_data_path("test_image_compare_1.png")

    #Get path for expected/reference image file from data folder
    exp_img_path = Common.get_data_path("test_image_compare_3.png")

    #Compare and assert images
    assert_gui(exp_img_path, png_img_path, "Login screen with relocated input box.")

  end

end
