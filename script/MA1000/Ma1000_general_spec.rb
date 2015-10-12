require 'rspec'
require 'selenium-webdriver'
require_relative '../../lib/base_test'


describe 'Terminal Information' do

  before(:each) do
    @driver = Selenium::WebDriver.for :firefox
    @base_url = "http://10.102.3.146/"
    @accept_next_alert = true
    @driver.manage.timeouts.implicit_wait = 30
  end

  after(:each) do
    @driver.quit
  end

  it 'should check terminal discription' do

    @driver.get(@base_url + "/")
    @driver.find_element(:id, "password").clear
    @driver.find_element(:id, "password").send_keys "12345"
    @driver.find_element(:xpath, "//*[@id='loginform']/table/tbody/tr[4]/td/input").click

  end
end