#!/usr/bin/env python3

import re
import argparse
from pathlib import Path

from base import Base


COOKIES_PATH = Path.home() / '.config/cookies/dlsite.json'

DATE_PATTERN = re.compile(r'(\d+)/(\d+)/(\d+) ')

class Main(Base):
    def __init__(self, args):
        super().__init__()
        self.load_cookies(COOKIES_PATH)

        self.base_url = f'https://ci-en.dlsite.com/creator/{args.creator}/article' + '?mode=list&page={page}'
        self.aria2_base /= f'ci-en/{args.creator}/'
        self.after_id = args.after_id
        self.page_num = args.from_page

        if self.page_num < 0:
            self.get(self.base_url.format(page=1))
            self.page_num = int(self.select('div.pager a.pagerItem:has(+ a[rel="next"])').inner_text())

    def parse_post(self, url, cover=None):
        pid = url.split('/')[-1]
        if int(pid) <= self.after_id:
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
        subdir = Path(f'[{date}] {title}')

        if cover:
            self.download(cover, subdir, 'folder.jpeg')

        for box in boxes:
            category = self.select_from(box, 'h3.c-rewardBox-heading').inner_text()

            dls = self.select_all_from(box, 'a[download]')
            if not dls:
                print(f'No download link found for reward box in {url}')
                continue

            for dl in dls:
                dl_name = dl.evaluate('el => el.download')
                dl_link = dl.evaluate('el => el.href')
                name = f'[{date}] {dl_name}'
                self.download(dl_link, subdir, name)

    def main(self):
        while self.page_num > 0:
            print(f'Page: {self.page_num}')
            self.get(self.base_url.format(page=self.page_num))

            posts = self.select_all('div.c-cardCase-item')
            urls = [self.select_from(e, 'a.c-cardLink').evaluate('el => el.href') for e in posts]
            covers = [self.select_from(e, 'img').evaluate('el => el.getAttribute("data-src")') for e in posts]
            for url, cover in zip(urls, covers):
                self.parse_post(url, cover)

            self.page_num -= 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('creator', type=int)
    parser.add_argument('--after-id', type=int, default=0, help='Minimum post ID (exclusive; default: 0)')
    parser.add_argument('--from-page', type=int, default=-1, help='Page to start with, old to new (inclusive; default: last page, i.e. all posts)')
    args = parser.parse_args()
    with Main(args) as m:
        m.main()
