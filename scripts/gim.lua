local _G = GLOBAL
local ipairs = _G.ipairs
local pairs = _G.pairs
local tostring = _G.tostring
local tonumber = _G.tonumber
local math = _G.math
local table = _G.table

local MOD_RPC_NAMESPACE = "dst_gitems_manager"
local CLIENT_RPC_NAMESPACE = "dst_gitems_manager"
local SCAN_BATCH_SIZE = 180
local RESULT_CHUNK_ROWS = 48
local RESULT_CHUNK_CHARS = 3600

local function GetClientRpc(name)
    return _G.GetClientModRPC(CLIENT_RPC_NAMESPACE, name)
end

local function GetPlayerWidget()
    return _G.ThePlayer ~= nil and _G.ThePlayer.HUD ~= nil and _G.ThePlayer.HUD.gim_widget or nil
end

local function IsGroundItem(inst)
    return inst ~= nil
        and inst:IsValid()
        and inst.prefab ~= nil
        and inst.components ~= nil
        and inst.components.inventoryitem ~= nil
        and inst.components.inventoryitem.owner == nil
        and not inst:HasTag("INLIMBO")
        and not inst:HasTag("NOCLICK")
        and not inst:HasTag("FX")
        and not inst:HasTag("DECOR")
end

local function GetItemCount(inst)
    return inst.components.stackable ~= nil and inst.components.stackable:StackSize() or 1
end

local function BuildSortedResults(prefab_totals)
    local results = {}
    local total_count = 0

    for prefab, count in pairs(prefab_totals) do
        total_count = total_count + count
        results[#results + 1] = {
            prefab = prefab,
            count = count,
        }
    end

    table.sort(results, function(a, b)
        if a.count == b.count then
            return a.prefab < b.prefab
        end
        return a.count > b.count
    end)

    return results, total_count
end

local function SendScanBegin(player, scan_id)
    _G.SendModRPCToClient(GetClientRpc("scan_begin"), player.userid, scan_id)
end

local function SendScanChunk(player, scan_id, payload)
    _G.SendModRPCToClient(GetClientRpc("scan_chunk"), player.userid, scan_id, payload)
end

local function SendScanComplete(player, scan_id, unique_count, total_count)
    _G.SendModRPCToClient(GetClientRpc("scan_complete"), player.userid, scan_id, unique_count, total_count)
end

local function SendPickupResult(player, prefab, taken_count)
    _G.SendModRPCToClient(GetClientRpc("pickup_result"), player.userid, prefab, taken_count)
end

local function CancelPlayerScan(player, close_panel)
    if player == nil then
        return
    end

    if player._gim_scan_task ~= nil then
        player._gim_scan_task:Cancel()
        player._gim_scan_task = nil
    end

    player._gim_scan_state = nil

    if close_panel then
        player._gim_scan_open = false
    end
end

