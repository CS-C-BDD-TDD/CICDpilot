# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class NewIndicator(unittest.TestCase):

    def setUp(self):
        self.start_test()
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(35)
        self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"
        self.log_in()

    def test_new_indicator(self):
        #rename self.driver to driver for simplicity
        driver = self.driver

        #wait for the text "Welcome svcadmin" to appear in the element whose id is "nametag"
        WebDriverWait(driver, 20).until(EC.text_to_be_present_in_element((By.ID, "nametag"), "Welcome svcadmin"))

        #find the element specified by this id (a button), store it in the variable "new_indicator_button", and click it
        new_indicator_button = driver.find_element_by_id("new_indicator_button")
        new_indicator_button.click() 

        #wait for the text "Title *" to appear anywhere in the page. an xpath of "//* means anywhere in the page
        WebDriverWait(driver, 20).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "Title *"))
        
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
        WebDriverWait(driver, 45).until(EC.text_to_be_present_in_element((By.XPATH, "//*"), "Indicator has been saved"))

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
        log_file = open("logs/new_indicator_log.txt", 'a')
        log_file.write("task: \"" + task + "\" completed successfully at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n")
        log_file.close()      

    def start_test(self):
        log_file = open("logs/new_indicator_log.txt", 'a')
        log_file.write("test case started at " + time.strftime("%X") + " on " +  time.strftime("%x") + "\n")
        log_file.close()

    def end_test(self):
        log_file = open("logs/new_indicator_log.txt", 'a')
        log_file.write("test case ended at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n\n")
        log_file.close()

if __name__ == "__main__":
    unittest.main()