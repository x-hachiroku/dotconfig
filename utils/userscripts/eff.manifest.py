import re
import os, sys
from sys import argv
from tqdm import tqdm
from pathlib import Path
import requests
from requests.adapters import HTTPAdapter


UA = "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3"

source = sys.argv[1]

dir_base = '/'.join(source.split('/')[1:-1]) + '/'
url_base = "https://e-f-frontier.net/3pttezr5e12wovd_annex/" + dir_base

session = requests.Session()
session.mount('https://', HTTPAdapter(max_retries=5))
session.headers.update({
    'User-Agent': UA,
    'Referer': url_base + source.split('/')[2].split('.')[0] + '.html'
})

with open(source, 'r') as f:
    manifest = re.search(r'manifest: \[(.*?)\]', f.read(), re.DOTALL).group(1)
    for line in tqdm(manifest.split(',\n')):
        resource_path = re.search(r'src:"(.*?)"', line).group(1)
        path = dir_base + '/'.join(resource_path.split('/')[:-1])
        file = path + '/' + resource_path.split('/')[-1].split('?')[0]
        if os.path.exists(file):
            continue

        res = session.get(url_base+resource_path)
        Path(path).mkdir(exist_ok=True, parents=True)
        with open(path + '/' + resource_path.split('/')[-1].split('?')[0], 'wb') as f:
            f.write(res.content)
