#!/usr/bin/env python3

import tempfile, yaml
import re, os, glob, pathlib, argparse
from subprocess import call

if os.path.exists('tmp'):
    print('tmp dir exists')
    exit(1)

EDITOR = os.environ.get('EDITOR', 'vi')

parser = argparse.ArgumentParser()
parser.add_argument('-r', action='store_true')
parser.add_argument('-n', action='store_true')
parser.add_argument('-d', action='store')
parser.add_argument('-p', default='*')
args = parser.parse_args()

glob_pattern = args.p
if args.r:
    glob_pattern = f'**/{glob_pattern}'
if args.d:
    glob_pattern = f'{"*/"*int(args.d)}{glob_pattern}'

original = sorted(glob.glob(glob_pattern, recursive=True))
original = {f'{i:0>4}':n for i,n in enumerate(original)}
modified = {}
for i in original:
    modified[i] = original[i]
    if args.n:
        modified[i] = re.sub(r'\s+', ' ', modified[i])

# Auto delete fucks stuff up on macOS :(
with tempfile.NamedTemporaryFile(mode='w+', suffix='.yaml', delete=False) as tf:
    yaml.dump(modified, tf,
              width=1024, allow_unicode=True, default_style="'", default_flow_style=False)
    tf.flush()
    tf_name = tf.name

try:
    call([EDITOR, tf_name])
    with open(tf_name) as tf:
        modified = yaml.safe_load(tf)
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
            os.rename(original[i], modified[i])
