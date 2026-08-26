local Skin = _G.Skin or "Default"

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local State = LocalPlayer:FindFirstChild("state")

if not State then
    while true do
        task.wait(1)
        State = LocalPlayer:FindFirstChild("state")
        if State then break end
    end
end

State:SetAttribute("EquippedSkin", Skin)
