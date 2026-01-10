local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- max fps, adapt your monitor
config.max_fps = 120
config.animation_fps = 120

config.prefer_egl = true

config.adjust_window_size_when_changing_font_size = false

-- appearance
config.window_decorations = "RESIZE"
config.window_padding = {
	left = 0.,
	right = 0.,
	top = 5, -- config with font size and line height
	bottom = 0,
}

-- font
config.font = wezterm.font("JetBrainsMonoNL Nerd Font")
config.font_size = 12.5
config.line_height = 1.1

-- init size
config.initial_cols = 160
config.initial_rows = 38

-- tab bar
config.hide_tab_bar_if_only_one_tab = false
config.tab_bar_at_bottom = true
config.use_fancy_tab_bar = false
config.tab_and_split_indices_are_zero_based = false

-- inactive pane style
config.inactive_pane_hsb = {
	saturation = 0.9,
	brightness = 0.8,
}

-- quit confirmation
config.window_close_confirmation = "NeverPrompt"

local is_windows = wezterm.target_triple:find("windows") ~= nil

-- default super key
local mod = {}
mod.SUPER = "ALT"
mod.SUPER_CTRL = mod.SUPER .. "|CTRL"
mod.SUPER_SHIFT = mod.SUPER .. "|SHIFT"

if is_windows then
	config.default_prog = { "C:\\Program Files\\PowerShell\\7\\pwsh.exe" }
end

-- colors
config.color_scheme = "Tokyo Night"

-- keybindings
config.leader = { key = "Space", mods = mod.SUPER, timeout_milliseconds = 1000 }
config.keys = {
	-- quit
	{ key = "q", mods = mod.SUPER_CTRL, action = act.QuitApplication },
	-- debug
	{ key = "F12", mods = "NONE", action = act.ShowDebugOverlay },
	-- reload config
	{ key = "R", mods = "LEADER", action = act.ReloadConfiguration },
	-- copy mode
	{ key = "Enter", mods = "LEADER", action = "ActivateCopyMode" },
	-- command palette
	{ key = ":", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },
	-- search
	{ key = "/", mods = "LEADER", action = act.Search({ CaseInSensitiveString = "" }) },
	-- launcher
	{ key = "s", mods = "LEADER", action = act.ShowLauncher },
	{ key = "t", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|TABS" }) },
	{ key = "w", mods = "LEADER", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- fullscreen
	{ key = "F11", mods = "NONE", action = act.ToggleFullScreen },
	-- copy and paste
	{
		key = "c",
		mods = "CTRL",
		action = wezterm.action_callback(function(window, pane)
			local has_selection = window:get_selection_text_for_pane(pane) ~= ""
			if has_selection then
				window:perform_action(act.CopyTo("ClipboardAndPrimarySelection"), pane)
				window:perform_action(act.ClearSelection, pane)
			else
				window:perform_action(act.SendKey({ key = "c", mods = "CTRL" }), pane)
			end
		end),
	},
	{ key = "v", mods = "CTRL", action = act.PasteFrom("Clipboard") },
	-- tabs navigation
	{
		key = "[",
		mods = mod.SUPER,
		action = act.ActivateTabRelative(-1),
	},
	{
		key = "]",
		mods = mod.SUPER,
		action = act.ActivateTabRelative(1),
	},
	{
		key = "[",
		mods = mod.SUPER_CTRL,
		action = act.MoveTabRelative(-1),
	},
	{
		key = "]",
		mods = mod.SUPER_CTRL,
		action = act.MoveTabRelative(1),
	},
	-- create new tab
	{
		key = "c",
		mods = "LEADER",
		action = act.SpawnTab("CurrentPaneDomain"),
	},
	-- kill pane
	{
		key = "x",
		mods = "LEADER",
		action = act.CloseCurrentPane({ confirm = true }),
	},
	-- kill tab
	{
		key = "X",
		mods = "LEADER",
		action = act.CloseCurrentTab({ confirm = false }),
	},
	-- split pane
	{
		key = "V",
		mods = "LEADER",
		action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }),
	},
	{
		key = "S",
		mods = "LEADER",
		action = act.SplitVertical({ domain = "CurrentPaneDomain" }),
	},
	-- pane zoom
	{
		key = "z",
		mods = "LEADER",
		action = act.TogglePaneZoomState,
	},
	-- pane navigation
	{
		key = "h",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Left"),
	},
	{
		key = "j",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Down"),
	},
	{
		key = "k",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Up"),
	},
	{
		key = "l",
		mods = "LEADER",
		action = wezterm.action.ActivatePaneDirection("Right"),
	},
	-- pane scroll
	{ key = "u", mods = mod.SUPER, action = act.ScrollByLine(-5) },
	{ key = "d", mods = mod.SUPER, action = act.ScrollByLine(5) },
	{ key = "g", mods = "LEADER", action = act.ScrollToTop },
	{ key = "G", mods = "LEADER", action = act.ScrollToBottom },
	-- pane size adjustment
	{
		key = "H",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Left", 5 }),
	},
	{
		key = "L",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Right", 5 }),
	},
	{
		key = "J",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Down", 5 }),
	},
	{
		key = "K",
		mods = "LEADER",
		action = act.AdjustPaneSize({ "Up", 5 }),
	},
	-- windows zoom
	{
		key = "0",
		mods = mod.SUPER_CTRL,
		action = wezterm.action_callback(function(window, _)
			window:restore()
		end),
	},
	{
		key = "-",
		mods = mod.SUPER_CTRL,
		action = wezterm.action_callback(function(window, _)
			local dimensions = window:get_dimensions()
			if dimensions.is_full_screen then
				return
			end
			local new_width = dimensions.pixel_width - 50
			local new_height = dimensions.pixel_height - 50
			window:set_inner_size(new_width, new_height)
		end),
	},
	{
		key = "=",
		mods = mod.SUPER_CTRL,
		action = wezterm.action_callback(function(window, _)
			local dimensions = window:get_dimensions()
			if dimensions.is_full_screen then
				return
			end
			local new_width = dimensions.pixel_width + 50
			local new_height = dimensions.pixel_height + 50
			window:set_inner_size(new_width, new_height)
		end),
	},
	{
		key = "Enter",
		mods = mod.SUPER_CTRL,
		action = wezterm.action_callback(function(window, _)
			window:maximize()
		end),
	},
	{
		key = "k",
		mods = mod.SUPER_CTRL,
		action = act.QuickSelect,
	},
	{
		key = "l",
		mods = mod.SUPER_CTRL,
		action = act.QuickSelectArgs({
			label = "open url",
			patterns = {
				"\\((https?://\\S+)\\)",
				"\\[(https?://\\S+)\\]",
				"\\{(https?://\\S+)\\}",
				"<(https?://\\S+)>",
				"\\bhttps?://\\S+[)/a-zA-Z0-9-]+",
			},
			action = wezterm.action_callback(function(window, pane)
				local url = window:get_selection_text_for_pane(pane)
				wezterm.log_info("opening: " .. url)
				wezterm.open_with(url)
			end),
		}),
	},
}

