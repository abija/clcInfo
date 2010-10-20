import getopt
import mimetypes
import os.path
import sys

import gdata.sample_util
import gdata.sites.client
import gdata.sites.data
import pprint


SOURCE_APP_NAME = 'googleInc-GoogleSitesAPIPythonLibSample-v1.1'
class MyUpdater(object):
	"""Wrapper around the Sites API functionality."""

	def __init__(self, path):
		self.path = path
		site_domain = 'site'
		site_name = 'clcinfowiki'
		mimetypes.init()
		self.client = gdata.sites.client.SitesClient(source=SOURCE_APP_NAME, site=site_name, domain=site_domain)
		self.client.http_client.debug = False
		self.client.ssl = True
		
		try:
			service = self.client.auth_service
			source = SOURCE_APP_NAME
			self.client.client_login(email, password, source=source, service=service)
		except:
			print "Unexpected error:", sys.exc_info()[0]
			raise

	def Run(self):
		try:
			uri = '%s?path=%s' % (self.client.make_content_feed_uri(), self.path)
			feed = self.client.GetContentFeed(uri=uri)
			entry = feed.entry[0]
			
			update_file = "G:\\clcInfo_Docs\\gsitesinline\\" + self.path.replace("/", "__") + ".html"
			print update_file
			try:
				f = open(update_file, "r")
				entry.content.html = "<html:div xmlns:html=\"http://www.w3.org/1999/xhtml\">" + f.read() + "</html:div>"
				self.client.Update(entry)
			except:
				print "Unexpected error:", sys.exc_info()[0]
				
		except gdata.client.RequestError, error:
			print error
		except KeyboardInterrupt:
			return

def dump(obj):
	for attr in dir(obj):
		print "obj.%s = %s" % (attr, getattr(obj, attr))

def main():
	sample = MyUpdater(sys.argv[1])
	sample.Run()


if __name__ == '__main__':
	main()
