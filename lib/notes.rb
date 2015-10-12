module MA1000AutomationTool
  module Notes
    #Predefined summary remarks
    L1_NEG_FAILURE = "NOTE: This is a negative test for one of the parameters in current serial command and is expected failure on L1 4G device."
    L1_DOC_FAILURE = "NOTE: Behaviour of this serial command is not as per the document and is expected failure on L1 4G device."
    L1_TEST_PRECONDITION = "NOTE: This test case requires special test setup as pre-condition."
    L1_CMD_NOTSUPPORTED = "NOTE: This serial command is not supported on current device type. Support is planned for Ma1000 device."
    OTHER_THAN_ETHERNET = "NOTE: This test interferes with ethernet network communication parameters, hence it is executed only over other than ethernet channel."
    OTHER_THAN_WIRELESS = "NOTE: This test interferes with wireless network communication parameters, hence it is executed only over other than wireless channel."
    OTHER_THAN_SERIAL = "NOTE: This test interferes with serial communication parameters, hence it is executed only over other than serial channel."
    NA_FOR_ETHERNET = "NOTE: This test is only valid for device communicated over serial channel, hence it is omitted over ethernet channel."
    NO_FAKE_FINGER = "NOTE: Fake finger is not identified by current serial command, hence physical finger is required to placed on sensor."
    ONLY_RS485_RS422 = "NOTE: This test is valid only for device communicated over RS485 or RS422 channel."
    ONLY_RS485 = "NOTE: This test is valid only for device communicated over RS485 channel."
    ONLY_RS232 = "NOTE: This test is valid only for device communicated over RS232 channel."
    ONLY_RS422 = "NOTE: This test is valid only for device communicated over RS422 channel."
    ONLY_USB = "NOTE: This test is valid only for device communicated over USB channel."
    ONLY_CBI = "NOTE: This test is valid only for device which has CBI sensor"
    ONLY_WIRED_ETHERNET = "NOTE: This test is valid only for device communicated over Wired Ethernet channel."
    ONLY_WIRELESS = "NOTE: This test is valid only for device communicated over Wireless channel."
    ONLY_ETHERNET = "NOTE: This test is valid only for device communicated over Ethernet channel."
    ONLY_SERIAL = "NOTE: This test is valid only for device communicated over Serial channel."
    ONLY_SEARCHING = "NOTE: This test is valid only when device is in searching (1:N Identification) mode."
    ONLY_NON_SEARCHING = "NOTE: This test is valid only when device is in non-searching (1:1 Authentication) mode."
    ONLY_MIFARE = "NOTE: This test is valid only for device/terminal with MIFARE card reader support."
    ONLY_ICLASS = "NOTE: This test is valid only for device/terminal with iCLASS card reader support."
    ONLY_PROX = "NOTE: This test is valid only for device/terminal with PROX card reader support."
    MA500_EXP_FAILURE = "NOTE: Behaviour of this distant command is not as per the document and is expected failure on MA500 device."
    MA500_NEG_FAILURE = "NOTE: This is a negative test for one of the parameters in current ILV command and is expected failure on 500 device."
  end
end