for i = 1, 9 do
	table.insert(config.keys, {
		key = tostring(i),
		mods = "LEADER",
		action = act.ActivateTab(i - 1),
	})
end

-- tab bar
local meta_colors = {
	rosewater = "#f4dbd6",
	flamingo = "#f0c6c6",
	pink = "#eb8497",
	mauve = "#c6a0f6",
	red = "#f38ba8",
	peach = "#ff79c6",
	peach2 = "#f5a97f",
	maroon = "#eba0ac",
	yellow = "#f9e2af",
	orange = "#fd8c6a",
	green = "#a6e3a1",
	teal = "#8bd5ca",
	sky = "#91d7e3",
	sapphire = "#7dc4e4",
	blue = "#8aadf4",
	lavender = "#b7bdf8",
	white = "#fff",
	crust = "#11111b",
	surface0 = "#313244",
	subtext1 = "#bac2de",
	surface2 = "#585b70",
	text = "#cdd6f4",
}

local std_colors = {
	tab_bar_active_tab_bg = meta_colors.pink,
	tab_bar_inactive_tab_bg = meta_colors.surface0,
	tab_bar_text = meta_colors.white,
	leader_active = meta_colors.yellow,
	leader_inactive = meta_colors.green,
	workspace_bg = meta_colors.teal,
	leader_text = meta_colors.crust,
	date_fg = meta_colors.crust,
	date_bg = meta_colors.lavender,
	bat_fg = meta_colors.white,
	bat_bg = meta_colors.peach,
}

