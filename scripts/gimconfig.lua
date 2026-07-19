local _G = _G

local M = {}

M.DEFAULT_TOGGLE_KEY = "KEY_N"

local function ReadConfigValue()
    local getter = GetModConfigData or (_G ~= nil and _G.GetModConfigData) or nil
    if getter == nil then
        return nil
    end

    return getter("toggle_key")
end

function M.GetToggleKeyName()
    local value = ReadConfigValue()
    if type(value) == "string" and value ~= "" then
        return value
    end

    return M.DEFAULT_TOGGLE_KEY
end

function M.GetToggleKeyCode()
    local key_name = M.GetToggleKeyName()
    return (_G ~= nil and _G[key_name]) or (_G ~= nil and _G[M.DEFAULT_TOGGLE_KEY]) or nil
end

function M.GetToggleKeyLabel()
    return string.gsub(M.GetToggleKeyName(), "^KEY_", "")
end

return M
