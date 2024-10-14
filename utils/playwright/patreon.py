#!/usr/bin/env python3

from pathlib import Path
from datetime import datetime

from base import Base


CREATER = 'vicineko'
MIN_ID = 0
COOKIES_PATH = Path.home() / '.config/cookies/patreon.json'

BASE_URL = f'https://patreon.com/c/{CREATER}/posts'
ARIA2_BASE = f'/mnt/kitchen/patreon/{CREATER}/'

class Main(Base):
    def __init__(self):
        super().__init__(timeout=10000)
        self.load_cookies(COOKIES_PATH)

        self.min_id = MIN_ID

    def main(self):
        self.get(BASE_URL)

        # while True:
        #     try:
        #         self.select('div[class^="MarginBottom-module"] button').click()
        #     except:
        #         print('No more pages')
        #         break

        posts = self.select_all('[data-tag="post-card"]')
        for post in posts:
            title = self.select_from(post, 'div[class^="PostTitle-module"]').inner_text()
            date = self.select_from(post, '[data-tag="post-published-at"]').inner_text()
            if not ',' in date:
                date = datetime.strptime(f'{date}, {datetime.now().year}', '%B %d, %Y')
            else:
                date = datetime.strptime(date, '%b %d, %Y')
            date = date.strftime('%Y%m%d')
            dir_name = f'{ARIA2_BASE}/[{date}] {title}'
            print(f'Processing: {dir_name}')

            links = self.select_all_from(post, '[data-tag="post-attachment-link"]')
            try:
                cover = self.select_from(post, '[data-tag="gallery-image"]').evaluate('el => el.getAttribute("src")')
                # self.download(cover, dir_name, 'folder.jpeg')
                print(f'Downloading: {cover}')
            except:
                pass

            for link in links:
                print(f'Downloading: {link.evaluate("el => el.getAttribute('href')")}')
                # self.download(link.evaluate('el => el.getAttribute("href")'), dir_name)

if __name__ == '__main__':
    with Main() as m:
        m.main()
