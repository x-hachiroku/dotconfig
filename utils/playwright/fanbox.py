#!/usr/bin/env python3

import re
import argparse
from pathlib import Path

from base import Base


COOKIES_PATH = Path.home() / '.config/cookies/fanbox.json'

DATE_PATTERN = re.compile(r'(\d+)年(\d+)月(\d+)日')

class Main(Base):
    def __init__(self, args):
        super().__init__(timeout=3000)
        self.load_cookies(COOKIES_PATH)

        self.base_url = f'https://{args.creator}.fanbox.cc/posts' + '?page={page}&sort=oldest'
        self.aria2_base /= f'fanbox/{args.creator}/'
        self.after_id = args.after_id
        self.page_num = args.from_page

    def parse_post(self, url):
        pid = url.split('/')[-1]
        if int(pid) <= self.after_id:
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
        subdir = Path(f'[{date}] {title}')

        try:
            cover = self.select('[class*="Cover__CoverImage"]').evaluate('el => getComputedStyle(el).backgroundImage')
            cover_url = cover[5:-2]
            self.download(cover_url, subdir, 'folder.jpeg')
        except:
            pass

        links = [e.evaluate('el => el.href') for e in downloads]
        for link in links:
            self.download(link, subdir)

    def main(self):
        while self.page_num > 0:
            print(f'Page: {self.page_num}')
            self.get(self.base_url.format(page=self.page_num))
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
    parser = argparse.ArgumentParser()
    parser.add_argument('creator')
    parser.add_argument('--after-id', type=int, default=0, help='Minimum post ID (exclusive; default: 0)')
    parser.add_argument('--from-page', type=int, default=1, help='Page to start with, old to new (inclusive; default: 1, i.e. all posts)')
    args = parser.parse_args()
    with Main(args) as m:
        m.main()
