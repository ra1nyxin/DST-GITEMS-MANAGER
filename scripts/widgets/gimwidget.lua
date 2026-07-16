local _G = _G
local Class = _G.Class
local Widget = require("widgets/widget")
local Image = require("widgets/image")
local Text = require("widgets/text")
local ImageButton = require("widgets/imagebutton")

local MOD_RPC_NAMESPACE = "dst_gitems_manager"
local PANEL_ATLAS = "images/global.xml"
local PANEL_TEX = "square.tex"
local PANEL_WIDTH = 920
local PANEL_HEIGHT = 620
local LIST_WIDTH = 820
local ROW_HEIGHT = 40
local ROW_PADDING = 4
local ROW_VISIBLE_COUNT = 7
local LIST_CONTENT_HEIGHT = ROW_VISIBLE_COUNT * ROW_HEIGHT + (ROW_VISIBLE_COUNT - 1) * ROW_PADDING
local LIST_HEIGHT = LIST_CONTENT_HEIGHT + 32

local function GetNow()
    return _G.GetTime ~= nil and _G.GetTime() or 0
end

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

local RectButton = Class(Widget, function(self, width, height, label, onclick)
    Widget._ctor(self, "gim_rect_button")

    self.onclick = onclick

    self.button = self:AddChild(ImageButton(
        PANEL_ATLAS,
        PANEL_TEX,
        PANEL_TEX,
        PANEL_TEX,
        PANEL_TEX,
        PANEL_TEX,
        { 1, 1 },
        { 0, 0 }
    ))
    self.button:ForceImageSize(width, height)
    self.button.scale_on_focus = false
    self.button.move_on_click = false
    self.button.ignore_standard_scaling = true
    self.button:SetImageNormalColour(0.16, 0.16, 0.16, 0.98)
    self.button:SetImageFocusColour(0.26, 0.26, 0.26, 0.98)
    self.button:SetImageDisabledColour(0.1, 0.1, 0.1, 0.7)
    self.button:SetText(label or "")
    self.button:SetTextSize(22)
    self.button:SetTextColour(0.92, 0.92, 0.92, 1)
    self.button:SetTextFocusColour(1, 1, 1, 1)
    self.button:SetTextDisabledColour(0.58, 0.58, 0.58, 1)
    self.button:SetOnClick(function()
        if self.onclick ~= nil then
            self.onclick()
        end
    end)
end)

function RectButton:SetEnabled(enabled)
    if enabled then
        self.button:Enable()
    else
        self.button:Disable()
    end
end

function RectButton:SetText(label)
    self.button:SetText(label or "")
end

local GIMRow = Class(Widget, function(self, owner, onclick)
    Widget._ctor(self, "gim_row")

    self.owner = owner
    self.onclick = onclick
    self.data = nil

    self.bg = self:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.bg:ScaleToSize(804, ROW_HEIGHT)
    self.bg:SetTint(0.08, 0.08, 0.08, 0.96)
    self.bg:SetClickable(false)

    self.name_text = self:AddChild(Text(_G.CHATFONT, 24, ""))
    self.name_text:SetColour(0.95, 0.95, 0.95, 1)
    self.name_text:SetHAlign(_G.ANCHOR_LEFT)
    self.name_text:SetRegionSize(280, 34)
    self.name_text:SetPosition(-282, 0, 0)

    self.prefab_text = self:AddChild(Text(_G.CHATFONT, 18, ""))
    self.prefab_text:SetColour(0.72, 0.72, 0.72, 1)
    self.prefab_text:SetHAlign(_G.ANCHOR_LEFT)
    self.prefab_text:SetRegionSize(270, 28)
    self.prefab_text:SetPosition(-42, 0, 0)

    self.count_text = self:AddChild(Text(_G.CHATFONT, 22, ""))
    self.count_text:SetColour(0.92, 0.86, 0.58, 1)
    self.count_text:SetHAlign(_G.ANCHOR_RIGHT)
    self.count_text:SetRegionSize(90, 30)
    self.count_text:SetPosition(212, 0, 0)

    self.button = self:AddChild(RectButton(110, 32, "Take", function()
        if self.data ~= nil and self.onclick ~= nil then
            self.onclick(self.data.prefab)
        end
    end))
    self.button:SetPosition(328, 0, 0)
end)

