from selenium import webdriver
import time 
from selenium.common.exceptions import TimeoutException 
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0 
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0 
from selenium.webdriver.common.by import By 
import unittest

class LogOut(unittest.TestCase):
    
    # Must define initial set up function
    def setUp(self):
	# Create a new instance of the Firefox driver
	self.driver = webdriver.Firefox()

	# Inherit the webdriver
	driver = self.driver

	# go to the cyber-indicators home page and maximize the window 
	driver.get("https://localhost:8443/cyber-indicators/") 
 	driver.maximize_window()

	# find the element that's name attribute is username 
	usernameElement = driver.find_element_by_name("username") 
 
	# type in the username 
	usernameElement.send_keys("svcadmin") 
 
	# type in the password after locating the element 
	passwordElement = driver.find_element_by_name("password") 
	passwordElement.send_keys("P@ssw0rd!") 
 
	# submit the input 
	loginButton = driver.find_element_by_name("button") 
	loginButton.submit() 
 
	# Waits until the nametag in the top right contains the string "Welcome admin" and then stores the text within that element 
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"nametag"),"Welcome admin")) 

	# Append to output file that the log in successfully completed 
	f = open('Selenium_Output.txt', 'a') 
	f.write('The log in completed successfully at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + '\n') 
	f.close()

    # Must start with test_ for it to be a recognized test case
    def test_log_out(self): 
        # Inherit the webdriver 
        driver = self.driver 
 
	# Set an implicit wait time so the browser always waits for the element to be there, or times out after 10 seconds
	driver.implicitly_wait(10)

        # Find the "Welcome admin" button to click on 
        nametag_button = driver.find_element_by_id("nametag") 
        nametag_button.click() 
 
        # Assert that the log out button and profile button are shown 
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"logout_button"))) 
        WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"profile_button"))) 
 
        # Find the logout button 
        logout_button = driver.find_element_by_id("logout_button") 
        logout_button.click() 
 
	# Look for the text "You have been looged out." in ANY xpath
        WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.XPATH,"//*"),"You have been logged out."))
	 
	# Append to the output file that the test completed successfully
        f = open('Selenium_Output.txt', 'a') 
        f.write('The log out test completed successfully at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + '\n') 
        f.close() 

    def tearDown(self):
	self.driver.close()

if __name__ == "__main__":
    unittest.main()
