#!/usr/bin/env python3

"""
Note: Disable the `Always use Multi-Page Viewer` option.
"""

import re
import json
import base64
import hashlib
import datetime
import argparse
from tqdm import tqdm
from time import sleep
from pathlib import Path

import requests
from requests.adapters import HTTPAdapter
from bs4 import BeautifulSoup, Tag
from bs4.element import NavigableString

import sys
import importlib.util

sys.path.insert(0,str(Path.home() / ".config/utils/local_bin"))
from imv import make_safe_filename

BASE_URL='https://exhentai.org'

PATH_PATTERN = re.compile(r'([0-9a-f_]+)\]?$')
TAG_PATTERN = re.compile(r"return toggle_tagmenu\(\d+,'(.*)',this\)")
URL_PATTERN = re.compile(r'/(\d+)/([0-9a-f_]+)/')

## Array.from(document.querySelectorAll('td.gl2e>div>a')).map(a => `'${a.href}'`).join(',\n');
TOKENS = { url_re.group(1): url_re.group(2) for url_re in map(URL_PATTERN.search, [
])}

print = tqdm.write

def html_to_text(tag: Tag, ehs):
    _inline_elements = { 'a', 'abbr', 'acronym', 'audio', 'b', 'bdi', 'bdo', 'big', 'button', 'canvas', 'cite', 'code', 'data', 'datalist', 'del', 'dfn', 'em', 'embed', 'i', 'iframe', 'img', 'input', 'ins', 'kbd', 'label', 'map', 'mark', 'meter', 'noscript', 'object', 'output', 'picture', 'progress', 'q', 'ruby', 's', 'samp', 'script', 'select', 'slot', 'small', 'span', 'strong', 'sub', 'sup', 'svg', 'template', 'textarea', 'time', 'u', 'tt', 'var', 'video', 'wbr', 'br' }
    def _get_text(tag: Tag):
        for child in tag.children:
            if isinstance(child, Tag):
                # if the tag is a block type tag then yield new lines before after
                is_block_element = child.name not in _inline_elements
                if is_block_element:
                    yield "\n"
                if child.name == "br":
                    yield "\n"
                elif child.name == "img":
                    ext = child['src'].split('.')[-1]
                    yield f'data:image/{ext};base64,{base64.b64encode(ehs.get(child["src"]).content).decode()}'
                else:
                    yield from _get_text(child)
                if is_block_element:
                    yield "\n"
            elif isinstance(child, NavigableString):
                yield child
    return "".join(_get_text(tag))


class EHSession:
    def __init__(self, min_interval=1):
        self.min_interval = min_interval

        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36",
        }
        proxies = {
            "https": 'http://127.0.0.1:9000'
        }

        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=5))
        self.session.headers.update(headers)
        # self.session.proxies.update(proxies)
        _cookies = Path.home() / ".config/eh-cookies.json"
        if _cookies.is_file():
            cookies = json.loads(_cookies.read_text())
            requests.utils.add_dict_to_cookiejar(self.session.cookies, cookies)

        self.last_req_time = 0

    def wait(self):
        _wait = self.min_interval - (datetime.datetime.now().timestamp() - self.last_req_time)
        sleep(_wait) if _wait > 0 else None
        self.last_req_time = datetime.datetime.now().timestamp()

    def get(self, *args, **kwargs):
        self.wait()
        res = self.session.get(*args, **kwargs)
        return res

    def post(self, *args, **kwargs):
        self.wait()
        res = self.session.post(*args, **kwargs)
        return res

    def gdata(self, gidlist):
        _url = f'{BASE_URL}/api.php'
        _json = {
            'method': 'gdata',
            'gidlist': gidlist,
            'namespace': 1,
        }
        res = self.post(_url, json=_json).json()['gmetadata']
        return res


