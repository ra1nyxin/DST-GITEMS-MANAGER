modimport("scripts/gim.lua")

local _G = GLOBAL
local TheNet = _G.TheNet
local string = _G.string

local toggle_key_name = GetModConfigData ~= nil and GetModConfigData("toggle_key") or "KEY_N"
if type(toggle_key_name) ~= "string" or toggle_key_name == "" then
    toggle_key_name = "KEY_N"
end

local toggle_key_code = _G[toggle_key_name] or _G.KEY_N
local toggle_key_label = string.gsub(toggle_key_name, "^KEY_", "")

if TheNet ~= nil and not TheNet:IsDedicated() then
    local GIMWidget = require("widgets/gimwidget")

    AddClassPostConstruct("screens/playerhud", function(self)
        if self == nil or self.gim_widget ~= nil then
            return
        end

        self.gim_widget = self:AddChild(GIMWidget(self.owner, self, toggle_key_label))

        if self._gim_old_onrawkey == nil then
            self._gim_old_onrawkey = self.OnRawKey
            self.OnRawKey = function(hud, key, down)
                if hud._gim_old_onrawkey ~= nil and hud._gim_old_onrawkey(hud, key, down) then
                    return true
                end

                if not down
                    and toggle_key_code ~= nil
                    and key == toggle_key_code
                    and hud.gim_widget ~= nil
                    and hud.owner ~= nil
                    and hud.owner == _G.ThePlayer
                then
                    return hud.gim_widget:HandleToggleKey()
                end
            end
        end
    end)
end
