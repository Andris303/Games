--!optimize 2
--!strict

local BaseColor = _G.BaseColor or "8479D9"
local AttachmentColor = _G.AttachmentColor or "B5A8EF"
local Color3Offset = _G.Color3Offset or 0 -- Offset is 0x148 as of version-5cf2272675e145f5
local HighlightColor = _G.HighlightColor or Color3.fromRGB(16, 167, 234)
local TextColor = _G.TextColor or Color3.fromRGB(16, 167, 234)
local TeammateESP = _G.TeammateESP or false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local Timer = 0
local ColoredPrimary
local ColoredSecondary
local PlayerList
local TempHealth = {}
local Humanoids = {}
local ModList = {"_1"}
local Mods = {"lustin2800", "mmmmmonster", "RazvanWar28", "Fastesfern", "poipser", "Slender", "PandoraSkywalk2r", "AimDynamics", "Bunlawgs", "turner22", "Blazzy_Blaz",}
local GadgetWhitelist = {"Defuser", "ImpactGrenade", "DeployableShield", "BreachCharge", "Drone", "FragGrenade", "SmokeGrenade", "StunGrenade", "ShockBattery", "EMPGrenade", "RemoteC4", "IncendiaryGrenade", "ToxicCharge", "StickyCamera", "ProximityAlarm", "HardBreachCharge", "DeployableShield", "Claymore", "BarbedWire", "BulletproofCamera", "ThermiteCharge", "SignalDisruptor"}

_G.PixelOffset = 5
_G.Outline = true
local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local HLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()
local Text = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Text.lua"))()

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

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

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
    task.wait(.7)
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

local function ModelToPlayer(inst)
	if not inst or not inst.Parent then return nil end
	if not inst:FindFirstChild("torso") then return nil end
	for _, Char in workspace:GetChildren() do
		local IsPlr = Char:GetAttribute("Team")
		if IsPlr then
			if Char:FindFirstChild("collision") then
				if not Char:FindFirstChild("Humanoid") then continue end
				local p = Char.collision.Position
				local ModelPos = inst.torso.Position
				CharPos = Vector3.new(p.x + .02, p.y + .25, p.z + .1)
				local Desync = math.floor(vector.magnitude(ModelPos - CharPos) * 100) / 100

				if Desync < 1.3 then
					return Players:FindFirstChild(Char.Name)
				end
			end
		end
	end
	return nil
end

