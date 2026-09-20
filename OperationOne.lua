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
local ModelRetry = {}
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

-- Instances can be destroyed (and their memory reused, e.g. by a Beam) between
-- any two reads, so the whole draw is protected instead of pre-checking.
local function Highlight(inst, color, opacityFill, opacityOutline, thickness)
    return (pcall(HLib.Highlight, inst, color, opacityFill or .23, opacityOutline or .6, thickness or .7))
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
        local prevPrev = string:sub(i - 2, i - 2)
        local nextChar = string:sub(i + 1, i + 1)

        local isUpper = char:match("%u")
        local prevIsUpper = prev:match("%u")
        local prevPrevIsUpper = prevPrev:match("%u")
        local prevIsLower = prev:match("%l")
        local nextIsLower = nextChar:match("%l")

        local shouldAddSpace = false

        if isUpper and i > 1 then
            if prevIsLower then
                shouldAddSpace = true
            elseif prevIsUpper and prevPrevIsUpper and nextIsLower then
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

local SOUND_INTERVAL = .05
local POST_INTERVAL = .1
local GADGET_INTERVAL = .25
local PLAYER_SCAN_INTERVAL = 1
local PAUSE_GAP = 1
local MATCH_DISTANCE = 1.3

local GadgetSet = {}
for _, name in GadgetWhitelist do
    GadgetSet[name] = true
end

local SolidClasses = {Part = true, MeshPart = true, UnionOperation = true}
local IgnoredSounds = {Rustle = true, Rope = true, RopeDescend = true}

local MTPDebug = {}
local SoundRetry = {}
local GadgetTargets = {}
local CameraTargets = {}
local LabelCache = {}
local NextSoundTick = 0
local NextPostTick = 0
local NextPlayerScan = 0
local LastBeat = 0
local DebugErrors = false

-- Instances can be destroyed between two reads, so per-instance work is
-- protected and failures are skipped. Set DebugErrors to true to print them.
local function LogError(label, err)
    if DebugErrors then
        print("[Skipped]", label, err)
    end
end

-- Severe stops running scripts while Roblox is unfocused, so every callback
-- goes through Heartbeat. A long gap since the last call means we were paused
-- and every cache may point at destroyed or replaced instances.
local function ResetCaches()
    PlayerCache = {}
    RenderCache = {}
    ModelRetry = {}
    SoundRetry = {}
    MTPDebug = {}
    GadgetCache = {}
    GadgetTargets = {}
    CameraTargets = {}
    LastGadgetScan = 0
    NextSoundTick = 0
    NextPostTick = 0
    NextPlayerScan = 0
end

local function Heartbeat()
    local now = os.clock()
    if LastBeat ~= 0 and now - LastBeat > PAUSE_GAP then
        ResetCaches()
    end
    LastBeat = now
    return now
end

local function PruneExpired(retryTable, now)
    for key, expires in retryTable do
        if now >= expires then
            retryTable[key] = nil
        end
    end
end

local function GetTorso(inst)
    for _, child in inst:GetChildren() do
        if child.Name == "torso" then
            if SolidClasses[child.ClassName] then
                return child
            end
        end
    end
end

local function DebugMTP(inst, ...)
    local id = InstId(inst)
    if not id then return end

    local now = os.clock()
    if MTPDebug[id] and now - MTPDebug[id] < 1 then return end
    MTPDebug[id] = now

    print("[MTP]", inst.Name, ...)
end

local function CollisionToPosition(collision)
    local p = collision.Position
    return Vector3.new(p.x + .02, p.y + .25, p.z + .1)
end

-- World character -> viewmodel. The viewmodel's torso is compared against the
-- character's collision part, and the closest viewmodel within range wins.
local function PlayerToModel(Char)
    local collision = Char:FindFirstChild("collision")
    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not collision or not viewmodels then return nil end

    local CharPos = CollisionToPosition(collision)
    local bestModel
    local bestDistance

    for _, viewmodel in viewmodels:GetChildren() do
        if not viewmodel:FindFirstChildOfClass("Model") then continue end

        local torso = GetTorso(viewmodel)
        if not torso then
            DebugMTP(viewmodel, "NO VALID TORSO")
            continue
        end

        local Desync = math.floor(vector.magnitude(torso.Position - CharPos) * 100) / 100
        if not bestDistance or Desync < bestDistance then
            bestDistance = Desync
            bestModel = viewmodel
        end
    end

    if bestDistance and bestDistance < MATCH_DISTANCE then
        return bestModel
    end
    return nil
end

