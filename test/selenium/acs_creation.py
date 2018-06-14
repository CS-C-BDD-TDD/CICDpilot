from selenium import webdriver
import time 
from selenium.common.exceptions import TimeoutException 
from selenium.webdriver.support.ui import WebDriverWait # available since 2.4.0 
from selenium.webdriver.support import expected_conditions as EC # available since 2.26.0 
from selenium.webdriver.common.by import By 
import unittest
from selenium.webdriver.support.select import Select
import sys

class ACS_Sets(unittest.TestCase):
    
    # Must define initial set up function
    def setUp(self):
	# Create a new instance of the Firefox driver
	self.driver = webdriver.Firefox()

	# Inherit the webdriver
	driver = self.driver

	# go to the cyber-indicators home page 
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
	 
	# Waits until the nametag in the top right contains the string "Welcome admin" 
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"nametag"),"Welcome admin")) 

	# Append to output file that the log in successfully completed 
	f = open('Selenium_Output.txt', 'a') 
	f.write('The log in completed successfully at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + '\n') 
	f.close()

    # Must start with test_ for it to be a recognized test case
    def test_acs_set_creation(self): 
	# Inherit the webdriver 
	driver = self.driver 
	 
	# Set an implicit wait time so the browser always waits for the element to be there, or times out after 10 seconds
	driver.implicitly_wait(10)

	# Find the Admin button to click on
	admin_dropdown_button = driver.find_element_by_id("Admin") 
	admin_dropdown_button.click() 
	WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"Admin_ACS_Sets")))

	# Find the ACS Sets button to click on
	time.sleep(5)
	acs_sets_button = driver.find_element_by_id("Admin_ACS_Sets")
	acs_sets_button.click()
	acs_sets_button.click()

	# Assert that the New and List buttons display 
	WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"Admin_ACS_Sets_List"))) 
	WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID,"Admin_ACS_Sets_New"))) 

	# Find and click on the new ACS Set Button
	new_acs_set_button = driver.find_element_by_id("Admin_ACS_Sets_New") 
	new_acs_set_button.click() 

	# Try to save with blank fields and assert that the red alert occurs when the name field is blank
	save_acs_set_button = driver.find_element_by_id("ACS_Set_Save_Button")
	save_acs_set_button.click()
	WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"acs_set_spinning_wheel")))
	WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"toast-container")))
	
	my_var = driver.find_element_by_id("toast-container").text
	if my_var != "Name can't be blank":
		f = open('Selenium_Output.txt', 'a') 
		f.write('The ACS Set Creation failed at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ' because the alert did not popup when trying to save with a blank name.\n') 
		f.close() 
		sys.exit(0)
	f = open('Selenium_Output.txt', 'a') 
	f.write('The ACS Set Creation without a name sucessfully completed at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', the alert popuped when trying to save with a blank name.\n') 
	f.close()

	# Try to save with too many characters
	acs_set_name_field = driver.find_element_by_id("ACS_Set_Name")
	#acs_set_name_field.send_keys("This is the test of having more than 256 characters in a text field..................................................................................................................................................................................................................................................................................................................................")
	#save_acs_set_button.click()
	#WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"acs_set_spinning_wheel")))
	#WebDriverWait(driver, 10).until(EC.element_to_be_clickable((By.ID,"Admin_ACS_Sets_New")))
	#f = open('Selenium_Output.txt', 'a') 
   	#f.write('The ACS Set Creation with too many characters sucessfully completed at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', the indicator did not save and the page became editable again.\n') 
   	#f.close()
		# Clear the name and enter Selenium ACS Set
	#acs_set_name_field.clear()
	
	acs_set_name_field.send_keys("Selenium ACS Set03")
	
	# Instantiating all the fields on the page
	acs_set_tlp_field = driver.find_element_by_id("ACS_Set_TLP_Color")
	acs_set_tlp_options_red = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[2]/div[1]/select/option[5]")
	acs_set_restrict_to_orgs = driver.find_element_by_id("ACS_Set_Restrict_To_Orgs")
	acs_set_re_custodian = driver.find_element_by_id("ACS_Set_RE_Custodian")
	acs_set_re_originator = driver.find_element_by_id("ACS_Set_RE_Originator")
	acs_set_re_originator_x = driver.find_element_by_id("ACS_Set_RE_Originator_X_Button")
	acs_set_re_created = driver.find_element_by_id("stixMarking.isa_marking_structure_attributes.data_item_created_at")
	acs_set_p_release = driver.find_element_by_id("ACS_Set_P_Release")
	acs_set_p_authorizer = driver.find_element_by_id("ACS_Set_P_Authorizer")
	acs_set_p_realeased_on = driver.find_element_by_id("stixMarking.isa_assertion_structure_attributes.public_released_on")
	acs_set_p_display = driver.find_element_by_id("ACS_Set_P_Display")
	acs_set_p_ten = driver.find_element_by_id("ACS_Set_P_TEN")
	acs_set_p_tear = driver.find_element_by_id("ACS_Set_P_Tear")
	acs_set_p_legal = driver.find_element_by_id("ACS_Set_P_Legal")
	acs_set_p_analysis = driver.find_element_by_id("ACS_Set_P_Analysis")
	acs_set_p_operation = driver.find_element_by_id("ACS_Set_P_Operation")
	acs_set_p_source = driver.find_element_by_id("ACS_Set_P_Source")
	acs_set_p_nda = driver.find_element_by_id("ACS_Set_P_NDA")
	acs_set_p_waiver = driver.find_element_by_id("ACS_Set_P_Waiver")
	acs_set_cs_formal = driver.find_element_by_id("ACS_Set_CS_Formal")
	acs_set_cs_unclassed_info = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[3]/div/multi-select/div[3]/select")
	acs_set_cs_shareability = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[4]/div/multi-select/div[3]/select")
	acs_set_cs_countries = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[2]/div/multi-select/div[3]/select")
	acs_set_cs_orgs = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[3]/div/multi-select/div[3]/select")
	acs_set_cs_entities = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[4]/div/multi-select/div[3]/select")
	
	# Filling in every field with some information
	acs_set_tlp_dropdown = Select(acs_set_tlp_field)
	acs_set_tlp_dropdown.select_by_value("red")
	acs_set_restrict_to_orgs_dropdown = Select(acs_set_restrict_to_orgs)
	acs_set_restrict_to_orgs_dropdown.select_by_value("0")
	acs_set_re_custodian_dropdown = Select(acs_set_re_custodian)
	acs_set_re_custodian_dropdown.select_by_value("0")
	acs_set_re_originator_dropdown = Select(acs_set_re_originator)
	acs_set_re_originator_dropdown.select_by_value("2")
	acs_set_re_originator = driver.find_element_by_id("originator")
	#if acs_set_re_originator.text == "USA.DHS":
	#	f = open('Selenium_Output.txt', 'a') 
	#	f.write('Adding DHS as the originator was successful at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + '\n') 
	#	f.close()
	#else:
	#	sys.exit(0)
	print acs_set_re_originator.text
	WebDriverWait(driver, 10).until(EC.presence_of_element_located((By.ID,"ACS_Set_RE_Originator_X_Button")))
	acs_set_re_originator_x.click()
	acs_set_re_originator_dropdown.select_by_value("2")
	#acs_set_re_created.send_keys("10/27/2015")
	time.sleep(0.25)
	acs_set_p_display.click()
	time.sleep(0.25)
	acs_set_p_ten.click()
	time.sleep(0.25)
	acs_set_p_tear.click()
	time.sleep(0.25)
	acs_set_p_legal.click()
	time.sleep(0.25)
	acs_set_p_analysis.click()
	time.sleep(0.25)
	acs_set_p_operation.click()
	time.sleep(0.25)
	acs_set_p_source.click()
	time.sleep(0.25)
	acs_set_p_nda.click()
	time.sleep(0.25)
	acs_set_p_waiver.click()
	time.sleep(0.25)
	acs_set_cs_formal_dropdown = Select(acs_set_cs_formal)
	acs_set_cs_formal_dropdown.select_by_value("2")
	acs_set_cs_unclassed_info_dropdown = Select(acs_set_cs_unclassed_info)
	time.sleep(0.25)
	acs_set_cs_unclassed_info_dropdown.select_by_value("1")
	time.sleep(0.25)
	acs_set_cs_unclassed_info_dropdown.select_by_value("0")
	time.sleep(0.25)
	acs_set_cs_unclassed_info_X1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[3]/div/multi-select/div[1]/div[1]/span[1]/button")
	acs_set_cs_unclassed_info_Tag1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[3]/div/multi-select/div[1]/div[1]/span[1]")
	#if acs_set_cs_unclassed_info_Tag1.text == "INT":
	#	f = open('Selenium_Output.txt', 'a') 
	#	f.write('Adding INT as unclassed info was successful at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', now deleting that to leave FOUO.\n') 
	#	f.close()
	#else:
	#	sys.exit(0)

	acs_set_cs_unclassed_info_X1.click()
	acs_set_cs_shareability_dropdown = Select(acs_set_cs_shareability)
	acs_set_cs_shareability_dropdown.select_by_value("1")
	time.sleep(0.25)
	acs_set_cs_shareability_dropdown.select_by_value("0")
	acs_set_cs_shareability_X1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[4]/div/multi-select/div[1]/div[1]/span[1]/button")
	acs_set_cs_shareability_Tag1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[4]/div/multi-select/div[1]/div[1]/span[1]")
	#if acs_set_cs_shareability_Tag1.text == "CIKR":
	#	f = open('Selenium_Output.txt', 'a') 
	#	f.write('Adding CIKR as shareability group was successful at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', now deleting that to leave CDC.\n') 
	#	f.close()
	#else:
	#	sys.exit(0)

	acs_set_cs_shareability_X1.click()
	acs_set_cs_countries_dropdown = Select(acs_set_cs_countries)
	acs_set_cs_countries_dropdown.select_by_value("1")
	time.sleep(0.25)
	acs_set_cs_countries_dropdown.select_by_value("0")
	time.sleep(0.25)
	acs_set_cs_countries_X1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[2]/div/multi-select/div[1]/div[1]/span[1]/button")
	acs_set_cs_countries_Tag1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[2]/div/multi-select/div[1]/div[1]/span[1]")
	#if acs_set_cs_countries_Tag1.text == "ABW":
	#	f = open('Selenium_Output.txt', 'a') 
	#	f.write('Adding ABW as a country was successful at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', now deleting that to leave USA.\n') 
	#	f.close()
	#else:
	#	sys.exit(0)

	acs_set_cs_countries_X1.click()
	acs_set_cs_orgs_dropdown = Select(acs_set_cs_orgs)
	acs_set_cs_orgs_dropdown.select_by_value("4")
	time.sleep(0.25)
	acs_set_cs_orgs_dropdown.select_by_value("7")
	acs_set_cs_orgs_X1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[3]/div/multi-select/div[1]/div[1]/span[1]/button")
	acs_set_cs_orgs_Tag1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[3]/div/multi-select/div[1]/div[1]/span[1]")
	#if acs_set_cs_orgs_Tag1.text == "USA.USG":
	#	f = open('Selenium_Output.txt', 'a') 
	#	f.write('Adding USG as an organization was successful at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', now deleting that to leave DHS.\n') 
	#	f.close()
	#else:
	#	sys.exit(0)

	acs_set_cs_orgs_X1.click()
	acs_set_cs_entities_dropdown = Select(acs_set_cs_entities)
	acs_set_cs_entities_dropdown.select_by_value("0")
	acs_set_cs_entities_dropdown.select_by_value("1")
	acs_set_cs_entities_X1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[4]/div/multi-select/div[1]/div[1]/span[1]/button")
	acs_set_cs_entities_Tag1 = driver.find_element_by_xpath("/html/body/div[2]/div[2]/div/div[2]/div/div/div/acs-set-form/form/div/div/div[2]/div/div[5]/essa-tags/div/div[2]/div[3]/div/div[5]/div/div[4]/div/multi-select/div[1]/div[1]/span[1]")
	#if acs_set_cs_entities_Tag1.text == "CTR":
	#	f = open('Selenium_Output.txt', 'a') 
	#	f.write('Adding CTR as a responsible entity was successful at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + ', now deleting that to leave CTR.\n') 
	#	f.close()
	#else:
	#	sys.exit(0)
	acs_set_cs_entities_X1.click()

	# Save the ACS Set 
	save_acs_set_button.click()

	# Set expected conditions on save page
	# Title
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Name"),"Selenium ACS Set03"))
	# Custodian
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Custodian"),"USA.CIA"))
	# Originator
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Originator"),"USA.DHS"))
	# Data Item Created At
	#WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Item_Created_At"),"Oct 27, 2015"))
	# Policies - Release to Public
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Release_To_Public"),"FALSE"))
	# Policies - Display
	'''WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Display"),"DENY"))
	# Policies - Identity Source
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Identity Source"),"PERMIT"))
	# Policies - Target Entity Notification
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Target Entity Notification"),"PERMIT"))
	# Policies - Network Defense Action
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Network Defense Action"),"DENY"))
	# Policies - Legal Preceedings
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Legal Preceedings"),"PERMIT"))
	# Policies - Intelligence Analysis
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Intelligence Analysis"),"DENY"))
	# Policies - Tear-Line
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Tear-line"),"DENY"))
	# Policies - Operation Action
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Operation Action"),"DENY"))
	# Policies - Access Privilege Waiver Request
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Access Privilege Waiver Request"),"DENY"))
	# Control Set - Formal Determination
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Formal_Determination"),"OC"))
	# Control Set - Controlled Unclassified Information
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Controlled_Unclassified_Information"),"FOUO"))
	# Control Set - Shareability Group
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Shareability_Group"),"CDC"))
	# Control Set - Affiliated Countries
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Affiliated_Countries"),"USA"))
	# Control Set - Affiliated Organizations
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Show_Affiliated_Organizations"),"USA.DHS"))
	# Control Set- Affiliated Entities
	WebDriverWait(driver, 10).until(EC.text_to_be_present_in_element((By.ID,"ACS_Set_Affiliated_Entities"),"CTR"))'''

	# Append to the output file that the test completed successfully
	f = open('Selenium_Output.txt', 'a') 
	f.write('The ACS Set Creation test completed successfully at ' + time.strftime('%X') + ' on ' + time.strftime('%x') + '\n') 
	f.close()

	def tearDown(self):
		self.driver.close()

if __name__ == "__main__":
	unittest.main()
