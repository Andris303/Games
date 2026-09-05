--!optimize 2
--!strict

if game.GameId == 8307114974 then

local bESP = true
local GadgetESP = true
local SoundESP = false
local TeammateESP = false
local TeamGadgetESP = false
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local InputService = game:GetService("UserInputService")
local HighlightColor = Color3.fromRGB(70,130,180)
local TextColor = Color3.fromRGB(70,130,180)
local ColoredPrimary
local ColoredSecondary
local PlayerList
local PlayerCache = {}
local RenderCache = {}
local GadgetCache = {}
local FocusTimer = 0
local LastGadgetScan = 0
local ModList = {"_1"}
local BodyParts = {"head", "torso", "shoulder1", "arm1", "shoulder2", "arm2", "hip1", "hip2", "leg1", "leg2",}
local Mods = {"lustin2800", "mmmmmonster", "RazvanWar28", "Fastesfern", "poipser", "Slender", "PandoraSkywalk2r", "AimDynamics", "Bunlawgs", "turner22", "Blazzy_Blaz",}
local GadgetWhitelist = {"Defuser", "ImpactGrenade", "DeployableShield", "BreachCharge", "Drone", "FragGrenade", "SmokeGrenade", "StunGrenade", "ShockBattery", "EMPGrenade", "RemoteC4", "IncendiaryGrenade", "ToxicCharge", "StickyCamera", "ProximityAlarm", "HardBreachCharge", "Claymore", "BarbedWire", "BulletproofCamera", "ThermiteCharge", "SignalDisruptor", "NeedleMine"}
local volumec = {
    MaxVolume = Color3.fromRGB(220,0,0),
    MinVolume = Color3.fromRGB(255,255,190),
}
local c = {
	red = Color3.fromRGB(250,80,83),
	yellow = Color3.fromRGB(255,222,33),
	grey = Color3.fromRGB(109,129,150),
	blue = Color3.fromRGB(48,92,222),
	purple = Color3.fromRGB(127,0,255),
}
local GadgetColors = {
	Defuser = c.red,
	ImpactGrenade = c.yellow,
	DeployableShield = c.grey,
	BreachCharge = c.blue,
	Drone = c.yellow,
	FragGrenade = c.yellow,
	SmokeGrenade = c.grey,
	StunGrenade = c.yellow,
	ShockBattery = c.purple,
	EMPGrenade = c.grey,
	RemoteC4 = c.yellow,
	IncendiaryGrenade = c.red,
	ToxicCharge = c.yellow,
	StickyCamera = c.blue,
	ProximityAlarm = c.purple,
	HardBreachCharge = c.blue,
	Claymore = c.red,
	BarbedWire = c.grey,
	BulletproofCamera = c.blue,
	ThermiteCharge = c.blue,
	SignalDisruptor = c.purple,
	NeedleMine = c.red,
}

_G.PixelOffset = 5
_G.Outline = true

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local HLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()
local Text = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Text.lua"))()

local function GetColor(vol)
    local clamp = math.clamp(vol, .1, .9)
    local alpha = (clamp - .1) / .8

    return volumec.MinVolume:Lerp(volumec.MaxVolume, alpha)
end

local s, vis = pcall(function()
	return LocalPlayer.PlayerGui.LoadoutMenu.Center.Bottom.SpectateFrame --0x5ad, u8 == 1
end)

local function PlayerToModel(inst)
	for _, Char in workspace.Viewmodels:GetChildren() do
		local torso = inst:FindFirstChild("torso")
		if not torso then return nil end
		local class = torso.ClassName
		if class ~= "Part" and class ~= "MeshPart" and class ~= "UnionOperation" then
			return nil
		end

		if Char:FindFirstChildOfClass("Model") then
			local ModelPos = torso.Position
			local p = inst.collision.Position
			local CharPos = Vector3.new(p.x + .02, p.y + .25, p.z + .1)
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
        HLib.Highlight(inst, color, .23, .6, .7)
        return true
    else
        return false
    end
end

local function UpdateGadgetCache()
    if os.clock() - LastGadgetScan < .25 then return end
    LastGadgetScan = os.clock()

    for inst in GadgetCache do
        if not inst or not inst.Parent then
            GadgetCache[inst] = nil
        end
    end

    for _, inst in workspace:GetChildren() do
        if inst.ClassName == "Model" and table.find(GadgetWhitelist, inst.Name) then
            GadgetCache[inst] = true
        end
    end
