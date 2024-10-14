#!/usr/bin/env python3
import os
import re, glob
import argparse
import unicodedata
import tempfile, yaml
from subprocess import call

from mutagen.flac import FLAC
from mutagen.easymp4 import EasyMP4
from mutagen.mp3 import EasyMP3
from mutagen.oggvorbis import OggVorbis

from mutagen.easyid3 import EasyID3
EasyID3.RegisterTextKey('comment', 'COMM')

EDITOR = os.environ.get('EDITOR', 'vi')

parser = argparse.ArgumentParser()
parser.add_argument('-n', action='store_true', help='use filenames')
parser.add_argument('base')
args = parser.parse_args()
base = args.base


def windows_name(name):
    name = name.strip()
    ILLEGAL_CHARS = r'[\/:\*\?"<>\|]'
    name = re.sub(ILLEGAL_CHARS, '_', name)
    while name.endswith('.'):
        name = name[:-1]
    return name


audios = []
for file in sorted(glob.glob(glob.escape(base)+'/*.flac')):
    audios.append(FLAC(file))
for file in sorted(glob.glob(glob.escape(base)+'/*.m4a')):
    audios.append(EasyMP4(file))
for file in sorted(glob.glob(glob.escape(base)+'/*.mp3')):
    audios.append(EasyMP3(file))
for file in sorted(glob.glob(glob.escape(base)+'/*.ogg')):
    audios.append(OggVorbis(file))


tracks = []
album = {'album': [''], 'albumartist': [''], 'date': [''], 'tracks': tracks}


for i in range(len(audios)):
    audio_dict = dict(audios[i])
    keys = tuple(audio_dict.keys())

    to_split = {'artist', 'albumartist', 'composer', 'label', 'genre'}
    for key in keys:
        if (len(audio_dict[key]) == 1 and audio_dict[key][0] == '') or len(key) == 36:
            del audio_dict[key]
            continue
        if key in to_split and len(audio_dict[key]) == 1:
            audio_dict[key] = re.split(r'\s*[,、，;\/／；&＆]\s*', audio_dict[key][0])
        for j in range(len(audio_dict[key])):
            audio_dict[key][j] = audio_dict[key][j].replace('：', ':')
            audio_dict[key][j] = re.sub(r'CV[.: ]+', 'CV:', audio_dict[key][j], flags=re.IGNORECASE)
            audio_dict[key][j] = audio_dict[key][j].replace('（', '(')
            audio_dict[key][j] = audio_dict[key][j].replace('）', ')')

    filename = os.path.splitext(os.path.basename(audios[i].filename))[0]
    try:
        disc, track, title = re.findall(r'^(\d-)?(\d+) (.*)', filename)[0]

        disc = disc[:-1] if disc else '1'
        if args.n or 'title' not in keys:
            audio_dict['title'] = [title]
        if 'discnumber' not in keys:
            audio_dict['discnumber'] = [disc]
        if 'tracknumber' not in keys:
            audio_dict['tracknumber'] = [track]
    except:
        pass

    if not album['date'][0]:
        if 'date' in audio_dict:
            album['date'][0] = audio_dict['date'][0][:10]
        elif 'year' in audio_dict:
            album['date'][0] = audio_dict['year'][0][:10]

    if args.n:
        album['album'] = [os.path.basename(base)]
    elif (not album['album'][0]) and ('album' in audio_dict):
        album['album'] = audio_dict['album'][:]

    if not album['albumartist'][0]:
        if 'albumartist' in audio_dict:
            album['albumartist'] = audio_dict['albumartist'][:]
        elif 'album_artist' in audio_dict:
            album['albumartist'] = audio_dict['album_artist'][:]
        elif 'artist' in audio_dict:
            album['albumartist'] = audio_dict['artist'][:]

    keys = tuple(audio_dict.keys())
    trash_tags = {'album', 'albumartist', 'date', 'mood', 'performer', 'year', 'organization'}
    for key in keys:
        if key in trash_tags:
            del audio_dict[key]

    required = ['title', 'artist']
    for r in required:
        if r not in audio_dict:
            audio_dict[r] = ['']

    tracks.append(audio_dict)

if not album['album'][0]:
    album['album'] = [os.path.basename(base)]


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

for i in range(len(audios)):
    audios[i].delete()
    audios[i].update(modified_tracks[i])
    audios[i]['album'] = modified['album']
    audios[i]['albumartist'] = modified['albumartist']
    audios[i]['date'] = modified['date']
    if 'artist' not in audios[i]:
        audios[i]['artist'] = modified['albumartist']
    audios[i].save()

    filetype = audios[i].filename.split('.')[-1]
    discnumber = audios[i]['discnumber'][0] if 'discnumber' in audios[i] else '1'
    new_name = f'{discnumber}-{audios[i]["tracknumber"][0]:0>2} {modified_tracks[i]["title"][0]}.{filetype}'
    new_name = windows_name(new_name)
    if new_name != audios[i].filename:
        os.rename(audios[i].filename, base+'/'+new_name)

new_base = modified['album'][0]
if new_base[0] != '「':
    new_base = f'{";".join(modified["albumartist"]).replace(":", "")} - {modified["album"][0]}'
new_base = windows_name(new_base)
if base != new_base:
    os.rename(base, new_base)
