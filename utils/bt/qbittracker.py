import qbittorrentapi

CONN_INFO = {
    'host': "10.6.6.1",
    'port': 8080,
    'username': '',
    'password': ''
}

## https://qbittorrent-api.readthedocs.io/en/latest/apidoc/torrents.html#qbittorrentapi.torrents.TorrentsAPIMixIn.torrents_info
FILTERS = {
    # 'category': ''
}
KEY = ''
NEW = ''

## Do not edit below this line ##


qbt_client = qbittorrentapi.Client(**CONN_INFO)

with qbittorrentapi.Client(**CONN_INFO) as qbt_client:
    for torrent in qbt_client.torrents.info(**FILTERS):
        if torrent_info['trackers'][-1]['url'].includes(KEY):
            qbt_client.torrents_edit_tracker(
                    torrent_hash=torrent['hash'],
                    original_url=torrent['trackers'][-1]['url'],
                    new_url=NEW
            )
