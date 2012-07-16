#!/usr/bin/env python

import re
import json
import requests
from termcolor import colored
from bs4 import BeautifulSoup as bs

BASE_URL = "http://www.summer.harvard.edu"

courses = []
for a in bs(requests.get(BASE_URL + "/courses").text).select('dd > a'):
    href = a.attrs['href']
    # Handle inconsistency in DOM
    if "/" not in href: href = "/courses/" + href
    print colored(a.text, "red", attrs=["bold"])
    for li in bs(requests.get(BASE_URL + href).text).find_all(href=re.compile("^#.*")):
        # Skip cruft that our regex caught
        if li.parent.name == 'li':
            title = li.next_sibling.strip().replace('\n', ' ')
            print "\tFound course: %s" % colored(title, attrs=["bold"])
            courses.append(title)

print json.dumps(courses)