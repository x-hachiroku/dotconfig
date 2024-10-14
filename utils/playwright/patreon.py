#!/usr/bin/env python3

import argparse
from urllib.parse import urlencode
from pathlib import Path
from datetime import datetime

from base import Base


COOKIES_PATH = Path.home() / '.config/cookies/patreon.json'

BASE_PARAMS = {
    'filters[user_can_access]': 'true',
    'sort': 'published_at'
}

class Main(Base):
    def __init__(self, args):
        super().__init__()
        self.load_cookies(COOKIES_PATH)
        self.base_url = f'https://patreon.com/c/{args.creator}/posts'
        self.aria2_base /= f'patreon/{args.creator}/'
        self.from_year = args.from_year
        self.to_year = args.to_year

    def process_month(self, year, month):
        BASE_PARAMS['filters[month]'] = f'{year}-{month}'
        self.get(f'{self.base_url}?{urlencode(BASE_PARAMS)}')

        while True:
            try:
                self.select('div[class^="MarginBottom-module"] button').click()
            except:
                print('No more pages')
                break

        try:
            posts = self.select_all('[data-tag="post-card"]')
        except:
            print(f'No posts found for {year}-{month}')
            return

        for post in posts:
            title = self.select_from(post, 'div[class^="PostTitle-module"]').inner_text()
            date = self.select_from(post, '[data-tag="post-published-at"]').inner_text()
            if not ',' in date:
                date = datetime.strptime(f'{date}, {datetime.now().year}', '%B %d, %Y')
            else:
                date = datetime.strptime(date, '%b %d, %Y')
            date = date.strftime('%Y%m%d')
            subdir = Path(f'[{date}] {title}')
            print(f'Processing: {subdir}')

            images = self.select_all_from(post, '[data-tag="gallery-image"]')
            files = self.select_all_from(post, '[data-tag="post-attachment-link"]')

            for image in images:
                url = image.evaluate('el => el.src')
                self.download(url, subdir)

            for file in files:
                url = file.evaluate('el => el.href')
                self.download(url, subdir)


    def main(self):
        for year in range(self.from_year, self.to_year + 1):
            for month in range(1, 13):
                self.process_month(year, month)

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('creator')
    parser.add_argument('--from-year', type=int, default=2020, help='inclusive; default: 2020')
    parser.add_argument('--to-year', type=int, default=datetime.now().year, help=f'inclusive; default: {datetime.now().year}')
    args = parser.parse_args()
    with Main(args) as m:
        m.main()
