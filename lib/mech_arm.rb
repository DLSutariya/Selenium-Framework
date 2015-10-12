module MA1000AutomationTool
  class MechArmControl

    #Constants
    FULL_ROTATION = 3200
    CARD_DEG = -45
    CARD_DUR = 200
    #Stepper Motor 1 or 2
    CARD_MOTOR = 1
    def self.open_conn

      max_retry = 5
      #Reset trial counter
      trial = 1
      com_port = $test_config.get("MechanicalArmController.ComPort").to_s
      begin
      #Reset retry flag
        to_retry = false
        #Open serial port
        @@ser_port = SerialPort.new("COM" + com_port, 115200)
      rescue Exception => ex
        $test_logger.log_e("Error while opening port for mechanical arm controller!!", ex)
        case ex
        when Errno::EACCES, Errno::ENOENT
          if trial >= max_retry
          to_retry = false
          else
            $test_logger.log "    Cannot connect to mechanical arm controller for trial '#{trial}/#{max_retry}', retrying in 5 sec...", true
            $test_logger.log_e "Connection error!", ex
            to_retry = true
            trial += 1
            sleep 5
          end
        end
      end while to_retry

      #Set com port read timeout as 2 seconds
      @@ser_port.read_timeout = 1000

    end

    def self.close_conn

      if @@ser_port
        #Motor off
        motor_off
      @@ser_port.close
      end

      @@ser_port = nil

    end
    
    def self.flashcard(card_no, delay, times=1)
      
      $test_logger.log("Flash card '#{card_no}' for #{times} times ")
      
      times.times{
        flashcard_once(card_no, delay)
        
        sleep delay
      }
      
    end

    def self.flashcard_once(card_no, delay)

      #Open connection
      open_conn

      begin

        if (card_no == 0)
          angle = -CARD_DEG
          duration = CARD_DUR
        else
          
          if card_no == 1 || card_no == 2
            angle = CARD_DEG * card_no + (card_no - 1) * CARD_DEG  
          elsif card_no == 3 || card_no == 4
            card_no = 5 - card_no  
            angle = -(CARD_DEG * card_no + (card_no - 1) * CARD_DEG)
          end
                    
          duration = CARD_DUR * card_no + (card_no - 1) * CARD_DUR
        end
        
        axis = get_axis_from_angle(angle)
        
        $test_logger.log("Flash card '#{card_no}' time(s) (Duration= #{duration} ms, angle= #{angle} degree, axis= #{axis} , delay= #{delay} ms)...")
        if CARD_MOTOR == 2
          cmdStr1 = "SM,#{duration},0,#{axis}"
          cmdStr2 = "SM,#{duration},0,#{-axis}"
        elsif CARD_MOTOR == 1
          cmdStr1 = "SM,#{duration},#{axis},0"
          cmdStr2 = "SM,#{duration},#{-axis},0"
        end

        #for i in 1..itera do
        #$test_logger.log("Card iteration: #{(i + 1)} / #{itera}")
        sendCommand(cmdStr1)
        if (card_no != 0)

          sleep(duration/1000)

          1.upto(delay*2) do
            sleep(0.5)
            break if Thread.current[:to_exit]
          end

          sendCommand(cmdStr2)
          sleep((duration/1000) + 1)
        #Motor off
        #motor_off
        end
      rescue Exception=>ex
        $test_logger.log_e("Error in flash card!",ex)
      ensure
        close_conn
      end

    end

    def self.motor_off
      $test_logger.log("Sending motor off!")
      sendCommand("EM,0,0")
    end

    def self.sendCommand(commandStr)

      raise "Connection not open!" if !@@ser_port

      $test_logger.log("\nSending command: #{commandStr} ...")

      @@ser_port.write(commandStr)
      @@ser_port.write("\n")

      $test_logger.log("Command sent!")

      resp_str = "READ ERR!"
      begin
      #ser_port.read_timeout = 1000
        resp_str = read(@@ser_port)
      rescue Exception => ex
        $test_logger.log_e("Error while reading data from controller!!", ex)
      end
      if resp_str != "OK"
        raise "Command Response not ok: #{resp_str}"
      end
      resp_str
    end

    def self.get_angle_from_axis(axis)
      angle = 0
      angle = 360 * axis / FULL_ROTATION;
      angle
    end

    def self.get_axis_from_angle(angle)
      fullRotation = 3200
      axis = 0
      axis = fullRotation * angle / 360;
      axis
    end

    def self.read(ser_port)
      str = ""
      while true
        c = ser_port.read(2)
        if c == "\r\n"
        break
        end
        str << c.to_s
      end
      str
    end
  end
end

