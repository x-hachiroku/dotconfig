from transmission_rpc import Client

client = Client(
        host="10.6.6.6",
        port=7500,
        username="",
        password=""
    )

KEY = ''
NEW = ''

## Do not edit below this line ##

torrents = client.get_torrents()

for torrent in torrents:
    if KEY in torrent.trackers[0].announce:
        print(torrent.trackers[0].id, torrent.name)
        client.change_torrent(ids=torrent.id, tracker_replace=((0, NEW)))