end

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

local function ModelToPlayer(inst)
	if not inst or not inst.Parent then return nil end

    local torso = inst:FindFirstChild("torso")
    if not torso then return nil end
    local class = torso.ClassName
    if class ~= "Part" and class ~= "MeshPart" and class ~= "UnionOperation" then
        return nil
    end

	for _, Char in workspace:GetChildren() do
		if inst.Name ~= "WarehouseMenu" then
			if inst.ClassName == "Model" then
				if Char:FindFirstChild("collision") then
					if Char:FindFirstChild("Electronic") then
						if not Char:FindFirstChild("Humanoid") then continue end
						local p = Char.collision.Position
						local ModelPos = torso.Position
						CharPos = Vector3.new(p.x + .02, p.y + .25, p.z + .1)
						local Desync = math.floor(vector.magnitude(ModelPos - CharPos) * 100) / 100
						if Desync < 1.3 then
							return Players:FindFirstChild(Char.Name), Char
						end
					end
				end
			end
		end
	end

	return nil
end

local function PreLocal()
    if not SoundESP then return end

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
                    PlayerCache[id] = {Char, 0, volumec.MinVolume, model}
                end
            end
        end
    end

    for id, table in PlayerCache do
        local inst = table[1]
        local model = table[4]

        if not inst or not model then
            PlayerCache[id] = nil
            RenderCache[id] = nil
            continue
        end

        if not inst:FindFirstChild("Humanoid") then
            PlayerCache[id] = nil
            RenderCache[id] = nil
            continue
        else
            if inst.Humanoid.Health <= 0 then
                PlayerCache[id] = nil
                RenderCache[id] = nil
                continue
            end
        end

        local legs = inst:FindFirstChild("legs")
        local gun
        for _, part in model:GetChildren() do
            if part:FindFirstChild("StateObject") then
                gun = part
            end
        end

        local tempcolor
        if gun then
            for _, part in gun:GetDescendants() do
                if part.ClassName == "Sound" then
                    if part.Name == "Shoot" then
                        if root and part.Parent then
                            local class = part.Parent.ClassName
                            if class == "Part" or class == "UnionOperation" or class == "MeshPart" then
                                if vector.magnitude(root.Position - part.Parent.Position) > 105 then
                                    break
                                end
                                tempcolor = volumec.MaxVolume
                                break
                            end
                        end
                    else
                        if root and part.Parent then
                            local class = part.Parent.ClassName
                            if class == "Part" or class == "UnionOperation" or class == "MeshPart" then
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
                if part.Name ~= "Rustle" and part.Name ~= "Rope" and part.Name ~= "RopeDescend" and part.ClassName == "Sound" then
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
end

local function PostLocal()
	local ModelRetry = {}
    if not workspace:FindFirstChild("Viewmodels") then return end

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

	if not bESP then return end

    for _, inst in workspace.Viewmodels:GetChildren() do
		local instid = InstId(inst)
		if not instid then continue end
		ESP.IsTracked(inst)

		if not inst:FindFirstChildOfClass("Model") then continue end

		local retry = ModelRetry[inst]
		if retry and os.clock() < retry then
			continue
		end

		local Player, Char = ModelToPlayer(inst)

		if not Player then
			ModelRetry[inst] = os.clock() + .5
			continue
		end
		ModelRetry[inst] = nil

		if Player and Char then
			local Human = Char:FindFirstChild("Humanoid")
			if not Human then continue end
			ESP.AddPlayer(inst, {
				Player = Player,
				SourceCharacter = Char,
				HealthSource = Human,
				IsLocal = inst.Name == "LocalViewmodel",
				NoHuman = true,
				GetTeam = function(data)
					local head = data.Character:FindFirstChild("head")
					if head and head:FindFirstChild("Username") then
						return "Friendly"
					end
					return "Enemies"
				end,

				GetLocalTeam = function()
					return "Friendly"
				end,

				GetTool = function(data)
					for _, part in data.Character:GetChildren() do
						if part:GetAttribute("loadout_type") then
							return part.Name
						end
					end

					return "None"
				end,

				ShouldShow = function(data)
					if data.CurrentTeam == "Friendly" then
						return TeammateESP
					end

					return true
				end,
			})
		end
    end
end

