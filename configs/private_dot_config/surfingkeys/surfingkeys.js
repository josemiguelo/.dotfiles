const { mapkey, Hints } = api;

// --------------------------------------------------------------------------
// 1. THEME: TOKYO NIGHT IN DARK MODE, TOKYO NIGHT DAY IN LIGHT
// --------------------------------------------------------------------------
// Follows Brave's appearance through prefers-color-scheme. Surfingkeys' own UI
// (omnibar, help, status bar, tab picker) is an iframe that only settings.theme
// styles; link hints are a shadow root in the page that only Hints.style
// styles. Both run their CSS through DOMPurify, which escapes `>`, so no
// child combinators here.
const palette = `
  :root, :host {
    --sk-bg: #e1e2e7;
    --sk-bg-alt: #d5d6db;
    --sk-fg: #3760bf;
    --sk-muted: #848cb5;
    --sk-border: #a8aecb;
    --sk-selected: #c4c8da;
    --sk-accent: #2e7de9;
    --sk-match: #f52a65;
    --sk-folder: #9854f1;
    --sk-hint-bg: #8c6c3e;
    --sk-hint-fg: #e1e2e7;
  }
  @media (prefers-color-scheme: dark) {
    :root, :host {
      --sk-bg: #1a1b26;
      --sk-bg-alt: #16161e;
      --sk-fg: #c0caf5;
      --sk-muted: #565f89;
      --sk-border: #3b4261;
      --sk-selected: #292e42;
      --sk-accent: #7aa2f7;
      --sk-match: #ff9e64;
      --sk-folder: #bb9af7;
      --sk-hint-bg: #e0af68;
      --sk-hint-fg: #1a1b26;
    }
  }
`;

settings.theme = `
  ${palette}
  .sk_theme {
    background: var(--sk-bg);
    color: var(--sk-fg);
    font-family: system-ui, sans-serif;
  }
  .sk_theme input { color: var(--sk-fg); }
  .sk_theme .url, .sk_theme .annotation { color: var(--sk-muted); }
  .sk_theme kbd {
    background: var(--sk-selected);
    color: var(--sk-fg);
    border-color: var(--sk-border);
    box-shadow: none;
  }
  .sk_theme .frame { background: color-mix(in srgb, var(--sk-accent) 40%, transparent); }
  .sk_theme .omnibar_highlight { color: var(--sk-match); }
  .sk_theme .omnibar_folder { color: var(--sk-folder); }
  .sk_theme .omnibar_timestamp { color: var(--sk-muted); }
  .sk_theme .omnibar_visitcount { color: var(--sk-accent); }
  .sk_theme .prompt, .sk_theme .resultPage { color: var(--sk-muted); }
  .sk_theme .feature_name { color: var(--sk-accent); }
  .sk_theme .separator { color: var(--sk-border); }
  .sk_theme #sk_omnibarSearchResult ul li:nth-child(odd) { background: var(--sk-bg-alt); }
  .sk_theme #sk_omnibarSearchResult ul li.focused { background: var(--sk-selected); }
  .sk_theme #sk_omnibarSearchResult ul li.window.focused { border-color: var(--sk-accent); }
  #sk_omnibar, #sk_status, #sk_banner, #sk_popup, #sk_usage, #sk_editor {
    border-color: var(--sk-border);
  }
  #sk_banner { background: var(--sk-bg); color: var(--sk-fg); }
  #sk_keystroke { background: var(--sk-bg-alt); color: var(--sk-fg); }
  div.sk_tab {
    background: var(--sk-bg);
    border: 1px solid var(--sk-border);
  }
  div.sk_tab_title { color: var(--sk-fg); }
  div.sk_tab_url { color: var(--sk-muted); }
  div.sk_tab_hint {
    background: var(--sk-hint-bg);
    color: var(--sk-hint-fg);
    border-color: var(--sk-hint-bg);
  }
`;

// Hints.style wraps CSS that doesn't start with `div` in `div{…}`.
Hints.style(`
  div {
    background: var(--sk-hint-bg);
    color: var(--sk-hint-fg);
    border: 1px solid var(--sk-hint-bg);
    box-shadow: none;
  }
  div.begin { color: var(--sk-muted); }
  ${palette}
`);
Hints.style(`
  div {
    background: var(--sk-selected);
    color: var(--sk-fg);
    border: 1px solid var(--sk-border);
    box-shadow: none;
  }
  div.begin { color: var(--sk-accent); }
  ${palette}
`, "text");

// --------------------------------------------------------------------------
// 2. SIDE PREVIEW PANEL WITH MATCHING THEME
// --------------------------------------------------------------------------
function removePreviewPanel() {
    let container = document.getElementById('surfingkeys-overlay-container');
    if (container) {
        container.remove();
        window.focus();
    }
}

mapkey('gs', 'Toggle or open link in side overlay panel', function() {
    let existingContainer = document.getElementById('surfingkeys-overlay-container');
    
    if (existingContainer) {
        removePreviewPanel();
        return;
    }

    Hints.create('a[href]', function(element) {
        if (!element || !element.href) return;
        
        let url = element.href;
        let container = document.createElement('div');
        container.id = 'surfingkeys-overlay-container';
        container.style.cssText = `
            position: fixed;
            top: 0;
            right: 0;
            width: 40vw;
            height: 100vh;
            z-index: 2147483647;
            box-shadow: -5px 0 25px rgba(0,0,0,0.3);
            display: flex;
            flex-direction: column;
            font-family: system-ui, -apple-system, sans-serif;
            transition: transform 0.2s ease-in-out;
        `;

        const shadow = container.attachShadow({ mode: 'open' });

        shadow.innerHTML = `
            <style>
                ${palette}

                :host {
                    display: flex;
                    flex-direction: column;
                    height: 100%;
                    width: 100%;
                    background: var(--sk-bg);
                }
                .frame-container {
                    position: relative;
                    flex: 1;
                    width: 100%;
                    height: 100%;
                    overflow: hidden;
                    background: var(--sk-bg);
                }
                iframe {
                    width: 100%;
                    height: 100%;
                    border: none;
                    background: var(--sk-bg);
                }
            </style>
            <div class="frame-container">
                <iframe id="preview-iframe"></iframe>
            </div>
        `;

        document.body.appendChild(container);
        
        const shadowRoot = container.shadowRoot;
        const iframe = shadowRoot.getElementById('preview-iframe');

        iframe.src = url;

        window.focus();
    });
});

mapkey('gS', 'Close side overlay', removePreviewPanel);

// Scroll iframe remotely strictly with Ctrl+j and Ctrl+k
mapkey('<Ctrl-j>', 'Scroll side preview down', function() {
    let container = document.getElementById('surfingkeys-overlay-container');
    if (container && container.shadowRoot) {
        let iframe = container.shadowRoot.getElementById('preview-iframe');
        if (iframe) {
            try {
                iframe.contentWindow.scrollBy({ top: 250, behavior: 'smooth' });
            } catch (e) {
                iframe.focus();
            }
        }
    }
});

mapkey('<Ctrl-k>', 'Scroll side preview up', function() {
    let container = document.getElementById('surfingkeys-overlay-container');
    if (container && container.shadowRoot) {
        let iframe = container.shadowRoot.getElementById('preview-iframe');
        if (iframe) {
            try {
                iframe.contentWindow.scrollBy({ top: -250, behavior: 'smooth' });
            } catch (e) {
                iframe.focus();
            }
        }
    }
});

document.addEventListener('keydown', function(e) {
    if (e.key === 'Escape') {
        removePreviewPanel();
    }
}, true);
