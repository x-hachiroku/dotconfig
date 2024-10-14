#!/usr/bin/env python3

import argparse
import re
from pathlib import Path

from base import Base


COOKIES_PATH = Path.home() / '.config/cookies/fantia.json'

DATE_PATTERN = re.compile(r'(\d+)/(\d+)/(\d+) ')

class Main(Base):
    def __init__(self, args):
        super().__init__()
        self.load_cookies(COOKIES_PATH)

        self.base_url = f'https://fantia.jp/fanclubs/{args.creator}/posts' + '?page={page}'
        self.aria2_base /= f'fantia/{args.creator}/'
        self.after_id = args.after_id
        self.page_num = args.from_page

        if self.page_num < 0:
            self.get(self.base_url.format(page=1))
            last_page_url = self.select('ul.pagination li:last-child a').evaluate('el => el.href')
            self.page_num = int(re.search(r'page=(\d+)', last_page_url).group(1))

    def parse_post(self, url):
        pid = url.split('/')[-1]
        if int(pid) <= self.after_id:
            print(f'Skipping: {url}')
            return

        print(f'Processing: {url}')
        self.get(url)

        try:
            contents = self.select_all('.post-content')
        except:
            print(f'No contents found for {url}')
            return

        title = self.select('h1.post-title').inner_text()
        date_str = self.select('.post-meta .post-date').inner_text()
        y, m, d = DATE_PATTERN.search(date_str).groups()
        date = f'{y:0>4}{m:0>2}{d:0>2}'
        subdir = f'[{date}] {title}'

        try:
            cover = self.select('source.img-default').get_attribute('srcset')
            self.download(cover, subdir, 'folder.webp')
        except:
            pass

        for content in contents:
            links = self.select_all_from(content, 'a[download]')
            if len(links) >1:
                raise ValueError(f'Multiple download links found for content in {url}')
            if not links:
                print(f'No download link found for content in {url}')
                continue
            link = links[0].evaluate('el => el.href')

            subtitle = self.select_from(content, 'h2').inner_text()
            cat = self.select_from(content, '.post-content-for').inner_text()
            suggested = self.select_from(content, 'a[download] + div').inner_text()
            ext = suggested.split('.')[-1]
            name = f'[{date}] {subtitle}.{ext}'
            self.download(link, subdir, name)

    def main(self):
        while self.page_num > 0:
            print(f'Page: {self.page_num}')
            self.get(self.base_url.format(page=self.page_num))

            posts = self.select_all('div.post-md-square a.link-block')
            post_urls = [e.evaluate('el => el.href') for e in posts]
            [self.parse_post(url) for url in post_urls]

            self.page_num -= 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('creator')
    parser.add_argument('--after-id', type=int, default=0, help='Minimum post ID (exclusive; default: 0)')
    parser.add_argument('--from-page', type=int, default=-1, help='Page to start with, old to new (inclusive; default: last page, i.e. all posts)')
    args = parser.parse_args()
    with Main(args) as m:
        m.main()
