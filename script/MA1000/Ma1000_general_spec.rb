require 'rspec'
require 'selenium-webdriver'



describe 'Terminal Information' do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox

    # maximize window screen
    @driver.manage.window.maximize

    # URL for the Webserver
    @base_url = "http://10.102.3.146/"

    @accept_next_alert = true

    @driver.manage.timeouts.implicit_wait = 30
  end

  after(:each) do
    @driver.quit
  end

  it 'Check Valid Webserver Tital page valid name' do

    @driver.get(@base_url + "/")

    #clear password field using Id
    @driver.find_element(:id, "password").clear

    #send String to password field usig Id
    @driver.find_element(:id, "password").send_keys "12345"

    # Click on login button using Xpath
    @driver.find_element(:xpath, "//*[@id='loginform']/table/tbody/tr[4]/td/input").click
    stringTitle = "Safran Morpho"

    puts stringTitle.should match(@driver.title)

  end

  it 'Check InValid Webserver Tital page valid name' do

    @driver.get(@base_url + "/")

    #clear password field using Id
    @driver.find_element(:id, "password").clear

    #send String to password field usig Id
    @driver.find_element(:id, "password").send_keys "12345"

    # Click on login button using Xpath
    @driver.find_element(:xpath, "//*[@id='loginform']/table/tbody/tr[4]/td/input").click
    stringTitle = "test"

    puts stringTitle.should_not match(@driver.title)

  end


end