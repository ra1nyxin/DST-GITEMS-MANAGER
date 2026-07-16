local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Text = require("widgets/text")
local ImageButton = require("widgets/imagebutton")
local ScrollableList = require("widgets/scrollablelist")

local MOD_RPC_NAMESPACE = "dst_gitems_manager"
local PANEL_WIDTH = 920
local PANEL_HEIGHT = 620
local LIST_WIDTH = 820
local LIST_HEIGHT = 420
local ROW_HEIGHT = 48
local ROW_PADDING = 8
local ROW_VISIBLE_COUNT = 8

local function GetItemName(prefab)
    local names = _G.STRINGS ~= nil and _G.STRINGS.NAMES or nil
    local upper_prefab = prefab ~= nil and string.upper(prefab) or nil
    local display_name = upper_prefab ~= nil and names ~= nil and names[upper_prefab] or nil
    if type(display_name) == "string" and display_name ~= "" then
        return display_name
    end
    return prefab or "unknown"
end

local function SortEntries(items)
    table.sort(items, function(a, b)
        if a.count == b.count then
            return a.prefab < b.prefab
        end
        return a.count > b.count
    end)
end

local GIMRow = Class(Widget, function(self, owner, onclick)
    Widget._ctor(self, "gim_row")

    self.owner = owner
    self.onclick = onclick
    self.data = nil

    self.bg = self:AddChild(Image("images/ui.xml", "blank.tex"))
    self.bg:ScaleToSize(LIST_WIDTH - 72, ROW_HEIGHT)
    self.bg:SetTint(0.08, 0.08, 0.08, 0.85)
    self.bg:SetClickable(false)

    self.name_text = self:AddChild(Text(_G.CHATFONT, 28, ""))
    self.name_text:SetHAlign(_G.ANCHOR_LEFT)
    self.name_text:SetRegionSize(410, 36)
    self.name_text:SetPosition(-280, 0, 0)

    self.prefab_text = self:AddChild(Text(_G.CHATFONT, 20, ""))
    self.prefab_text:SetColour(0.72, 0.72, 0.72, 1)
    self.prefab_text:SetHAlign(_G.ANCHOR_LEFT)
    self.prefab_text:SetRegionSize(220, 30)
    self.prefab_text:SetPosition(10, 0, 0)

    self.count_text = self:AddChild(Text(_G.CHATFONT, 24, ""))
    self.count_text:SetColour(0.92, 0.86, 0.58, 1)
    self.count_text:SetHAlign(_G.ANCHOR_RIGHT)
    self.count_text:SetRegionSize(120, 32)
    self.count_text:SetPosition(205, 0, 0)

    self.button = self:AddChild(ImageButton())
    self.button:SetScale(0.68, 0.72, 1)
    self.button:SetText("Take")
    self.button:SetTextSize(24)
    self.button:SetPosition(325, 0, 0)
    self.button:SetOnClick(function()
        if self.data ~= nil and self.onclick ~= nil then
            self.onclick(self.data.prefab)
        end
    end)
end)

function GIMRow:SetData(data, row_index)
    self.data = data

    if data == nil then
        self:Hide()
        return
    end

    if row_index % 2 == 0 then
        self.bg:SetTint(0.1, 0.1, 0.1, 0.92)
    else
        self.bg:SetTint(0.06, 0.06, 0.06, 0.92)
    end

    self.name_text:SetString(GetItemName(data.prefab))
    self.prefab_text:SetString(data.prefab)
    self.count_text:SetString(tostring(data.count))
    self:Show()
end

local GIMWidget = Class(Widget, function(self, owner, hud)
    Widget._ctor(self, "gim_widget")

    self.owner = owner
    self.hud = hud
    self.is_open = false
    self.is_scanning = false
    self.active_scan_id = 0
    self.items = {}
    self.prefab_index = {}

    self:SetHAnchor(_G.ANCHOR_MIDDLE)
    self:SetVAnchor(_G.ANCHOR_MIDDLE)
    self:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)

    self.blocker = self:AddChild(Image("images/ui.xml", "blank.tex"))
    self.blocker:ScaleToSize(2000, 1200)
    self.blocker:SetTint(0, 0, 0, 0.22)

    self.panel = self:AddChild(Widget("gim_panel"))

    self.panel_bg = self.panel:AddChild(Image("images/ui.xml", "blank.tex"))
    self.panel_bg:ScaleToSize(PANEL_WIDTH, PANEL_HEIGHT)
    self.panel_bg:SetTint(0.03, 0.03, 0.03, 0.94)
    self.panel_bg:SetClickable(false)

    self.header = self.panel:AddChild(Text(_G.CHATFONT, 40, "GIM"))
    self.header:SetPosition(-380, 255, 0)
    self.header:SetHAlign(_G.ANCHOR_LEFT)
    self.header:SetRegionSize(240, 48)

    self.subheader = self.panel:AddChild(Text(_G.CHATFONT, 22, "Open: N   Scan scope: current shard"))
    self.subheader:SetColour(0.76, 0.76, 0.76, 1)
    self.subheader:SetPosition(-188, 210, 0)
    self.subheader:SetHAlign(_G.ANCHOR_LEFT)
    self.subheader:SetRegionSize(620, 30)

    self.status_text = self.panel:AddChild(Text(_G.CHATFONT, 24, "Press N to scan."))
    self.status_text:SetColour(0.9, 0.9, 0.9, 1)
    self.status_text:SetPosition(0, 172, 0)
    self.status_text:SetRegionSize(760, 32)
    self.status_text:SetHAlign(_G.ANCHOR_MIDDLE)

    self.rows = {}
    for i = 1, ROW_VISIBLE_COUNT do
        self.rows[i] = GIMRow(self.owner, function(prefab)
            self:RequestPickup(prefab)
        end)
    end

    self.scroll_list = self.panel:AddChild(ScrollableList(
        {},
        LIST_WIDTH,
        LIST_HEIGHT,
        ROW_HEIGHT,
        ROW_PADDING,
        function(row, data, row_index)
            row:SetData(data, row_index)
        end,
        self.rows,
        18,
        false,
        0,
        -6,
        1,
        1,
        "BLACK"
    ))
    self.scroll_list:SetPosition(0, -35, 0)
    self.scroll_list:LayOutStaticWidgets(-6, false, true)

    self.footer = self.panel:AddChild(Text(_G.CHATFONT, 20, "Sorted by total count, highest first."))
    self.footer:SetColour(0.72, 0.72, 0.72, 1)
    self.footer:SetPosition(-150, -272, 0)
    self.footer:SetRegionSize(640, 28)
    self.footer:SetHAlign(_G.ANCHOR_LEFT)

    self.close_hint = self.panel:AddChild(Text(_G.CHATFONT, 20, "Press N again to close."))
    self.close_hint:SetColour(0.72, 0.72, 0.72, 1)
    self.close_hint:SetPosition(280, -272, 0)
    self.close_hint:SetRegionSize(240, 28)
    self.close_hint:SetHAlign(_G.ANCHOR_RIGHT)

    self:Hide()
