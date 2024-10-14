#!/usr/bin/env python3

import argparse
import unicodedata
import tempfile, yaml
import re, os, pathlib
from subprocess import call
from functools import cmp_to_key

argparser = argparse.ArgumentParser()
argparser.add_argument('-i', action='store_true')
args = argparser.parse_args()

EDITOR = os.environ.get('EDITOR', 'vi')

GID_PATTERN = re.compile(r'\[\d+\]$')
URL_GID_PATTERN = re.compile(r'https://e[\-x]hentai\.org/g/(\d+?)/')
TITLE_PATTERN = re.compile(r'^(\(.*?\))?\s*(\[.*?\])?\s*(.*)')


def compare_title(a, b):
    a = TITLE_PATTERN.search(a[1]).group(3)
    b = TITLE_PATTERN.search(b[1]).group(3)
    if a < b: return -1
    return 1

def init(gallery):
    CIRCLE = '〇' # \u3007
    DOT = '・'    # \u30fb
    STAR = '☆'    # \u2606
    HEART = '♡'   # \u2661
    REPLACE_TABLE = {
        '/': '／','?': '？', '!': '！', '|': '｜', ':': '：',
        '’': "'", '´': "'", '‘': "'", '`': "'", '"': '＂', '”': '＂', '“': '＂',
        '*': '＊', '٭': '＊', '―': '-',
        '<': '＜', '>': '＞', '^': '＾', '~': '～', '&': '＆',
        '[': ' [', ']': '] ', '(': ' (', ')': ') ', '+': ' + ',
        '◯': CIRCLE, '○': CIRCLE, '⚬': CIRCLE, '⚫': CIRCLE, '⬤': CIRCLE, '●': CIRCLE,
        '·': DOT, '˙': DOT, '•': DOT, '∙': DOT, '⋅': DOT,
        '✭': STAR, '★': STAR, '✩': STAR, '✫': STAR, '✬': STAR, '✮': STAR, '✯': STAR, '✰': STAR,
        '❤': HEART, '❤': HEART, '♥': HEART,
    }

    if not os.path.exists(gallery + '/galleryinfo.txt'):
        print(f'No galleryinfo.txt found in {gallery}')
        name = gallery
    else:
        with open(gallery + '/galleryinfo.txt') as galleryinfo:
            info = galleryinfo.readlines()
        if gid := GID_PATTERN.search(gallery):
            gid = gid.group()
        elif gid := URL_GID_PATTERN.search(info[-1]):
            gid = f'[{gid.group(1)}]'
        else:
            print(f'No gid found in {gallery}')
            gid = ''
        name = info[0][6:].strip() + ' ' + gid

    name = unicodedata.normalize('NFKC', name)
    for k, v in REPLACE_TABLE.items():
        name = name.replace(k, v)
    name = re.sub(r'\s+', ' ', name)
    name = re.sub(r'\s+\.cbz', '.cbz', name)
    name = name.replace(') ]', ')]')
    name = name.replace('[ (', '[(')
    name = name.replace(') .', ').')
    name = name.strip()
    name = re.sub(r'^\.+', '', name)
    return name


original = os.listdir('.')
if args.i:
    original = [(n, init(n)) for n in original]
else:
    original = [(n, n) for n in original]
original.sort(key=cmp_to_key(compare_title))
modified = {f'{i:0>4}': n for i, (_, n) in enumerate(original)}
original = {f'{i:0>4}': n for i, (n, _) in enumerate(original)}

with tempfile.NamedTemporaryFile(mode='w+', suffix='.yaml') as tf:
    yaml.dump(modified, tf,
              width=1024, allow_unicode=True, default_style="'", default_flow_style=False)
    tf.flush()

    call([EDITOR, tf.name])

    tf.seek(0)
    modified = yaml.safe_load(tf)

for i in original:
    if i not in modified:
        pathlib.Path('tmp/'+os.path.dirname(original[i])).mkdir(parents=True, exist_ok=True)
        os.rename(original[i], f'tmp/{original[i]}')
    elif original[i] != modified[i]:
        if os.path.exists(modified[i]):
            print(f'{original[i]} -> {modified[i]} dst already exists')
            continue
        os.rename(original[i], modified[i])
