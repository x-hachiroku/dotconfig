#!/usr/bin/env python3

import argparse
import re
import unicodedata

from base import Base


NORM_TABLE = str.maketrans({
    '[': '\\[', ']': '\\]',
    '~': '～', '&': '＆', '―': '-', '…': '...',
    **dict.fromkeys('◯○⚬⚫⬤●', '〇'),
    **dict.fromkeys('·˙•∙⋅', '・'),
    **dict.fromkeys('✭★✩✫✬✮✯✰', '☆'),
    **dict.fromkeys('❤♥', '♡'),
})


def normalize(text):
    text = unicodedata.normalize('NFC', text)
    text = re.sub('[ \u00a0\u3000]+', ' ', text)
    text = re.sub(r'^[—–\-]+$', '---', text, flags=re.MULTILINE)
    text = re.sub(r'\s?[—–]+\s?', ' -- ', text)
    text = text.strip().translate(NORM_TABLE)
    return re.sub(r' ?([，、。！？“”]) ?', r'\1', text)


class Main(Base):
    def chapters(self):
        chapters = []
        for item in self.select_all('ul.serieslist-ul li'):
            link = self.select_from(item, 'a')
            if link:
                title = link.get_attribute('title') or link.inner_text()
                url = link.evaluate('el => el.href')
            else:
                title = item.inner_text()
                url = self.page.url
            chapters.append((title, url))
        return chapters

    def content(self):
        # Read DOM properties here; format and normalize the text in Python.
        nodes = self.select('.entry-content').evaluate('''el =>
            Array.from(el.childNodes, node => ({
                type: node.nodeType,
                tag: node.nodeName.toLowerCase(),
                id: node.id || '',
                classes: node.className || '',
                text: node.nodeType === Node.TEXT_NODE
                    ? node.textContent : (node.innerText || ''),
            }))
        ''')
        contents = []
        for node in nodes:
            if node['type'] == 3:
                contents.append(node['text'])
                continue
            if node['type'] != 1:
                continue
            if node['id'] == 'toc' or {'post-series', 'saboxplugin-wrap'} & set(node['classes'].split()):
                continue

            text = node['text'].replace('\r\n', '\n').replace('\r', '\n')
            tag = node['tag']
            if tag in ('fieldset'):
                break
            if tag in ('a', 'div'):
                continue
            if tag == 'h2':
                contents.append('## ' + text)
            elif tag == 'h3':
                contents.append('### ' + text)
            elif tag == 'blockquote':
                contents.append(text.replace('\n', '\n> \n> '))
            elif text != '[pilipili]' and '这个页面/文章内容有问题？' not in text:
                contents.extend(text.split('\n'))

        contents = [normalize(text) for text in contents]
        return [text for text in contents if text]

    def main(self, url):
        self.page.goto(url, wait_until='networkidle')
        print(self.select('h3.post-info').inner_text())
        print(self.select('footer.entry-footer').inner_text())

        chapters = self.chapters()
        for title, url in chapters:
            self.get(url)
            contents = ['\n## ' + title]
            contents.extend(self.content())
            print('\n\n'.join(contents))


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='Print series chapters as Markdown.')
    parser.add_argument('url', help='Chapter page containing the series list')
    args = parser.parse_args()
    with Main() as m:
        m.main(args.url)