function GIMRow:SetData(data, row_index)
    self.data = data

    if data == nil then
        self:Hide()
        return
    end

    if row_index % 2 == 0 then
        self.bg:SetTint(0.11, 0.11, 0.11, 0.98)
    else
        self.bg:SetTint(0.06, 0.06, 0.06, 0.98)
    end

    self.name_text:SetString(GetItemName(data.prefab))
    self.prefab_text:SetString(data.prefab)
    self.count_text:SetString(tostring(data.count))
    self.button:SetEnabled(true)
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
    self.scroll_offset = 0
    self.scan_started_at = 0
    self.last_scan_elapsed = 0

    self:SetHAnchor(_G.ANCHOR_MIDDLE)
    self:SetVAnchor(_G.ANCHOR_MIDDLE)
    self:SetScaleMode(_G.SCALEMODE_PROPORTIONAL)

    self.blocker = self:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.blocker:ScaleToSize(2200, 1400)
    self.blocker:SetTint(0, 0, 0, 0.5)
    self.blocker:SetClickable(false)

    self.panel = self:AddChild(Widget("gim_panel"))

    self.panel_bg = self.panel:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.panel_bg:ScaleToSize(PANEL_WIDTH, PANEL_HEIGHT)
    self.panel_bg:SetTint(0.015, 0.015, 0.015, 0.985)
    self.panel_bg:SetClickable(false)

    self.header_band = self.panel:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.header_band:ScaleToSize(PANEL_WIDTH - 36, 92)
    self.header_band:SetPosition(0, 236, 0)
    self.header_band:SetTint(0.09, 0.09, 0.09, 0.985)
    self.header_band:SetClickable(false)

    self.status_band = self.panel:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.status_band:ScaleToSize(PANEL_WIDTH - 36, 48)
    self.status_band:SetPosition(0, 176, 0)
    self.status_band:SetTint(0.07, 0.07, 0.07, 0.985)
    self.status_band:SetClickable(false)

    self.column_band = self.panel:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.column_band:ScaleToSize(LIST_WIDTH + 28, 34)
    self.column_band:SetPosition(0, 131, 0)
    self.column_band:SetTint(0.06, 0.06, 0.06, 0.985)
    self.column_band:SetClickable(false)

    self.list_bg = self.panel:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.list_bg:ScaleToSize(LIST_WIDTH + 28, LIST_HEIGHT)
    self.list_bg:SetPosition(0, -31, 0)
    self.list_bg:SetTint(0.05, 0.05, 0.05, 0.985)
    self.list_bg:SetClickable(false)

    self.footer_band = self.panel:AddChild(Image(PANEL_ATLAS, PANEL_TEX))
    self.footer_band:ScaleToSize(PANEL_WIDTH - 36, 58)
    self.footer_band:SetPosition(0, -262, 0)
    self.footer_band:SetTint(0.075, 0.075, 0.075, 0.985)
    self.footer_band:SetClickable(false)

    self.header = self.panel:AddChild(Text(_G.CHATFONT, 40, "GIM"))
    self.header:SetPosition(-286, 252, 0)
    self.header:SetHAlign(_G.ANCHOR_LEFT)
    self.header:SetRegionSize(300, 48)

    self.subheader = self.panel:AddChild(Text(_G.CHATFONT, 20, "Open: N   Close: N   Scope: current shard"))
    self.subheader:SetColour(0.78, 0.78, 0.78, 1)
    self.subheader:SetPosition(-78, 218, 0)
    self.subheader:SetHAlign(_G.ANCHOR_LEFT)
    self.subheader:SetRegionSize(660, 28)

    self.status_text = self.panel:AddChild(Text(_G.CHATFONT, 22, "Press N to scan."))
    self.status_text:SetColour(0.92, 0.92, 0.92, 1)
    self.status_text:SetPosition(0, 176, 0)
    self.status_text:SetRegionSize(790, 30)
    self.status_text:SetHAlign(_G.ANCHOR_MIDDLE)

    self.column_item = self.panel:AddChild(Text(_G.CHATFONT, 22, "Item"))
    self.column_item:SetColour(0.86, 0.86, 0.86, 1)
    self.column_item:SetPosition(-314, 131, 0)
    self.column_item:SetRegionSize(200, 28)
    self.column_item:SetHAlign(_G.ANCHOR_LEFT)

    self.column_prefab = self.panel:AddChild(Text(_G.CHATFONT, 22, "Prefab"))
    self.column_prefab:SetColour(0.86, 0.86, 0.86, 1)
    self.column_prefab:SetPosition(-76, 131, 0)
    self.column_prefab:SetRegionSize(230, 28)
    self.column_prefab:SetHAlign(_G.ANCHOR_LEFT)

    self.column_count = self.panel:AddChild(Text(_G.CHATFONT, 22, "Count"))
    self.column_count:SetColour(0.86, 0.86, 0.86, 1)
    self.column_count:SetPosition(172, 131, 0)
    self.column_count:SetRegionSize(90, 28)
    self.column_count:SetHAlign(_G.ANCHOR_RIGHT)

    self.page_text = self.panel:AddChild(Text(_G.CHATFONT, 20, "0 / 0"))
    self.page_text:SetColour(0.74, 0.74, 0.74, 1)
    self.page_text:SetPosition(58, -262, 0)
    self.page_text:SetRegionSize(180, 28)
    self.page_text:SetHAlign(_G.ANCHOR_MIDDLE)

    self.footer = self.panel:AddChild(Text(_G.CHATFONT, 20, "Sorted by total count, highest first."))
    self.footer:SetColour(0.72, 0.72, 0.72, 1)
    self.footer:SetPosition(-246, -262, 0)
    self.footer:SetRegionSize(360, 28)
    self.footer:SetHAlign(_G.ANCHOR_LEFT)

    self.list_root = self.panel:AddChild(Widget("gim_list_root"))
    self.list_root:SetPosition(0, -40, 0)

    self.rows = {}
    local top_y = LIST_CONTENT_HEIGHT * 0.5 - ROW_HEIGHT * 0.5
    for i = 1, ROW_VISIBLE_COUNT do
        local row = self.list_root:AddChild(GIMRow(self.owner, function(prefab)
            self:RequestPickup(prefab)
        end))
        row:SetPosition(0, top_y - (i - 1) * (ROW_HEIGHT + ROW_PADDING), 0)
        self.rows[i] = row
    end

    self.scroll_up = self.panel:AddChild(RectButton(118, 34, "Prev", function()
        self:ScrollBy(-1)
    end))
    self.scroll_up:SetPosition(252, -262, 0)

    self.scroll_down = self.panel:AddChild(RectButton(118, 34, "Next", function()
        self:ScrollBy(1)
    end))
    self.scroll_down:SetPosition(382, -262, 0)

    self:Hide()
