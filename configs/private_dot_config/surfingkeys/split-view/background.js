// Brave's split view from the keyboard. Requests come from Surfingkeys' config
// through content.js.

function inSplit(tab) {
    return tab.splitViewId !== undefined && tab.splitViewId !== -1;
}

function isWebUrl(url) {
    return typeof url === 'string' && /^https?:/i.test(url);
}

async function otherSide(tab) {
    if (!inSplit(tab)) return null;
    const tabs = await chrome.tabs.query({ windowId: tab.windowId });
    return tabs.find(t => t.splitViewId === tab.splitViewId && t.id !== tab.id) || null;
}

const actions = {
    // In a split, the link replaces the other side; otherwise it opens a new
    // split. Focus stays on this side either way.
    async open(tab, request) {
        if (!isWebUrl(request.url)) return;
        const other = await otherSide(tab);
        if (other) {
            await chrome.tabs.update(other.id, { url: request.url });
        } else {
            await chrome.tabs.create({ url: request.url, splitWithTabId: tab.id, active: false });
        }
    },
    async close(tab) {
        const other = await otherSide(tab);
        if (other) await chrome.tabs.remove(other.id);
    },
};

chrome.runtime.onMessage.addListener((request, sender) => {
    const action = Object.hasOwn(actions, request.action) && actions[request.action];
    if (action && sender.tab) action(sender.tab, request).catch(console.error);
});
