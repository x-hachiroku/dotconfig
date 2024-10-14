#!/usr/bin/env python3

import re
import json
import base64, hashlib
import os, pathlib, argparse, subprocess
import datetime
from tqdm import tqdm
from time import sleep

import requests
from requests.adapters import HTTPAdapter
from bs4 import BeautifulSoup, Tag
from bs4.element import NavigableString

## Note: This script requires the Always use Multi-Page Viewer option disabled.

PATH_PATTERN = re.compile(r'([0-9a-f_]+)\]?$')
TAG_PATTERN = re.compile(r"return toggle_tagmenu\(\d+,'(.*)',this\)")
URL_PATTERN = re.compile(r'https?://exhentai\.org/g/(\d+)/([0-9a-f_]+)/')

## Array.from(document.querySelectorAll('td.gl2e>div>a')).map(a => `'${a.href}'`).join(',\n');
TOKENS = { url_re.group(1): url_re.group(2) for url_re in map(URL_PATTERN.search, [
])}


def html_to_text(tag: Tag):
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
    def __init__(self):
        headers = {
            "User-Agent": "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/58.0.3029.110 Safari/537.36",
        }
        proxies = {
            "http": 'http://127.0.0.1:9000',
            "https": 'http://127.0.0.1:9000'
        }
        with open(os.path.expanduser('~/.config/eh-cookies.json')) as f:
            cookies = json.load(f)

        self.session = requests.Session()
        self.session.mount('https://', HTTPAdapter(max_retries=5))
        self.session.headers.update(headers)
        # self.session.proxies.update(proxies)
        requests.utils.add_dict_to_cookiejar(self.session.cookies, cookies)

        self.last_req_time = 0

    def wait(self):
        _wait = 2 - (datetime.datetime.now().timestamp() - self.last_req_time)
        sleep(_wait) if _wait > 0 else None
        self.last_req_time = datetime.datetime.now().timestamp()

    def get(self, url):
        self.wait()
        res = self.session.get(url)
        return res

    def gdata(self, gidlist):
        _url = 'https://exhentai.org/api.php'
        _json = {
            'method': 'gdata',
            'gidlist': gidlist,
            'namespace': 1,
        }
        self.wait()
        res = self.session.post(_url, json=_json).json()['gmetadata']
        return res


ehs = EHSession()

parser = argparse.ArgumentParser()
parser.add_argument('-f', action='store_true', help='force regenerate')
args = parser.parse_args()


galleries = os.listdir('.')
galleries = list(filter(lambda x: os.path.isdir(x), galleries))
if not args.f:
    galleries = list(filter(lambda x: not os.path.exists(f'{x}/galleryinfo.txt'), galleries))

err = 0
for gallery in tqdm(galleries):
    gid = None
    assert len(list(filter(lambda x: os.path.isdir(x), os.listdir(gallery)))) == 0, f'{gallery} contains subdirectories'
    os.mkdir(f'{gallery}/tmp')

    images = os.listdir(gallery)
    images.sort()
    images = list(filter(lambda x: x.endswith(('jpg', 'jpeg', 'png', 'gif', 'webp', 'JPG', 'JPEG', 'PNG', 'GIF', 'WEBP')), images))
    local_hash_table = {}

    for image in images:
        with open(f'{gallery}/{image}', 'rb') as f:
            local_hash = hashlib.sha1(f.read()).hexdigest()[:10]
        if local_hash in local_hash_table:
            tqdm.write(f'{gallery}/{image} duplicated with {local_hash_table[local_hash]}, removing.')
            os.remove(f'{gallery}/{image}')
            continue
        local_hash_table[local_hash] = image
        os.rename(f'{gallery}/{image}', f'{gallery}/tmp/{image}')

    if os.path.exists(f'{gallery}/galleryinfo.txt'):
        with open(f'{gallery}/galleryinfo.txt') as f:
            if gid := URL_PATTERN.search(f.readlines()[-1]):
                gid = [gid.group(1), gid.group(2)]

    if not gid and (path := PATH_PATTERN.search(gallery)):
        path = path.group(1)
        if '_' in path:
            gid = path.split('_')[:2]
        elif path in TOKENS:
            gid = [path, TOKENS[path]]

    if not gid:
        file_search_url = 'https://exhentai.org/?f_shash={sha1}&fs_covers=on'
        cover_hash = next(iter(local_hash_table))
        search_res = ehs.get(file_search_url.format(sha1=cover_hash))
        if gid := URL_PATTERN.search(search_res.text):
            gid = [gid.group(1), gid.group(2)]

    if gid:
        gid[0] = int(gid[0])
    else:
        tqdm.write(f'{gallery} token not found.')
        continue


    res = ehs.get(f'https://exhentai.org/g/{gid[0]}/{gid[1]}/')
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
        info.append(html_to_text(comments))
        info.append('')

    info.append(f"Downloaded by E-Hentai archiver from https://exhentai.org/g/{gid[0]}/{gid[1]}/\n")

    with open(f'{gallery}/galleryinfo.txt', 'w') as f:
        f.write('\n'.join(info))


    checksums = list(map(lambda a: a['href'].split('/')[-2], soup.select('#gdt a')))
    thumb_pages = - (int(attrs[11].text.split(' ')[0]) // -len(checksums))
    for thumb_page in range(1, int(thumb_pages)):
        _res = ehs.get(f'https://exhentai.org/g/{gid[0]}/{gid[1]}/?p={thumb_page}')
        _soup = BeautifulSoup(_res.text, 'lxml')
        checksums += list(map(lambda a: a['href'].split('/')[-2], _soup.select('#gdt a')))

    not_found = []
    for page in range(len(checksums)):
        if checksums[page] not in local_hash_table:
            not_found.append(page+1)
            continue
        img = local_hash_table[checksums[page]]
        ext = img.split('.')[-1]
        os.link(
            f'{gallery}/tmp/{img}',
            f'{gallery}/{page+1:04d}.{ext}'
        )

    # sleep(1.1) # wait for my mergerfs file attr cache to be invalid, remove if not needed
    subprocess.call(['find', f'{gallery}/tmp', '-type', 'f', '-links', '+1', '-delete'])
    ophaned_files = os.listdir(f'{gallery}/tmp')
    if not_found or ophaned_files:
        tqdm.write(f'{gallery}:')
        if not_found:
            tqdm.write(f'{not_found} not found')
        if ophaned_files:
            tqdm.write(f'{len(ophaned_files)} orphaned files found')
        pathlib.Path('err').mkdir(exist_ok=True)
        os.rename(gallery, f'err/{gallery}')
        err += 1
    if not ophaned_files:
        os.rmdir(f'{gallery}/tmp')

exit(min(err, 233))
