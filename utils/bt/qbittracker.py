import qbittorrentapi

CONN_INFO = {
    'host': "10.6.8.6",
    'port': 7800,
    'username': '',
    'password': ''
}

## https://qbittorrent-api.readthedocs.io/en/latest/apidoc/torrents.html#qbittorrentapi.torrents.TorrentsAPIMixIn.torrents_info
FILTERS = {
    # 'category': ''
}
KEY = ''
NEW = ''


assert KEY and NEW

with qbittorrentapi.Client(**CONN_INFO) as qbt_client:
    for torrent in qbt_client.torrents.info(**FILTERS):
        for tracker in qbt_client.torrents_trackers(torrent_hash=torrent['hash']):
            if KEY in tracker['url']:
                qbt_client.torrents_edit_tracker(
                    torrent_hash=torrent['hash'],
                    original_url=tracker['url'],
                    new_url=NEW
                )
