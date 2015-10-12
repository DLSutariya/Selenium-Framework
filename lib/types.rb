module MA1000AutomationTool

  #ProtocolMode Type Enum
  module ProtocolMode
    UNKNOWN = 0
    L1 = 1
    MA500 = 2
    MA1000 = 3
  end

  #Test script type
  module TestType
    UNKNOWN = 0
    TDRIVER = 1
    ILV = 2
    SERIALCMD = 3
    THRIFT = 4
    SAMPLE = 5
  end

  #Test result
  module TestResult
    PASS = 1
    FAIL = 2
    ERROR = 4
    OMIT = 8
    PENDING = 16
    NA = 32
    EXP_FAIL = 64
    BLOCKED = 128
    PARTIAL = 256
    UNKNOWN = 512
  end

  #Test execution run mode
  module RunMode
    UNKNOWN = 0
    ALL = 1
    SCRIPT = 2
    LIST = 3
  end

  #Test communication type
  module CommType
    UNKNOWN = 0
    ETHERNET = 1
    SERIAL = 2
  end

  #Device communication type
  module DeviceCommType
    UNKNOWN = 0
    ETH_WIRED = 1
    ETH_WIFI = 2
    USB = 3
    RS232 = 4
    RS485 = 5
    RS422 = 6
  end

  #Sensor types
  module SensorType
    UNKNOWN = 0
    SECUGEN = 1
    UPEK1 = 2
    UPEK2 = 3
    VENUS = 4
    MSO = 5
    MSI = 6
    CBI = 7
    FVP = 8
  end

  #Card reader types
  module CardReaderType
    UNKNOWN = 0
    NONE = 1
    MIFARE = 2
    ICLASS = 3
    PROX = 4
  end

  #Device mode
  module DeviceMode
    UNKNOWN = 0
    VERIFY = 1
    IDENTIFY = 2
  end

  #Get comm type name
  def protocol_mode_name(protocol_mode)
    r = ""
    case protocol_mode
    when ProtocolMode::UNKNOWN
      r = "UNKNOWN"
    when ProtocolMode::L1
      r = "L1 legacy"
    when ProtocolMode::MA500
      r = "MA500 legacy"
    when ProtocolMode::MA1000
      r = "MA1000"
    end
    r
  end

  #Get result name from type
  def test_result_name(test_result)
    r = ""
    case test_result
    when TestResult::PASS
      r = "PASS"
    when TestResult::FAIL
      r = "FAIL"
    when TestResult::ERROR
      r = "ERROR"
    when TestResult::OMIT
      r = "OMIT"
    when TestResult::NA
      r = "NOT_APPLICABLE"
    when TestResult::PENDING
      r = "PENDING"
    when TestResult::EXP_FAIL
      r = "EXPECTED_FAILURE"
    when TestResult::BLOCKED
      r = "BLOCKED"
    when TestResult::PARTIAL
      r = "PARTIAL"
    when TestResult::UNKNOWN
      r = "UNKNOWN"
    end
    r
  end

  #Get test type name
  def test_type_name(test_type)
    r = ""
    case test_type
    when TestType::TDRIVER
      r = "Testability Driver"
    when TestType::ILV
      r = "Morpho ILV Command"
    when TestType::SERIALCMD
      r = "L1 4G Serial Command"
    when TestType::THRIFT
      r = "Morpho THRIFT Command"
    when TestType::UNKNOWN
      r = "Unknown"
    else
    r = "N/A"
    end
    r
  end

  #Get run mode name from type
  def run_mode_name(run_mode)
    r = ""
    case run_mode
    when RunMode::UNKNOWN
      r = "UNKNOWN"
    when RunMode::ALL
      r = "ALL TEST SCRIPTS"
    when RunMode::LIST
      r = "SCRIPT LIST FILE"
    when RunMode::SCRIPT
      r = "SCRIPT FILE"
    end
    r
  end

  #Get comm type name
  def comm_type_name(comm_type)
    r = ""
    case comm_type
    when CommType::UNKNOWN
      r = "UNKNOWN"
    when CommType::ETHERNET
      r = "ethernet"
    when CommType::SERIAL
      r = "serial"
    end
    r
  end

  #Get device comm type name
  def device_comm_type_name(device_comm_type)
    r = ""
    case device_comm_type
    when DeviceCommType::UNKNOWN
      r = "UNKNOWN"
    when DeviceCommType::ETH_WIRED
      r = "Wired Ethernet"
    when DeviceCommType::ETH_WIFI
      r = "WiFi"
    when DeviceCommType::USB
      r = "Serial USB/AUX"
    when DeviceCommType::RS232
      r = "Serial RS232"
    when DeviceCommType::RS485
      r = "Serial RS485"
    when DeviceCommType::RS422
      r = "Serial RS422"
    end
    r
  end

  #Get sensor type name
  def sensor_type_name(sensor_type)
    r = ""
    case sensor_type
    when SensorType::SECUGEN
      r = "Secugen"
    when SensorType::UPEK1
      r = "UPEK1"
    when SensorType::UPEK2
      r = "UPEK2"
    when SensorType::VENUS
      r = "Lumidigm Venus"
    when SensorType::MSO
      r = "MSO"
    when SensorType::MSI
      r = "MSI"
    when SensorType::CBI
      r = "CBI"
    when SensorType::FVP
      r = "FVP"
    else
    r = "UNKNOWN"
    end
    r
  end

  #Get card reader type name
  def card_reader_type_name(reader_type)
    r = ""
    case reader_type
    when CardReaderType::NONE
      r = "None"
    when CardReaderType::MIFARE
      r = "MIFARE"
    when CardReaderType::ICLASS
      r = "iCLASS"
    when CardReaderType::PROX
      r = "PROX"
    else
    r = "UNKNOWN"
    end
    r
  end

  #Get device mode name
  def device_mode_name(device_mode)
    r = ""
    case device_mode
    when DeviceMode::UNKNOWN
      r = "UNKNOWN"
    when DeviceMode::VERIFY
      r = "Verify (Non-Searching mode)"
    when DeviceMode::IDENTIFY
      r = "Identify (Searching mode)"
    end
    r
  end

end