local function tab_title(tab_info)
	local title = tab_info.tab_title
	-- if the tab title is explicitly set, take that
	if title and #title > 0 then
		return title
	end
	-- Otherwise, use the title from the active pane
	-- in that tab
	return tab_info.active_pane.title
end
---@diagnostic disable-next-line: unused-local
wezterm.on("format-tab-title", function(tab, tabs, panes, _config, hover, max_width)
	local title = " " .. tab.tab_index + 1 .. " " .. tab_title(tab) .. " "
	title = wezterm.truncate_right(title, max_width - 2)

	if tab.is_active then
		return {
			{ Background = { Color = std_colors.tab_bar_active_tab_bg } },
			{ Foreground = { Color = std_colors.tab_bar_text } },
			{ Text = title },
		}
	else
		return {
			{ Background = { Color = std_colors.tab_bar_inactive_tab_bg } },
			{ Foreground = { Color = std_colors.tab_bar_text } },
			{ Text = title },
		}
	end
end)

wezterm.on("update-status", function(window, pane)
	local workspace = window:active_workspace()
	local domain = pane:get_domain_name()
	local bg_color = std_colors.leader_inactive
	if window:leader_is_active() then
		bg_color = std_colors.leader_active
	end
	window:set_left_status(wezterm.format({
		{ Background = { Color = bg_color } },
		{ Foreground = { Color = std_colors.leader_text } },
		{ Text = "  " .. domain .. " " },
		{ Background = { Color = std_colors.workspace_bg } },
		{ Foreground = { Color = std_colors.leader_text } },
		{ Text = " 󰖲 " .. workspace .. " " },
	}))
end)

wezterm.on("update-right-status", function(window, _)
	local date = wezterm.strftime("%Y-%m-%d %H:%M")
	local battery_info = wezterm.battery_info()
	local right_status = {
		{ Foreground = { Color = std_colors.date_fg } },
		{ Background = { Color = std_colors.date_bg } },
		{ Text = " " .. date .. " " },
	}
	if #battery_info > 0 then
		local bat = ""
		for _, b in ipairs(battery_info) do
			local icon = ""
			local state = b.state_of_charge
			if state < 0.3 then
				icon = " 󰁻 "
			elseif state < 0.5 then
				icon = " 󰁾 "
			elseif state < 0.9 then
				icon = " 󰂂 "
			else
				icon = " 󰁹 "
			end
			bat = icon .. string.format("%.0f%%", state * 100)
		end
		local bat_status = {
			{ Foreground = { Color = std_colors.bat_fg } },
			{ Background = { Color = std_colors.bat_bg } },
			{ Text = bat .. " " },
		}
		local combined_status = bat_status
		for _, status in ipairs(right_status) do
			table.insert(combined_status, status)
		end
		right_status = combined_status
	end
	window:set_right_status(wezterm.format(right_status))
end)

table.insert(config.keys, { key = "T", mods = "LEADER", action = act.EmitEvent("tabs.toggle-tab-bar") })

-- custom event
wezterm.on("tabs.toggle-tab-bar", function(window, _)
	local effective_config = window:effective_config()
	window:set_config_overrides({
		enable_tab_bar = not effective_config.enable_tab_bar,
		background = effective_config.background,
	})
end)

-- ssh domains
config.ssh_domains = wezterm.default_ssh_domains()

---@param unique_key string
---@param list table[]
---@return table<string, table>
local function list_to_dict(unique_key, list)
	local d = {}
	for _, v in ipairs(list) do
		if v[unique_key] then
			d[v[unique_key]] = v
		end
	end
	return d
end

---@param domains table[]
local function merge_ssh_domains(domains)
	if not domains or #domains == 0 then
		return
	end
	if config.ssh_domains and #config.ssh_domains > 0 then
		local parsed_domains = list_to_dict("name", config.ssh_domains)
		local individual_domains = list_to_dict("name", domains)
		for k, v in pairs(individual_domains) do
			if parsed_domains[k] then
				for k2, v2 in pairs(v) do
					parsed_domains[k][k2] = v2
				end
			else
				table.insert(config.ssh_domains, v)
			end
		end
	else
		config.ssh_domains = domains
	end
end

-- merge local options
local status, local_options = pcall(require, "local-options")
if status then
	for k, v in pairs(local_options) do
		if k == "font" then
			config[k] = wezterm.font(v)
		elseif k == "ssh_domains" then
			merge_ssh_domains(v)
		else
			config[k] = v
		end
	end
end

return config