end)

function GIMWidget:SetStatus(text, r, g, b, a)
    self.status_text:SetString(text or "")
    self.status_text:SetColour(r or 0.9, g or 0.9, b or 0.9, a or 1)
end

function GIMWidget:ResetResults()
    self.items = {}
    self.prefab_index = {}
    self.scroll_list:SetList(self.items, true, 0)
end

function GIMWidget:RefreshList()
    SortEntries(self.items)
    self.scroll_list:SetList(self.items, true, 0)
    self.scroll_list:Scroll(0, true)
end

function GIMWidget:RequestScan()
    self.is_scanning = true
    self.active_scan_id = 0
    self:ResetResults()
    self:SetStatus("Scanning dropped items...", 0.94, 0.9, 0.72, 1)
    _G.SendModRPCToServer(_G.GetModRPC(MOD_RPC_NAMESPACE, "request_scan"))
end

function GIMWidget:RequestCancel()
    _G.SendModRPCToServer(_G.GetModRPC(MOD_RPC_NAMESPACE, "cancel_scan"))
end

function GIMWidget:RequestPickup(prefab)
    if prefab == nil or prefab == "" then
        return
    end

    self:SetStatus(string.format("Picking up %s...", GetItemName(prefab)), 0.88, 0.94, 1, 1)
    _G.SendModRPCToServer(_G.GetModRPC(MOD_RPC_NAMESPACE, "request_pickup"), prefab)
end

function GIMWidget:Open()
    if self.is_open then
        return
    end

    self.is_open = true
    self:Show()
    self.scroll_list:SetFocus()
    self:RequestScan()
end

function GIMWidget:Close(send_cancel)
    if not self.is_open then
        return
    end

    self.is_open = false
    self.is_scanning = false

    if send_cancel then
        self:RequestCancel()
    end

    self:Hide()
end

function GIMWidget:HandleToggleKey()
    if self.is_open then
        self:Close(true)
    else
        self:Open()
    end
    return true
end

function GIMWidget:OnServerScanBegin(scan_id)
    if not self.is_open then
        return
    end

    self.is_scanning = true
    self.active_scan_id = scan_id
    self:ResetResults()
    self:SetStatus("Scanning dropped items...", 0.94, 0.9, 0.72, 1)
end

function GIMWidget:OnServerScanChunk(scan_id, payload)
    if not self.is_open or scan_id ~= self.active_scan_id or payload == nil or payload == "" then
        return
    end

    for line in string.gmatch(payload, "[^\n]+") do
        local prefab, count = string.match(line, "^(.-)=(%d+)$")
        count = tonumber(count)
        if prefab ~= nil and prefab ~= "" and count ~= nil then
            local entry = self.prefab_index[prefab]
            if entry == nil then
                entry = {
                    prefab = prefab,
                    count = count,
                }
                self.prefab_index[prefab] = entry
                self.items[#self.items + 1] = entry
            else
                entry.count = count
            end
        end
    end

    self:RefreshList()
end

function GIMWidget:OnServerScanComplete(scan_id, unique_count, total_count)
    if not self.is_open or scan_id ~= self.active_scan_id then
        return
    end

    self.is_scanning = false
    self:RefreshList()

    if unique_count <= 0 then
        self:SetStatus("No dropped items found in this shard.", 0.76, 0.92, 0.76, 1)
        return
    end

    self:SetStatus(
        string.format("Scan done. %d item types / %d total items.", unique_count, total_count),
        0.76,
        0.92,
        0.76,
        1
    )
end

function GIMWidget:OnServerPickupResult(prefab, taken_count)
    if not self.is_open then
        return
    end

    if taken_count > 0 then
        self:SetStatus(
            string.format("Took %d x %s.", taken_count, GetItemName(prefab)),
            0.76,
            0.92,
            0.76,
            1
        )
    else
        self:SetStatus(
            string.format("No free space for %s.", GetItemName(prefab)),
            1,
            0.72,
            0.72,
            1
        )
    end
end

return GIMWidget
