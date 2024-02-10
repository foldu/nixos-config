-- Pull in the wezterm API
local wezterm = require("wezterm")
local io = require("io")
local os = require("os")

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
    config = wezterm.config_builder()
end

-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
    -- this is set by the plugin, and unset on ExitPre in Neovim
    return pane:get_user_vars().IS_NVIM == "true"
end

local direction_keys = {
    h = "Left",
    j = "Down",
    k = "Up",
    l = "Right",
}

local function split_nav(resize_or_move, key)
    return {
        key = key,
        mods = resize_or_move == "resize" and "META" or "CTRL",
        action = wezterm.action_callback(function(win, pane)
            if is_vim(pane) then
                -- pass the keys through to vim/nvim
                win:perform_action({
                    SendKey = { key = key, mods = resize_or_move == "resize" and "META" or "CTRL" },
                }, pane)
            else
                if resize_or_move == "resize" then
                    win:perform_action({ AdjustPaneSize = { direction_keys[key], 3 } }, pane)
                else
                    win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
                end
            end
        end),
    }
end

-- This is where you actually apply your config choices

-- For example, changing the color scheme:
config.color_scheme = "Kanagawa (Gogh)"

config.enable_wayland = false
config.keys = {
    {
        key = "Enter",
        mods = "ALT",
        action = wezterm.action.DisableDefaultAssignment,
    },
    -- {
    --     key = "k",
    --     mods = "CTRL|SHIFT",
    --     action = wezterm.action.ActivatePaneDirection("Prev"),
    -- },
    -- {
    --     key = "j",
    --     mods = "CTRL|SHIFT",
    --     action = wezterm.action.ActivatePaneDirection("Next"),
    -- },
    {
        key = "g",
        mods = "CTRL|SHIFT",
        action = wezterm.action.EmitEvent("last-output-pager"),
    },
    -- move between split panes
    split_nav("move", "h"),
    split_nav("move", "j"),
    split_nav("move", "k"),
    split_nav("move", "l"),
    -- resize panes
    split_nav("resize", "h"),
    split_nav("resize", "j"),
    split_nav("resize", "k"),
    split_nav("resize", "l"),
}

local function starts_with(s, prefix)
    return s:sub(1, #prefix) == prefix
end

local function remove_prefix(s, prefix)
    if starts_with(s, prefix) then
        return s:sub(#prefix + 1)
    else
        return nil
    end
end

local function ends_with(s, suffix)
    return s == "" or s:sub(-#suffix) == suffix
end

local build_line_scheme = "build-line://"

wezterm.on("open-uri", function(window, pane, uri)
    local file_path = remove_prefix(uri, build_line_scheme)
    if file_path ~= nil then
        local tab = pane:tab()
        local editor_pane = nil
        for _, apane in ipairs(tab:panes()) do
            -- TODO: use get_title instead, if helix can ever set the window title
            if is_vim(apane) then
                editor_pane = pane
                break
            end
        end

        if editor_pane == nil then
            local action = wezterm.action({
                SplitPane = {
                    direction = "Up",
                    command = { args = { "nvim", file_path } },
                },
            })
            window:perform_action(action, pane)
        else
            local action = wezterm.action.multiple({
                wezterm.action.SendKey({
                    key = "Escape",
                }),
                wezterm.action.SendString(":e " .. file_path .. "\r\n"),
            })
            window:perform_action(action, editor_pane)
        end

        -- don't jump into normal uri handler
        return false
    end
    -- nil jumps into normal uri handler
end)

config.hyperlink_rules = wezterm.default_hyperlink_rules()
table.insert(config.hyperlink_rules, {
    regex = [[[^\n \t]+:\d+:\d+]],
    format = build_line_scheme .. "$0",
})

wezterm.on("last-output-pager", function(window, pane)
    local output_zones = pane:get_semantic_zones("Output")
    if #output_zones == 0 then
        return
    end

    local last_output_zone = output_zones[#output_zones - 1]
    local output = pane:get_text_from_semantic_zone(last_output_zone)

    local name = os.tmpname()
    local f = io.open(name, "w+")
    if f == nil then
        return
    end
    f:write(output)
    f:flush()
    f:close()

    local action = wezterm.action.SendString(string.format("less %s\r\n", name))
    window:perform_action(action, pane)

    -- Wait "enough" time for less to read the file before we remove it.
    -- The window creation and process spawn are asynchronous wrt. running
    -- this script and are not awaitable, so we just pick a number.
    --
    -- Note: We don't strictly need to remove this file, but it is nice
    -- to avoid cluttering up the temporary directory.
    wezterm.sleep_ms(10000)
    os.remove(name)
end)

-- config.unix_domains = {
--     {
--         name = "unix",
--     },
-- }

-- -- This causes `wezterm` to act as though it was started as
-- -- `wezterm connect unix` by default, connecting to the unix
-- -- domain on startup.
-- -- If you prefer to connect manually, leave out this line.
-- config.default_gui_startup_args = { "connect", "unix" }

config.font = wezterm.font({
    family = "Monaspace Neon",
    harfbuzz_features = { "calt=1", "zero" },
})

config.mux_env_remove = {
    "SSH_AUTH_SOCK",
    "SSH_CLIENT",
}

return config