end)

function GIMWidget:GetMaxOffset()
    return math.max(0, #self.items - ROW_VISIBLE_COUNT)
end

function GIMWidget:UpdateScrollButtons()
    local max_offset = self:GetMaxOffset()
    self.scroll_up:SetEnabled(self.scroll_offset > 0)
    self.scroll_down:SetEnabled(self.scroll_offset < max_offset)

    local first_index = #self.items > 0 and (self.scroll_offset + 1) or 0
    local last_index = math.min(#self.items, self.scroll_offset + ROW_VISIBLE_COUNT)
    self.page_text:SetString(string.format("%d-%d / %d", first_index, last_index, #self.items))
end

function GIMWidget:RefreshVisibleRows()
    for i = 1, ROW_VISIBLE_COUNT do
        local data_index = self.scroll_offset + i
        self.rows[i]:SetData(self.items[data_index], data_index)
    end
    self:UpdateScrollButtons()
end

function GIMWidget:ScrollBy(delta)
    local max_offset = self:GetMaxOffset()
    local new_offset = math.max(0, math.min(max_offset, self.scroll_offset + delta))
    if new_offset == self.scroll_offset then
        return
    end
    self.scroll_offset = new_offset
    self:RefreshVisibleRows()
end

function GIMWidget:SetStatus(text, r, g, b, a)
    self.status_text:SetString(text or "")
    self.status_text:SetColour(r or 0.92, g or 0.92, b or 0.92, a or 1)
end

function GIMWidget:ResetResults()
    self.items = {}
    self.prefab_index = {}
    self.scroll_offset = 0
    self:RefreshVisibleRows()
end

function GIMWidget:RefreshList()
    SortEntries(self.items)
    self.scroll_offset = math.min(self.scroll_offset, self:GetMaxOffset())
    self:RefreshVisibleRows()
end

function GIMWidget:RequestScan()
    self.is_scanning = true
    self.active_scan_id = 0
    self.scan_started_at = 0
    self.last_scan_elapsed = 0
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
    self.scroll_up.button:SetFocus()
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
    self.scan_started_at = GetNow()
    self.last_scan_elapsed = 0
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
    self.last_scan_elapsed = math.max(0, GetNow() - self.scan_started_at)
    self:RefreshList()

    if unique_count <= 0 then
        self:SetStatus(
            string.format("Scan done in %.2fs. No dropped items found in this shard.", self.last_scan_elapsed),
            0.76,
            0.92,
            0.76,
            1
        )
        return
    end

    self:SetStatus(
        string.format(
            "Scan done in %.2fs. %d item types / %d total items.",
            self.last_scan_elapsed,
            unique_count,
            total_count
        ),
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
