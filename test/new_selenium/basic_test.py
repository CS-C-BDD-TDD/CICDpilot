from selenium import webdriver
from selenium.webdriver.common.by import By
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.support.ui import WebDriverWait
from selenium.webdriver.support import expected_conditions as EC
from selenium.common.exceptions import TimeoutException
from selenium.webdriver.support.select import Select
import unittest, time, re

class BasicTest(unittest.TestCase):

	def setUp(self):
		self.driver = webdriver.Firefox()
		self.driver.implicitly_wait(35)
		self.url = "https://0.0.0.0:3000/cyber-indicators/auth/login"

	def test_test1(self):
		driver = self.driver
		driver.get(self.url) #open the page
		driver.maximize_window() #maximize window

		username_textbox = driver.find_element_by_id("username")
		username_textbox.clear()
		username_textbox.send_keys("svcadmin")

		password = driver.find_element_by_id("password")
		password.clear()
		password.send_keys("P@ssw0rd!")

		button = driver.find_element_by_name("button")
		button.click()

	def tearDown(self):
		self.driver.quit()

if __name__ == "__main__":
	unittest.main()