local function FlushResultsToClient(player, scan_id, results, total_count)
    local chunk_lines = {}
    local chunk_chars = 0

    for i = 1, #results do
        local entry = results[i]
        local line = string.format("%s=%d", entry.prefab, entry.count)
        local extra_chars = #line + (#chunk_lines > 0 and 1 or 0)

        if #chunk_lines >= RESULT_CHUNK_ROWS or (chunk_chars + extra_chars) > RESULT_CHUNK_CHARS then
            SendScanChunk(player, scan_id, table.concat(chunk_lines, "\n"))
            chunk_lines = {}
            chunk_chars = 0
        end

        chunk_lines[#chunk_lines + 1] = line
        chunk_chars = chunk_chars + extra_chars
    end

    if #chunk_lines > 0 then
        SendScanChunk(player, scan_id, table.concat(chunk_lines, "\n"))
    end

    SendScanComplete(player, scan_id, #results, total_count)
end

local function FinalizePlayerScan(player, scan_id)
    local state = player ~= nil and player._gim_scan_state or nil
    if state == nil or state.scan_id ~= scan_id or not player:IsValid() then
        return
    end

    player._gim_scan_task = nil

    if not player._gim_scan_open then
        player._gim_scan_state = nil
        return
    end

    local results, total_count = BuildSortedResults(state.prefab_totals)
    player._gim_scan_state = nil
    FlushResultsToClient(player, scan_id, results, total_count)
end

local function ProcessPlayerScanSlice(player, scan_id)
    local state = player ~= nil and player._gim_scan_state or nil
    if state == nil
        or state.scan_id ~= scan_id
        or not player:IsValid()
        or not player._gim_scan_open
    then
        return
    end

    local end_index = math.min(state.index + SCAN_BATCH_SIZE - 1, #state.entities)
    for i = state.index, end_index do
        local inst = state.entities[i]
        if IsGroundItem(inst) then
            local count = GetItemCount(inst)
            state.prefab_totals[inst.prefab] = (state.prefab_totals[inst.prefab] or 0) + count
        end
    end

    state.index = end_index + 1

    if state.index <= #state.entities then
        player._gim_scan_task = player:DoTaskInTime(0, function()
            ProcessPlayerScanSlice(player, scan_id)
        end)
        return
    end

    FinalizePlayerScan(player, scan_id)
end

local function StartPlayerScan(player)
    if player == nil or not player:IsValid() or player.userid == nil then
        return
    end

    CancelPlayerScan(player, false)

    player._gim_scan_open = true
    player._gim_scan_serial = (player._gim_scan_serial or 0) + 1

    local state = {
        scan_id = player._gim_scan_serial,
        entities = {},
        index = 1,
        prefab_totals = {},
    }

    for _, inst in pairs(_G.Ents) do
        state.entities[#state.entities + 1] = inst
    end

    player._gim_scan_state = state
    SendScanBegin(player, state.scan_id)

    player._gim_scan_task = player:DoTaskInTime(0, function()
        ProcessPlayerScanSlice(player, state.scan_id)
    end)
end

local function CollectGroundItemsByPrefab(prefab)
    local items = {}
    for _, inst in pairs(_G.Ents) do
        if IsGroundItem(inst) and inst.prefab == prefab then
            items[#items + 1] = inst
        end
    end

    table.sort(items, function(a, b)
        local acount = GetItemCount(a)
        local bcount = GetItemCount(b)
        if acount == bcount then
            return a.GUID < b.GUID
        end
        return acount > bcount
    end)

    return items
end

local function PickupPrefabForPlayer(player, prefab)
    if player == nil
        or not player:IsValid()
        or prefab == nil
        or player.components == nil
        or player.components.inventory == nil
    then
        return 0
    end

    local inventory = player.components.inventory
    local taken_count = 0
    local src_pos = player:GetPosition()
    local items = CollectGroundItemsByPrefab(prefab)

    for i = 1, #items do
        local inst = items[i]
        if not inst:IsValid() then
            -- This stack disappeared while the request was running.
        else
            local stack_size = GetItemCount(inst)
            local accept_count = inventory:CanAcceptCount(inst, stack_size)
            if accept_count <= 0 then
                break
            end

            local give_inst = inst
            if inst.components.stackable ~= nil and accept_count < stack_size then
                give_inst = inst.components.stackable:Get(accept_count)
            end

            if inventory:GiveItem(give_inst, nil, src_pos) then
                taken_count = taken_count + accept_count
            else
                if give_inst ~= nil and give_inst:IsValid() and give_inst ~= inst then
                    give_inst.Transform:SetPosition(src_pos:Get())
                end
                break
            end
        end
    end

    return taken_count
end

local function OnRequestScan(player)
    if _G.TheWorld == nil or not _G.TheWorld.ismastersim then
        return
    end

    StartPlayerScan(player)
end

local function OnCancelScan(player)
    if _G.TheWorld == nil or not _G.TheWorld.ismastersim then
        return
    end

    CancelPlayerScan(player, true)
end

local function OnRequestPickup(player, prefab)
    if _G.TheWorld == nil or not _G.TheWorld.ismastersim then
        return
    end

    local taken_count = PickupPrefabForPlayer(player, prefab)
    SendPickupResult(player, prefab, taken_count)

    if player ~= nil and player._gim_scan_open then
        StartPlayerScan(player)
    end
end

local function OnClientScanBegin(scan_id)
    local widget = GetPlayerWidget()
    if widget ~= nil then
        widget:OnServerScanBegin(tonumber(scan_id) or 0)
    end
end

local function OnClientScanChunk(scan_id, payload)
    local widget = GetPlayerWidget()
    if widget ~= nil then
        widget:OnServerScanChunk(tonumber(scan_id) or 0, payload or "")
    end
end

local function OnClientScanComplete(scan_id, unique_count, total_count)
    local widget = GetPlayerWidget()
    if widget ~= nil then
        widget:OnServerScanComplete(
            tonumber(scan_id) or 0,
            tonumber(unique_count) or 0,
            tonumber(total_count) or 0
        )
    end
end

local function OnClientPickupResult(prefab, taken_count)
    local widget = GetPlayerWidget()
    if widget ~= nil then
        widget:OnServerPickupResult(prefab, tonumber(taken_count) or 0)
    end
end

AddModRPCHandler(MOD_RPC_NAMESPACE, "request_scan", OnRequestScan)
AddModRPCHandler(MOD_RPC_NAMESPACE, "cancel_scan", OnCancelScan)
AddModRPCHandler(MOD_RPC_NAMESPACE, "request_pickup", OnRequestPickup)

AddClientModRPCHandler(CLIENT_RPC_NAMESPACE, "scan_begin", OnClientScanBegin)
AddClientModRPCHandler(CLIENT_RPC_NAMESPACE, "scan_chunk", OnClientScanChunk)
AddClientModRPCHandler(CLIENT_RPC_NAMESPACE, "scan_complete", OnClientScanComplete)
AddClientModRPCHandler(CLIENT_RPC_NAMESPACE, "pickup_result", OnClientPickupResult)

AddPlayerPostInit(function(inst)
    if _G.TheWorld == nil or not _G.TheWorld.ismastersim then
        return
    end

    inst._gim_scan_open = false
    inst._gim_scan_serial = 0
    inst._gim_scan_state = nil
    inst._gim_scan_task = nil

    inst:ListenForEvent("onremove", function(player)
        CancelPlayerScan(player, true)
    end)
end)
