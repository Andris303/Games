--!strict
--!optimize 2

local Offset1 = _G.OffsetRequiresLineOfSight or 0x137 -- version-9affbe66b2624d20
local Offset2 = _G.OffsetEnabled or 0x136 -- version-9affbe66b2624d20
local Offset3 = _G.OffsetMaxActivationDistance or 0x128 -- version-9affbe66b2624d20
local WaitTime = _G.WaitTime or .02

if game.GameId == 8773050457 then

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local ItemCache = {}
local CardLevel = 0

local Cards = {}
Cards["SCP_005"] = 5
Cards["O5 Council Card"] = 5
Cards["Facility Manager Card"] = 4
Cards["Lieutenant Card"] = 4
Cards["Commander Card"] = 4
Cards["MTF Operative Card"] = 4
Cards["Hacking Device"] = 4
Cards["Major Scientist Card"] = 3
Cards["Containment Engineer Card"] = 3
Cards["Zone Manager Card"] = 3
Cards["Medical Specialist"] = 3
Cards["Doctor Card"] = 2
Cards["Scientist Card"] = 2
Cards["Engineer Card"] = 2
Cards["Janitor Card"] = 1

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

RunService.Render:Connect(function()
    if not LocalPlayer.Team then return end
    if LocalPlayer.Team.Name == "Lobby" then return end
    local Char = LocalPlayer.Character
    if not Char then return end
    if not Char:FindFirstChild("HumanoidRootPart") then return end
    if not Char:FindFirstChild("Humanoid") then return end
    local RootPos = Char.HumanoidRootPart.Position

    for id, inst in ItemCache do
        if not inst or not inst.Parent then
            ItemCache[id] = nil
            continue
        end

        local Primary = inst.PrimaryPart
        if not Primary or not Primary:IsA("Part") then
            ItemCache[id] = nil
            continue
        end

        if Cards[inst.Name] then
            if CardLevel >= Cards[inst.Name] then
                ItemCache[id] = nil
                continue
            end
        end

        if Primary:IsA("Part") then
            if vector.magnitude(RootPos - Primary.Position) < 300 then
                local Position, Visible = Camera:WorldToScreenPoint(Primary.Position)
                DrawingImmediate.OutlinedText(Position, 13, Color3.fromRGB(49, 228, 173), 1, inst.Name, true)
            end
        end
    end
end)

local counter = 0

task.spawn(function()
    while true do
        task.wait(WaitTime)

        counter += 1

        if not LocalPlayer.Team then continue end
        if LocalPlayer.Team.Name == "Lobby" then continue end
        local Char = LocalPlayer.Character
        if not Char then continue end
        if not Char:FindFirstChild("HumanoidRootPart") then continue end
        if not Char:FindFirstChild("Humanoid") then continue end
        local LocalItems = LocalPlayer.Backpack:GetChildren()
        local Items = workspace.ItemSpawns

        local TempLevel = 0

        for _, inst in LocalItems do
            if Cards[inst.Name] then
                TempLevel = Cards[inst.Name]
            end
        end

        CardLevel = TempLevel

        for _, inst in Items:GetChildren() do
            if ItemCache[InstId(inst)] then continue end
            if inst:IsA("Model") and inst.PrimaryPart then
                if inst.PrimaryPart:IsA("Part") then
                    task.wait(WaitTime)
                    local Prompt = inst:FindFirstChildOfClass("ProximityPrompt")
                    if Prompt then
                        memory.writeu8(Prompt, Offset1, 0)
                        memory.writeu8(Prompt, Offset2, 1)
                        memory.writef32(Prompt, Offset3, 10)
                    end
                    if Cards[inst.Name] then
                        if CardLevel >= Cards[inst.Name] then continue end
                    end
                    if inst.Name == "Flashbang" or string.find(inst.Name, "Grenade") then continue end
                    if Char.Humanoid.Health == Char.Humanoid.MaxHealth then
                        if inst.Name == "Bandage" then continue end
                    end
                    if InstId(inst) then
                        ItemCache[InstId(inst)] = inst
                    end
                end
            end
        end
    end
end)

print("Loaded")

end
