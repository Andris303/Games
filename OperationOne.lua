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
local AccentColor = Color3.fromRGB(70,130,180)
local LocalName = LocalPlayer.Name
local PlayerCache = {}
local RenderCache = {}
local ModelRetry = {}
local LastGadgetScan = 0
local ModsShown = {}
local BodyPartNames = {head = true, torso = true, shoulder1 = true, arm1 = true, shoulder2 = true, arm2 = true, hip1 = true, hip2 = true, leg1 = true, leg2 = true}
local Mods = {"lustin2800", "mmmmmonster", "RazvanWar28", "Fastesfern", "poipser", "Slender", "PandoraSkywalk2r", "AimDynamics", "Bunlawgs", "turner22", "Blazzy_Blaz",}
local ShotColor = Color3.fromRGB(220,0,0)
local QuietColor = Color3.fromRGB(255,255,190)
local NearGunColor = QuietColor:Lerp(ShotColor, .625)
local StepColor = QuietColor:Lerp(ShotColor, .125)
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
local preLocalConnect
local postLocalConnect
local renderConnect

_G.PixelOffset = 5
_G.Outline = true

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local HLib = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()
local Highlight = HLib.Highlight

local Text = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Text.lua"))()

local GadgetRenderCache = {}
local CameraRenderCache = {}
local NextCameraSync = 0

local function ReadPosition(part)
    return part.Position
end

local function ReadPose(part)
    return part.Position, part.RightVector, part.UpVector, part.LookVector
end

local function ReadSize(part)
    return part.Size
end

_G.CustomParts = nil

