# -*- coding: utf-8 -*-
from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class PackageTest(unittest.TestCase):

    def setUp(self):
        self.start_test()
        self.driver = webdriver.Firefox()
        self.driver.implicitly_wait(30)
        self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"
        self.log_in()

    def test_package(self):
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
        log_file = open("logs/package_test_log.txt", 'a')
        log_file.write("task: \"" + task + "\" completed successfully at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n")
        log_file.close()      

    def start_test(self):
        log_file = open("logs/package_test_log.txt", 'a')
        log_file.write("test case started at " + time.strftime("%X") + " on " +  time.strftime("%x") + "\n")
        log_file.close()

    def end_test(self):
        log_file = open("logs/package_test_log.txt", 'a')
        log_file.write("test case ended at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n\n")
        log_file.close()

if __name__ == "__main__":
    unittest.main()