local function PreLocal()
	local LocalModel = workspace.Viewmodels:FindFirstChild("LocalViewmodel")
	local Inventory = LocalPlayer:FindFirstChild("Items")
	local Primary
	local Secondary

	if workspace:GetAttribute("Gamemode") then
		if not PlayerList then
			PlayerList = {}
			for _, inst in Players:GetChildren() do
				table.insert(PlayerList, inst.Name)
			end
		else
			for _, inst in Players:GetChildren() do
				if not table.find(PlayerList, inst.Name) then
					table.insert(PlayerList, inst.Name)
					local BAdd = false
					for _, mod in Mods do
						if inst.Name == mod then BAdd = true end
					end
					if BAdd then
						table.insert(ModList, inst.Name)
						Text.Add(inst.Name, "Moderator \"" .. inst.Name .. "\" ingame.", Color3.fromRGB(255, 255, 255))
						send_notification("Moderator \"" .. inst.Name .. "\" joined." , "warning")
					end
				end
			end
			for i, inst in ModList do
				if not Players:FindFirstChild(inst) then
					table.remove(ModList, i)
					if inst ~= "_1" then
						Text.Remove(inst)
						send_notification("Moderator \"" .. inst .. "\" left." , "warning")
					end
				end
			end
		end
	end

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
		if inst.Name == "LocalViewmodel" then continue end
        if not inst or not inst.Parent then
			if TempHealth[InstId(inst)] then
				TempHealth[InstId(inst)] = nil
			end
			if Humanoids[InstId(inst)] then
				Humanoids[InstId(inst)] = nil
			end
            ESP.RemovePlayer(ID)
			continue
		end
		if type(inst:GetChildren()) == "table" then
			local Tool
			for _, part in inst:GetChildren() do
				if part:GetAttribute("loadout_type") then
					Tool = part
				end
			end
			if Tool then
				if _G.ESPData[ID]["Toolname"] ~= Tool.Name then
					_G.ESPData[ID]["Toolname"] = Tool.Name
					TempHealth[ID] = _G.ESPHealths[ID]
					ESP.RemovePlayer(ID)
					continue
				end
			end
		end
		if Humanoids[ID] and _G.ESPHealths[ID] ~= math.floor(Humanoids[ID].Health) then
			if Humanoids[ID].Health <= 0 then
				TempHealth[InstId(inst)] = nil
				Humanoids[InstId(inst)] = nil
				ESP.RemovePlayer(ID)
				continue
			else
				ESP.EditHealth(ID, math.floor(Humanoids[ID].Health))
			end
		end
    end

    for _, inst in workspace.Viewmodels:GetChildren() do
        if not inst or not inst.Parent then continue end
		if not inst:FindFirstChildOfClass("Model") then continue end

		local TeamName = "Enemies"
        if not inst:FindFirstChild("head") then continue end
        if inst.head:FindFirstChild("Username") then
			if not TeammateESP then continue end
			TeamName = "Friendly"
		end

		local ToolName = "None"
		for _, part in inst:GetChildren() do
			if part:GetAttribute("loadout_type") then
				ToolName = part.Name
			end
		end

		local IsLocal = false
        if inst.Name == "LocalViewmodel" then
			IsLocal = true
		end

		local Player = ModelToPlayer(inst)
		if Player and InstId(inst) then
			local Human = Player.Character:FindFirstChild("Humanoid")
			local Health = Human.Health
			if Health <= 0 then continue end
			local MaxHealth = Human.MaxHealth
			if TempHealth[InstId(inst)] then
				if TempHealth[InstId(inst)] > 0 then
					Health = TempHealth[InstId(inst)]
					TempHealth[InstId(inst)] = nil
				else
					TempHealth[InstId(inst)] = nil
					Humanoids[InstId(inst)] = nil
					ESP.RemovePlayer(ID)
					continue
				end
			end
			local Username = Player.Name
			local DisplayName = Player.DisplayName
			local UserId = Player.UserId
			Humanoids[InstId(inst)] = Human
			ESP.AddPlayer(inst, IsLocal, Health, MaxHealth, Username, DisplayName, UserId, TeamName, ToolName, true, Human)
			continue
		end
    end
end

local function Render()
    if type(workspace:GetChildren()) ~= "table" then return end

    for _, inst in workspace:GetChildren() do
		if inst:IsA("Model") then
			local Map = inst:FindFirstChildOfClass("Folder")
			if Map then
				if Map:FindFirstChild("DefaultCameras") then
					if type(Map.DefaultCameras:GetChildren()) == "table" then
						for _, part in Map.DefaultCameras:GetChildren() do
							if part:GetAttribute("Disabled") == "false" and part:FindFirstChild("Cam") and not part:FindFirstChild("Owner") then
								HLib.Highlight(part.Cam, HighlightColor, 0.2, 0.8, 1)
								local Position, Visible = Camera:WorldToScreenPoint(part.Cam.Position)
								if Visible then
									local NewPos = Vector2.new(Position.x, Position.y - 6.5)
									DrawingImmediate.OutlinedText(NewPos, 13, TextColor, 1, "Hacked Camera", true)
								end
							end
						end
					end
				end
			end
        end
        if inst:IsA("Model") and inst.PrimaryPart then
            if not inst.PrimaryPart then continue end
            if not inst.PrimaryPart:IsA("Part") and not inst.PrimaryPart:IsA("UnionOperation") then continue end
            if inst:FindFirstChild("Owner") then
                if inst.Owner:IsA("BillboardGui") then continue end
            end

			if inst.Name == "Defuser" then
				if not inst.PrimaryPart then continue end
				if inst.PrimaryPart:FindFirstChild("DefuserFlag") then continue end
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
