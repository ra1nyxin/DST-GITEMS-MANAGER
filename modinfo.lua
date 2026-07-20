name = "DST-GITEMS-MANAGER"
description = [[
Server-side dropped item manager focused on practical cleanup and retrieval.

Current features:
- Every player in the room can press the configured hotkey (default N) to open GIM.
- GIM scans dropped ground items only when the panel is opened.
- The scan is limited to the player's current shard or world instance.
- The list is sorted by total item count from highest to lowest.
- Each row can pick up that prefab directly into inventory and backpack space.
- Partial pickup is supported, so oversized stacks stop cleanly at real capacity.
- Stack-size compatibility follows the live server inventory rules, including common larger-stack mods.
- Pressing the configured hotkey again while scanning closes the panel and cancels the active scan immediately.
]]
author = "ra1nyxin"
version = "0.1.13"

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
        name = "toggle_key",
        label = "GIM Toggle Key",
        hover = "Client-side hotkey used to open and close GIM. Default: N.",
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
}
