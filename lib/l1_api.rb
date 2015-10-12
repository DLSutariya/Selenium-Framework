require 'ffi'
module MA1000AutomationTool
  class L1API

    #import wrapper dll and load
    extend FFI::Library
    Dir.chdir(FWConfig::LIB_FOLDER_PATH) do
     ffi_lib 'BII_V1100'
    end
    ffi_convention :stdcall

    #create structure (special variable types)
    class BII_Audio_File_Param < FFI::Struct
      layout  :szFilename, [:char, 255],
              :iVolumeLevel, :int,
              :bDefaultFile, :bool
    end

    #import API Function
    attach_function :initialize_communication, :BII_Initialize_Socket_Communications, [ ], :int
    attach_function :open_communication, :BII_Open_TCPIP_Communications, [ :string, :int], :int
    attach_function :close_conn, :BII_Close_TCPIP_Communications, [], :int
    attach_function :upload_image, :BII_Upload_Image_File, [:int, :string], :int
    attach_function :upload_audio, :BII_Upload_Audio_File, [:int, BII_Audio_File_Param.by_value], :int

    #intialize communication and open TCP/IP communication to device
    def self.tcp_open(ipaddress)
      begin
        res = L1API.initialize_communication()
        $test_logger.log("Intialize communication to device using DLL: #{res}")
        res = L1API.open_communication(ipaddress,10001)
        $test_logger.log("Open TCP/IP communication to device using DLL: #{res}")
      rescue Exception => ex
        raise ex, "Error in opening tcp connection through DLL!\n#{ex.message}", ex.backtrace
      end
    end

    #close TCP/IP communication to device
    def self.tcp_close
      begin
        res = L1API.close_conn()
        $test_logger.log("Close communication to device using DLL: #{res}")
      rescue Exception => ex
        raise ex, "Error in closing tcp connection through DLL!\n#{ex.message}", ex.backtrace
      end
    end

    #uploading image file to device
    def self.w_upload_image(dir,path)
      begin
        $test_logger.log("Calling Wrapper function for uploading image using DLL")
        res = L1API.upload_image(dir,path)
        res
      rescue Exception => ex
        raise ex, "Error in uploading image through DLL!\n#{ex.message}", ex.backtrace
      end
    end

    #uploading audio file to device
    def self.w_upload_audio_file(dir,path,vol,file_type)
      begin
        $test_logger.log("Calling Wrapper function for uploading audio file using DLL")
        audio_ptr = L1API::BII_Audio_File_Param.new
        audio_ptr[:szFilename] = path
        audio_ptr[:iVolumeLevel] = vol
        audio_ptr[:bDefaultFile] = file_type
        res = L1API.upload_audio(dir,audio_ptr)
        res
      rescue Exception => ex
        raise ex, "Error in uploading audio file through DLL!\n#{ex.message}", ex.backtrace
      end
    end

  end
end