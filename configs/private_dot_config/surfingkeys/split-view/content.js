// Surfingkeys' config can't message this extension, but both see the page's
// DOM events: it asks with a `split-view-keys` event (a JSON detail, since
// objects don't cross between extensions). The page can send the same event,
// so background.js only opens http(s) links.

document.addEventListener('split-view-keys', e => {
    let request;
    try {
        request = JSON.parse(e.detail);
    } catch {
        return;
    }
    if (request && typeof request.action === 'string') {
        chrome.runtime.sendMessage(request).catch(() => {});
    }
});
