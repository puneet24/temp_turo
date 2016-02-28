import sys  
from PyQt4.QtGui import *  
from PyQt4.QtCore import *  
from PyQt4.QtWebKit import *  
from lxml import html 
import requests
from selenium import webdriver
import time
from bs4 import BeautifulSoup
import json

#Take this class for granted.Just use result of rendering.
class Render(QWebPage):  
  def __init__(self, url):  
    self.app = QApplication(sys.argv)  
    QWebPage.__init__(self)  
    self.loadFinished.connect(self._loadFinished)  
    self.mainFrame().load(QUrl(url))  
    self.app.exec_()  
  
  def _loadFinished(self, result):  
    self.frame = self.mainFrame()  
    self.app.quit() 
    
def calc(url):
  r = Render(url)
  result = r.frame.toHtml()
  f = str(result.toAscii())
  return html.fromstring(f)

    
all_cities_url = 'https://turo.com/all-cities/'
state_page = html.fromstring(requests.get(all_cities_url).content)
all_states = state_page.xpath('//div[@class="state-name"]//a/@href')
all_states_name = state_page.xpath('//div[@class="state-name"]//a/text()')
all_states_arr = {}

for state in all_states:
  state_url = "https://turo.com/" + str(state)
  print state_url
  city_page = html.fromstring(requests.get(state_url).content)
  all_cities = city_page.xpath('//div[@id="active-cities"]//p//a/@href')
  for city in all_cities:
  	if all_states_arr.has_key(state) == True:
  	  all_states_arr[state] += [city]
  	else:
  	  all_states_arr[state] = [city]
  	print "*******************************************************************"
  	city_url = 'https://turo.com/search#location=' + city[city.rfind('/')+1:]
  	match_data = {"query":{"match":{"city":city[city.rfind('/')+1:]}}}
  	match_data = json.dumps(match_data)
  	res = requests.post('http://localhost:9200/dev_car_luxury/_search',data=match_data)
  	info = json.loads(res.content)
  	if info['hits']['total'] == 0:
	  	print city_url
	  	driver = webdriver.Firefox()
		driver.get(city_url)
		time.sleep(10) # wait to load
		soup = BeautifulSoup(driver.page_source,"lxml")  
		#print soup
		f = str(soup)
		driver.quit()
		vehicles_page = html.fromstring(f)
		h = vehicles_page.xpath('//div[@id="results"]//a/@href')
		for vehicle_path in h:
		  data = {"state":state,"city":city,"car_path":vehicle_path}
		  data = json.dumps(data)
		  print data
		  v = requests.post('http://localhost:9200/dev_car_luxury/vehicles',data=data)
		  print v
		print h
	else:
	  print "already"
	print "*******************************************************************"
  print all_states_arr  

