-- App and scratchpad keys on Hyper (SUPER+CTRL+ALT+SHIFT, sent by the
-- keyboard): see ~/.config/hypr/harpoon.lua for the modes
-- (loadouts/private_dot_config/.hypr/.loadout/omarchy-harpoon.ts rewrites this block).
local harpoon = require("hypr.harpoon")
local hyper = "SUPER + CTRL + ALT + SHIFT + "
harpoon.bind(hyper .. "T", { name = "Terminal", class = "^kitty$", launch = "omarchy-launch-terminal", mode = "jump" })
harpoon.bind(hyper .. "B", { name = "Browser", class = "^brave%-browser$", launch = "omarchy-launch-browser", mode = "jump" })
-- Overlays: a scratchpad workspace each, named for what it holds, with its main app.
harpoon.bind(hyper .. "N", { name = "Notes", class = "^md%.obsidian%.Obsidian$", launch = o.launch("obsidian"), mode = "overlay" })
harpoon.bind(hyper .. "A", { name = "AI", class = "^brave%-claude%.ai__%-Default$", launch = "omarchy-launch-webapp https://claude.ai/", mode = "overlay" })
harpoon.bind(hyper .. "M", { name = "Media", class = "^[Ss]potify$", launch = "omarchy-launch-spotify", mode = "overlay" })
harpoon.bind(hyper .. "S", { name = "Social", class = "^brave%-web%.whatsapp%.com__%-Default$", launch = "omarchy-launch-webapp https://web.whatsapp.com/", mode = "overlay" })
-- Omarchy's scratchpad beside the overlays, in place of SUPER+S.
hl.unbind("SUPER + S")
o.bind(hyper .. "ESCAPE", "Toggle scratchpad", hl.dsp.workspace.toggle_special("scratchpad"))
