class MA500CCWritePKGEN < BaseTest
  class << self
    def startup
      super(TestType::ILV)
      $test_logger.log("MA500 CC Write PKGEN Tests startup")      
    end

    def shutdown
      #Close cmd processors
      $test_logger.log("MA500 CC CC Write PKGEN Tests shutdown")
      super
    end
  end

  def setup
    super
    $test_logger.log("MA500 CC CC Write PKGEN Tests setup")    
  end

  def teardown
    $test_logger.log("MA500 CC CC Write PKGEN Tests teardown")
    super
  end

  def test_cc_cmd_auth_valid_pk_lite

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_lite = ILVMessage.read_file_data(Resource.get_path("finger_1.pklite"))
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", "0x61")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values", "Minutiae", pk_lite,"hex")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "WriteSC")

  end

  def test_cc_cmd_auth_valid_pk_comp_without_pkgen

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    ilv_req.remove_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/")
    
    pk_v2_template = ILVMessage.read_file_data(Resource.get_path("finger_1.pkc"))
    pk_v2_template1 = ILVMessage.read_file_data(Resource.get_path("finger_2.pkc"))
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "ReferenceTemplate1", "0x30")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/ReferenceTemplate1/Values", "Minutiae", pk_v2_template,"hex")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "ReferenceTemplate2", "0x31")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/ReferenceTemplate2/Values", "Minutiae", pk_v2_template1,"hex")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "WriteSC")

  end

  def test_cc_cmd_auth_valid_pk_comp

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_v2_template = ILVMessage.read_file_data(Resource.get_path("finger_1.pkc"))
    pk_v2_template1 = ILVMessage.read_file_data(Resource.get_path("finger_2.pkc"))
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::PK_COMP_V2)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values", "Minutiae", pk_v2_template,"hex")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "BioTemp1", "0x08")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp1/Values", "ReferenceTemplate1", MA500::PK_COMP_V2)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp1/Values/ReferenceTemplate1/Values", "Minutiae", pk_v2_template1,"hex")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "WriteSC")

  end

  def test_cc_cmd_auth_valid_pk_comp_norm_norm

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_v2_template = ILVMessage.read_file_data(Resource.get_path("finger_1.pkc"))
    pk_v2_template1 = ILVMessage.read_file_data(Resource.get_path("finger_2.pkc"))
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_PK_COMP_NORM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values", "Minutiae", pk_v2_template,"hex")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "BioTemp1", "0x08")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp1/Values", "ReferenceTemplate1", MA500::ID_PK_COMP_NORM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp1/Values/ReferenceTemplate1/Values", "Minutiae", pk_v2_template1,"hex")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "WriteSC")

  end

  def test_cc_cmd_auth_valid_template_pk_mat

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_mat = ILVMessage.read_file_data(Resource.get_path("finger_1.pkmat"))
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_PK_MAT)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values", "Minutiae", pk_mat, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/Minutiae", ILVMessage::SIZE_ATTR, 512)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")

  end

  def test_cc_cmd_auth_valid_template_pk_mat_norm

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_mat = ILVMessage.read_file_data(Resource.get_path("finger_1.pkmat"))
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_PK_MAT_NORM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values", "Minutiae", pk_mat, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/Minutiae", ILVMessage::SIZE_ATTR, 512)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")

  end
  
  def test_cc_cmd_auth_valid_template_pk_fvp

    #not_applicable "NOTE: This test is executed only on terminal which have FV sensor" if $sensor_type == SensorType::MSO
    
    #set_fake_finger @@cmd_proc, true

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_fvp_1 = ILVMessage.read_file_data(Resource.get_path("1_finger_1.fvp"))
    pk_fvp_2 = ILVMessage.read_file_data(Resource.get_path("1_finger_2.fvp"))

