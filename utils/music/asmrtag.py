import os, sys, glob

import re
import tempfile
import json, yaml
import unicodedata
from subprocess import call

from mutagen.flac import FLAC
from mutagen.easymp4 import EasyMP4
from mutagen.mp3 import EasyMP3
from mutagen.oggvorbis import OggVorbis

from mutagen.easyid3 import EasyID3
EasyID3.RegisterTextKey('comment', 'COMM')


EDITOR = os.environ.get('EDITOR', 'vi')

base = sys.argv[1]
with open(f'{base}/info.json', 'r') as f:
    info = json.load(f)

album = {
    'album': [info['title']],
    'albumartist': [info['circle']],
    'artist': [info['cv']],
    'date': [info['date'][:10]],
    'genres': info['genres'],
    'comment': [info['RJ']],
    'tracks': [],
}

audios = []
for file in sorted(glob.glob(glob.escape(base)+'/*.flac')):
    audios.append(FLAC(file))
for file in sorted(glob.glob(glob.escape(base)+'/*.m4a')):
    audios.append(EasyMP4(file))
for file in sorted(glob.glob(glob.escape(base)+'/*.mp3')):
    audios.append(EasyMP3(file))
for file in sorted(glob.glob(glob.escape(base)+'/*.ogg')):
    audios.append(OggVorbis(file))

for i in range(len(audios)):
    audios_dict = {}

    filename = os.path.splitext(os.path.basename(audios[i].filename))[0]
    disc, track, title = re.search(r'^(\d+-)?(\d+)( .*)?', filename).groups()

    disc = disc[:-1] if disc else '1'
    title = title[1:] if title else f'Track {track}'
    audios_dict['title'] = [title]
    audios_dict['discnumber'] = [disc]
    audios_dict['tracknumber'] = [track]
    album['tracks'].append(audios_dict)


with tempfile.NamedTemporaryFile(mode='w+', suffix='.yaml') as tf:
    yaml.dump(dict(album), tf,
              width=1024, allow_unicode=True, default_style="'", default_flow_style=False)
    tf.flush()

    call([EDITOR, tf.name])

    tf.seek(0)
    tf_text = tf.read()
    tf_text = unicodedata.normalize('NFC', tf_text)
    modified = yaml.load(tf_text, Loader=yaml.FullLoader)
    if not modified:
        print("Nothing to do")
        exit(0)
    modified_tracks = modified['tracks']


illegal_chars = r'[\/:\*\?"<>\|]'

for i in range(len(audios)):
    audios[i].delete()
    audios[i].update(modified_tracks[i])
    audios[i]['album'] = modified['album']
    audios[i]['albumartist'] = modified['albumartist']
    audios[i]['artist'] = modified['artist']
    audios[i]['date'] = modified['date']
    audios[i]['genre'] = modified['genres']
    audios[i]['comment'] = modified['comment']
    audios[i].save()

    filetype = audios[i].filename.split('.')[-1]
    new_name = f'{audios[i]["discnumber"][0]}-{audios[i]["tracknumber"][0]:0>2} {audios[i]["title"][0]}.{filetype}'
    new_name = re.sub(illegal_chars, '_', new_name)
    if new_name != audios[i].filename:
        os.rename(audios[i].filename, base+'/'+new_name)

new_base = f"[{modified['albumartist'][0]} ({modified['artist'][0]})] {modified['album'][0]} ({info['series']}) [{modified['comment'][0]}]"
new_base = re.sub(illegal_chars, '_', new_base)
if base != new_base:
    os.rename(base, new_base)
