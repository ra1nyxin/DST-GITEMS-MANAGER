local source = assert(io.open("scripts/widgets/gimwidget.lua", "r")):read("*a")
local methods = assert(source:match("(function GIMWidget:GetMaxOffset%(%).-)function GIMWidget:OnControl"))
local GIMWidget = {}
local load_chunk = loadstring or load
assert(load_chunk("local GIMWidget = ...\nlocal ROW_VISIBLE_COUNT = 7\n" .. methods))(GIMWidget)

for count = 0, 100 do
    local widget = { items = {}, rows = {}, scroll_offset = 0 }
    setmetatable(widget, { __index = GIMWidget })
    for i = 1, count do widget.items[i] = i end
    for i = 1, 7 do
        widget.rows[i] = { SetData = function(row, data) row.data = data end }
    end
    widget.scroll_up = { SetEnabled = function(button, enabled) button.enabled = enabled end }
    widget.scroll_down = { SetEnabled = function(button, enabled) button.enabled = enabled end }
    widget.page_text = { SetString = function(label, value) label.value = value end }

    widget:RefreshVisibleRows()
    local seen = {}
    repeat
        for _, row in ipairs(widget.rows) do
            if row.data then
                assert(not seen[row.data], "duplicate entry " .. row.data)
                seen[row.data] = true
            end
        end
        if not widget.scroll_down.enabled then break end
        widget:ScrollBy(1)
    until false
    for i = 1, count do assert(seen[i], "missing entry " .. i) end
    local last_offset = widget.scroll_offset
    widget:ScrollBy(1)
    assert(widget.scroll_offset == last_offset and not widget.scroll_down.enabled)
    while widget.scroll_up.enabled do widget:ScrollBy(-1) end
    widget:ScrollBy(-1)
    assert(widget.scroll_offset == 0 and not widget.scroll_up.enabled)
    widget:ScrollBy(1000)
    assert(widget.scroll_offset == last_offset)
    widget:ScrollBy(-1000)
    assert(widget.scroll_offset == 0)
end
print("Pagination checks passed for 0-100 entries")