def main():
    ehs = EHSession()

    parser = argparse.ArgumentParser()
    parser.add_argument('-f', action='store_true', help='rewrite existing')
    parser.add_argument('galleries', nargs='*', type=Path)
    args = parser.parse_args()

    galleries = args.galleries
    if not galleries:
        galleries = Path('.').iterdir()

    galleries = filter(lambda x: x.is_dir(), galleries)

    err = 0
    for gallery in tqdm(list(galleries)):
        if any(x.is_dir() for x in gallery.iterdir()):
            tqdm.write(f'{gallery} contains subdir, skipping.')
            continue

        key = []
        galleryinfo = gallery / 'galleryinfo.txt'
        if not args.f and galleryinfo.is_file():
            continue
        if _key := PATH_PATTERN.search(gallery.name):
            _key = _key.group(1)
            if '_' in _key:
                key = _key.split('_')[:2]
            elif _key in TOKENS:
                key = [_key, TOKENS[_key]]

        if not key and galleryinfo.is_file():
            if _key := URL_PATTERN.search(galleryinfo.read_text().splitlines()[-1]):
                key = _key.groups()

        if not key:
            cover_hash = hashlib.sha1(next(iter(gallery.iterdir())).read_bytes()).hexdigest()
            search_res = ehs.get(f'{BASE_URL}/?f_shash={cover_hash}')
            if _key := URL_PATTERN.findall(search_res.text):
                key = _key[-1] # take the last one and pray it's not expunge

        if not key:
            tqdm.write(f'{gallery} token not found.')
            continue


        res = ehs.get(f'{BASE_URL}/g/{key[0]}/{key[1]}/')
        soup = BeautifulSoup(res.text, 'lxml')
        attrs = soup.select('#gdd td')

        title = soup.select_one('#gj').text
        if not title:
            title = soup.select_one('#gn').text
        tags = [TAG_PATTERN.search(tag['onclick']).group(1) for tag in soup.select('#taglist div.gt a, #taglist div.gtl a')]

        info = [
            f"Title:       {title}",
            f"Upload Time: {attrs[1].text}",
            f"Uploaded By: {soup.select_one('#gdn').text}",
            f"Downloaded:  {datetime.datetime.now(datetime.UTC).strftime('%Y-%m-%d %H:%M')}",
            f"Tags:        {', '.join(tags)}",
            f"Category:    {soup.select_one('#gdc').text}",
        ]

        if (comments := soup.select_one('#comment_0')):
            info.append("\nUploader's Comments:\n")
            info.append(html_to_text(comments, ehs))
            info.append('')

        info.append(f"Downloaded by E-Hentai archiver from https://e-hentai.org/g/{key[0]}/{key[1]}/\n")
        galleryinfo.write_text('\n'.join(info))

        if 'other:out of order' in tags:
            err += 1
            tqdm.write(f'{gallery} is out of order, sorting skipped.')
            continue

        images = gallery.iterdir()
        (gallery / 'tmp').mkdir()
        local_hash_table = {}
        for image in images:
            if image.suffix == '.txt':
                continue
            local_hash = hashlib.sha1(image.read_bytes()).hexdigest()[:10]
            if local_hash in local_hash_table:
                image.unlink()
                continue
            _image = gallery / 'tmp' / image.name
            image.rename(_image)
            local_hash_table[local_hash] = _image

        checksums = list(map(lambda a: a['href'].split('/')[-2], soup.select('#gdt a')))
        thumb_pages = - (int(attrs[11].text.split(' ')[0]) // -len(checksums))
        for thumb_page in range(1, int(thumb_pages)):
            _res = ehs.get(f'{BASE_URL}/g/{key[0]}/{key[1]}/?p={thumb_page}')
            _soup = BeautifulSoup(_res.text, 'lxml')
            checksums += list(map(lambda a: a['href'].split('/')[-2], _soup.select('#gdt a')))

        not_found = []
        for page in range(len(checksums)):
            if checksums[page] not in local_hash_table:
                not_found.append(page+1)
                continue
            img = local_hash_table[checksums[page]]
            (gallery / f'{page+1:04d}{img.suffix}').hardlink_to(img)

        # sleep(1.1) # wait for my mergerfs file attr cache to be invalid
        for f in (gallery / 'tmp').iterdir():
            if f.stat().st_nlink > 1:
                f.unlink()

        orphaned = list((gallery / 'tmp').iterdir())
        if not orphaned:
            (gallery / 'tmp').rmdir()
            safename = make_safe_filename(title + f' [{key[0]}]')
            gallery.rename(gallery.with_name(safename))

        if not_found or orphaned:
            tqdm.write(f'{gallery}:', end=' ')
            if not_found:
                tqdm.write(f'{not_found} not found')
            if orphaned:
                tqdm.write(f'{len(orphaned)} orphaned file found')
            Path('err').mkdir(exist_ok=True)
            gallery.rename(f'err/{gallery}')
            err += 1

    return err


if __name__ == "__main__":
    raise SystemExit(main())
