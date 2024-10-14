// ==UserScript==
// @name        EH Utils
// @version     0.1
// @author      chierinyan
// @description Ciallo~
// @namespace   chierinyan
// @match       *://e-hentai.org/*
// @match       *://exhentai.org/*
// @grant       unsafeWindow
// @grant       GM_setClipboard
// @grant       GM.xmlHttpRequest
// @connect     10.6.10.6
// @connect     10.6.10.6:7000
// @connect     localhost
// @run-at      document-idle
// ==/UserScript==

/* Sort by main title */
unsafeWindow.ss = function () {
    const titlePartern = /^(\(.*?\))?\s*(\[.*?\])?\s*(.*)/;
    const trs = Array.from(document.querySelectorAll("table.itg > tbody > tr"));
    trs.forEach((tr) => {
        tr.remove();
        tr.mainTitle = tr.querySelector("div.glink").innerText.match(titlePartern)[3];
    });
    trs.sort((a, b) => {
        return a.mainTitle.localeCompare(b.mainTitle);
    });
    trs.forEach((tr) => {
        document.querySelector("table.itg > tbody").appendChild(tr);
    });
}

/* Download current page
 * @param {boolean} hath - true for Hath, false for aria2.
 *
 * Remember to set adress and token, and add aria2 address to @connect
 */
unsafeWindow.dd = async function (hath) {
    const aria2='http://localhost:7000/jsonrpc';

    if (hath === undefined) {
      throw new Error("Please specify download method");
    }

    window.onbeforeunload = () => true;
    const popUpPattern = /popUp\('(.+?)'.*\)/;
    const resultPattern = /<h1 style="font-size:10pt; font-weight:bold">(.*?)<\/p>/;
    const downloadPattern = /document.location = "(.*)"/;
    const pathPattern = /org\/g\/(.*)\//;

    function arai2(name, url) {
        GM.xmlHttpRequest({
            method: "POST",
            url: aria2,
            headers: { "Content-Type": "application/json" },
            data: JSON.stringify({
                jsonrpc: "2.0",
                id: "1",
                method: "aria2.addUri",
                params: [
                    [url],
                    {
                        dir: '/home/chieri/Downloads/aria2/eh/',
                        out: `${name}.cbz`
                    },
                ],
            }),
            onload: (res) => {
                console.log(JSON.parse(res.responseText).result);
            },
        });
    }

    const trs = Array.from(document.querySelectorAll("table.itg > tbody > tr"));
    const total = trs.length;

    if (!confirm(`Download ${total} galleries ${hath ? "by Hath" : "directly"}?`)) { return; }

    const downloader = setInterval(async () => {
        const tr = trs.pop();
        console.log(`(${total - trs.length}/${total}) ${tr.querySelector("div.glink").innerText}`);
        const galleryURL = tr.querySelector("td.gl2e > div > a").href;
        const path = galleryURL.match(pathPattern)[1].replace('/', '_');
        const getRes = await fetch(galleryURL);
        const getText = await getRes.text();
        let formURL = getText.match(popUpPattern)[1];
        formURL = formURL.replaceAll('&amp;', '&');
        formURL = formURL.replace('--', '-');

        const payload = new URLSearchParams();
        if (hath) { payload.append("hathdl_xres", "org"); }
        else {
            payload.append("dltype", "org");
            payload.append("dlcheck", "Download Original Archive");
        }

        const postRes = await fetch(formURL, {
            method: "POST",
            headers: { "Content-Type": "application/x-www-form-urlencoded" },
            body: payload,
        })
        const postText = await postRes.text()

        if (hath) { console.log(postText.match(resultPattern)[1]); }
        else {
            const downloadURL = postText.match(downloadPattern)[1] + '?start=1';
            arai2(path, downloadURL);
        }

        if (trs.length === 0) {
          clearInterval(downloader);
          window.onbeforeunload = null;
        }
    }, 3 * 1000);
}

/* Generate galleryinfo.txt */
unsafeWindow.gg = function () {
    const tags = [];
    document.querySelectorAll('#taglist tr').forEach((tr) => {
        const tds = tr.querySelectorAll('td');
        const namespace = tds[0].innerText;
        tags.push(...Array.from(tds[1].querySelectorAll('div.gt,div.gtl'))
                          .map(div => `${namespace}${div.textContent}`));
    });
    const info = [
        `Title:       ${document.querySelector("#gj").innerText}`,
        `Upload Time: ${document.querySelector("td.gdt2").innerText}`,
        `Uploaded By: ${document.querySelector("#gdn").innerText}`,
        `Downloaded:  ${new Date().toISOString().slice(0, 16).replace('T', ' ')}`,
        `Tags:        ${tags.join(', ')}`,
        `Category:    ${document.querySelector("#gdc > div").innerText}`,
    ]
    const comments = document.querySelector('#comment_0');
    if (comments) {
        info.push("\nUploader's Comments:\n");
        info.push(comments.innerText);
        info.push("");
    }
    info.push("<3")
    GM_setClipboard(info.join('\n'));
}

/* Highlight galleries by gID */
unsafeWindow.hh = function () {
    const gidPattern = /org\/g\/(\d+?)\//;
    const galleries = new Map();
    document.querySelectorAll("table.itg > tbody > tr").forEach((tr) => {
        const gid = tr.querySelector("td.gl2e > div > a").href.match(gidPattern)[1];
        galleries.set(parseInt(gid), tr);
    });
    for (const gid of arguments) {
        const tr = galleries.get(gid);
        if (tr) {
            tr.style.backgroundColor = "hsl(180,20%,30%)";
        } else {
            console.log(`Gallery ${gid} not found`);
        }
    }
}
