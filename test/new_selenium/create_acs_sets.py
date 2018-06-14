from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class CreateACSSets(unittest.TestCase):

    #setUp function. runs before test_ functions
    def setUp(self):
        self.start_test()

        #create instance of webdriver which controls the web page
        self.driver = webdriver.Firefox()

        #tell the webdriver to wait up to 30 seconds to find an element if it is not immediately available. this remains in effect for the rest of the test.
        self.driver.implicitly_wait(30)

        #put the CIAP URL in a variable called self.url
        self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"

        #logs in to CIAP as svcadmin
        self.log_in()

    def test_create_acs_sets(self):
        #rename self.driver to driver for simplicity
        driver = self.driver

        #identify the element specified by this xpath, store it in the variable "admin_dropdown", and click on it
        admin_dropdown = driver.find_element_by_id("Admin")
        admin_dropdown.click()

        #identify the element whose id is "Admin_ACS_Sets", store it in the variable "acs_sets_dropdown", and click on it
        acs_sets_dropdown = driver.find_element_by_id("Admin_ACS_Sets")
        acs_sets_dropdown.click()

        #identify the element specified by this xpath, store it in the variable "new_acs_set_button", and click on it
        new_acs_set_button = driver.find_element_by_id("Admin_ACS_Sets_New")
        new_acs_set_button.click()

        #identify the element whose id is "ACS_Set_Name" and store it in the variable "name_textbox". then type in the current time (this is to make each ACS set created by this test unique)
        name_textbox = driver.find_element_by_id("ACS_Set_Name")
        name_textbox.clear()
        name_textbox.send_keys(time.strftime("%X"))

        #identify the dropdown menu with this xpath and store it in the variable "formal_determination_dropdown". then select the dropdown options whose values are "1" and "2"
        formal_determination_dropdown = Select(driver.find_element_by_xpath("(//select)[2]"))
        formal_determination_dropdown.select_by_value("1")
        formal_determination_dropdown.select_by_value("2")

        #identify the dropdown menu specified by this xpath and store it in the variable "sensitivity_dropdown". then select the dropdown options whose values are "1" and "2"
        sensitivity_dropdown = Select(driver.find_element_by_xpath("(//select)[3]"))
        sensitivity_dropdown.select_by_value("1")
        sensitivity_dropdown.select_by_value("2")

        #identify the dropdown menu specified by this xpath and store it in the variable "country_dropdown". then select the dropdown options whose values are "0" and "1"
        country_dropdown = Select(driver.find_element_by_xpath("(//select)[5]"))
        country_dropdown.select_by_value("0")
        country_dropdown.select_by_value("1")

        #find the element whose id is "ACS_Set_Save_Button" and store it in the variable "save_button". then click it.
        save_button = driver.find_element_by_id("ACS_Set_Save_Button")
        save_button.click()

        #wait until the text "ACS Set successfully added" appears somewhere on the page. The XPath "//*" means anywhere on the page. this message is an alert.
        WebDriverWait(driver, 30).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "ACS Set successfully added"))

        self.log_success("create new ACS set")
    
    def tearDown(self):
        #close web browser
        self.driver.quit()
        self.end_test()

    #login method. just logs in to CIAP as SVCadmin
    def log_in(self):
        driver = self.driver
        driver.get(self.url)
        driver.maximize_window()

        username_textbox = driver.find_element_by_id("username")
        username_textbox.clear()
        username_textbox.send_keys("svcadmin")

        password_textbox = driver.find_element_by_id("password")
        password_textbox.clear()
        password_textbox.send_keys("P@ssw0rd!")

        login_button = driver.find_element_by_name("button")
        login_button.click()

        self.log_success("login")

    def log_success(self, task):
        log_file = open("logs/create_acs_sets_log.txt", 'a')
        log_file.write("task: \"" + task + "\" completed successfully at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n")
        log_file.close()

    def start_test(self):
        log_file = open("logs/create_acs_sets_log.txt", 'a')
        log_file.write("test case started at " + time.strftime("%X") + " on " +  time.strftime("%x") + "\n")
        log_file.close()

    def end_test(self):
        log_file = open("logs/create_acs_sets_log.txt", 'a')
        log_file.write("test case ended at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n\n")
        log_file.close()

#run the test case starting with setUp(), then the "test_" methods and finally tearDown()
if __name__ == "__main__":
    unittest.main()