# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class TestSuite(unittest.TestCase):

    test = True

    def setUp(self):
        self.start_test()
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"

    def test_log_in(self):

        #rename self.driver to driver for simplicity 
        driver = self.driver

        #open up CIAP page
        driver.get(self.url)

        #tell the webdriver to find a web element whose HTML id is "username" and store it in the variable "username_textbox"
        username_textbox = driver.find_element_by_id("username")

        #delete everything inside textbox (there might be existing text within the textbox)
        username_textbox.clear()

        #enter "svcadmin" into the textbox
        username_textbox.send_keys("svcadmin")

        #find the textbox whose id is "password" and enter "P@ssw0rd!"
        password_textbox = driver.find_element_by_id("password")
        password_textbox.clear()
        password_textbox.send_keys("P@ssw0rd!")

        #find the button whose name is "button" and click it
        login_button = driver.find_element_by_name("button")
        login_button.click()

        #prints "login completed successfully" to a text file
        self.log_success("login")

    def test_create_acs_sets(self):

        self.log_in()

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

    def test_package(self):
        self.log_in()

        driver = self.driver

        package_dropdown = driver.find_element_by_xpath("/html/body/div[2]/div[1]/ul/li[3]/a")
        package_dropdown.click()

        new_package_button = driver.find_element_by_xpath("/html/body/div[2]/div[1]/ul/li[3]/ul/li[2]/a")
        new_package_button.click()

        title_textbox = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/package-form/form/div/div/div[2]/div[1]/div[1]/div[1]/input")
        title_textbox.clear()
        title_textbox.send_keys("blah")

        add_indicators_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/package-form/form/div/div/div[2]/div[1]/div[9]/span[1]/button")
        add_indicators_button.click()

        indicators_search_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/package-form/form/div/div/div[2]/div[1]/indicator-browser/div/div[2]/div/div/span/button")
        indicators_search_button.click()

        first_checkbox = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/package-form/form/div/div/div[2]/div[1]/indicator-browser/div/div[2]/div/table/tbody/tr[1]/td[1]/input")
        first_checkbox.click()

        done_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/package-form/form/div/div/div[2]/div[1]/div[9]/span[2]/button")
        done_button.click()

        save_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/package-form/form/div/div/div[2]/div[2]/button")
        save_button.click()
        
        WebDriverWait(driver, 45).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "New package created"))

        self.log_success("create new package")

    def test_edit_indicator(self):
        
        self.log_in()

        driver = self.driver

        #select the 1st indicator from the list
        driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/div[2]/indicator-table/div/div[2]/div/table/tbody[1]/tr[1]/td[1]/a").click()

        #find the element whose link text is "Edit" (a button), store it in the variable "edit_button", and click it
        edit_button = driver.find_element_by_link_text("Edit")
        edit_button.click()

        #wait until the text "Title *" appears anywhere on the page
        WebDriverWait(driver, 30).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "Title *"))

        #find the element specified by this xpath (a textbox), and type "Jim" into it
        reference_textbox = driver.find_element_by_xpath("(//input[@type='text'])[3]")
        reference_textbox.clear()
        reference_textbox.send_keys("Jim")

        #find the element specified by this xpath (a dropdown menu), store it in the variable "kill_chain_phases_dropdown", and select the options specified by those values.
        kill_chain_phases_dropdown = Select(driver.find_element_by_xpath("(//select)[2]"))
        kill_chain_phases_dropdown.select_by_value("0")
        kill_chain_phases_dropdown.select_by_value("1")
        kill_chain_phases_dropdown.select_by_value("2")
        kill_chain_phases_dropdown.select_by_value("3")
        kill_chain_phases_dropdown.select_by_value("4")

        #find the element specified by this xpath(a button), store it the variable "link_button", and click it
        link_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/indicator-form/form/div[2]/observable-select/div/div[1]/div[2]/div/table/tbody/tr/td[2]/button")
        link_button.click()

        #find the element specified by this xpath (a dropdown menu), store it in the variable "link_type_dropdown", and select the option whose value is "1"
        link_type_dropdown = Select(driver.find_element_by_xpath("//div[@id='main-container']/div[2]/div/div[2]/div/div/div/indicator-form/form/div[2]/observable-select/div/div[2]/div[2]/div/div/select"))
        link_type_dropdown.select_by_value("1")

        #find the element specified by this xpath (a button), store it in the variable "new_observable_button", and click it
        new_observable_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/indicator-form/form/div[2]/observable-select/div/div[2]/div[2]/div/div/button")
        new_observable_button.click()

        #find the element specified by this xpath (a textbox), store it in the variable "address_value_textbox", and type "70.25.25.70" into it
        address_value_textbox = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/indicator-form/form/div[2]/observable-select/div/div[4]/div[2]/div/div/dns-record-creator/dns-record-form/form/div/div[1]/div/input")
        address_value_textbox.clear()
        address_value_textbox.send_keys("70.25.25.70")

        #find the element specified by this xpath (a textbox), store it in the variable "domain_name_textbox", and type "www.mackin.com" into it
        domain_name_textbox = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/indicator-form/form/div[2]/observable-select/div/div[4]/div[2]/div/div/dns-record-creator/dns-record-form/form/div/div[3]/div/input")
        domain_name_textbox.clear()
        domain_name_textbox.send_keys("www.mackin.com")

        #find the element specified by this xpath (a button), store it in the variable "observable_save_button", and click it
        observable_save_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/indicator-form/form/div[2]/observable-select/div/div[4]/div[2]/div/div/dns-record-creator/dns-record-form/div/div/form/div[1]/div/button[1]")
        observable_save_button.click()

        #find the element specified by this xpath ( a buton), store it in the variable "indicator_save_button", and click it
        indicator_save_button = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/indicator-form/form/div[3]/div/button")
        indicator_save_button.click()

        #variables used below for keeping track of whether or not a particular popup has appeared. false means it has not appeared.        
        dns_saved = False
        obs_saved = False
        ind_saved = False

        timeout = time.time() + 30
        #while any of the 3 expected popups have not yet appeared on the page, search for the popups. 
        while not(dns_saved) or not(obs_saved) or not(ind_saved):

            #if the "DNS record observable saved" popup is on the page, set the "dns_saved" variable to true, indicating that the popup has appeared
            if EC.text_to_be_present_in_element((By.XPATH, "//*"), "DNS record observable saved"):
                dns_saved = True

            #same as above but for "Observable successfully linked" popup
            if EC.text_to_be_present_in_element((By.XPATH, "//*"), "Observable successfully linked"):
                obs_saved = True

            #same
            if EC.text_to_be_present_in_element((By.XPATH, "//*"), "Indicator saved"):
                ind_saved = True

            if time.time() > timeout:
                print "timed out looking for alerts"
                break

        #
        #the reason for doing it this way instead of looking for the 3 popups one after another (ie wait for this popup, then once that's found wait for this popup) is that
        #selenium might get stuck looking for one popup while another one has come and gone. this way, selenium is essentially looking for every popup at the same time, so
        #it is not possible to "miss" a popup while stuck searching for another one
        #

        self.log_success("edit indicator")

    def test_new_indicator(self):

        self.log_in()

        #rename self.driver to driver for simplicity
        driver = self.driver

        #wait for the text "Welcome svcadmin" to appear in the element whose id is "nametag"
        WebDriverWait(driver, 30).until(EC.text_to_be_present_in_element((By.ID, "nametag"), "Welcome svcadmin"))

        #find the element specified by this id (a button), store it in the variable "new_indicator_button", and click it
        new_indicator_button = driver.find_element_by_id("new_indicator_button")
        new_indicator_button.click() 

        #wait for the text "Title *" to appear anywhere in the page. an xpath of "//* means anywhere in the page
        WebDriverWait(driver, 30).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "Title *"))
        
        #find the element specified by this id (a textbox), store it in the variable "title_textbox", and type "name" into it
        title_textbox = driver.find_element_by_id("title_textbox")
        title_textbox.send_keys("name")

        #find the element whose id is "form-field-8" (a textbox), store it in the variable "description_textbox", and click on it
        description_textbox = driver.find_element_by_id("form-field-8")
        description_textbox.send_keys("name1")

        #find the element specified by this id (a dropdown menu), store it in the variable "indicator_type_dropdown", and then select the option whose value is "benign"
        indicator_type_dropdown = Select(driver.find_element_by_id("indicator_type_dropdown"))
        indicator_type_dropdown.select_by_value("benign")
        
        #find the element specified by this id (a button), store it in the variable "save_button", and click it
        save_button = driver.find_element_by_id("save_button")
        save_button.click()
        save_button.click()

        #wait until the text "Indicator has been saved" appears anywhere on the page. this message pops up after hitting save.
        WebDriverWait(driver, 35).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "Indicator has been saved"))

        self.log_success("create new indicator")
    
    def tearDown(self):
        self.driver.quit()
        self.end_test()

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
        log_file = open("logs/suite_log.txt", 'a')
        log_file.write("task: \"" + task + "\" completed successfully at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n")
        log_file.close()      

    def start_test(self):
        log_file = open("logs/suite_log.txt", 'a')
        log_file.write("test case started at " + time.strftime("%X") + " on " +  time.strftime("%x") + "\n")
        log_file.close()

    def end_test(self):
        log_file = open("logs/suite_log.txt", 'a')
        log_file.write("test case ended at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n\n")
        log_file.close()

if __name__ == "__main__":
    unittest.main()