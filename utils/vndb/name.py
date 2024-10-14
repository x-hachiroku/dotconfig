#!/usr/bin/env python3

import re
import os, sys

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('v', nargs='?')
args = parser.parse_args()

import requests
from requests.adapters import HTTPAdapter
from bs4 import BeautifulSoup


rsession = requests.Session()
rsession.mount('https://', HTTPAdapter(max_retries=5))
rsession.headers.update({
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3',
})


def get_name(v):
    CHARSET = re.compile(r'[^\w\s\-_]')
    url = f'https://vndb.org/{v}'
    try:
        res = rsession.get(url).text

        soup = BeautifulSoup(res, 'lxml')
        title = soup.select_one('main > article h1').text
        title = CHARSET.sub(' ', title)
        title = re.sub(r'\s+', '.', title).strip('.').strip().replace(' ', '')

        releases = soup.select('.vnreleases tr')
        for release in releases:
            if not release.select('.icon-rel-free'):
                date = release.select_one('.tc1').text
                date = date.replace('-', '')
                break

        info = soup.select('article .stripe tr')
        for rol in info:
            cols = rol.select('td')
            if cols[0].text == 'Developer':
                developer = cols[1].text.strip('.').strip().replace(' ', '')
                break

        name = f"{developer}.{date}.{title}"
        return name
    except Exception as e:
        print(e)
        print(url)


print(get_name(args.v))
