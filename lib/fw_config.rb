module MA1000AutomationTool
  class FWConfig

    #Framework folder constants
    SCRIPT_FOLDER = "script"
    LIB_FOLDER = "lib"
    DATA_FOLDER = "data"
    CONFIG_FOLDER = "config"
    USER_FOLDER = "user"
    RES_FOLDER = "res"
    THRIFT_FILE_FOLDER = "ma1000_thrift"
    THRIFT_CLIENT_FOLDER = "client"
    L1_LEGACY_FOLDER = "L1 legacy"
    MA500_LEGACY_FOLDER = "MA500 legacy"
    MA1000_FOLDER = "MA1000"
    XML_FOLDER = "XML"

    #Log file constants
    LOG_FOLDER = "log"
    RUN_FOLDER_PREFIX = "Run"
    DEBUG_LOG_PREFIX = "Debug"
    DEBUG_LOG_EXT = ".log"
    SUMMARY_LOG_PREFIX = "Summary"
    SUMMARY_LOG_EXT = ".csv"
    RESULT_LOG_EXT = ".log"
    HTML_LOG_PREFIX = "HTML"
    HTML_LOG_EXT = ".html"
    HTML_LOG_TEMPLATE = "result.html"
    TL_LOG_PREFIX = "TL"
    TL_LOG_EXT = ".xml"
    DD_LOG_PREFIX = "DataDriven"
    DD_LOG_EXT = ".csv"

    #Test config constants
    DEFAULT_TEST_CONFIG = "default.yml"

    #Test link constants
    TESTLINK_MAPPING_FILE = "testlink_mapping.csv"
    TESTLINK_PROJECT_PREFIX = "MA1K-"

    #Jira constants
    JIRA_ID_PREFIX = "MA5G_SW_PUBLIC-"
    #JIRA_URL = "https://extranet-einfochips.morpho.com/browse/,DanaInfo=jira.srv.sec.safran+#{JIRA_ID_PREFIX}"

    #Testability constants
    SUT_ID = "sut_id_auto_fw"
    GUI_APP_NAME = "MALite_GUI"
    TD_PARAMS_XML = "tdriver_parameters.xml"

    #Framework config constants
    PER_DAY_RUN_FOLDER = true
    
    #Framework version constants
    FRAMEWORK_VERSION = "0.5"
    
    #Computed constants
    ROOT_FOLDER_PATH = File.expand_path(Dir.pwd)
    SCRIPT_FOLDER_PATH = File.join(ROOT_FOLDER_PATH, SCRIPT_FOLDER)
    DATA_FOLDER_PATH = File.join(ROOT_FOLDER_PATH, DATA_FOLDER)
    RES_FOLDER_PATH = File.join(ROOT_FOLDER_PATH, RES_FOLDER)
    LIB_FOLDER_PATH = File.join(ROOT_FOLDER_PATH, LIB_FOLDER)
    HTML_LOG_TEM_PATH = File.join(RES_FOLDER_PATH, HTML_LOG_TEMPLATE)
    TESTLINK_MAPPING_PATH = File.join(RES_FOLDER_PATH, TESTLINK_MAPPING_FILE)

  end
end