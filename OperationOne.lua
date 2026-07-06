local BaseColor = _G.BaseColor or "8479D9"
local AttachmentColor = _G.AttachmentColor or "B5A8EF"
local Color3Offset = _G.Color3Offset or 0 -- Offset is 0x148 as of version-5cf2272675e145f5
local HighlightColor = _G.HighlightColor or Color3.fromRGB(16, 167, 234)
local TextColor = _G.TextColor or Color3.fromRGB(16, 167, 234)

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Timer = 0
local ColoredPrimary
local ColoredSecondary

local GadgetWhitelist = {"Defuser", "ImpactGrenade", "DeployableShield", "BreachCharge", "Drone", "FragGrenade", "SmokeGrenade", "StunGrenade", "ShockBattery", "EMPGrenade", "RemoteC4", "IncendiaryGrenade", "ToxicCharge", "StickyCamera", "ProximityAlarm", "HardBreachCharge", "DeployableShield", "Claymore", "BarbedWire", "BulletproofCamera", "ThermiteCharge", "SignalDisruptor"}

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local HLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()

_G.CustomParts = {
    RigType = "R15",
    HumanoidRootPart = "torso",
    Head = "head",
    UpperTorso = "torso",
    LowerTorso = "torso",
    RightUpperArm = "shoulder1",
    RightLowerArm = "arm1",
    RightHand = "arm1",
    LeftUpperArm = "shoulder2",
    LeftLowerArm = "arm2",
    LeftHand = "arm2",
    RightUpperLeg = "hip1",
    LeftUpperLeg = "hip2",
    RightLowerLeg = "leg1",
    RightFoot = "leg1",
    LeftLowerLeg = "leg2",
    LeftFoot = "leg2",
}

local function AddSpaces(string)
	local result = ""

	for i = 1, #string do
		local char = string:sub(i, i)
		local prev = string:sub(i - 1, i - 1)
		local nextChar = string:sub(i + 1, i + 1)
		local isUpper = char:match("%u")
		local prevIsUpper = prev:match("%u")
		local prevIsLower = prev:match("%l")
		local nextIsLower = nextChar:match("%l")
		local shouldAddSpace = false

		if isUpper and i > 1 then
			if prevIsLower then
				shouldAddSpace = true
			elseif prevIsUpper and nextIsLower then
				shouldAddSpace = true
			end
		end

		if shouldAddSpace then
			result ..= " "
		end

		result ..= char
	end

	return result
end

local function Encoder(String)
	local r = String:sub(1,2)
	local g = String:sub(3,4)
	local b = String:sub(5,6)
	return tonumber("0x00" .. b .. g .. r, 16)
end

local function ColorGun(inst)
    task.wait(.3)
	if inst:IsA("UnionOperation") or inst:IsA("Part") then
		memory.writei32(inst, Color3Offset, Encoder(BaseColor))
	end
	if inst:IsA("Model") then
		for _, part in inst:GetChildren() do
			if part:IsA("UnionOperation") or part:IsA("Part") then
				if part.Name ~= "RedDot" and part.Name ~= "Dot" and part.Name ~= "TintGlass" then
					memory.writei32(part, Color3Offset, Encoder(AttachmentColor))
				end
			end
		end
	end
end

local function PreLocal()
	local LocalModel = workspace.Viewmodels:FindFirstChild("LocalViewmodel")
	local Inventory = LocalPlayer:FindFirstChild("Items")
	local Primary
	local Secondary

	if LocalModel and type(LocalModel:GetChildren()) == "table" then
		for _, inst in LocalModel:GetChildren() do
			if inst:GetAttribute("loadout_type") == "primary" then
				Primary = inst
			elseif inst:GetAttribute("loadout_type") == "secondary" then
				Secondary = inst
			end
		end
	end

	if Inventory and type(Inventory:GetChildren()) == "table" then
		for _, inst in Inventory:GetChildren() do
			if inst:GetAttribute("loadout_type") == "primary" then
				Primary = inst
			elseif inst:GetAttribute("loadout_type") == "secondary" then
				Secondary = inst
			end
		end
	end

	if Primary and ColoredPrimary ~= Primary then
		ColoredPrimary = Primary
		for _, inst in Primary:GetChildren() do
            task.spawn(ColorGun, inst)
        end
	end
	if Secondary and ColoredSecondary ~= Secondary then
		ColoredSecondary = Secondary
		for _, inst in Secondary:GetChildren() do
            task.spawn(ColorGun, inst)
        end
	end
end

local function PostLocal()
    if type(workspace:GetChildren()) ~= "table" then return end
    if type(Players:GetChildren()) ~= "table" then return end
    if not workspace:FindFirstChild("Viewmodels") then return end
    if type(workspace.Viewmodels:GetChildren()) ~= "table" then return end

    if Timer ~= 0 and Timer + .5 < os.clock() then
        _G.ESPList = {}
        clear_model_data()
    end
    Timer = os.clock()

    for ID, inst in _G.ESPList do
        if not inst or not inst.Parent then
            ESP.RemovePlayer(ID)
        end
    end

    for _, inst in workspace.Viewmodels:GetChildren() do
        if not inst or not inst.Parent then continue end

        if not inst:FindFirstChild("head") then continue end
        if inst.head:FindFirstChild("Username") then continue end
        if inst.Name == "LocalViewmodel" then continue end
        if not inst:FindFirstChildOfClass("Model") then continue end

        ESP.AddPlayer(inst, false, nil, nil, nil, nil, nil, nil, nil, true)
    end
end

local function Render()
    if type(workspace:GetChildren()) ~= "table" then return end

    for _, inst in workspace:GetChildren() do
        if inst:IsA("Model") and inst.PrimaryPart then
            if not inst.PrimaryPart then continue end
            if not inst.PrimaryPart:IsA("Part") and not inst.PrimaryPart:IsA("UnionOperation") then continue end
            if inst:FindFirstChild("Owner") then
                if inst.Owner:IsA("BillboardGui") then continue end
            end

            local Continue = false
            for _, v in GadgetWhitelist do
                if inst.Name == v then Continue = true end
            end
            if not Continue then continue end

            if not inst.PrimaryPart then continue end
            HLib.Highlight(inst.PrimaryPart, HighlightColor, 0.2, 0.8, 1)

            if not inst.PrimaryPart then continue end
            local Position, Visible = Camera:WorldToScreenPoint(inst.PrimaryPart.Position)
            if Visible then
                local NewPos = Vector2.new(Position.x, Position.y - 6.5)
                DrawingImmediate.OutlinedText(NewPos, 13, TextColor, 1, AddSpaces(inst.Name), true)
            end
        end
    end
end

clear_model_data()

print("Loaded")

if Color3Offset ~= 0 then
    RunService.PreLocal:Connect(PreLocal)
end

RunService.PostLocal:Connect(PostLocal)
RunService.Render:Connect(Render)
