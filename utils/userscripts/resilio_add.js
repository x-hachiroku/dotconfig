const BASE = 'http://10.6.8.6:7900/gui/?';
const TOKEN = '';

const ITEMS = [
  {
    "name": "",
    "key": ""
  },
];

let params = {
    'token': TOKEN,
    'action': 'addsyncfolder',
    'selectivesync': false
};

for (i of ITEMS) {
    console.log(i['key'], i['name']);

    params['path'] = '/downloads/'
    params['path'] += i['name']
    params['secret'] = i['key']
    params['t'] = Date.now()

    const url = BASE + new URLSearchParams(params).toString()
    console.log(url)
    res = await fetch(url, { 'method': 'GET' });

    console.log(res.status, await res.text())
}
