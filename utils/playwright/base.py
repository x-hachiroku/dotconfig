#!/usr/bin/env python3

import json
import aria2p
from time import sleep
from datetime import datetime

from playwright.sync_api import sync_playwright

UA='user-agent=Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36'

class Base:
    def __init__(
        self,
        min_interval=2,
        timeout=3000,
        headless=False
    ):
        self.min_interval = min_interval
        self.last_req_time = 0
        self.timeout = timeout

        self.aria2 = aria2p.API(
            aria2p.Client(
                host='http://10.6.8.6',
                port=7000,
            )
        )

        self._playwright = sync_playwright().start()
        self.browser = self._playwright.chromium.launch(headless=headless)
        self.context = self.browser.new_context(
            user_agent=UA,
            viewport={'width': 1920, 'height': 1440}
        )
        self.page = self.context.new_page()

    def close(self):
        self.browser.close()
        self._playwright.stop()

    def __enter__(self):
        return self

    def __exit__(self, *_):
        self.close()

    def load_cookies(self, cookies_path, domain=None):
        cookies = json.loads(cookies_path.read_text())
        for cookie in cookies:
            if 'expirationDate' in cookie:
                del cookie['expirationDate']
            cookie['path'] = '/'
            cookie['sameSite'] = 'None'
            if domain:
                cookie['domain'] = domain
        self.context.add_cookies(cookies)

    def get_cookies_header(self):
        return '; '.join(f'{c["name"]}={c["value"]}' for c in self.context.cookies())

    def pause(self):
        t = self.min_interval - (datetime.now().timestamp() - self.last_req_time)
        sleep(t) if t > 0 else None
        self.last_req_time = datetime.now().timestamp()

    def get(self, url):
        self.pause()
        response = self.page.goto(url, wait_until='domcontentloaded')
        if response is None or not response.ok:
            status = response.status if response else 'N/A'
            raise RuntimeError(f'GET {url} failed with status {status}')

    def download(self, url, path, filename=None):
        options = {
            'dir': path,
            'header': [f'Cookie: {self.get_cookies_header()}'],
        }
        if filename:
            options['out'] = filename
        self.aria2.add_uris([url], options=options)

    def select(self, selector):
        return self.page.wait_for_selector(selector, timeout=self.timeout)

    def select_all(self, selector):
        self.page.wait_for_selector(selector, timeout=self.timeout)
        return self.page.query_selector_all(selector)

    @staticmethod
    def select_from(element, selector):
        return element.query_selector(selector)

    @staticmethod
    def select_all_from(element, selector):
        return element.query_selector_all(selector)
