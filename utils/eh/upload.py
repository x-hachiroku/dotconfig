#!/usr/bin/env python3

import re
import json
import asyncio
import argparse
import mimetypes
import httpx
from pathlib import Path
from urllib.parse import urlsplit, parse_qsl, urlencode


TIMEOUT = 120
MAX_CONNECTIONS=8
COOKIE_PATH = Path.home() / ".config/cookies/eh.json"

_headers = {
    "User-Agent": "Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/119.0.0.0 Safari/537.3"
}
_cookies = json.loads(COOKIE_PATH.read_text())
_limits = httpx.Limits(max_connections=MAX_CONNECTIONS, max_keepalive_connections=MAX_CONNECTIONS)

## httpx retry sucks...
# _transport = httpx.AsyncHTTPTransport(retries=5)

client = httpx.AsyncClient( # bite me
    headers=_headers,
    cookies=_cookies,
    limits=_limits,
    # transport=_transport,
    timeout=TIMEOUT,
    follow_redirects=True,
)

NEW_GALLERY_URL = "https://upload.e-hentai.org/managegallery?act=new"
CATEGORIES = {
    "doujinshi": "2",
    "manga": "3",
    "artist-cg": "4",
    "game-cg": "5",
    "western": "10",
    "non-h": "9",
    "image-set": "6",
    "cosplay": "7",
    "misc": "1",
    "private": "0",
}


async def fetch_progress_key() -> str:
    response = await client.get(NEW_GALLERY_URL, timeout=TIMEOUT)
    response.raise_for_status()

    progresskey = re.search(
        r'<input type="hidden" name="PHP_SESSION_UPLOAD_PROGRESS" id="progresskey" value="([^"]+)" />',
        response.text,
    )
    if not progresskey:
        raise SystemExit("Could not find PHP_SESSION_UPLOAD_PROGRESS key in response.")
    return progresskey.group(1)


async def post_file(
    url: str,
    data: dict,
    file_path: Path,
) -> httpx.Response:
    if file_path.suffix.lower() in (".zip", ".cbz"):
        mime_type = "application/zip"
    else:
        mime_type, _ = mimetypes.guess_type(file_path.name)

    with file_path.open("rb") as h:
        files_data = [("files[]", (file_path.name, h, mime_type))]
        for retry in range(3):
            try:
                response = await client.post(url, data=data, files=files_data)
                response.raise_for_status()
                return response
            except Exception as e:
                print(f"Got error, retrying {retry + 1}/3: {e}")
    raise SystemExit("Giving up")

def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("target", type=Path, help="Path to zip archive or directory to upload")
    parser.add_argument("--title", required=True)
    parser.add_argument("--title-jp", default="")
    parser.add_argument("--category", default="doujinshi", choices=CATEGORIES.keys())
    parser.add_argument("--language-type", default="official", choices=("official", "translated", "rewrite"))
    parser.add_argument("--human-translated", default=False, action="store_true")
    parser.add_argument("--comment", default="")
    parser.add_argument("--no-publish", default=False, action="store_true", help="Save gallery as draft without publishing")
    return parser.parse_args()

async def main() -> int:
    args = parse_args()

    target = args.target.expanduser().resolve()

    if target.is_file():
        files = [target]
    elif target.is_dir():
        files = sorted([p for p in target.rglob("*")
                        if (p.is_file() and p.suffix.lower()[1:] in ('jpg', 'jpeg', 'png', 'webp', 'webm', 'bpm', 'gif'))])
        if not files:
            raise SystemExit(f"No valid files found in directory: {target}")
    else:
        raise SystemExit(f"Invalid target path: {target}")

    progress_key = await fetch_progress_key()
    print(f"Progress key fetched: {progress_key}")

    fields = {
        "MAX_FILE_SIZE": "1258291200",
        "PHP_SESSION_UPLOAD_PROGRESS": progress_key,
        "do_save": "1",
        "gname_en": args.title,
        "gname_jp": args.title_jp,
        "category": CATEGORIES[args.category],
        "langtag": "0",
        "langtype": {"official": "0", "translated": "1", "rewrite": "2"}[args.language_type],
        "folderid": "0",
        "foldername": "",
        "ulcomment": args.comment,
        "tos": "on",
    }

    if args.human_translated and args.language_type == "translated":
        fields["langctl"] = "on"

    response = await post_file(
        NEW_GALLERY_URL,
        fields,
        files[0],
    )
    uploaded = 1
    print(f"Posted file 1/{len(files)} ({files[0].name}) to {NEW_GALLERY_URL}")

    manage_url = str(response.url)
    manage_url_parts = urlsplit(manage_url)

    remaining_files = files[1:]

    async def _upload_task(p: Path) -> None:
        nonlocal uploaded
        upload_fields = {
            "MAX_FILE_SIZE": "1258291200",
            "PHP_SESSION_UPLOAD_PROGRESS": progress_key,
        }
        await post_file(
            manage_url,
            upload_fields,
            p,
        )
        uploaded += 1
        print(f"Posted file {uploaded}/{len(files)} ({p.name}) to {manage_url}")

    # Too lazy to add a sem here
    # If you spawn too much workers and blow up you system, then that's definitely too much images for one gallery
    tasks = [_upload_task(p) for p in remaining_files]
    await asyncio.gather(*tasks)

    ulgid = dict(parse_qsl(manage_url_parts.query))["ulgid"]
    ulgid_query = urlencode({"ulgid": ulgid})
    reorder_url = manage_url_parts._replace(query=ulgid_query, fragment="reorder").geturl()
    await client.post(
        reorder_url,
        data={
            "do_reorder": "auto",
            "autosort": "natural"
        },
    )

    print(f"Gallery saved as draft: {manage_url}")

    if args.no_publish:
        return 0

    print(f"Publishing gallery: {manage_url}")

    manage_params = dict(parse_qsl(manage_url_parts.query))
    manage_params['act'] = 'publish'
    manage_params['from'] = 'gallery'
    query = urlencode(manage_params)
    publish_url = manage_url_parts._replace(query=query, fragment="").geturl()

    response = await client.post(
        publish_url,
        data={
            "return": "preview",
            "qa_publish": "Publish"
        },
    )
    print(f"Gallery published successfully: {response.url}")
    return 0


if __name__ == "__main__":
    raise SystemExit(asyncio.run(main()))
