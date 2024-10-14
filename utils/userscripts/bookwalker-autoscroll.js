function isLoaded() {
    for (e of document.querySelectorAll('.loading')) {
        if (getComputedStyle(e).visibility === "visible") return false;
    }
    return true;
}


let options;
for (key of Object.keys(NFBR.a6G.Initializer)) {
    if (Object.keys(NFBR.a6G.Initializer[key]).includes('menu')) {
        options = NFBR.a6G.Initializer[key].menu.options.a6l;
        break;
    }
}

// options.setSpreadDouble(false);
options.launchForceVerticalScrollMode();
options.moveToFirst();

const total = parseInt(document.querySelector('#pageSliderCounter').innerText.split('/')[1])

const checkLoading = setInterval(function() {
    const current = parseInt(document.querySelector('#pageSliderCounter').innerText.split('/')[0])
    console.log('Waiting for page', current);
    if (isLoaded()) {
        console.log('Page loaded');
        if (current < total) {
            options.moveToNext();
        } else {
            alert('Finished!');
            clearInterval(checkLoading);
        }
    }
}, 1000);
