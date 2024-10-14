#!/usr/bin/env python3

import re
from pathlib import Path

from base import Base


CREATER = 19528
START_PAGE = 1
MIN_ID = 0
COOKIES_PATH = Path.home() / '.config/cookies/dlsite.json'

DATE_PATTERN = re.compile(r'(\d+)/(\d+)/(\d+) ')
BASE_URL = f'https://ci-en.dlsite.com/creator/{CREATER}/article' + '?mode=list&page={page}'
ARIA2_BASE = f'/mnt/kitchen/ci-en/{CREATER}/'

class Main(Base):
    def __init__(self):
        super().__init__()
        self.load_cookies(COOKIES_PATH)

        self.page_num = START_PAGE
        self.min_id = MIN_ID

        if not self.page_num:
            self.get(BASE_URL.format(page=1))
            self.page_num = int(self.select('div.pager a.pagerItem:has(+ a[rel="next"])').inner_text())

    def parse_post(self, url, cover=None):
        pid = url.split('/')[-1]
        if int(pid) < self.min_id:
            print(f'Skipping: {url}')
            return

        print(f'Processing: {url}')
        self.get(url)

        boxes = self.select_all('.c-rewardBox')
        if not boxes:
            print(f'No reward box found for {url}')
            return

        title = self.select('h1.article-title').inner_text()
        date_str = self.select('span.e-date').inner_text()
        y, m, d = DATE_PATTERN.search(date_str).groups()
        date = f'{y:0>4}{m:0>2}{d:0>2}'
        dir_name = f'{ARIA2_BASE}/[{date}] {title}'

        if cover:
            self.download(cover, dir_name, 'folder.jpeg')

        for box in boxes:
            cat = self.select_from(box, 'h3.c-rewardBox-heading').inner_text()

            dls = self.select_all_from(box, 'a[download]')
            if not dls:
                print(f'No download link found for reward box in {url}')
                continue

            for dl in dls:
                dl_name = dl.evaluate('el => el.download')
                dl_link = dl.evaluate('el => el.href')
                name = f'[{date}] {dl_name}'
                self.download(dl_link, dir_name, name)

    def main(self):
        while self.page_num > 0:
            print(f'Page: {self.page_num}')
            self.get(BASE_URL.format(page=self.page_num))

            posts = self.select_all('div.c-cardCase-item')
            urls = [self.select_from(e, 'a.c-cardLink').evaluate('el => el.href') for e in posts]
            covers = [self.select_from(e, 'img').evaluate('el => el.getAttribute("data-src")') for e in posts]
            for url, cover in zip(urls, covers):
                self.parse_post(url, cover)

            self.page_num -= 1


if __name__ == '__main__':
    with Main() as m:
        m.main()