-- Built once per scan and shared by every viewmodel that needs matching.
local function GetCharCandidates()
    local candidates = {}

    for _, Char in workspace:GetChildren() do
        if Char.Name == "WarehouseMenu" then continue end
        if Char.ClassName ~= "Model" then continue end

        local collision = Char:FindFirstChild("collision")
        if not collision then continue end
        if not Char:FindFirstChild("Electronic") then continue end
        if not Char:FindFirstChild("Humanoid") then continue end

        candidates[#candidates + 1] = {Char = Char, Collision = collision}
    end

    return candidates
end

local function ModelToPlayer(inst, candidates)
    if not inst or not inst.Parent then return nil end

    local torso = GetTorso(inst)
    if not torso then
        DebugMTP(inst, "NO VALID TORSO")
        return nil
    end

    local ModelPos = torso.Position
    local bestChar
    local bestDistance

    for _, candidate in candidates do
        local CharPos = CollisionToPosition(candidate.Collision)
        local Desync = math.floor(vector.magnitude(ModelPos - CharPos) * 100) / 100

        if not bestDistance or Desync < bestDistance then
            bestDistance = Desync
            bestChar = candidate.Char
        end
    end

    if not bestChar then
        DebugMTP(inst, "NO VALID CHARACTER CANDIDATES")
        return nil
    end

    if bestDistance >= MATCH_DISTANCE then
        DebugMTP(inst, "CLOSEST:", bestChar.Name, "DISTANCE:", bestDistance)
        return nil
    end

    local Player = Players:FindFirstChild(bestChar.Name)

    if not Player then
        DebugMTP(inst, "MATCHED CHAR:", bestChar.Name, "BUT PLAYER NOT FOUND")
        return nil
    end

    return Player, bestChar
end

local BodyPartSet = {}
for _, name in BodyParts do
    BodyPartSet[name] = true
end

-- Several children can share a name (a "torso" may be a Beam), so only real
-- parts are taken, one per name.
local function GetBodyParts(model)
    local parts = {}
    local found = {}

    for _, child in model:GetChildren() do
        local name = child.Name
        if BodyPartSet[name] and not found[name] and SolidClasses[child.ClassName] then
            found[name] = true
            parts[#parts + 1] = child
        end
    end

    return parts
end

local function FindGun(model)
    local gun

    for _, part in model:GetChildren() do
        if part:FindFirstChild("StateObject") then
            gun = part
        end
    end

    return gun
end

local function GunSoundColor(gun, rootPos)
    local color

    for _, sound in gun:GetDescendants() do
        if sound.ClassName ~= "Sound" then continue end

        local parent = sound.Parent
        if not parent or not SolidClasses[parent.ClassName] then continue end

        local distance = vector.magnitude(rootPos - parent.Position)
        if sound.Name == "Shoot" then
            if distance > 105 then break end
            return volumec.MaxVolume
        end

        if distance > 30 then break end
        color = GetColor(.6)
    end

    return color
end

-- Returns keep, isTeammate. A false keep means the entry should be dropped.
local function UpdateSoundEntry(id, entry, rootPos, now, viewmodelsId)
    local Char = entry.Char
    local model = entry.Model
    local player = entry.Player

    -- The character, viewmodel or player may have been destroyed or replaced
    -- since this entry was cached (respawn, leaving, address reuse).
    if not player.Parent then return false end
    if InstId(player.Character) ~= id then return false end
    if not InstId(model) or InstId(model.Parent) ~= viewmodelsId then return false end

    local head = model:FindFirstChild("head")
    if head and head:FindFirstChild("Username") then return false, true end

    local Humanoid = Char:FindFirstChild("Humanoid")
    if not Humanoid or Humanoid.Health <= 0 then return false end

    if now >= entry.NextScan then
        entry.NextScan = now + .25
        entry.Gun = FindGun(model)
        entry.Parts = GetBodyParts(model)
    end

    local gun = entry.Gun
    local gunColor
    if gun and gun.Parent then
        gunColor = GunSoundColor(gun, rootPos)
    end

    if gunColor then
        entry.Hold = now + .5
        RenderCache[id] = {Parts = entry.Parts, Color = gunColor}
        return true
    end

    local legs = Char:FindFirstChild("legs")
    if legs then
        if legs:FindFirstChildOfClass("Sound") then
            entry.Hold = now + .5
            entry.Color = GetColor(.2)
        end

        if now < entry.Hold then
            if vector.magnitude(rootPos - legs.Position) > 30 then
                RenderCache[id] = nil
            else
                RenderCache[id] = {Parts = entry.Parts, Color = entry.Color}
            end
            return true
        end
    end

    local collision = Char:FindFirstChild("collision")
    if collision then
        for _, part in collision:GetChildren() do
            if part.ClassName == "Sound" and not IgnoredSounds[part.Name] then
                if vector.magnitude(rootPos - collision.Position) > 20 then
                    RenderCache[id] = nil
                else
                    entry.Hold = now + .5
                    RenderCache[id] = {Parts = entry.Parts, Color = GetColor(.2)}
                end
                return true
            end
        end
    end

    RenderCache[id] = nil
    return true
end

local function PreLocal()
    local now = Heartbeat()

    if not SoundESP then return end
    if now < NextSoundTick then return end
    NextSoundTick = now + SOUND_INTERVAL

    local LocalChar = LocalPlayer.Character
    local root
    if LocalChar then
        root = LocalChar:FindFirstChild("HumanoidRootPart")
    end

    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not root or not viewmodels then
        PlayerCache = {}
        RenderCache = {}
        return
    end

    local okRoot, rootPos = pcall(function()
        return root.Position
    end)
    if not okRoot then return end

    local viewmodelsId = InstId(viewmodels)

    PruneExpired(SoundRetry, now)

    for _, player in Players:GetChildren() do
        if player.Name == LocalPlayer.Name then continue end

        local Char = player.Character
        local id = InstId(Char)
        if not id or PlayerCache[id] or SoundRetry[id] then continue end

        local model
        if Char:FindFirstChild("legs") then
            local ok, result = pcall(PlayerToModel, Char)
            if ok then
                model = result
            else
                LogError("PlayerToModel", result)
            end
        end

        local head = model and model:FindFirstChild("head")
        if head and model.Name ~= "LocalViewmodel" and not head:FindFirstChild("Username") then
            PlayerCache[id] = {
                Char = Char,
                Model = model,
                Player = player,
                Hold = 0,
                Color = volumec.MinVolume,
                NextScan = 0,
                Gun = nil,
                Parts = {},
            }
        else
            SoundRetry[id] = now + .5
        end
    end

    for id, entry in PlayerCache do
        local ok, keep, teammate = pcall(UpdateSoundEntry, id, entry, rootPos, now, viewmodelsId)
        if not ok then
            LogError("UpdateSoundEntry", keep)
            keep = false
        end

        if not keep then
            PlayerCache[id] = nil
            RenderCache[id] = nil
            SoundRetry[id] = now + (teammate and 1 or .5)
        end
    end
end

local function ScanModerators()
    local current = {}

    for _, player in Players:GetChildren() do
        local name = player.Name
        current[name] = true

        if PlayerList and not PlayerList[name] and table.find(Mods, name) then
            table.insert(ModList, name)
            Text.Add(name, "Moderator \"" .. name .. "\" ingame.", Color3.fromRGB(255, 255, 255))
            send_notification("Moderator \"" .. name .. "\" joined.", "warning")
        end
    end

    for i = #ModList, 1, -1 do
        local name = ModList[i]
        if not current[name] then
            if name ~= "_1" then
                Text.Remove(name)
                send_notification("Moderator \"" .. name .. "\" left.", "warning")
            end
            table.remove(ModList, i)
        end
    end

    PlayerList = current
end

local function PostLocal()
    local now = Heartbeat()

    if now < NextPostTick then return end
    NextPostTick = now + POST_INTERVAL

    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not viewmodels then return end

    local lchar = LocalPlayer.Character
    if not lchar or not lchar:FindFirstChild("collision") or not lchar:FindFirstChild("Electronic") then
        ModelRetry = {}
        return
    end

    if now >= NextPlayerScan then
        NextPlayerScan = now + PLAYER_SCAN_INTERVAL
        ScanModerators()
    end

    if not bESP then return end

    PruneExpired(ModelRetry, now)

    local candidates

    for _, inst in viewmodels:GetChildren() do
        local instid = InstId(inst)
        if not instid then continue end
        if ESP.IsTracked(inst) then continue end
        if ModelRetry[instid] then continue end
        if not inst:FindFirstChildOfClass("Model") then continue end

        candidates = candidates or GetCharCandidates()
        local ok, Player, Char = pcall(ModelToPlayer, inst, candidates)
        if not ok then LogError("ModelToPlayer", Player) end

        if not ok or not Player then
            ModelRetry[instid] = now + .5
            continue
        end

        local Human = Char:FindFirstChild("Humanoid")
        if not Human then continue end

        local teamCache = {Value = "Enemies", Next = 0}
        local toolCache = {Part = nil, Name = "None", Next = 0}

        ESP.AddPlayer(inst, {
            Player = Player,
            SourceCharacter = Char,
            HealthSource = Human,
            IsLocal = inst.Name == "LocalViewmodel",
            NoHuman = true,
            GetTeam = function(data)
                local t = os.clock()
                if t >= teamCache.Next then
                    teamCache.Next = t + .25

                    local head = data.Character:FindFirstChild("head")
                    if head and head:FindFirstChild("Username") then
                        teamCache.Value = "Friendly"
                    else
                        teamCache.Value = "Enemies"
                    end
                end

                return teamCache.Value
            end,

            GetLocalTeam = function()
                return "Friendly"
            end,

            -- Keeps the current weapon until it disappears so the name can't
            -- flip between weapons, and only rescans a few times per second.
            GetTool = function(data)
                local t = os.clock()
                if t < toolCache.Next then return toolCache.Name end
                toolCache.Next = t + .25

                local part = toolCache.Part
                if not (part and InstId(part.Parent) == InstId(data.Character) and part:GetAttribute("loadout_type")) then
                    part = nil
                    for _, child in data.Character:GetChildren() do
                        if child:GetAttribute("loadout_type") then
                            part = child
                            break
                        end
                    end
                    toolCache.Part = part
                end

                toolCache.Name = part and AddSpaces(part.Name) or "None"
                return toolCache.Name
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

-- Rebuilds the list of gadgets and cameras to draw a few times per second.
-- Render then only projects and draws what this found.
local function UpdateGadgets(now)
    if now - LastGadgetScan < GADGET_INTERVAL then return end
    LastGadgetScan = now

    local found = {}
    for _, inst in workspace:GetChildren() do
        if GadgetSet[inst.Name] and inst.ClassName == "Model" then
            local id = InstId(inst)
            if id then found[id] = inst end
        end
    end
    GadgetCache = found

    local targets = {}
    local cameras = {}
    local seenCameras = {}
    local gamemode

    for _, inst in found do
        local Map = inst:FindFirstChildOfClass("Folder")
        if Map then
            if gamemode == nil then
                gamemode = workspace:GetAttribute("Gamemode") or false
            end

            local defaults = gamemode and Map:FindFirstChild("DefaultCameras")
            local children = defaults and defaults:GetChildren()
            if type(children) == "table" then
                for _, part in children do
                    local cam = part:FindFirstChild("Cam")
                    if not cam or part:GetAttribute("Disabled") ~= "false" then continue end
                    if part:FindFirstChild("Owner") and not TeamGadgetESP then continue end

                    local camId = InstId(cam)
                    if camId and not seenCameras[camId] then
                        seenCameras[camId] = true
                        cameras[#cameras + 1] = cam
                    end
                end
            end
        end

        if not inst:FindFirstChild("StateObject") then continue end

        local iname = inst.Name
        local PPart = inst.PrimaryPart
        if iname == "Claymore" then
            PPart = inst:FindFirstChild("Root") or PPart
        end
        if not PPart or not SolidClasses[PPart.ClassName] then continue end

        local maybeowner = inst:FindFirstChild("Owner")
        if maybeowner and not TeamGadgetESP and maybeowner.ClassName == "BillboardGui" then continue end

        if iname == "Defuser" and PPart:FindFirstChild("DefuserFlag") then continue end

        local label = LabelCache[iname]
        if not label then
            label = AddSpaces(iname)
            LabelCache[iname] = label
        end

        targets[#targets + 1] = {Model = inst, Part = PPart, Color = GadgetColors[iname], Label = label}
    end

    GadgetTargets = targets
    CameraTargets = cameras
end

local function ScreenPoint(part)
    local ok, position, visible = pcall(function()
        return Camera:WorldToScreenPoint(part.Position)
    end)

    if ok then return position, visible end
    return nil, false
end

local function Render()
    local now = Heartbeat()

    if SoundESP then
        for _, render in RenderCache do
            for _, part in render.Parts do
                Highlight(part, render.Color)
            end
        end
    end

    if not GadgetESP then return end

    local okScan, scanError = pcall(UpdateGadgets, now)
    if not okScan then LogError("UpdateGadgets", scanError) end

    for _, cam in CameraTargets do
        if not cam.Parent then continue end

        if not Highlight(cam, HighlightColor, .2, .8, .6) then continue end

        local Position, Visible = ScreenPoint(cam)
        if Visible then
            local NewPos = Vector2.new(Position.x, Position.y - 6.5)
            DrawingImmediate.OutlinedText(NewPos, 13, TextColor, 1, "Hacked Camera", true)
        end
    end

    for _, target in GadgetTargets do
        if target.Model.Parent ~= workspace then continue end

        if not Highlight(target.Part, target.Color, .2, .8, 1) then continue end

        local Position, Visible = ScreenPoint(target.Part)
        if Visible then
            local NewPos = Vector2.new(Position.x, Position.y - 6.5)
            DrawingImmediate.OutlinedText(NewPos, 13, target.Color, 1, target.Label, true)
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
