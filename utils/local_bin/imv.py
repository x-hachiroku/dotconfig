#!/usr/bin/env python3

import tempfile, yaml
import re, os, glob, pathlib, argparse
from subprocess import call
from functools import cmp_to_key

if os.path.exists('tmp'):
    print('tmp dir exists')
    exit(1)

EDITOR = os.environ.get('EDITOR', 'vi')

def make_safe_filename(name, normalize=False, tree=True):
    CIRCLE = '〇' # \u3007
    DOT = '・'    # \u30fb
    STAR = '☆'    # \u2606
    HEART = '♡'   # \u2661
    normalize_table = {
        '~': '～', '&': '＆', '―': '-',
        '[': ' [', ']': '] ', '(': ' (', ')': ') ', '+': ' + ',
        '◯': CIRCLE, '○': CIRCLE, '⚬': CIRCLE, '⚫': CIRCLE, '⬤': CIRCLE, '●': CIRCLE,
        '·': DOT, '˙': DOT, '•': DOT, '∙': DOT, '⋅': DOT,
        '✭': STAR, '★': STAR, '✩': STAR, '✫': STAR, '✬': STAR, '✮': STAR, '✯': STAR, '✰': STAR,
        '❤': HEART, '❤': HEART, '♥': HEART,
    }

    replace_table = {
        '\\': '＼', '?': '？', '!': '！', '"': "'",
        '<': '＜', '>': '＞', '|': '｜', ':': '：', '*': '＊',
    }
    if not tree:
        replace_table['/'] = '／'
    if normalize:
        replace_table.update(normalize_table)

    replace_chars = ''.join(replace_table.keys())
    replace_pattern = re.compile(f'[{re.escape(replace_chars)}]')

    safename = replace_pattern.sub(lambda m: replace_table[m.group(0)], name)
    safename = re.sub(r'(\s+)', ' ', safename)
    safename = safename.replace(' .', '.')

    safename = safename.strip(' .')

    reserved = {
        'CON', 'PRN', 'AUX', 'NUL',
        *(f'COM{i}' for i in range(1, 10)),
        *(f'LPT{i}' for i in range(1, 10)),
    }
    if safename.upper().split('.')[0] in reserved:
        safename = f'_{name}'

    encoded = safename.encode('utf-8')
    if len(encoded) > 250:
        encoded = encoded[:230] + encoded[-20:]
    safe_name = encoded.decode('utf-8', errors='ignore')

    if name != safe_name:
        print(f'Normalized "{name}" -> "{safe_name}"')

    return safe_name

TITLE_PATTERN = re.compile(r'^(\(.*?\))?\s*(\[.*?\])?\s*(.*)')
def compare_gallery(a, b):
    a = TITLE_PATTERN.search(a[1]).group(3)
    b = TITLE_PATTERN.search(b[1]).group(3)
    if a < b: return -1
    return 1


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('-r', action='store_true', help='Recursive')
    parser.add_argument('-n', action='store_true', help='Normalize filenames')
    parser.add_argument('-g', action='store_true', help='Sort as gallery')
    parser.add_argument('-d', action='store')
    parser.add_argument('-p', default='*', help='Glob pattern')
    args = parser.parse_args()


    glob_pattern = args.p
    if args.r:
        glob_pattern = f'**/{glob_pattern}'
    if args.d:
        glob_pattern = f'{"*/"*int(args.d)}{glob_pattern}'

    if args.g:
        key = cmp_to_key(compare_gallery)
    else:
        key = None

    _original = sorted(glob.glob(glob_pattern, recursive=True), key=key)
    original = {f'{i:0>4}':n for i,n in enumerate(_original)}
    modified = {k:make_safe_filename(n, args.n, (args.r or args.d)) for k,n in original.items()}

# Auto delete breaks this on macOS :(
    with tempfile.NamedTemporaryFile(mode='w+', suffix='.yaml', delete=False) as tf:
        yaml.dump(modified, tf,
                  width=1024, allow_unicode=True, default_style="'", default_flow_style=False)
        tf.flush()
        tf_name = tf.name

    try:
        call([EDITOR, tf_name])
        with open(tf_name) as tf:
            modified = yaml.safe_load(tf)
            modified = {k:make_safe_filename(v, args.n, (args.r or args.d)) for k,v in modified.items()}
    finally:
        os.unlink(tf_name)

    for i in original:
        if i not in modified:
            pathlib.Path('tmp/'+os.path.dirname(original[i])).mkdir(parents=True, exist_ok=True)
            os.rename(original[i], f'tmp/{original[i]}')
        elif original[i] != modified[i]:
            if os.path.exists(modified[i]):
                print(f'File {modified[i]} already exists')
            else:
                print(f'Renaming {original[i]} -> {modified[i]}')
                os.rename(original[i], modified[i])
