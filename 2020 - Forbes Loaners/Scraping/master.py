import scrapy
from scrapy.crawler import CrawlerProcess
from spiders.roto.roto.spiders.roto_players import RotowireSpider
from scripts.scraping_tools import *
from scripts.scraping_info import *
from scripts.pipeline_tools import *
from selenium import webdriver
from selenium.common.exceptions import NoSuchElementException
from selenium.webdriver.firefox.firefox_profile import FirefoxProfile

# Data Collection
#process = CrawlerProcess(settings={'FEED_FORMAT': 'json', 'FEED_URI': 'spiders/roto/rotowire_data.json'})
#process.crawl(RotowireSpider)
#process.start()

gather_data()

# Raw to Pipeline
update_playerxref()
update_histories()