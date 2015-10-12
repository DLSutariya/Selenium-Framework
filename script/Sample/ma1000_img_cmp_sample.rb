class MA1000ImgCmpSample < BaseTest
  class << self
    def startup
      super(TestType::THRIFT)
      $test_logger.log("MA1000 image comparison sample test startup")
    end

    def shutdown
      $test_logger.log("MA1000 image comparison sample test shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("MA1000 image comparison sample test setup")
  end

  def teardown
    $test_logger.log("MA1000 image comparison sample test teardown")
    super
  end

  def test_image_compare_1

    #Display user prompt
    puts "\nNavigate to login screen on the terminal and then press 'Enter' key to continue..."
    STDIN.getc

    #Call thrift API to capture screen image from terminal in PNG format
    act_raw_png = @@cmd_proc.call_thrift{picture_capture(Picture_interface::Screen, Picture_format::PNG)}

    #Save raw image string from terminal to PNG file in output folder
    png_img_path = ImageCompare.save_png_stream(act_raw_png)

    #Get path for expected/reference image file from data folder
    exp_img_path = Common.get_data_path("test_image_compare_1.png")

    #Compare and assert images
    assert_gui(exp_img_path, png_img_path, "Unchanged login screen.")

  end

  def test_image_compare_2

    #Display user prompt
    puts "\nNavigate to login screen on the terminal and then press 'Enter' key to continue..."
    STDIN.getc

    #Call thrift API to capture screen image from terminal in PNG format
    act_raw_png = @@cmd_proc.call_thrift{picture_capture(Picture_interface::Screen, Picture_format::PNG)}

    #Save raw image string from terminal to PNG file in output folder
    png_img_path = ImageCompare.save_png_stream(act_raw_png)

    #Get path for expected/reference image file from data folder
    exp_img_path = Common.get_data_path("test_image_compare_2.png")

    #Compare and assert images
    assert_gui(exp_img_path, png_img_path, "Login screen with slightly bigger input box.")

  end

  def test_image_compare_3

    #Display user prompt
    puts "\nNavigate to login screen on the terminal and then press 'Enter' key to continue..."
    STDIN.getc

    #Call thrift API to capture screen image from terminal in PNG format
    act_raw_png = @@cmd_proc.call_thrift{picture_capture(Picture_interface::Screen, Picture_format::PNG)}

    #Save raw image string from terminal to PNG file in output folder
    png_img_path = ImageCompare.save_png_stream(act_raw_png)

    #Get path for expected/reference image file from data folder
    exp_img_path = Common.get_data_path("test_image_compare_3.png")

    #Compare and assert images
    assert_gui(exp_img_path, png_img_path, "Login screen with relocated input box.")

  end

end
