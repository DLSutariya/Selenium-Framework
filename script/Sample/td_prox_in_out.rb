require 'tdriver'

#include TDriverVerify
class TDProxInOut < BaseTest
  class << self
    def startup
      super(TestType::TDRIVER)
      $test_logger.log("TD_ProxTAInOut startup")
    end

    def shutdown
      $test_logger.log("TD_ProxTAInOut shutdown")
      super
    end
  end

  def setup
    super

    #Connect to QTTAS running on device
    @sut = TDriver.sut(:Id => TDElements::SUT_ID)
    @app = @sut.application(:name => TDElements::APP_NAME)

    #Close all open dialogs, if any
    $test_logger.log("Close all open dialogs, if any")
    $form_obj = @app.children({},false)
    $form_obj.each_with_index {|x, y|
      if x.name != TDElements::FORM_START
        $test_logger.log("#{x.name} => #{y}")
        x.call_method(TDElements::FUNC_CLOSE);
      end
    }
  end

  def teardown
    #@app.close
    super
  end

  def test_proxinout

    # Login to LCD Touch Screen
    $test_logger.log "Login to LCD touch screen and erase all transaction logs", true
    @app.QToolButton( :name=>TDElements::BTN_UNLOCK ).tap
    @app.QPushButton( :name=>TDElements::BTN_0 ).tap
    @app.QPushButton( :name=>TDElements::BTN_0 ).tap
    @app.QPushButton( :name=>TDElements::BTN_0 ).tap
    @app.QPushButton( :name=>TDElements::BTN_0 ).tap
    @app.QPushButton( :name=>TDElements::BTN_OK ).tap
    sleep(1)

    # Click on system menu
    @app.QToolButton( :name=>'toolButtonSys' ).tap
    sleep(0.5)

    #Verify Menu option transaction log exists
    verify(){@app.BytFrmSystemMenu( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem(:text => 'Transaction Log')}

    #Click on Menu Option transaction log item
    @app.BytFrmSystemMenu( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem(:text =>'Transaction Log').select
    sleep(0.5)

    #Click on Erase Log (All) item
    @app.BytFrmTLogMenu( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem( :text => 'Erase Log (All)' ).select
    sleep(0.5)

    #Click on Erase confirmation ok button
    @app.BytMsgBox( :name => 'FrmMsgBox' ).QLabel( :name => 'cmdMsgOK' ).tap
    sleep(0.5)

    #Wait till log erased message box is present
    @app.BytMsgBox( :name => 'FrmMsgBox' ).wait_child({:type=>'QLabel',:text => 'Log erased'} )

    #Click on Erase success message box ok button
    @app.BytMsgBox( :name => 'FrmMsgBox' ).QLabel( :name => 'cmdMsgOK' ).tap

    #Click Back buttons to navigate to home screen
    @app.BytFrmTLogMenu( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnBack' ).tap
    @app.BytFrmSystemMenu( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnBack' ).tap
    @app.BytTouchLabel( :name => 'btnBack' ).tap

    #Flash PROX card using robotic arm
    $test_logger.log "Flash PROX card on reader for T&A IN", true
    #system("ParallelPortController.exe FLASH1 1000")
    Common.shell_execute("ParallelPortController.exe", "FLASH1 1000")
    sleep(1)

    #Click on T&A F1 button
    $test_logger.log "Press function key F1(IN) for T&A mode", true
    @app.BytFrmTNA( :name=>'FrmTNA').BytTouchLabel( :name=>'lblF1' ).tap
    @app.wait_child({:type=>'BytFrmLcdApi',:name => 'FrmLcdApi'})
    accep_IN =@app.BytFrmLcdApi( :name => 'FrmLcdApi' ).BytTouchLabel( :name => 'lblLcdApiTxt' )
    accep_IN_str =accep_IN.attribute('text')
    accep_IN_str[-8..-1]=""

    verify_equal("Accepted : 234\nIN\n", 1,"Accepted message not found for Template Id 234") {accep_IN_str}
    sleep(5)

    #Flash PROX card again using robotic arm
    $test_logger.log "Flash PROX card on reader for T&A OUT", true
    #system("ParallelPortController.exe FLASH1 1000")
    Common::ShellExecute("ParallelPortController.exe", "FLASH1 1000")
    sleep(1)

    #Click on T&A F2 button
    $test_logger.log "Press function key F2(OUT) for T&A mode", true
    @app.BytFrmTNA( :name=>'FrmTNA').BytTouchLabel( :name=>'lblF2' ).tap
    @app.wait_child({:type=>'BytFrmLcdApi',:name => 'FrmLcdApi'})
    accep_OUT =@app.BytFrmLcdApi( :name => 'FrmLcdApi' ).BytTouchLabel( :name => 'lblLcdApiTxt' )
    accep_OUT_str =accep_OUT.attribute('text')
    accep_OUT_str[-8..-1]=""
    #$test_logger.log accep_OUT_str
    verify_equal("Accepted : 234\nOUT\n", 1,"Accepted message not found for Template Id 234") {accep_OUT_str}
    sleep(5)

    # Login to LCD Touch Screen
    $test_logger.log "Login to LCD touch screen and verify transaction logs", true
    @app.QToolButton( :name=>'toolBtnUnlock' ).tap
    sleep(0.5)
    @app.QPushButton( :name=>'btn_0' ).tap
    @app.QPushButton( :name=>'btn_0' ).tap
    @app.QPushButton( :name=>'btn_0' ).tap
    @app.QPushButton( :name=>'btn_0' ).tap
    @app.QPushButton( :name=>'btn_ok' ).tap

    sleep(1)

    # Click on system menu
    @app.QToolButton( :name=>'toolButtonSys' ).tap

    sleep(0.5)
    @app.BytFrmSystemMenu( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem(:text =>'Transaction Log').select
    sleep(0.5)

    #Click on View Log
    @app.BytFrmTLogMenu( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnOk' ).tap

    #Click next
    @app.BytFrmTlogInfoFilter( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnOk' ).tap

    #uncheck index filter
    @app.BytFrmTlogDisplayFilter( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem( :text => 'Index' ).select

    #uncheck date filter
    @app.BytFrmTlogDisplayFilter( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem( :text => 'Date' ).select

    @sut.press_key(MobyCommand::KeySequence.new(:kDown).times!(7))

    #check T & A Message
    @app.BytFrmTlogDisplayFilter( :name => 'FrmListWindow' ).QWidget( :name => 'layoutWidget' ).BytTouchList( :name => 'lstWidget' ).QListWidgetItem( :text => 'T & A Message' ).select

    #Click next
    @app.BytFrmTlogDisplayFilter( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnOk' ).tap

    #Verify T&A transaction logs are displayed

    #Verify Template Id 234 exists for T&A IN entry
    @app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[12].select
    test_234_IN =@app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[12]
    verify_equal('234', 1,"Template Id 234 is not found for T&A IN entry") {test_234_IN.attribute('text')}
    #sleep(1)

    #Verify T&A Action F1 exists for IN entry
    @app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[15].select
    test_234_F1 =@app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[15]
    verify_equal('F1', 1,"T&A Action F1 is not found for IN entry") {test_234_F1.attribute('text')}
    #sleep(1)

    #Verify Template Id 234 exists for T&A OUT entry
    @app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[20].select
    test_234_OUT =@app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[20]
    verify_equal('234', 1,"Template Id 234 is not found for T&A OUT entry") {test_234_OUT.attribute('text')}
    #sleep(1)

    #Verify T&A Action F2 exists for IN entry
    @app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[23].select
    test_234_F2 =@app.BytFrmViewTLog( :name => 'FrmViewTLog' ).QWidget( :name => 'layoutWidget' ).BytTouchTableView( :name => 'tableWidget').children(:type=>'QTableWidgetItem')[23]
    verify_equal('F2', 1,"T&A Action F2 is not found for IN entry") {test_234_F2.attribute('text')}
    #sleep(1)

    #Click Back buttons to navigate to home screen
    @app.BytFrmViewTLog( :name => 'FrmViewTLog' ).BytTouchLabel( :name => 'btnBack' ).tap
    @app.BytFrmTLogMenu( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnBack' ).tap
    @app.BytFrmSystemMenu( :name => 'FrmListWindow' ).QWidget( :name => 'verticalLayoutWidget' ).BytTouchLabel( :name => 'btnBack' ).tap
    @app.BytTouchLabel( :name => 'btnBack' ).tap

  end
end