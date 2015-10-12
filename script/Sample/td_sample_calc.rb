require 'tdriver'

class TDSampleCalc < BaseTest
  class << self
    def startup
      super(TestType::TDRIVER)
      $test_logger.log("Demo Calc startup")
      $test_logger.log("Pre-Conditions:
      1. Testability demo application named 'calculator' and QTTAS (QT Testability Server) must be running on the target machine
      2. QT System Under Test ID must be configured in file 'c:\\tdriver\\tdriver_parameters.xml' as per below:
         <sut id=\"sut_qt\" template=\"qt\">
             <parameter name=\"qttas_server_ip\" value=\"localhost\" />
         </sut>
         NOTE: 'localhost' to be replaced with IP address of target machine where QTTAS is running.", true)
    end

    def shutdown
      $test_logger.log("Demo Calc shutdown")
      super
    end
  end

  def setup
    super

    #Connect to QTTAS running on host machine
    @sut = TDriver.sut(:Id => "sut_qt")
    @app = @sut.application(:name => "calculator")

  end

  def teardown
    #@app.close
    super
  end

  def test_sum

    @app.Button( :name => 'clearAllButton' ).tap
    display = @app.QLineEdit( :name => 'display' ).attribute('text')
    verify_equal("0", 1,"Empty display mismatch!") {display}

    @app.Button( :name=>'fourButton' ).tap

    display = @app.QLineEdit( :name => 'display' ).attribute('text')
    verify_equal("4", 1,"Display mismatch with 4!") {display}

    @app.Button( :name=>'plusButton' ).tap
    @app.Button( :name=>'oneButton' ).tap
    display = @app.QLineEdit( :name => 'display' ).attribute('text')
    verify_equal("1", 1,"Display mismatch with 1!") {display}

    @app.Button( :name=>'equalButton' ).tap
    display = @app.QLineEdit( :name => 'display' ).attribute('text')
    verify_equal("5", 1,"Display mismatch for result!") {display}

  end

end