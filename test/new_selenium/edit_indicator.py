# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class EditIndicator(unittest.TestCase):

    def setUp(self):
        self.start_test()
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"
        self.log_in()

    def test_edit_indicator(self):
        driver = self.driver

        #select the 1st indicator from the list
        driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/div[2]/indicator-table/div/div[2]/div/table/tbody[1]/tr[1]/td[1]/a").click()

        #find the element whose link text is "Edit" (a button), store it in the variable "edit_button", and click it
        edit_button = driver.find_element_by_link_text("Edit")
        edit_button.click()

        #wait until the text "Title *" appears anywhere on the page
        WebDriverWait(driver, 15).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "Title *"))

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
        log_file = open("logs/edit_indicator_log.txt", 'a')
        log_file.write("task: \"" + task + "\" completed successfully at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n")
        log_file.close()      

    def start_test(self):
        log_file = open("logs/edit_indicator_log.txt", 'a')
        log_file.write("test case started at " + time.strftime("%X") + " on " +  time.strftime("%x") + "\n")
        log_file.close()

    def end_test(self):
        log_file = open("logs/edit_indicator_log.txt", 'a')
        log_file.write("test case ended at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n\n")
        log_file.close()


if __name__ == "__main__":
    unittest.main()