name = "DST-GITEMS-MANAGER"
description = [[
Server-side dropped item manager focused on practical cleanup and retrieval.

Current features:
- Every player in the room can press N to open GIM.
- GIM scans dropped ground items only when the panel is opened.
- The scan is limited to the player's current shard or world instance.
- The list is sorted by total item count from highest to lowest.
- Each row can pick up that prefab directly into inventory and backpack space.
- Partial pickup is supported, so oversized stacks stop cleanly at real capacity.
- Stack-size compatibility follows the live server inventory rules, including common larger-stack mods.
- Closing the panel while scanning cancels the active scan instead of finishing in the background.
]]
author = "ra1nyxin"
version = "0.1.8"

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
