#!/usr/bin/env python3

import re
from pathlib import Path

from base import Base


FANBOX = 'customudon'

COOKIES_PATH = Path.home() / '.config/cookies/fanbox.json'

DATE_PATTERN = re.compile(r'(\d+)年(\d+)月(\d+)日')
BASE_URL = f'https://{FANBOX}.fanbox.cc/posts' + '?page={page}&sort=oldest'
ARIA2_BASE = f'/mnt/kitchen/{FANBOX}/'

class Main(Base):
    def __init__(self):
        super().__init__(timeout=3000)
        self.load_cookies(COOKIES_PATH)

        self.page_num = 1
        self.min_id = 0

    def parse_post(self, url):
        pid = url.split('/')[-1]
        if int(pid) < self.min_id:
            print(f'Skipping: {url}')
            return

        print(f'Processing: {url}')
        self.get(url)

        try:
            downloads = self.select_all('[class*="FileContent__DownloadLink"]')
        except:
            print(f'No download link found for {url}')
            return

        title = self.select('[class*="styled__PostTitle"]').inner_text()
        date_str = self.select('[class*="styled__PostHead"]').inner_text()
        y, m, d = DATE_PATTERN.search(date_str).groups()
        date = f'{y:0>4}{m:0>2}{d:0>2}'
        dir_name = f'{ARIA2_BASE}/[{date}] {title}'

        try:
            cover = (self.select('[class*="Cover__CoverImage"]')
                     .evaluate('el => getComputedStyle(el).backgroundImage')
            )
            cover_url = cover[5:-2]
            self.download(cover_url, dir_name, filename='folder.jpeg')
        except:
            pass

        links = [e.evaluate('el => el.href') for e in downloads]
        for link in links:
            self.download(link, dir_name)

    def main(self):
        while self.page_num > 0:
            print(f'Page: {self.page_num}')
            self.get(BASE_URL.format(page=self.page_num))
            try:
                self.select('pixiv-icon[name$="Next"]')
            except:
                print('No more pages')
                self.page_num = -1
            else:
                self.page_num += 1

            posts = self.select_all('[class*="CardPostItem__Wrapper"]')
            post_urls = [e.evaluate('el => el.href') for e in posts]
            [self.parse_post(url) for url in post_urls]


if __name__ == '__main__':
    with Main() as m:
        m.main()
