#!/usr/bin/env python3

import re
import json

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-i', action='store_true', help='save images')
parser.add_argument('-t', action='store_true', help='generate table')
parser.add_argument('p', nargs='?')
args = parser.parse_args()

import requests
from requests.adapters import HTTPAdapter
from bs4 import BeautifulSoup

CHARSET = re.compile(r'[^\w\s\-_]')
BASE_URL = f'https://vndb.org/'

rsession = requests.Session()
rsession.mount('https://', HTTPAdapter(max_retries=5))
rsession.headers.update({
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3',
})


def save_img(title, soup):
    img = soup.select_one('div.vnimg img')
    if not img:
        print(f"Warning: No image found for {title}")
        return
    img_url = img.get('src')
    img_url = img_url.replace('/cv.t/', '/cv/')
    ext = img_url.split('.')[-1]
    img_data = rsession.get(img_url).content
    filename = f"{len(l):02d}-{title}.{ext}"
    with open(filename, 'wb') as f:
        f.write(img_data)

def get_titles(l, title, soup):
    for span in soup.select('tr.title span'):
        if 'lang' not in span.attrs:
            continue
        if span.attrs['lang'] == 'ja':
            l[title]['ja'] = span.text
        elif span.attrs['lang'] == 'zh-Hans':
            l[title]['zh'].append(span.text)
        elif span.attrs['lang'] == 'zh-Hant' and not l[title]['zh']:
            l[title]['zh'].append(span.text)



l = {}

res = rsession.get(BASE_URL + args.p).text
soup = BeautifulSoup(res, 'lxml')
developer = soup.select_one('article h1').text.strip('.').strip().replace(' ', '')
developer = developer.replace(' ', '')

table = soup.select_one('table.releases')

for tr in table.select('tr'):
    if tr.has_attr('class'):
        title = tr.text
        title = CHARSET.sub(' ', title)
        title = title.strip('.').strip()
        title = re.sub(r'\s+', '.', title)
        l[title] = {'ja': '', 'zh': []}
        if args.i or args.t:
            link = tr.select_one('a').get('href')
            _res = rsession.get(BASE_URL + link).text
            _soup = BeautifulSoup(_res, 'lxml')
        if args.i:
            save_img(title, _soup)
        if args.t:
            get_titles(l, title, _soup)
    elif 'filename' in l[title] or tr.select_one('.icon-rel-free'):
        continue
    else:
        date = tr.select_one('.tc1').text
        date = date.replace('-', '')
        l[title]['filename'] = f"{developer}.{date}.{title}"

if args.t:
    with open(f'{developer}.json', 'w') as f:
        _l = {}
        for k, v in l.items():
            _l[v['filename']] = {'ja': v['ja'], 'zh': v['zh']}
        json.dump(_l, f, ensure_ascii=False)
else:
    with open(f'{developer}.txt', 'w') as f:
        _l = [i['filename'] for i in l.values() if 'filename' in i]
        f.write('\n'.join(_l) + '\n')
