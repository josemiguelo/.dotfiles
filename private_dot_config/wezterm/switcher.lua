local wezterm = require("wezterm")
local act = wezterm.action

local M = {}

local filter = function(tbl, callback)
	local filt_table = {}

	for i, v in ipairs(tbl) do
		if callback(v, i) then
			table.insert(filt_table, v)
		end
	end
	return filt_table
end

local kill_workspace = function(workspace)
	local success, stdout = wezterm.run_child_process({ "wezterm", "cli", "list", "--format=json" })

	if success then
		local json = wezterm.json_parse(stdout)
		if not json then
			return
		end

		local workspace_panes = filter(json, function(p)
			return p.workspace == workspace
		end)

		for _, p in ipairs(workspace_panes) do
			wezterm.run_child_process({ "wezterm", "cli", "kill-pane", "--pane-id=" .. p.pane_id })
		end
	end
end

M.setup = function(config)
	wezterm.on("update-right-status", function(window, pane)
		window:set_right_status(" " .. window:active_workspace() .. " ")
	end)

	local plugin_url = "https://github.com/MLFlexer/smart_workspace_switcher.wezterm"
	local workspace_switcher = wezterm.plugin.require(plugin_url)
	workspace_switcher.apply_to_config(config)

	 -- stylua: ignore
	table.insert(config.keys, { key = "t", mods = "CTRL|ALT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) })
	table.insert(config.keys, { key = "[", mods = "CTRL|ALT", action = act.SwitchWorkspaceRelative(1) })
	table.insert(config.keys, { key = "]", mods = "CTRL|ALT", action = act.SwitchWorkspaceRelative(-1) })
	table.insert(config.keys, { key = "s", mods = "CTRL|ALT", action = workspace_switcher.switch_workspace() })
	table.insert(config.keys, {
		key = "r",
		mods = "CTRL|ALT",
		action = wezterm.action.PromptInputLine({
			description = "Enter new name for workspace",
			action = wezterm.action_callback(function(window, pane, line)
				if line then
					wezterm.mux.rename_workspace(wezterm.mux.get_active_workspace(), line)
				end
			end),
		}),
	})
	table.insert(config.keys, {
		key = "k",
		mods = "CTRL|ALT",
		action = wezterm.action_callback(function(window)
			kill_workspace(window:active_workspace())
		end),
	})
end

return M
