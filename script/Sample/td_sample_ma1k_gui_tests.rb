require 'tdriver'

#include TDriverVerify
class TDSampleMA1KGuiTests < BaseTest
  class << self
    def startup
      super(TestType::TDRIVER)
      $test_logger.log("MA1K Gui startup")
    end

    def shutdown
      $test_logger.log("MA1K Gui shutdown")
      super
    end
  end

  def setup
    super

    #Connect to QTTAS running on device
    @sut = TDriver.sut(:Id => TDElements::SUT_ID)
    @app = @sut.application(:name => TDElements::APP_NAME)

  #Close all open dialogs, if any
  # $test_logger.log("Close all open dialogs, if any", true)
  # $form_obj = @app.children({},false)
  # $form_obj.each_with_index {|x, y|
  # if x.name != TDElements::FORM_START
  # $test_logger.log("#{x.name} => #{y}")
  # x.call_method(TDElements::FUNC_CLOSE);
  # end
  # }
  end

  def teardown
    #@app.close
    super
  end

  def test_device_info

    $test_logger.log "Login to Information Menu", true

    # Select Main menu in LCD
    @app.QToolButton( :name=>'tbt_admin_menu' ).tap

    # Select Information menu in LCD
    @app.QToolButton( :name=>'tbt_info' ).tap

    # Select Device menu in Information menu
    @app.QListWidget( :name => 'list_widget' ).QListWidgetItem(:text =>'Device').select

    #Compare Device Commercial name label
    device_commrcial_label = @app.Dlg_information( :name => 'Dlg_list' ).Dlg_device_info( :name => 'Dlg_list' ).QListWidget( :name => 'list_widget' ).QWidget( :name => 'qt_scrollarea_viewport' ).QLabel(:text => 'Device Commercial Name')
    device_commrcial_value = device_commrcial_label.attribute('text')
    verify_equal("Device Commercial Name", 1,"Device Commercial is mismatch") {device_commrcial_value}

    #Compare Device Commercial name label
    device_description_label = @app.Dlg_information( :name => 'Dlg_list' ).Dlg_device_info( :name => 'Dlg_list' ).QListWidget( :name => 'list_widget' ).QWidget( :name => 'qt_scrollarea_viewport' ).QLabel(:text => 'MA1K')
    device_description_value = device_description_label.attribute('text')
    verify_equal("MA1K", 1,"Device Description name is mismatch") {device_description_value}

    #Click on back button
    @app.Dlg_information( :name => 'Dlg_list' ).Dlg_device_info( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
    @app.Dlg_information( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
    @app.QWidget( :name => 'Dlg_admin_menu' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
  end

  def test_Password_mode_on
    $test_logger.log "Login to Security Menu", true

    # Select Main menu in LCD
    @app.QToolButton( :name=>'tbt_admin_menu' ).tap

    # Select Security menu in LCD
    @app.QToolButton( :name=>'tbt_security' ).tap

    #Select Biometric menu in Security menu
    @app.QListWidget( :name => 'list_widget' ).QListWidgetItem(:text =>'Biometric').select

    #Select Password Mode in Biometric Menu
    @app.Dlg_security( :name => 'Dlg_list' ).Dlg_bio_security( :name => 'Dlg_list' ).QListWidget( :name => 'list_widget' ).QWidget( :name => 'qt_scrollarea_viewport' ).QLabel(:text => 'Password Mode').tap

    #Click on Apply button
    @app.Dlg_security( :name => 'Dlg_list' ).Dlg_bio_security( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_confirm' ).tap
    @app.Dlg_security( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
    @app.QWidget( :name => 'Dlg_admin_menu' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
  end

  def test_TNA_In_Verify
    $test_logger.log "Select Time & Attendence mode", true

    #Select Time & Attendence Mode
    @app.QWidget( :name => 'Dlg_start' ).QWidget( :name => 'layoutWidget' ).QToolButton( :name => 'tbt_tna' ).tap

    #Click on IN#1 button
    @app.Dlg_TNA( :name => 'Dlg_TNA' ).QWidget( :name => 'layoutWidget' ).QPushButton( :name => 'pbt_g1_1' ).tap

    #Click on Apply button
    @app.Dlg_TNA( :name => 'Dlg_TNA' ).QWidget( :name => 'layoutWidget' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
  end

  def test_enter_verify_id
    $test_logger.log "Enter verify id", true

    #Select Verify button
    @app.QWidget( :name => 'Dlg_start' ).QWidget( :name => 'layoutWidget' ).QToolButton( :name => 'tbt_verify' ).tap

    #Enter "345" template id
    @app.QWidget( :name => 'Dlg_input' ).QFrame( :name => 'frame_keypad' ).QPushButton( :name => 'pbt_3' ).tap
    @app.QWidget( :name => 'Dlg_input' ).QFrame( :name => 'frame_keypad' ).QPushButton( :name => 'pbt_4' ).tap
    @app.QWidget( :name => 'Dlg_input' ).QFrame( :name => 'frame_keypad' ).QPushButton( :name => 'pbt_5' ).tap
    @app.QWidget( :name => 'Dlg_input' ).QFrame( :name => 'frame_keypad' ).QPushButton( :name => 'pbt_6' ).tap
    @app.QWidget( :name => 'Dlg_input' ).QFrame( :name => 'frame_keypad' ).QPushButton( :name => 'pbt_backspace' ).tap

    #Click on Apply button
    @app.QWidget( :name => 'Dlg_input' ).QPushButton( :name => 'pbt_ok' ).tap
  end

  def test_change_Login_Mode
    $test_logger.log "Login to Security Menu", true

    # Select Main menu in LCD
    @app.QToolButton( :name=>'tbt_admin_menu' ).tap

    # Select Security menu in LCD
    @app.QToolButton( :name=>'tbt_security' ).tap

    #Select LCD Login options menu in Security menu
    @app.QListWidget( :name => 'list_widget' ).QListWidgetItem(:text => 'LCD Login Options').select

    #Select LCD Login Mode in LCD Login Options
    @app.Dlg_security( :name => 'Dlg_list' ).Dlg_login_security( :name => 'Dlg_list' ).QListWidget( :name => 'list_widget' ).QWidget( :name => 'qt_scrollarea_viewport' ).QLabel(:text => 'LCD Login Mode').tap

    #Select Password Mode in Biometric Menu	and click on Apply button
    @app.Dlg_security( :name => 'Dlg_list' ).Dlg_login_security( :name => 'Dlg_list' ).Dlg_selection( :name => 'Dlg_list' ).QListWidget( :name => 'list_widget' ).QListWidgetItem(:text => 'Used ID + Password').select
    @app.Dlg_security( :name => 'Dlg_list' ).Dlg_login_security( :name => 'Dlg_list' ).Dlg_selection( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_exit' ).tap
    @app.Dlg_security( :name => 'Dlg_list' ).Dlg_login_security( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_confirm' ).tap

    #Return to Main menu
    @app.Dlg_security( :name => 'Dlg_list' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
    @app.QWidget( :name => 'Dlg_admin_menu' ).QFrame( :name => 'frame_bottom' ).QPushButton( :name => 'pbt_back' ).tap
  end

end