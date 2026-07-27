--!strict
--!optimize 2

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local PlayerCache = {}
local RenderCache = {}
local c = _G.Colors or {
    MaxVolume = Color3.fromRGB(220,0,0),
    MinVolume = Color3.fromRGB(255,255,190),
}
local FocusTimer = 0

local h = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()

--[[
local RobloxVersion = _G.RobloxVersion or "version-9affbe66b2624d20"

local SoundOffsets
local s, RawOffsets = pcall(function()
    return game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json")
end)
if s and RawOffsets then
    local s2, decoded = pcall(function()
        return crypt.json.decode(RawOffsets)
    end)
    if s2 and decoded and decoded.Offsets then
        SoundOffsets = decoded.Offsets.Sound
    end
end

local MaxDist = SoundOffsets.RollOffMaxDistance
local MinDist = SoundOffsets.RollOffMinDistance
local Volume = SoundOffsets.Volume
]]

BodyParts = {"head", "torso", "shoulder1", "arm1", "shoulder2", "arm2", "hip1", "hip2", "leg1", "leg2",}

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

local function GetColor(vol)
    clamp = math.clamp(vol, .1, .9)
    local alpha = (clamp - .1) / .8

    return c.MinVolume:Lerp(c.MaxVolume, alpha)
end

local function PlayerToModel(inst)
	for _, Char in workspace.Viewmodels:GetChildren() do
		if Char:FindFirstChildOfClass("Model") and Char:FindFirstChild("torso") then
			local ModelPos = Char.torso.Position
			local p = inst.collision.Position
			CharPos = Vector3.new(p.x + .02, p.y + .25, p.z + .1)
			local Desync = math.floor(vector.magnitude(ModelPos - CharPos) * 100) / 100

			if Desync < 1.3 then
				return Char
			end
		end
	end
	return nil
end

local function Highlight(inst, color)
    local s, p = pcall(function()
        return inst.Position
    end)
    if s then
        h.Highlight(inst, color, .23, .6, .7)
        return true
    else
        return false
    end
end

RunService.PreLocal:Connect(function()
    local LocalChar = LocalPlayer.Character
    local root
    if LocalChar then
        root = LocalChar:FindFirstChild("HumanoidRootPart")
    end

    if not LocalChar or not root then
        PlayerCache = {}
        RenderCache = {}
        return
    end

    if FocusTimer ~= 0 and FocusTimer + 1 < os.clock() then
        PlayerCache = {}
        RenderCache = {}
    end
    FocusTimer = os.clock()

    for _, inst in Players:GetChildren() do
        local Char = inst.Character
        local id = InstId(Char)
        if not id then continue end
        if PlayerCache[id] then continue end
        
        local legs = Char:FindFirstChild("legs")
        if not legs then continue end

        local model = PlayerToModel(Char)
        if model then
            if model.Name ~= "LocalViewmodel" and model:FindFirstChild("head") then
                if not model.head:FindFirstChild("Username") then
                    PlayerCache[id] = {Char, 0, c.MinVolume, model}
                end
            end
        end
    end

    for id, table in PlayerCache do
        local inst = table[1]
        local model = table[4]

        if not inst or not model then
            PlayerCache[id] = nil
            continue
        end

        if not inst:FindFirstChild("Humanoid") then
            PlayerCache[id] = nil
            continue
        else
            if inst.Humanoid.Health == 0 then
                PlayerCache[id] = nil
                continue
            end
        end

        local legs = inst:FindFirstChild("legs")
        local gun
        for _, part in model:GetChildren() do
            if part:GetAttribute("loadout_type") then
                gun = part
            end
        end

        local tempcolor
        if gun then
            for _, part in gun:GetDescendants() do
                if part:IsA("Sound") then
                    if part.Name == "Shoot" then
                        if root and part.Parent then
                            local class = part.Parent.ClassName
                            if class == "Part" or Class == "UnionOperation" or Class == "MeshPart" then
                                if vector.magnitude(root.Position - part.Parent.Position) > 105 then
                                    break
                                end
                                tempcolor = c.MaxVolume
                                break
                            end
                        end
                    else
                        if root and part.Parent then
                            local class = part.Parent.ClassName
                            if class == "Part" or Class == "UnionOperation" or Class == "MeshPart" then
                                if vector.magnitude(root.Position - part.Parent.Position) > 30 then
                                    break
                                end
                                tempcolor = GetColor(.6)
                            end
                        end
                    end
                end
            end
        end

        if tempcolor then
            table[2] = os.clock() + .5
            RenderCache[id] = {model, tempcolor}
            continue
        end

        if legs then
            local sound = legs:FindFirstChildOfClass("Sound")
            if sound then
                table[2] = os.clock() + .5
                local color = GetColor(.2)
                table[3] = color
            end

            if sound or os.clock() < table[2] then
                if root then
                    if vector.magnitude(root.Position - legs.Position) > 30 then
                        RenderCache[id] = nil
                        continue
                    end
                end
                for _, name in BodyParts do
                    if table[4]:FindFirstChild(name) then
                        RenderCache[id] = {model, table[3]}
                    end
                end
                continue
            end
        end

        if inst:FindFirstChild("collision") then
            for _, part in inst.collision:GetChildren() do
                if part.Name ~= "Rustle" and part.Name ~= "Rope" and part.Name ~= "RopeDescend" and part:IsA("Sound") then
                    if root then
                        if vector.magnitude(root.Position - inst.collision.Position) > 20 then
                            RenderCache[id] = nil
                            continue
                        end
                    end
                    table[2] = os.clock() + .5
                    RenderCache[id] = {model, GetColor(.2)}
                    continue
                end
            end
        end

        RenderCache[id] = nil
    end
end)

RunService.Render:Connect(function()
    for id, table in RenderCache do

    local model = table[1]
        for _, name in BodyParts do
            if model:FindFirstChild(name) then
                Highlight(model[name], table[2])
            end
        end
    end
end)

print("Loaded")
