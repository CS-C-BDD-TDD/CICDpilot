from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class LogIn(unittest.TestCase):

    #must define initial setup function. runs before the test functions
    def setUp(self): 

        #run start_test() function which logs the test's start date and time to a text file 
        self.start_test()

        #create instance of webdriver. the "self" part is a python convention
        self.driver = webdriver.Firefox() 

        #tells the webdriver to wait up to 30 seconds when trying to find an element that is not immediately available. this will be in effect for the duration of the test
        self.driver.implicitly_wait(30)

        #store CIAP's URL in a variable called url
        self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"
    
    #test function. must start with "test_" to be recognized as test
    def test_loginto_ciap(self):

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

    #must define tearDown function. runs after all the test cases run.
    def tearDown(self):

        #closes web browser
        self.driver.quit()

        #logs test's end time and date to a text file
        self.end_test()

    #method that prints success of a task to a log file
    def log_success(self, task):
        log_file = open('logs/log_in_log.txt', 'a')
        log_file.write("task: \"" + task + "\" completed successfully at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n")
        log_file.close()        

    #method that prints the start time and date of a test to a log file
    def start_test(self):
        log_file = open('logs/log_in_log.txt', 'a')
        log_file.write("test case started at " + time.strftime("%X") + " on " +  time.strftime("%x") + "\n")
        log_file.close()

    #method that prints the end time and date of a test to a log file
    def end_test(self):
        log_file = open('logs/log_in_log.txt', 'a')
        log_file.write("test case ended at " + time.strftime("%X") + " on " + time.strftime("%x") + "\n\n")
        log_file.close()

#runs the test case by running the setUp() function, then all methods starting with "test_", and then the tearDown() function
if __name__ == "__main__":
    unittest.main()