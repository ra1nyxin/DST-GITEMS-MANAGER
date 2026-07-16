modimport("scripts/gim.lua")

local _G = GLOBAL
local TheNet = rawget(_G, "TheNet")

if TheNet ~= nil and not TheNet:IsDedicated() then
    local GIMWidget = require("widgets/gimwidget")

    AddClassPostConstruct("screens/playerhud", function(self)
        if self == nil or self.gim_widget ~= nil then
            return
        end

        self.gim_widget = self:AddChild(GIMWidget(self.owner, self))

        if self._gim_old_onrawkey == nil then
            self._gim_old_onrawkey = self.OnRawKey
            self.OnRawKey = function(hud, key, down)
                if hud._gim_old_onrawkey ~= nil and hud._gim_old_onrawkey(hud, key, down) then
                    return true
                end

                if not down
                    and key == _G.KEY_N
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
