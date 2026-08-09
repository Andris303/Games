local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local function PostLocal()
    if type(workspace:GetChildren()) ~= "table" then return end
    if type(Players:GetChildren()) ~= "table" then return end
    if not workspace:FindFirstChild("DefenseEnemies") then return end   
    if type(workspace.DefenseEnemies:GetChildren()) ~= "table" then return end

    local Char = LocalPlayer.Character
    if not Char then return end

    for ID, inst in _G.ESPList do
        if not inst or not inst.Parent then
            ESP.RemovePlayer(ID)
        else
            if not inst:FindFirstChild("Humanoid") then continue end
            if _G.ESPHealths[ID] ~= inst.Humanoid.Health then
                if inst.Humanoid.Health <= 0 then
                    ESP.RemovePlayer(ID)
                    continue
                end
                ESP.EditHealth(ID, inst.Humanoid.Health)
            end
        end
    end

    for _, inst in workspace.DefenseEnemies:GetChildren() do
        if not inst or not inst.Parent then continue end
        if not inst:FindFirstChild("Humanoid") then continue end

        ESP.AddPlayer(inst, false, inst.Humanoid.Health, inst.Humanoid.MaxHealth)
    end

    if type(Players:GetChildren()) ~= "table" then return end

    for _, inst in Players:GetChildren() do
        if not inst or not inst.Parent then continue end
        if inst ~= LocalPlayer then continue end

        local Char = inst.Character
        if not Char then continue end

        if not Char:FindFirstChild("Health") then continue end

        ESP.AddPlayer(Char, true, Char.Humanoid.Health, Char.Humanoid.MaxHealth, inst.Name, inst.DisplayName, inst.UserId)
    end
end

clear_model_data()

print("Loaded")

RunService.PostLocal:Connect(PostLocal)