local ViewmodelRig = {
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

local MemoryChildren

do
    local robloxVersion = _G.RobloxVersion or game:GetClientVersion()
    local okOffsets, offsets = pcall(function()
        return crypt.json.decode(game:HttpGet("https://offsets.imtheo.lol/" .. robloxVersion .. "/offsets.json")).Offsets.Instance
    end)
    local childrenOffset = okOffsets and offsets and offsets.ChildrenStart
    local childrenEndOffset = okOffsets and offsets and offsets.ChildrenEnd

    local function ReadU64(address, offset)
        local ok, value = pcall(memory.readu64, address, offset)
        return ok and value or nil
    end

    function MemoryChildren(folder)
        local address = childrenOffset and tonumber(folder.Data)
        local list = address and ReadU64(address, childrenOffset)
        local first = list and ReadU64(list, 0)
        local last = list and ReadU64(list, childrenEndOffset)
        if not first or not last or last < first or last - first > 0x10 * 5000 then
            return folder:GetChildren()
        end

        local children = {}
        for pointer = first, last - 0x10, 0x10 do
            local child = ReadU64(pointer, 0)
            if child and child ~= 0 then
                local ok, inst = pcall(pointer_to_userdata, child)
                if ok and inst then children[#children + 1] = inst end
            end
        end
        return children
    end
end

local function AddSpaces(text)
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("(%u%u)(%u%l)", "%1 %2")
    return text
end

local soundInterval = .05
local postInterval = .1
local gadgetInterval = .1
local playerScanInterval = 1
local pauseGap = 1
local matchDistance = 1.3
local maxMatchesPerTick = 3
local maxModelLookupsPerTick = 2

local function RetryDelay(base)
    return base + math.random() * base * .5
end

local SolidClasses = {Part = true, MeshPart = true, UnionOperation = true}
local ZombieNames = {Walker = true, Runner = true, ["Special Op"] = true, Smoker = true, Tank = true, Bomber = true, Slasher = true, Firefighter = true}
local IgnoredSounds = {Rustle = true, Rope = true, RopeDescend = true}

local SoundRetry = {}
local GadgetTargets = {}
local CameraTargets = {}
local LabelCache = {}
local NextSoundTick = 0
local NextPostTick = 0
local NextPlayerScan = 0
local NextTrackedCheck = 0
local trackedCheckInterval = .25
local ScanCursor = 0
local LastBeat = 0
local heavySpacing = .006
local LastHeavy = 0

local function HeavyReady()
    return os.clock() - LastHeavy >= heavySpacing
end

local function MarkHeavy()
    LastHeavy = os.clock()
end

local function ResetCaches()
    PlayerCache = {}
    RenderCache = {}
    GadgetRenderCache = {}
    CameraRenderCache = {}
    NextCameraSync = 0
    ModelRetry = {}
    SoundRetry = {}
    GadgetTargets = {}
    CameraTargets = {}
    LastGadgetScan = 0
    NextSoundTick = 0
    NextPostTick = 0
    NextPlayerScan = 0
    NextTrackedCheck = 0
    ScanCursor = 0
end

local function Heartbeat()
    local now = os.clock()
    if LastBeat ~= 0 and now - LastBeat > pauseGap then
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

local function CollisionToPosition(collision)
    local p = collision.Position
    return Vector3.new(p.x + .02, p.y + .25, p.z + .1)
end

local function PlayerToModel(Char)
    local collision = Char:FindFirstChild("collision")
    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not collision or not viewmodels then return nil end

    local CharPos = CollisionToPosition(collision)
    local bestModel
    local bestDistance

    for _, viewmodel in MemoryChildren(viewmodels) do
        if not viewmodel:FindFirstChildOfClass("Model") and not GetTorso(viewmodel) then continue end

        local torso = GetTorso(viewmodel)
        if not torso then continue end

        local Desync = math.floor(vector.magnitude(torso.Position - CharPos) * 100) / 100
        if not bestDistance or Desync < bestDistance then
            bestDistance = Desync
            bestModel = viewmodel
        end
    end

    if bestDistance and bestDistance < matchDistance then
        return bestModel
    end
    return nil
end

local function GetCharCandidates()
    local candidates = {}

    for _, Char in MemoryChildren(workspace) do
        if Char.Name == "WarehouseMenu" then continue end
        if Char.ClassName ~= "Model" then continue end

        local collision = Char:FindFirstChild("collision")
        if not collision then continue end
        if not Char:FindFirstChild("Electronic") then continue end
        if not Char:FindFirstChild("Humanoid") then continue end

        local ok, position = pcall(CollisionToPosition, collision)
        if not ok then continue end

        candidates[#candidates + 1] = {Char = Char, Collision = collision, Position = position}
    end

    return candidates
end

-- scan.Candidates is built lazily, only once a viewmodel with a torso needs it.
local function ModelToPlayer(inst, scan)
    if not inst or not inst.Parent then return nil end

    local torso = GetTorso(inst)
    if not torso then
        return nil, "NoTorso"
    end

    local candidates = scan.Candidates
    if not candidates then
        candidates = GetCharCandidates()
        scan.Candidates = candidates
    end

    local okPos, ModelPos = pcall(function()
        return torso.Position
    end)
    if not okPos then
        return nil, "Unreadable"
    end

    local bestChar
    local bestDistance

    local isLocalModel = inst.Name == "LocalViewmodel"

    for _, candidate in candidates do
        if (candidate.Char.Name == LocalName) ~= isLocalModel then continue end

        local Desync = math.floor(vector.magnitude(ModelPos - candidate.Position) * 100) / 100

        if not bestDistance or Desync < bestDistance then
            bestDistance = Desync
            bestChar = candidate.Char
        end
    end

    if not bestChar then return nil end
    if bestDistance >= matchDistance then return nil end

    if ZombieNames[bestChar.Name] then
        return "Zombie", bestChar
    end

    local Player = Players:FindFirstChild(bestChar.Name)
    if not Player then return nil end

    return Player, bestChar
end

local function GetBodyParts(model)
    local parts = {}
    local found = {}

    for _, child in model:GetChildren() do
        local name = child.Name
        if BodyPartNames[name] and not found[name] and SolidClasses[child.ClassName] then
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
            if distance > 105 then continue end
            return ShotColor
        end

        if distance > 30 then continue end
        color = NearGunColor
    end

    return color
end

local function UpdateSoundEntry(id, entry, rootPos, now, viewmodelsId)
    local Char = entry.Char
    local model = entry.Model

    if now >= entry.NextScan then
        entry.NextScan = now + .25

        if not entry.Player.Parent then return false end
        if InstId(entry.Player.Character) ~= id then return false end
        if not InstId(model) or InstId(model.Parent) ~= viewmodelsId then return false end

        local head = model:FindFirstChild("head")
        if head and head:FindFirstChild("Username") then return false, true end

        local Humanoid = Char:FindFirstChild("Humanoid")
        if not Humanoid or Humanoid.Health <= 0 then return false end

        entry.Gun = FindGun(model)
        entry.Parts = GetBodyParts(model)
        entry.Legs = Char:FindFirstChild("legs")
        entry.Collision = Char:FindFirstChild("collision")
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

    local legs = entry.Legs
    if legs then
        if legs:FindFirstChildOfClass("Sound") then
            entry.Hold = now + .5
            entry.Color = StepColor
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

    local collision = entry.Collision
    if collision then
        for _, part in collision:GetChildren() do
            if part.ClassName == "Sound" and not IgnoredSounds[part.Name] then
                if vector.magnitude(rootPos - collision.Position) > 20 then
                    RenderCache[id] = nil
                else
                    entry.Hold = now + .5
                    RenderCache[id] = {Parts = entry.Parts, Color = StepColor}
                end
                return true
            end
        end
    end

    RenderCache[id] = nil
    return true
end

local function ScanGadget(inst, state)
    local Map = inst:FindFirstChildOfClass("Folder")
    if Map then
        if state.Gamemode == nil then
            state.Gamemode = workspace:GetAttribute("Gamemode") or false
        end

        local defaults = state.Gamemode and Map:FindFirstChild("DefaultCameras")
        local children = defaults and defaults:GetChildren()
        if type(children) == "table" then
            for _, part in children do
                local cam = part:FindFirstChild("Cam")
                if not cam or part:GetAttribute("Disabled") ~= "false" then continue end
                if part:FindFirstChild("Owner") and not TeamGadgetESP then continue end

                local camId = InstId(cam)
                if camId and not state.SeenCameras[camId] then
                    state.SeenCameras[camId] = true
                    state.Cameras[#state.Cameras + 1] = cam
                end
            end
        end
    end

    if not inst:FindFirstChild("StateObject") then return end

    local iname = inst.Name
    local PPart = inst.PrimaryPart
    if iname == "Claymore" then
        PPart = inst:FindFirstChild("Root") or PPart
    end
    if not PPart or not SolidClasses[PPart.ClassName] then return end

    local maybeowner = inst:FindFirstChild("Owner")
    if maybeowner and not TeamGadgetESP and maybeowner.ClassName == "BillboardGui" then return end

    if iname == "Defuser" and PPart:FindFirstChild("DefuserFlag") then return end

    local label = LabelCache[iname]
    if not label then
        label = AddSpaces(iname)
        LabelCache[iname] = label
    end

    state.Targets[#state.Targets + 1] = {Model = inst, Id = InstId(inst), Part = PPart, Color = GadgetColors[iname], Label = label}
end

local PlayerLikeGadgets = {Drone = "Drone"}

local function TrackGadgetModel(target, label)
    local model = target.Model
    if ESP.IsTracked(model) then return end

    local partName = target.Part.Name
    local rootName = model:FindFirstChild("Root") and "Root" or partName
    local owner = model:FindFirstChild("Owner")
    local friendly = owner ~= nil and owner.ClassName == "BillboardGui"

    ESP.AddPlayer(model, {
        Username = label,
        DisplayName = label,
        UserId = 0,
        NoHuman = true,
        TeamType = "Manual",
        TeamName = friendly and "Friendly" or "Enemies",
        LocalTeamName = "Friendly",
        CustomParts = {
            RigType = "R6",
            HumanoidRootPart = rootName,
            Head = rootName,
            Torso = rootName,
            ["Left Arm"] = rootName,
            ["Right Arm"] = rootName,
            ["Left Leg"] = rootName,
            ["Right Leg"] = rootName,
        },
        ShouldShow = function()
            return GadgetESP and (not friendly or TeamGadgetESP)
        end,
    })
end

local maxTwinDistance = 40

local function TwinPart(model)
    local client = model:FindFirstChild("ClientModel")
    if client and SolidClasses[client.ClassName] then return client end
    local part = model:FindFirstChild("Root") or model.PrimaryPart
    if not part and client and client.ClassName == "Model" then
        part = client:FindFirstChild("Root") or client.PrimaryPart
    end
    if part and SolidClasses[part.ClassName] then return part end
    return nil
end

local function UseVisibleTwins(targets, twins)
    local used = {}
    for _, target in targets do
        local okServer, serverPosition = pcall(ReadPosition, target.Part)
        if not okServer or not serverPosition then continue end

        local bestIndex, bestPart, bestDistance = nil, nil, maxTwinDistance
        for index, twin in twins do
            if used[index] or twin.Name ~= target.Model.Name then continue end
            local part = TwinPart(twin)
            if not part then continue end
            local okTwin, twinPosition = pcall(ReadPosition, part)
            if not okTwin or not twinPosition then continue end
            local distance = vector.magnitude(twinPosition - serverPosition)
            if distance < bestDistance then
                bestIndex, bestPart, bestDistance = index, part, distance
            end
        end

        if bestIndex then
            used[bestIndex] = true
            target.ServerPart = target.Part
            target.Part = bestPart
        end
    end

    for index, twin in twins do
        if used[index] or PlayerLikeGadgets[twin.Name] then continue end
        local part = TwinPart(twin)
        local id = InstId(twin)
        if not part or not id then continue end

        local owner = twin:FindFirstChild("Owner")
        if owner and not TeamGadgetESP and owner.ClassName == "BillboardGui" then continue end
        if twin.Name == "Defuser" and part:FindFirstChild("DefuserFlag") then continue end

        local label = LabelCache[twin.Name]
        if not label then
            label = AddSpaces(twin.Name)
            LabelCache[twin.Name] = label
        end
        targets[#targets + 1] = {Model = twin, Id = id, Part = part, Color = GadgetColors[twin.Name], Label = label}
    end
end

local HighlightModels = {MilitaryPouch = {Color = Color3.fromRGB(120, 200, 90), Label = "Military Pouch"}}

local function ModelPart(model)
    local part = model.PrimaryPart or model:FindFirstChildOfClass("MeshPart") or model:FindFirstChildOfClass("Part") or model:FindFirstChildOfClass("UnionOperation")
    if part and SolidClasses[part.ClassName] then return part end
    return nil
end

local function UpdateGadgets(now)
    if now - LastGadgetScan < gadgetInterval then return end
    if not HeavyReady() and now - LastGadgetScan < gadgetInterval * 3 then return end
    LastGadgetScan = now

    local state = {Targets = {}, Cameras = {}, SeenCameras = {}}
    local twins = {}
    local extras = {}

    pcall(function()
        for _, inst in MemoryChildren(workspace) do
            local extra = HighlightModels[inst.Name]
            if extra and inst.ClassName == "Model" then
                local part = ModelPart(inst)
                local id = InstId(inst)
                if part and id then
                    extras[#extras + 1] = {Model = inst, Id = id, Part = part, Color = extra.Color, Label = extra.Label}
                end
            end
            if GadgetColors[inst.Name] and inst.ClassName == "Model" and InstId(inst) then
                pcall(ScanGadget, inst, state)
                if not inst:FindFirstChild("StateObject") then
                    twins[#twins + 1] = inst
                end
            end
        end
    end)

    pcall(UseVisibleTwins, state.Targets, twins)
    for _, extra in extras do
        state.Targets[#state.Targets + 1] = extra
    end

    GadgetTargets = state.Targets

    for _, target in state.Targets do
        local label = PlayerLikeGadgets[target.Model.Name]
        if label then
            target.EspOnly = true
            pcall(TrackGadgetModel, target, label)
        end
    end
    CameraTargets = state.Cameras

    MarkHeavy()
end

local window
local FlagSetters = {}
local AppliedFlags = {}

local function SyncFlags()
    for flag, apply in FlagSetters do
        local value = window:get(flag)
        if value ~= AppliedFlags[flag] then
            AppliedFlags[flag] = value
            apply(value)
        end
    end
end

local function PreLocal()
    SyncFlags()
    local now = Heartbeat()

    if not SoundESP then return end
    if now < NextSoundTick then return end
    NextSoundTick = now + soundInterval

    local viewmodels = workspace:FindFirstChild("Viewmodels")

    local LocalChar = LocalPlayer.Character
    local root
    if LocalChar then
        root = LocalChar:FindFirstChild("HumanoidRootPart")
    end

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

    local lookups = 0

    for _, player in Players:GetChildren() do
        if player.Name == LocalName then continue end

        local Char = player.Character
        local id = InstId(Char)
        if not id or PlayerCache[id] or SoundRetry[id] then continue end

        if lookups >= maxModelLookupsPerTick then break end
        lookups += 1

        local model
        if Char:FindFirstChild("legs") then
            local ok, result = pcall(PlayerToModel, Char)
            if ok then
                model = result
            end
        end

        local head = model and model:FindFirstChild("head")
        if head and model.Name ~= "LocalViewmodel" and not head:FindFirstChild("Username") then
            PlayerCache[id] = {
                Char = Char,
                Model = model,
                Player = player,
                Hold = 0,
                Color = QuietColor,
                NextScan = 0,
                Gun = nil,
                Parts = {},
            }
        else
            SoundRetry[id] = now + RetryDelay(.5)
        end
    end

    for id, entry in PlayerCache do
        local ok, keep, teammate = pcall(UpdateSoundEntry, id, entry, rootPos, now, viewmodelsId)
        if not ok then
            keep = false
        end

        if not keep then
            PlayerCache[id] = nil
            RenderCache[id] = nil
            SoundRetry[id] = now + RetryDelay(teammate and 1 or .5)
        end
    end
end

local function ScanModerators()
    local current = {}

    for _, player in Players:GetChildren() do
        local name = player.Name
        if table.find(Mods, name) then
            current[name] = true

            if not ModsShown[name] then
                ModsShown[name] = true
                Text.Add(name, "Moderator \"" .. name .. "\" ingame.", Color3.fromRGB(255, 255, 255))
                send_notification("Moderator \"" .. name .. "\" joined.", "warning")
            end
        end
    end

    for name in ModsShown do
        if not current[name] then
            ModsShown[name] = nil
            Text.Remove(name)
            send_notification("Moderator \"" .. name .. "\" left.", "warning")
        end
    end
end

local function TrackViewmodel(inst, scan, now)
    local instid = InstId(inst)
    if not instid then return end

    local Player, Char = ModelToPlayer(inst, scan)
    if not Player then
        -- A viewmodel with no torso is unlikely to gain one within a
        -- fraction of a second, so it is retried less often.
        local retry = .5
        if Char == "NoTorso" then
            retry = 2
        elseif Char == "Unreadable" then
            retry = .15
        end
        ModelRetry[instid] = now + RetryDelay(retry)
        return
    end

    local Human = Char:FindFirstChild("Humanoid")
    if not Human then
        ModelRetry[instid] = now + RetryDelay(.5)
        return
    end

    local bZombie = Player == "Zombie"
    local teamCache = {Value = "Enemies", Next = 0}
    local toolCache = {Part = nil, Name = "None", Next = 0}

    ESP.AddPlayer(inst, {
        Player = if bZombie then nil else Player,
        Username = if bZombie then Char.Name else nil,
        DisplayName = if bZombie then Char.Name else nil,
        UserId = if bZombie then 0 else nil,
        SourceCharacter = Char,
        HealthSource = Human,
        IsLocal = inst.Name == "LocalViewmodel",
        NoHuman = true,
        CustomParts = ViewmodelRig,
        GetTeam = function(data)
            local t = os.clock()
            if t >= teamCache.Next then
                teamCache.Next = t + RetryDelay(.2)

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

        GetTool = function(data)
            if bZombie then return Char.Name end
            local t = os.clock()
            if t < toolCache.Next then return toolCache.Name end
            toolCache.Next = t + RetryDelay(.2)

            local part = toolCache.Part
            if not (part and InstId(part.Parent) == InstId(data.Character)) then
                part = nil
                for _, child in data.Character:GetChildren() do
                    if child.ClassName == "Model" and string.lower(child.Name) ~= "model" then
                        part = child
                        break
                    end
                end
                toolCache.Part = part
            end

            if part then
                local name = part.Name
                local label = LabelCache[name]
                if not label then
                    label = AddSpaces(name)
                    LabelCache[name] = label
                end
                toolCache.Name = label
            else
                toolCache.Name = "None"
            end
            return toolCache.Name
        end,

        ShouldShow = function(data)
            if data.CurrentTeam == "Friendly" then
                return TeammateESP
            end

            return true
        end,
    })

    if not ESP.IsTracked(inst) then
        ModelRetry[instid] = now + RetryDelay(1)
    end
end

local function RefreshTracked(children)
    for _, inst in children do
        if not ESP.IsTracked(inst) then continue end

        local data = ESP.GetTracked(inst)
        if data and data.SourceCharacter and not InstId(data.SourceCharacter) then
            ESP.RemovePlayer(inst)
        end
    end
end

local function RunPost()
    local now = Heartbeat()

    if now < NextPostTick then return end
    if not HeavyReady() then return end
    NextPostTick = now + postInterval

    local viewmodels = workspace:FindFirstChild("Viewmodels")
    if not viewmodels then return end

    local lchar = LocalPlayer.Character
    if not lchar or not lchar:FindFirstChild("collision") or not lchar:FindFirstChild("Electronic") then
        ModelRetry = {}
        return
    end

    if now >= NextPlayerScan then
        NextPlayerScan = now + playerScanInterval
        ScanModerators()
    end

    if not bESP then return end

    PruneExpired(ModelRetry, now)

    local scan = {}
    local matches = 0
    local children = MemoryChildren(viewmodels)
    local total = #children

    if now >= NextTrackedCheck then
        NextTrackedCheck = now + trackedCheckInterval
        pcall(RefreshTracked, children)
    end

    for step = 0, total - 1 do
        local inst = children[(ScanCursor + step) % total + 1]
        local instid = InstId(inst)
        if not instid then continue end
        if ESP.IsTracked(inst) then continue end
        if ModelRetry[instid] then continue end
        if not inst:FindFirstChildOfClass("Model") and not GetTorso(inst) then continue end

        if matches >= maxMatchesPerTick then
            ScanCursor = (ScanCursor + step) % total
            return
        end
        matches += 1

        local ok = pcall(TrackViewmodel, inst, scan, now)
        if not ok then
            ModelRetry[instid] = now + RetryDelay(1)
        end
    end

    ScanCursor = 0
end

local function UpdateRenderCaches(now)
    if not GadgetESP then
        GadgetRenderCache = {}
        CameraRenderCache = {}
        return
    end

    local newCameras = {}
    local newGadgets = {}

    for index = #CameraTargets, 1, -1 do
        local cam = CameraTargets[index]
        if not InstId(cam) then
            table.remove(CameraTargets, index)
            continue
        end

        local okSize, size = pcall(ReadSize, cam)
        newCameras[#newCameras + 1] = {Part = cam, Size = okSize and size or nil, Color = AccentColor, Label = "Hacked Camera"}
    end

    for index = #GadgetTargets, 1, -1 do
        local target = GadgetTargets[index]
        if target.ServerPart and not InstId(target.Part) then
            target.Part = target.ServerPart
            target.ServerPart = nil
        end
        if target.Model.Parent ~= workspace or InstId(target.Model) ~= target.Id or not InstId(target.Part) then
            table.remove(GadgetTargets, index)
            continue
        end

        if not target.EspOnly then
            local okSize, size = pcall(ReadSize, target.Part)
            newGadgets[#newGadgets + 1] = {Part = target.Part, Size = okSize and size or nil, Color = target.Color, Label = target.Label}
        end
    end

    CameraRenderCache = newCameras
    GadgetRenderCache = newGadgets
end

local function PostLocal()
    local before = NextPostTick
    RunPost()
    if NextPostTick ~= before then
        MarkHeavy()
    end

    local now = Heartbeat()

    if now >= NextCameraSync then
        NextCameraSync = now + .5
        local cam = workspace.CurrentCamera
        if cam then
            Camera = cam
            if HLib.SetCamera then HLib.SetCamera(cam) end
        end
    end

    if GadgetESP then
        pcall(UpdateGadgets, now)
    end

    UpdateRenderCaches(now)
end

local function DrawLabel(entry)
    local ok, position = pcall(ReadPosition, entry.Part)
    if not ok then return end

    local Position, Visible = Camera:WorldToScreenPoint(position)
    if Visible then
        local NewPos = Vector2.new(Position.x, Position.y - 6.5)
        DrawingImmediate.OutlinedText(NewPos, 13, entry.Color, 1, entry.Label, true)
    end
end

local livePose = {Parent = true}

local function HighlightLive(entry, color, opacityFill, opacityOutline, thickness)
    if not entry.Size then return end
    local ok, position, right, up, look = pcall(ReadPose, entry.Part)
    if not ok or not position then return end
    livePose.Position, livePose.RightVector, livePose.UpVector, livePose.LookVector, livePose.PartSize = position, right, up, look, entry.Size
    pcall(Highlight, livePose, color, opacityFill, opacityOutline, thickness)
end

local function Render()
    if SoundESP then
        for _, render in RenderCache do
            for _, part in render.Parts do
                pcall(Highlight, part, render.Color, .23, .6, .7)
            end
        end
    end

    if not GadgetESP then return end

    for _, entry in CameraRenderCache do
        HighlightLive(entry, AccentColor, .2, .8, .6)
        DrawLabel(entry)
    end

    for _, entry in GadgetRenderCache do
        HighlightLive(entry, entry.Color, .2, .8, 1)
        DrawLabel(entry)
    end
end

local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()

window = UI.new({
    Title = "OP1 | Andris",
    Subtitle = "Support",
    Version = "2.0.1",
    Folder = "AndrisOP1",
    Footer = "This script is in active development! New features releasing soon",
    UpdateNotice = {"V2.0.1", "This script now uses ok0f's V2 UI library."},
    OnUnload = function()
        preLocalConnect:Disconnect()
        preDataConnect:Disconnect()
        renderConnect:Disconnect()
        ESP.Clear()
        clear_model_data()
    end,
    OnReload = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/OperationOne.lua"))()
    end,
})

local tabMain = window:tab("Main")
local espSection = tabMain:section("ESP")

espSection:label("ESP support requires ESP to be enabled in severe")

espSection:toggle({Name = "Enable ESP support", Flag = "ESP", Default = true})
FlagSetters.ESP = function(val)
    bESP = val
    ESP.SetEnabled(val)
end

espSection:toggle({Name = "Show teammates", Flag = "TeammateESP", Default = false})
FlagSetters.TeammateESP = function(val)
    TeammateESP = val
    if not val then
        _G.ESPList = {}
        clear_model_data()
    end
end

espSection:toggle({Name = "Enable Gadget ESP", Flag = "GadgetESP", Default = true})
FlagSetters.GadgetESP = function(val)
    GadgetESP = val
end

espSection:toggle({Name = "Show your team's gadgets", Flag = "TeamGadgetESP", Default = false})
FlagSetters.TeamGadgetESP = function(val)
    TeamGadgetESP = val
end

local soundSection = tabMain:section("SOUND ESP")

soundSection:label("ESP that only activates on sound")
soundSection:label("This doesn't require severe's ESP")

soundSection:toggle({Name = "Enable Sound ESP", Flag = "SoundESP", Default = false})
FlagSetters.SoundESP = function(val)
    SoundESP = val
    if not val then
        PlayerCache = {}
        RenderCache = {}
    end
end

window:start()

clear_model_data()

print("Loaded")

preLocalConnect = RunService.PreLocal:Connect(PreLocal)
postLocalConnect = RunService.PostLocal:Connect(PostLocal)
renderConnect = RunService.Render:Connect(Render)

else
	print("Wrong game")
end
