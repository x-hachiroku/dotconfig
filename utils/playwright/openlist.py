#!/usr/bin/env python3

import os
import json
import argparse
from pathlib import Path, PurePosixPath
from urllib.parse import unquote, urljoin, urlsplit

from base import Base


COOKIES_PATH = Path.home() / '.config/cookies/openlist.json'
PASSWORD = os.getenv('OPENLIST_PASSWORD', '')


class Main(Base):
    def __init__(self, args):
        super().__init__()
        self.load_cookies(COOKIES_PATH)

        parsed = urlsplit(args.url)
        self.base_url = f'{parsed.scheme}://{parsed.netloc}'
        self.path = PurePosixPath('/' + unquote(parsed.path).lstrip('/'))
        self.aria2_base /= parsed.netloc
        self.url = args.url

    def post(self, endpoint, path, **params):
        while True:
            self.pause()
            # Playwright has it's own http client for native request
            # Use evaluate here to preserve browser fingerprint
            response = self.page.evaluate('''async ({url, payload}) => {
                const response = await fetch(url, {
                    method: 'POST',
                    credentials: 'include',
                    headers: {'Content-Type': 'application/json'},
                    body: JSON.stringify(payload),
                    signal: AbortSignal.timeout(30000)
                });
                return {status: response.status, body: await response.text()};
            }''', {
                'url': f'{self.base_url}/api/fs/{endpoint}',
                'payload': {'path': path, 'password': PASSWORD, **params},
            })
            if response['status'] != 200:
                raise RuntimeError(f"{endpoint}: HTTP {response['status']}")
            result = json.loads(response['body'])
            if result['code'] != 200:
                raise RuntimeError(f"{endpoint}: {result['message']}")
            return result['data']

    def list_dir(self, path):
        page = 1
        count = 0
        while True:
            data = self.post('list', path, page=page, per_page=100, refresh=False)
            entries = data['content'] or []
            yield from entries
            count += len(entries)
            if not entries or count >= data['total']:
                return
            page += 1

    def main(self):
        self.page.goto(self.url, wait_until='domcontentloaded')
        input('Press enter to start')

        # Never thought I have to write a bfs somewhere not leetcode...
        pending = [self.path]
        queued = 0
        while pending:
            subdir = pending.pop()
            print(f'Listing: {subdir}')
            for entry in self.list_dir(str(subdir)):
                child = subdir / entry['name']
                if entry['is_dir']:
                    pending.append(child)
                    continue

                data = self.post('get', str(child))
                url = urljoin(self.base_url + '/', data['raw_url'])
                self.download(url, subdir.relative_to('/'), entry['name'])
                queued += 1
                print(f'Queued: {child}')
        print(f'Queued {queued} files.')


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Queue an OpenList dir in aria2.')
    parser.add_argument('url')
    args = parser.parse_args()
    with Main(args) as m:
        m.main()
