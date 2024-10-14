// ==UserScript==
// @name        LRR-extend
// @namespace   chierinyan
// @match       http://10.6.6.6:8800/*
// @grant       unsafeWindow
// @version     1.0
// @author      chierinyan
// @namespace   chierinyan
// @description 21/06/2024, 00:41:14
// ==/UserScript==


unsafeWindow.ss = function () {
    document.querySelector('ul.collapsible').remove();
    document.querySelector('div.table-options').remove();
    document.querySelector('div.dataTables_info').remove();
    document.querySelector('.dataTables_paginate').remove();
    document.querySelector('#nb').remove();
    document.querySelector('#customheader1').remove()
    document.querySelector('#customheader2').remove()
    document.querySelectorAll('div.isnew').forEach(div => div.remove());
    document.querySelectorAll('td.custom1').forEach(td => td.remove());
    document.querySelectorAll('td.custom2').forEach(td => td.remove());
    document.querySelectorAll('span.tag-tooltip').forEach(span => span.remove());

    document.querySelectorAll('div.caption').forEach((div) => {
        div.style.display = null;
        div.style.margin = 'auto';
        div.style.width = 'fit-content';
        div.className = '';
    });

    document.querySelector('thead').remove();

    document.querySelectorAll('td.title').forEach((td) => {
        td.classList.remove('title');
        td.style.width = '280px';
    });

    document.querySelectorAll('tr.gtr0').forEach((tr) => {
        tr.classList.remove('gtr0');
        tr.classList.add('gtr1');
        tr.style.setProperty('border-top', '1px solid #ddd');
        tr.style.setProperty('border-bottom', '1px solid #ddd');
    });

    document.querySelectorAll('tbody.list > tr').forEach((tr) => {
        const a = tr.querySelector('a');
        const tags = tr.querySelector('td.tags');
        a.style.fontSize = '1.5em';
        tags.style.setProperty('padding-left', '20px');
        tags.insertBefore(a, tags.children[0]);
        tr.querySelector('table.itg').style.margin = '0';
    });
}

unsafeWindow.hh = function () {
    const galleries = new Map();
    document.querySelectorAll("span.eh_gid-tag").forEach((span) => {
        galleries.set(parseInt(span.textContent.trim()), span.closest("tr"));
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
