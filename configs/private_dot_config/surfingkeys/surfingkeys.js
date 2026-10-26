const { mapkey, Hints } = api;

// --------------------------------------------------------------------------
// 1. COMPLETE SURFINGKEYS UI THEME (AUTO DARK / LIGHT FOR POPUPS, TABS, OMNIBAR)
// --------------------------------------------------------------------------
const surfingkeysTheme = `
  /* --- LIGHT THEME DEFAULTS --- */
  :root {
    --sk-bg: #ffffff;
    --sk-header-bg: #f3f4f6;
    --sk-fg: #1f2937;
    --sk-border: #e5e7eb;
    --sk-hint-bg: #facc15;
    --sk-hint-fg: #000000;
    --sk-btn-bg: #ef4444;
    --sk-btn-fg: #ffffff;
    --sk-item-active: #e5e7eb;
  }

  /* --- DARK THEME OVERRIDES --- */
  @media (prefers-color-scheme: dark) {
    :root {
      --sk-bg: #181825;
      --sk-header-bg: #1e1e2e;
      --sk-fg: #cdd6f4;
      --sk-border: #313244;
      --sk-hint-bg: #f9e2af;
      --sk-hint-fg: #11111b;
      --sk-btn-bg: #f38ba8;
      --sk-btn-fg: #11111b;
      --sk-item-active: #313244;
    }
  }

  /* Global Surfingkeys Popups & Panels */
  .sk_theme, #sk_omnibar, #sk_status, #sk_banner, #sk_tabs, #sk_keystroke {
    background-color: var(--sk-bg) !important;
    color: var(--sk-fg) !important;
    border-color: var(--sk-border) !important;
  }

  /* Omnibar Input & Command Line (Triggered by :) */
  #sk_omnibar .prompt, #sk_omnibar .separator {
    color: var(--sk-fg) !important;
  }
  #sk_omnibar input {
    background-color: var(--sk-bg) !important;
    color: var(--sk-fg) !important;
  }
  #sk_omnibarResult li {
    background-color: var(--sk-bg) !important;
    color: var(--sk-fg) !important;
  }
  #sk_omnibarResult li.focused {
    background-color: var(--sk-item-active) !important;
  }

  /* Tab Preview Overlay (Triggered by t) */
  #sk_tabs .sk_tab {
    background-color: var(--sk-header-bg) !important;
    color: var(--sk-fg) !important;
    border: 1px solid var(--sk-border) !important;
  }
  #sk_tabs .sk_tab_title {
    color: var(--sk-fg) !important;
  }
  #sk_tabs .sk_tab_url {
    color: var(--sk-hint-bg) !important;
  }
  #sk_tabs div.sk_tab_hint {
    background-color: var(--sk-hint-bg) !important;
    color: var(--sk-hint-fg) !important;
  }

  /* Link Hints (Triggered by f / gs) */
  #sk_hints .begin {
    color: var(--sk-hint-fg) !important;
    background: var(--sk-hint-bg) !important;
    border: 1px solid var(--sk-border) !important;
    font-weight: bold !important;
  }
`;

// Apply theme dynamically to Surfingkeys system UI
api.Hints.style(surfingkeysTheme);

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
                ${surfingkeysTheme}

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
