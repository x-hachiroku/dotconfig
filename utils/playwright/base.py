#!/usr/bin/env python3

import re
import json
import aria2p
from time import sleep
from time import monotonic
from pathlib import Path

from playwright.sync_api import sync_playwright

def make_safe_name(name, path=False):
    invalit_table = {
        '\\': '', '?': '', '"': "'",
        '<': '[', '>': ']', '|': '-', ':': '-', '*': '.',
    }
    if not path:
        invalit_table['/'] = ''
    invalid_chars = ''.join(invalit_table.keys())
    invalid_pattern = re.compile(f'[{re.escape(invalid_chars)}]')
    safe_name = invalid_pattern.sub(lambda m: invalit_table[m.group(0)], name)

    safe_name = re.sub(r'(\s+)', ' ', safe_name)
    safe_name = safe_name.replace(' .', '.')
    safe_name = safe_name.strip(' .')

    reserved = {
        'CON', 'PRN', 'AUX', 'NUL',
        *(f'COM{i}' for i in range(1, 10)),
        *(f'LPT{i}' for i in range(1, 10)),
    }
    if safe_name.upper().split('.')[0] in reserved:
        safe_name = f'_{safe_name}'

    encoded = safe_name.encode('utf-8')
    if len(encoded) > 250:
        encoded = encoded[:230] + encoded[-20:]
    safe_name = encoded.decode('utf-8', errors='ignore')

    return safe_name

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

        self.aria2_base = Path(self.aria2.client.get_global_option()['dir'])

        self._playwright = sync_playwright().start()
        self.browser = self._playwright.chromium.launch(
            headless=headless,
            args=["--disable-blink-features=AutomationControlled"]
        )
        self.context = self.browser.new_context(
            viewport={
                'width': 1920,
                'height': 1440,
            }
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
        t = self.min_interval - (monotonic() - self.last_req_time)
        sleep(t) if t > 0 else None
        self.last_req_time = monotonic()

    def get(self, url):
        self.pause()
        response = self.page.goto(url, wait_until='domcontentloaded')
        if response is None or not response.ok:
            status = response.status if response else 'N/A'
            raise RuntimeError(f'GET {url} failed with status {status}')

    def download(self, url, subdir='', out=None):
        subdir = make_safe_name(str(subdir), path=True)
        options = {
            'dir': str(self.aria2_base / subdir),
            'user-agent': self.page.evaluate('navigator.userAgent'),
            'header': [f'Cookie: {self.page.evaluate("navigator.userAgent")}'],
        }
        if out:
            options['out'] = make_safe_name(out)
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
