require 'oily_png'

module MA1000AutomationTool
  class ImageCompare

    #Constants
    OUTPUT_SUB_DIR = "res"
    ALLOWED_DEVIATION = 1.0 #Deviation allowed in percentage
    #Save PNG raw string into PNG file and return the path
    def self.save_png_stream(png_raw_str)

      #Get img file name at output folder
      png_file = $test_logger.get_temp_file_path("act", ".png", OUTPUT_SUB_DIR)

      open(png_file, 'wb+') do |f|
        f.write png_raw_str
      end
      png_file
    end

    #Compare two images and returns the results
    def self.compare(ref_img_file, act_img_file)
      $test_logger.log("Call to compare with '#{ref_img_file}', '#{act_img_file}'")

      #Copy reference image to output folder
      ref_img_out_path = $test_logger.get_temp_file_path("ref", ".png", OUTPUT_SUB_DIR)
      Common.copy_file ref_img_file, ref_img_out_path

      #Copy actual image to difference image path
      diff_path = $test_logger.get_temp_file_path("diff", ".png", OUTPUT_SUB_DIR)
      Common.copy_file act_img_file, diff_path

      images = [ChunkyPNG::Image.from_file(ref_img_file),
        ChunkyPNG::Image.from_file(act_img_file)]

      diff = []

      images.first.height.times do |y|
        images.first.row(y).each_with_index do |pixel, x|
          diff << [x,y] unless pixel == images.last[x,y]
        end
      end

      tol_pixels = images.first.pixels.length
      pixel_change_count = diff.length
      pixel_change_per = ((diff.length.to_f / images.first.pixels.length) * 10000).round / 100.0

      if pixel_change_count != 0
        x, y = diff.map{ |xy| xy[0] }, diff.map{ |xy| xy[1] }

        #Draw highlight box on to the difference image (Thickness.times)
        3.times{|i|
          j = i
          images.last.rect(x.min-j, y.min-j, x.max+j, y.max+j, ChunkyPNG::Color.rgb(255,0,0))
        }

      #Get tmp file path for saving differential image
      images.last.save(diff_path)
      end

      return ref_img_out_path, pixel_change_count, pixel_change_per, diff_path
    end

  # #Temporary function to convert BMP stream to PNG image and return saved PNG file path
  # def self.convert_bmp_to_png(bmp_img_str)
  #
  # $test_logger.log("Call to convert bmp to png, input stream size: #{bmp_img_str.size}")
  #
  # #Get tmp file path for saving actual PNG image
  # act_png_path = $test_logger.get_temp_file_path("act", ".png", OUTPUT_SUB_DIR)
  #
  # #Get original thread list
  # ori_list = Thread.list
  #
  # $test_logger.log("Thread List before free-image: #{ori_list}")
  #
  # con_thread = Thread.new {
  # require "free-image"
  # img_bmp = FreeImage::Bitmap.open(FreeImage::Memory.new(bmp_img_str))
  #
  # img_bmp = img_bmp.make_thumbnail(500, false)
  #
  # img_bmp.save(act_png_path, :png, FreeImage::AbstractSource::Encoder::PNG_Z_BEST_COMPRESSION)
  # }
  #
  # #Wait till BMP to PNG conversion completes
  # con_thread.join
  #
  # $test_logger.log("BMP to PNG conversion completed!")
  #
  # new_list = Thread.list
  # $test_logger.log("Thread List after conversion: #{new_list}")
  #
  # new_list.each {|t1|
  # if !ori_list.include?(t1)
  # $test_logger.log("Unwanted thread found.. Force terminate it..")
  # t1.terminate
  # t1.join
  # $test_logger.log("Unwanted thread terminated!")
  # end
  # }
  #
  # $test_logger.log("Thread List after free-image: #{Thread.list}")
  #
  # act_png_path
  # end

  end

end