#    pk_fvp = ILVMessage.read_file_data(Resource.get_path("1_finger_1.fvp"))
    
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::PK_FVP)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values", "Minutiae", pk_fvp_1)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "BioTemp1", "0x08")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp1/Values", "ReferenceTemplate1", MA500::PK_FVP)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp1/Values/ReferenceTemplate1/Values", "Minutiae", pk_fvp_2)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")

  end
  
  def test_cc_cmd_auth_valid_template_pk_ansi

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)

    ansi = ILVMessage.read_file_data(Resource.get_path("finger_1.ansi"))
    
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_ISO_PK)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_PARAM", MA500::ID_ISO_PK_PARAM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "FingerSelection", "0x0")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "SelectAllFinger", "0x0")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_DATA_ANSI_378", MA500::ID_ISO_PK_DATA_ANSI_378)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ANSI_378/Values", "Ansi378Template", ansi, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ANSI_378/Values/Ansi378Template", ILVMessage::SIZE_ATTR, ansi.size/2)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")

  end
  
  def test_cc_cmd_auth_valid_template_iso_pk_data_minex

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_iso_minex = ILVMessage.read_file_data(Resource.get_path("finger_1.minex_a"))
    
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_ISO_PK)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_PARAM", MA500::ID_ISO_PK_PARAM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "FingerSelection", "0x0")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "SelectAllFinger", "0x0")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_DATA_MINEX_A", MA500::ID_ISO_PK_DATA_MINEX_A)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_MINEX_A/Values", "MinexATemplate", pk_iso_minex, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_MINEX_A/Values/MinexATemplate", ILVMessage::SIZE_ATTR, pk_iso_minex.size/2)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
        
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")
    
  end
 
  def test_cc_cmd_auth_valid_template_iso_fmr

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_iso_fmr = ILVMessage.read_file_data(Resource.get_path("finger_1.iso19794_2_fmr"))
    
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_ISO_PK)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_PARAM", MA500::ID_ISO_PK_PARAM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "FingerSelection", "0x0")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "SelectAllFinger", "0x0")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_DATA_ISO_FMR", MA500::ID_ISO_PK_DATA_ISO_FMR)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ISO_FMR/Values", "IsoFmrTemplate", pk_iso_fmr, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ISO_FMR/Values/IsoFmrTemplate", ILVMessage::SIZE_ATTR, pk_iso_fmr.size/2)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")
   
  end
  
  def test_cc_cmd_auth_valid_template_iso_fmc_ns
   
    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_iso_fmc_ns = ILVMessage.read_file_data(Resource.get_path("finger_1.iso19794_2_fmc_ns"))
    
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_ISO_PK)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_PARAM", MA500::ID_ISO_PK_PARAM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "FingerSelection", "0x0")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "SelectAllFinger", "0x0")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_DATA_ISO_FMC_NS", MA500::ISO_PK_DATA_ISO_FMC_NS)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ISO_FMC_NS/Values", "IsoFmrTemplate", pk_iso_fmc_ns, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ISO_FMC_NS/Values/IsoFmrTemplate", ILVMessage::SIZE_ATTR, pk_iso_fmc_ns.size/2)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")
   
  end
  
  def test_cc_cmd_auth_valid_template_iso_fmc_cs

    #Set ILV command XML file name
    #Xml file exists at <Framework Root Folder>\data
    xml_file_name = "write_sc_pkgen.xml"

    #Create ILV request command from xml file
    ilv_req = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REQ_TAG)
    
    pk_iso_fmc_cs = ILVMessage.read_file_data(Resource.get_path("finger_1.iso19794_2_fmc_cs"))
   
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values", "ReferenceTemplate1", MA500::ID_ISO_PK)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_PARAM", MA500::ID_ISO_PK_PARAM)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "FingerSelection", "0x0")
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_PARAM/Values", "SelectAllFinger", "0x0")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/", "ISO_PK_DATA_ISO_FMC_CS", MA500::ISO_PK_DATA_ISO_FMC_CS)
    ilv_req.add_tag_node("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ISO_FMC_CS/Values", "IsoFmrTemplate", pk_iso_fmc_cs, "hex")
    ilv_req.set_tag_attr("//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/BioTemp/Values/ReferenceTemplate1/Values/ISO_PK_DATA_ISO_FMC_CS/Values/IsoFmrTemplate", ILVMessage::SIZE_ATTR, pk_iso_fmc_cs.size/2)
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/", "CardMode", "0x35")
    create_add_ilv(ilv_req, "//Values/Sub_CMD_Write/Values/ContactlessProfile/Values/Data/Values/CardMode/Values", "BioCheck", "0x02")
    
    #Create expected ILV reply command from xml file
    expected_rep = ILVMessage.new(:xml_file_name => xml_file_name,
    :xml_ilv_tag => ILVMessage::REP_TAG)

    #Send ILV cmd to terminal and Receive ILV cmd from terminal
    actual_rep = @@cmd_proc.send_recv_ilv_msg(ilv_req,expected_rep)

    #Assert Whole Command
    @@cmd_proc.assert_command(expected_rep, actual_rep, "Write_sc")

  end
   
end
