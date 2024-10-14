#!/usr/bin/env python3

import re
import os, sys
import unicodedata

import argparse
parser = argparse.ArgumentParser()
parser.add_argument('-a', action='store_true')
parser.add_argument('-i', action='store_true')
parser.add_argument('RJ', nargs='?')
args = parser.parse_args()

import requests
from requests.adapters import HTTPAdapter
from bs4 import BeautifulSoup

FILENAME_PATTERN = re.compile(r'([RV]J\d+)[^V]*(V[\d\.]+)?', re.IGNORECASE)

CIRCLE = '〇' # \u3007
DOT = '・'    # \u30fb
STAR = '☆'    # \u2606
HEART = '♡'   # \u2661
REPLACE_TABLE = {
    '/': '／','?': '？', '!': '！', '|': '｜', ':': '：',
    '*': '＊', '٭': '＊', '―': '-',
    '<': '＜', '>': '＞', '^': '＾', '~': '～', '&': '＆',
    '◯': CIRCLE, '○': CIRCLE, '⚬': CIRCLE, '⚫': CIRCLE, '⬤': CIRCLE, '●': CIRCLE,
    '·': DOT, '˙': DOT, '•': DOT, '∙': DOT, '⋅': DOT,
    '✭': STAR, '★': STAR, '✩': STAR, '✫': STAR, '✬': STAR, '✮': STAR, '✯': STAR, '✰': STAR, '☆': STAR,
    '❤': HEART, '❤': HEART, '♥': HEART,
}



C_WORDS = sorted((
    '幼女',
    '園児',
    '幼稚園',
    '子供',
    'ロリの子',
    'ロリっ娘',
    'ロリ',
    'ランドセル',
    'メスガキ',
    'クソガキ',
    '奴隷',
    '催眠',
    '強姦',
    '輪姦',
    '強姦',
    '触手姦',
    '機械姦',
    '近親相姦',
), key=len, reverse=True)

CENSOR='〇'

def _gen_censored_re(word):
    _pattern = [f'[{t}{CENSOR}]' for t in word]
    return re.compile(''.join(_pattern))

censored_dict = {_gen_censored_re(word): word for word in C_WORDS}

def uncensor(text):
    for pattern, word in censored_dict.items():
        for match in pattern.finditer(text):
            if match.group(0).count(CENSOR) <= len(word) // 2:
                text = text.replace(match.group(0), word)
    return text


session = requests.Session()
session.mount('https://', HTTPAdapter(max_retries=5))
session.headers.update({
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3',
})
# session.proxies.update({
#     'http': 'http://localhost:9000',
#     'https': 'http://localhost:9000',
# })
requests.utils.add_dict_to_cookiejar(session.cookies, {
    'loginchecked': '1',
})


WEB_ARCHIVE = 'https://web.archive.org/web/2022/'

def get_name(RJ):
    url = f'https://www.dlsite.com/maniax/work/=/product_id/{RJ}.html'
    if args.a:
        url = WEB_ARCHIVE + url
    try:
        res = session.get(url).text
        soup = BeautifulSoup(res, 'lxml')
        circle = soup.select_one('#work_maker a').text
        title = soup.select_one('#work_name').text
        date = soup.select_one('#work_outline a').text
        date = re.sub(r'\D', '', date)[:8]

        name = f"[{circle}] [{date}] {title} [{RJ}]"
        name = unicodedata.normalize('NFC', name)
        for k, v in REPLACE_TABLE.items():
            name = name.replace(k, v)
        name = uncensor(name)
        return name
    except Exception as e:
        print(e)
        print(res)
        exit(1)


def get_img(RJ):
    rjdir = (int(RJ[2:]) + 999) // 1000 * 1000
    if RJ[2] == '0':
        rjdir = 'RJ0' + str(rjdir)
    else:
        rjdir = 'RJ' + str(rjdir)
    base = f'https://img.dlsite.jp/modpub/images2/work/doujin/{rjdir}/{RJ}'

    ext = 'webp'
    if session.head(base + '_img_main.webp').status_code != 200:
        ext = 'jpg'

    if not os.path.exists(f'folder.{ext}'):
        with open(f'folder.{ext}', 'wb') as f:
            f.write(session.get(base + f'_img_main.{ext}').content)

    for i in range(1, 10):
        if os.path.exists(f'{RJ}_img_smp{i}.{ext}'):
            continue
        if session.head(base + f'_img_smp{i}.{ext}').status_code == 200:
            with open(f'{RJ}_img_smp{i}.{ext}', 'wb') as f:
                f.write(session.get(base + f'_img_smp{i}.{ext}').content)
        else:
            break


if args.RJ:
    print("'"+get_name(args.RJ)+"'")
else:
    for d in os.listdir():
        if match := FILENAME_PATTERN.search(d):
            RJ = match.group(1).upper()
            version = match.group(2).upper() if match.group(2) else None

            if args.i:
                os.chdir(d)
                get_img(RJ)
                os.chdir('..')
            else:
                name = get_name(RJ)
                if version:
                    name += f' [{version}]'
                print(d, '->', name)
                os.rename(d, name)
