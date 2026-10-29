modimport("scripts/gim.lua")

local _G = GLOBAL
local TheNet = _G.TheNet
local string = _G.string

local function GetKeyCode(name)
    return type(name) == "string" and name ~= "" and _G[name] or nil
end

local function GetKeyLabel(name)
    if name == "KEY_CTRL" then
        return "Ctrl"
    elseif name == "KEY_SHIFT" then
        return "Shift"
    elseif name == "KEY_ALT" then
        return "Alt"
    end
    return string.gsub(name or "", "^KEY_", "")
end

local function GetConfig(name, default)
    local value = GetModConfigData ~= nil and GetModConfigData(name) or nil
    if value == nil then
        return default
    end
    return value
end

local toggle_key_name = GetConfig("toggle_key", "KEY_N")
if type(toggle_key_name) ~= "string" or toggle_key_name == "" then
    toggle_key_name = "KEY_N"
end

local modifier_key_name = GetConfig("modifier_key", "KEY_V")
if type(modifier_key_name) ~= "string" or modifier_key_name == "" or modifier_key_name == "NONE" then
    modifier_key_name = nil
end

local esc_close_enabled = GetConfig("esc_close", true) ~= false

local toggle_key_code = GetKeyCode(toggle_key_name) or _G.KEY_N
local modifier_key_code = modifier_key_name ~= nil and GetKeyCode(modifier_key_name) or nil

-- 同一个键时退化成单键触发，否则面板永远打不开
if modifier_key_code ~= nil and modifier_key_code == toggle_key_code then
    modifier_key_code = nil
    modifier_key_name = nil
end

local toggle_key_label = GetKeyLabel(toggle_key_name)
local modifier_key_label = modifier_key_name ~= nil and GetKeyLabel(modifier_key_name) or nil

local function IsToggleComboDown()
    if modifier_key_code == nil then
        return true
    end

    -- 查引擎实时键盘状态，不依赖修饰键事件有没有送到这个 HUD
    return _G.TheInput ~= nil and _G.TheInput:IsKeyDown(modifier_key_code) == true
end

if TheNet ~= nil and not TheNet:IsDedicated() then
    local GIMWidget = require("widgets/gimwidget")

    AddClassPostConstruct("screens/playerhud", function(self)
        if self == nil or self.gim_widget ~= nil then
            return
        end

        self.gim_widget = self:AddChild(GIMWidget(
            self.owner,
            self,
            toggle_key_label,
            modifier_key_label,
            esc_close_enabled
        ))

        if self._gim_old_onrawkey == nil then
            self._gim_old_onrawkey = self.OnRawKey
            self.OnRawKey = function(hud, key, down)
                if hud._gim_old_onrawkey ~= nil and hud._gim_old_onrawkey(hud, key, down) then
                    return true
                end

                if key ~= toggle_key_code
                    or hud.gim_widget == nil
                    or hud.owner == nil
                    or hud.owner ~= _G.ThePlayer
                then
                    return
                end

                if down then
                    -- 每次按下都重新判定，避免漏掉 keyup 后状态卡死
                    hud._gim_toggle_armed = IsToggleComboDown()
                    return hud._gim_toggle_armed or nil
                end

                if hud._gim_toggle_armed then
                    hud._gim_toggle_armed = false
                    return hud.gim_widget:HandleToggleKey()
                end
            end
        end

        if self._gim_old_oncontrol == nil then
            self._gim_old_oncontrol = self.OnControl
            self.OnControl = function(hud, control, down)
                -- Esc 在键盘上是 CONTROL_PAUSE，部分界面也会走 CONTROL_CANCEL。
                -- 面板打开时先吃掉，避免关面板的同时弹出暂停菜单。
                if esc_close_enabled
                    and (control == _G.CONTROL_PAUSE or control == _G.CONTROL_CANCEL)
                    and hud.gim_widget ~= nil
                    and hud.gim_widget.is_open
                    and hud.owner ~= nil
                    and hud.owner == _G.ThePlayer
                then
                    if not down then
                        hud.gim_widget:Close(true)
                    end
                    return true
                end

                if hud._gim_old_oncontrol ~= nil then
                    return hud._gim_old_oncontrol(hud, control, down)
                end
            end
        end
    end)
end
