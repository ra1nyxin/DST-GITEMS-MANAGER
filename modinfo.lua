name = "DST-GITEMS-MANAGER"
description = [[
Server-side dropped item manager focused on practical cleanup and retrieval.

Current features:
- Hold the configured modifier key and press the toggle key to open GIM (default: V+N).
- Esc closes the panel while it is open (can be turned off in mod config).
- Every player in the room can open GIM with the configured hotkey.
- GIM scans dropped ground items only when the panel is opened.
- The scan is limited to the player's current shard or world instance.
- The list is sorted by total item count from highest to lowest.
- Mouse wheel scrolls through result pages, same as the Prev / Next buttons.
- Each row has Take (moves that prefab from the ground into inventory and backpack space) and CTake (duplicates the same amount into inventory while the ground stacks stay).
- Partial pickup is supported, so oversized stacks stop cleanly at real capacity.
- Stack-size compatibility follows the live server inventory rules, including common larger-stack mods.
- Pressing the hotkey again while scanning closes the panel and cancels the active scan immediately.
]]
author = "ra1nyxin"
version = "0.1.15"

forumthread = ""
api_version = 10

dst_compatible = true
dont_starve_compatible = false
reign_of_giants_compatible = false
all_clients_require_mod = true
client_only_mod = false

icon_atlas = nil
icon = nil

server_filter_tags = {
    "server",
    "items",
    "pickup",
    "inventory",
    "manager",
    "cleanup",
}

configuration_options = {
    {
        name = "modifier_key",
        label = "GIM Modifier Key",
        hover = "Held down while pressing the toggle key. Default: V (so V+N opens GIM). Pick None to use the toggle key alone.",
        options = {
            { description = "V", data = "KEY_V" },
            { description = "Ctrl", data = "KEY_CTRL" },
            { description = "Shift", data = "KEY_SHIFT" },
            { description = "Alt", data = "KEY_ALT" },
            { description = "None", data = "NONE" },
        },
        default = "KEY_V",
    },
    {
        name = "toggle_key",
        label = "GIM Toggle Key",
        hover = "Pressed together with the modifier key. Default: N (so V+N opens GIM).",
        options = {
            { description = "A", data = "KEY_A" },
            { description = "B", data = "KEY_B" },
            { description = "C", data = "KEY_C" },
            { description = "D", data = "KEY_D" },
            { description = "E", data = "KEY_E" },
            { description = "F", data = "KEY_F" },
            { description = "G", data = "KEY_G" },
            { description = "H", data = "KEY_H" },
            { description = "I", data = "KEY_I" },
            { description = "J", data = "KEY_J" },
            { description = "K", data = "KEY_K" },
            { description = "L", data = "KEY_L" },
            { description = "M", data = "KEY_M" },
            { description = "N", data = "KEY_N" },
            { description = "O", data = "KEY_O" },
            { description = "P", data = "KEY_P" },
            { description = "Q", data = "KEY_Q" },
            { description = "R", data = "KEY_R" },
            { description = "S", data = "KEY_S" },
            { description = "T", data = "KEY_T" },
            { description = "U", data = "KEY_U" },
            { description = "V", data = "KEY_V" },
            { description = "W", data = "KEY_W" },
            { description = "X", data = "KEY_X" },
            { description = "Y", data = "KEY_Y" },
            { description = "Z", data = "KEY_Z" },
        },
        default = "KEY_N",
    },
    {
        name = "esc_close",
        label = "Esc Closes GIM",
        hover = "While GIM is open, Esc closes the panel instead of opening the pause menu. Default: Yes.",
        options = {
            { description = "Yes", data = true },
            { description = "No", data = false },
        },
        default = true,
    },
}
