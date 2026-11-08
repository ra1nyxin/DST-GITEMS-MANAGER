local file = assert(io.open("scripts/widgets/gimwidget.lua", "r"))
local source = file:read("*a")
file:close()
local definition = assert(source:match("(local RectButton = Class%(.+)%s+local GIMRow = Class"))
local Widget = { _ctor = function() end }
function Widget:AddChild(child) return child end
local function Class(base, constructor)
    local class = setmetatable({}, { __index = base })
    class.__index = class
    return setmetatable(class, { __index = base, __call = function(_, ...)
        local instance = setmetatable({}, class)
        constructor(instance, ...)
        return instance
    end })
end
local function ImageButton()
    local button = { focus = true, enabled = true }
    setmetatable(button, { __index = function(_, key)
        if key == "IsEnabled" then return function(self) return self.enabled end end
        if key == "SetOnClick" then return function(self, fn) self.onclick = fn end end
        if key == "OnMouseButton" then return function() return false end end
        return function() end
    end })
    return button
end
local load_chunk = loadstring or load
local make_button = assert(load_chunk("local Class, Widget, ImageButton, _G = ...\nlocal PANEL_ATLAS, PANEL_TEX = '', ''\n" .. definition .. "\nreturn RectButton"))(Class, Widget, ImageButton, { MOUSEBUTTON_RIGHT = 2 })
local left, right = 0, 0
local button = make_button(88, 32, "Take", function() left = left + 1 end, function() right = right + 1 end).button
button.onclick()
assert(left == 1 and right == 0)
assert(button:OnMouseButton(2, true))
assert(button:OnMouseButton(2, false))
assert(left == 1 and right == 1)
button.enabled = false
assert(not button:OnMouseButton(2, true) and right == 1)
button.enabled, button.focus = true, false
assert(not button:OnMouseButton(2, true) and right == 1)
assert(not button:OnMouseButton(1, true) and right == 1)
print("Take button input checks passed")
