import os
import re
import json
from tqdm import tqdm
from bs4 import BeautifulSoup

import requests
from requests.adapters import HTTPAdapter

ORIGINAL_TAGS = {
    "ざぁ～こ♡": "メスガキ",
    "合意なし": "レイプ",
    "ひよこ": "ロリ",
    "つるぺた": "ロリ",
    "ひよこババア": "ロリババア",
    "つるぺたババア": "ロリババア",
    "閉じ込め": "監禁",
    "超ひどい": "鬼畜",
    "逆レ": "逆レイプ",
    "命令/無理矢理": "強制/無理矢理",
    "近親もの": "近親相姦",
    "責め苦": "拷問",
    "トランス/暗示": "催眠",
    "動物なかよし": "獣姦",
    "畜えち": "獣姦",
    "精神支配": "洗脳",
    "秘密さわさわ": "痴漢",
    "しつけ": "調教",
    "下僕": "奴隷",
    "屈辱": "凌辱",
    "回し": "輪姦",
    "虫えっち": "蟲姦",
    "モブおじさん": "モブ姦",
    "異種えっち": "異種姦",
    "機械責め": "機械姦",
    "すやすやえっち": "睡眠姦",
    "トランス/暗示": "睡眠音声",
}

RESTRICTED_TAGS = {
    '全年齢': '全年齢',
    'R-15': 'R-15',
    'R18': 'R-18',
    '18禁': 'R-18',
}


wbm_session = requests.Session()
wbm_session.mount('https://', HTTPAdapter(max_retries=5))
wbm_session.headers.update({
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3',
})

dl_session = requests.Session()
dl_session.mount('https://', HTTPAdapter(max_retries=5))
dl_session.headers.update({
    'User-Agent': 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3',
})
dl_session.proxies.update({
    'http': 'http://localhost:9000',
    'https': 'http://localhost:9000',
})
requests.utils.add_dict_to_cookiejar(dl_session.cookies, {
    'loginchecked': '1',
})


for base in tqdm(os.listdir('.')):
    if os.path.isfile(base + '/info.json'):
        continue

    info = {
        'RJ': None,
        'title': None,
        'circle': None,
        'cv': None,
        'series': None,
        'date': None,
        'genres': [],
    }

    if not (nmatch := re.search(r'[RV]J\d+', base)):
        continue
    info['RJ'] = nmatch.group(0)
    wbm_url = f'https://web.archive.org/web/2020/https://www.dlsite.com/maniax/work/=/product_id/{info["RJ"]}.html'
    dl_url = f'https://www.dlsite.com/home/work/=/product_id/{info["RJ"]}.html'

    res = wbm_session.get(wbm_url).text
    soup = BeautifulSoup(res, 'lxml')

    title_element = soup.select_one('#work_name')
    if title_element is None:
        res = dl_session.get(dl_url).text
        soup = BeautifulSoup(res, 'lxml')
        title_element = soup.select_one('#work_name')

        if title_element is None:
            tqdm.write(f"Warning: {info['RJ']} not found.")
            continue

    info['title'] = title_element.text.strip()
    info['circle'] = soup.select_one('#work_maker a').text.strip()

    outline_trs = soup.select('#work_outline tr')
    outline = {}
    for tr in outline_trs:
        outline[tr.select_one('th').text.strip()] = tr.select_one('td')

    if date := outline.get('販売日'):
        date = date.select_one('a').text.strip()
        info['date'] = re.sub(r'\D', '-', date)[:10]
    if cv := outline.get('声優'):
        info['cv'] = cv.select_one('a').text.strip()
    if series := outline.get('シリーズ名'):
        info['series'] = series.select_one('a').text.strip()
    if restricted := outline.get('年齢指定'):
        restricted = restricted.text.strip()
        info['genres'].append(RESTRICTED_TAGS[restricted])
    if genre := outline.get('ジャンル'):
        info['genres'].extend(list(map(lambda a : a.text.strip(), genre.select('a'))))

    try: info['genres'].remove('ASMR')
    except: pass
    for i in range(len(info['genres'])):
        if info['genres'][i] in ORIGINAL_TAGS:
            info['genres'][i] = ORIGINAL_TAGS[info['genres'][i]]

    with open(f'{base}/info.json', 'w') as f:
        json.dump(info, f, ensure_ascii=False, indent=2)
