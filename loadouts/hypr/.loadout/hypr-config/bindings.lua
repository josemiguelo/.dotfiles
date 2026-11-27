-- Omarchy's Super+~ ("Move window to Quake console") is too easy to hit and
-- hides windows in special:qconsole. Super+` still shows and hides the console.
hl.unbind("SUPER + SHIFT + grave")

-- Omarchy's email and calendar keys open HEY (default/hypr/bindings/
-- applications.lua): Gmail and Google Calendar web apps in its place. Each key
-- is unbound first, as Omarchy's own comments say: two binds on one key would
-- both fire.
hl.unbind("SUPER + SHIFT + E")
o.bind("SUPER + SHIFT + E", "Gmail", { webapp = "https://mail.google.com/" })
hl.unbind("SUPER + SHIFT + ALT + E")
o.bind("SUPER + SHIFT + ALT + E", "New Gmail message", { webapp = "https://mail.google.com/mail/?view=cm&fs=1" })
hl.unbind("SUPER + SHIFT + C")
o.bind("SUPER + SHIFT + C", "Google Calendar", { webapp = "https://calendar.google.com/" })