local function Render()
	if SoundESP then
		for id, table in RenderCache do
			local model = table[1]
			for _, name in BodyParts do
				if model:FindFirstChild(name) then
					Highlight(model[name], table[2])
				end
			end
		end
    end

	if not GadgetESP then return end
    if type(workspace:GetChildren()) ~= "table" then return end

	UpdateGadgetCache()

    for inst in GadgetCache do
		local Map = inst:FindFirstChildOfClass("Folder")
		if Map and workspace:GetAttribute("Gamemode") then
			if Map:FindFirstChild("DefaultCameras") then
				if type(Map.DefaultCameras:GetChildren()) == "table" then
					for _, part in Map.DefaultCameras:GetChildren() do
						if part:GetAttribute("Disabled") == "false" and part:FindFirstChild("Cam") then
							if part:FindFirstChild("Owner") and not TeamGadgetESP then
								continue
							end
							HLib.Highlight(part.Cam, HighlightColor, .2, .8, .6)

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

		if not inst:FindFirstChild("StateObject") then continue end

		local PPart = inst.PrimaryPart
			if inst.Name ~= "Claymore" then
			if not PPart then continue end
			local PPartClass = PPart.ClassName
			if PPartClass ~= "Part" and PPartClass ~= "UnionOperation" then continue end
		elseif inst:FindFirstChild("Root") then
			PPart = inst.Root
		end

        if inst:FindFirstChild("Owner") and not TeamGadgetESP then
            if inst.Owner.ClassName == "BillboardGui" then continue end
        end

		if inst.Name == "Defuser" then
			if not inst.PrimaryPart then continue end
			if inst.PrimaryPart:FindFirstChild("DefuserFlag") then continue end
		end

        if not PPart then continue end
		HLib.Highlight(PPart, GadgetColors[inst.Name], 0.2, 0.8, 1)

        if not PPart then continue end
        local Position, Visible = Camera:WorldToScreenPoint(PPart.Position)
        if Visible then
            local NewPos = Vector2.new(Position.x, Position.y - 6.5)
            DrawingImmediate.OutlinedText(NewPos, 13, GadgetColors[inst.Name], 1, AddSpaces(inst.Name), true)
		end
    end
end

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/okdude42/ui-lib/refs/heads/main/SevereLib.lua"))()

local window = UI:createwindow({
    Title = "Operation One | Andris",
    Version = "VX",
    Keybind = "RightShift",
    ConfigFolder = "AndrisOP1",
    CustomResolution = Vector2.new(580, 360),
    DPIScale = _G.DPIScale or 1.0,
    CompactSettings = false,
    DefaultTab = "Main", 
    TabAlignment = "Center",
    DefaultColor = Color3.fromRGB(28, 27, 31),
    DefaultAccent = Color3.fromRGB(208, 188, 255),
    DefaultSnowfall = true,
    DefaultScale = 1.0,
    DefaultFont = 0,
})

local tabMain = window:createtab("Main")
local tabSettings = window:createtab("Settings")

window:createlabel(tabMain, "ESP support requires ESP to be enabled in severe", 1)

window:createtoggle(tabMain, {
    Name = "Enable ESP support",
    Col = 1,
    Default = true,
    Callback = function(val)
		bESP = val
		ESP.SetEnabled(val)
	end
})

window:createtoggle(tabMain, {
    Name = "Show teammates",
    Col = 1,
    Default = false,
    Callback = function(val)
		TeammateESP = val
		if not val then
			_G.ESPList = {}
			clear_model_data()
		end
	end
})

window:createseparator(tabMain, 1)

window:createtoggle(tabMain, {
    Name = "Enable Gadget ESP",
    Col = 1,
    Default = true,
    Callback = function(val)
		GadgetESP = val
	end
})

window:createtoggle(tabMain, {
    Name = "Show your team\'s gadgets",
    Col = 1,
    Default = false,
    Callback = function(val)
		TeamGadgetESP = val
	end
})

window:createlabel(tabMain, "ESP that only activates on sound", 2)
window:createlabel(tabMain, "This doesn\'t require severe\'s ESP", 2)

window:createtoggle(tabMain, {
    Name = "Enable Sound ESP",
    Col = 2,
    Default = false,
    Callback = function(val)
		SoundESP = val
		if not val then
			PlayerCache = {}
			RenderCache = {}
		end
	end
})

clear_model_data()

print("Loaded")

RunService.PreLocal:Connect(PreLocal)
RunService.PostLocal:Connect(PostLocal)
RunService.Render:Connect(Render)
loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/OP1SoundESP.lua"))()

else
	print("Wrong game")
end
