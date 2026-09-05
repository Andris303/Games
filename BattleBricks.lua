local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local NPCs = workspace.NPCFolders
local NPCCache = {}

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

local function PreLocal()
    if not NPCs:FindFirstChild("EnemyFolder") then return end
    if not NPCs:FindFirstChild("FriendlyFolder") then return end

    for _, inst in NPCs.EnemyFolder:GetChildren() do
        local id = InstId(inst)
        if id then
            NPCCache[id] = inst
        end
    end

    for _, inst in NPCs.FriendlyFolder:GetChildren() do
        local id = InstId(inst)
        if id then
            NPCCache[id] = inst
        end
    end
end

local function Render()
    for id, inst in NPCCache do
        if not inst or not inst.Parent then
            NPCCache[id] = nil
            continue
        end

        local root = inst:FindFirstChild("HumanoidRootPart")
        local humanoid = inst:FindFirstChild("Humanoid")
        if not root or not humanoid then
            NPCCache[id] = nil
            continue
        end

        local s, pos = pcall(function()
            return root.Position
        end)
        if s then
            local pos = Vector3.new(pos.x, pos.y + 3, pos.z)
            local p, v = Camera:WorldToScreenPoint(pos)
            if v then
                local size = 20
                local NewPos = Vector2.new(p.x, p.y - size / 2)

                local health = math.floor(humanoid.Health * 100) / 100
                local maxhealth = math.floor(humanoid.MaxHealth * 100) / 100
                local text = tostring(health) .. " / " .. tostring(maxhealth)

                local ratio = math.clamp(health / maxhealth, 0, 1)
                local color
                if ratio >= 2/3 then
                    local alpha = (ratio - 2/3) * 3
                    color = Color3.fromRGB(255, 255, 0):Lerp(Color3.fromRGB(0, 255, 0), alpha)
                elseif ratio >= 1/3 then
                    local alpha = (ratio - 1/3) * 3
                    color = Color3.fromRGB(255, 128, 0):Lerp(Color3.fromRGB(255, 255, 0), alpha)
                else
                    local alpha = ratio * 3
                    color = Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(255, 128, 0), alpha)
                end

                DrawingImmediate.OutlinedText(NewPos, size, color, 1, text, true)
            end
        end
    end
end

clear_model_data()

print("Loaded")

RunService.Render:Connect(Render)
RunService.PreLocal:Connect(PreLocal)
