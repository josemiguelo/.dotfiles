hl.config({
  general = {
    gaps_in = 3,
    gaps_out = 4,
    border_size = 5,
    -- Niri-like side-scrolling instead of Omarchy's dwindle.
    layout = "scrolling",
  },
  -- New columns take most of the screen instead of Omarchy's half, so each
  -- window gets the screen to itself and the next one peeks in at the edge.
  scrolling = {
    column_width = 0.9,
  },
})

hl.config({
  decoration = {
    rounding = 8,
    dim_inactive = true,
    dim_strength = 0.15,
  },
})

-- Workspace changes slide instead of cutting (Omarchy turns this off), so a
-- jump to another workspace is visible.
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "easeOutQuint", style = "slide" })
