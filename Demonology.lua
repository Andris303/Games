--!strict
--!optimize 2

if game.GameId == 6170143659 and workspace:FindFirstChild("Ghost") then

local RobloxVersion = _G.RobloxVersion or game:GetClientVersion()
local offsetsOk, offsetsData = pcall(crypt.json.decode, game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json"))
local O = offsetsOk and type(offsetsData) == "table" and offsetsData.Offsets or {}
local walkspeedOffset = O.Humanoid and O.Humanoid.Walkspeed
local textOffset = O.GuiObject and O.GuiObject.Text
local childrenOffset = O.Instance and O.Instance.ChildrenStart
local childrenEndOffset = O.Instance and O.Instance.ChildrenEnd

if not walkspeedOffset or not textOffset then
    print("No live offsets for " .. tostring(RobloxVersion) .. ", speed and spirit box tracking are disabled")
end

local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()
local Highlight = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))().Highlight

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Ghost = workspace.Ghost
local Rooms = workspace.Map.Rooms
local Handprints = workspace:FindFirstChild("Handprints")
local ScratchText = workspace:FindFirstChild("ScratchText")
local ItemsFolder = workspace:FindFirstChild("Items")

local bGhostESP = true
local bHandprintESP = true
local bInfoText = true
local bNotify = true
local bInfStamina = true
local ghostColor = Color3.fromRGB(196, 45, 32)
local handprintColor = Color3.fromRGB(177, 45, 146)

local window
local preLocalConnect
local renderConnect
local FlagSetters = {}
local AppliedFlags = {}

local Colors = {
    Green = Color3.fromRGB(32, 196, 93),
    Red = Color3.fromRGB(196, 45, 32),
    Orange = Color3.fromRGB(234, 165, 16),
    White = Color3.fromRGB(228, 217, 211),
    Blue = Color3.fromRGB(16, 167, 234),
}

local GhostCodes = {
    EMFInscriptWither = "Aswang",
    UVOrbFreeze = "Banshee",
    EMFUVFreeze = "Demon",
    FreezeLaserWither = "Dullahan",
    UVFreezeWither = "Dybbuk",
    UVSpiritBoxLaser = "Entity",
    SpiritBoxOrbFreeze = "Ghoul",
    UVSpiritBoxWither = "Keres",
    UVOrbInscript = "Leviathan",
    EMFSpiritBoxOrb = "Nightmare",
    SpiritBoxFreezeLaser = "Oni",
    EMFUVOrb = "Phantom",
    EMFSpiritBoxInscript = "Ravager",
    EMFFreezeInscript = "Revenant",
    EMFInscriptLaser = "Shadow",
    EMFSpiritBoxWither = "Siren",
    SpiritBoxFreezeInscript = "Skinwalker",
    EMFFreezeLaser = "Specter",
    UVSpiritBoxInscript = "Spirit",
    UVOrbLaser = "Umbra",
    UVInscriptWither = "Vesper",
    OrbFreezeWither = "Vex",
    OrbInscriptLaser = "Wretch",
    OrbLaserWither = "The Wisp",
    EMFSpiritBoxLaser = "Wraith",
}

local SpiritBoxResponses = {}
for _, response in {"CLOSE", "FAR", "FAR AWAY", "AWAY", "KILL", "HATE", "DON'T TURN AROUND", "BEHIND", "I'M BEHIND YOU", "DEATH", "ATTACK", "HURT", "YOUNG", "OLD", "ELDER"} do
    SpiritBoxResponses[response] = true
end

local EvidenceOrder = {"EMF", "UV", "SpiritBox", "Orb", "Freeze", "Inscript", "Laser", "Wither"}
local Evidence = {}
local BodyParts = {"Head", "Torso", "Right Arm", "Left Arm", "Right Leg", "Left Leg"}

local Lines = {}
local LineById = {}
local viewportY = Camera.ViewportSize.Y

local GhostParts = {}
local HandprintParts = {}
local HandprintClass = {}
local ItemNames = {}
local RoomList = Rooms:GetChildren()
local roomIndex = 0

local Timers = {Refs = 0, Ghost = 0, Energy = 0, Stamina = 0, Rooms = 0, RoomList = 0, Items = 0, Handprints = 0, Parts = 0, Static = 0}
local lastTick = 0
local lastData = 0

local typeFound = false
local skinwalkerPartial = false
local ghostHunting = false
local speedEnabled = walkspeedOffset ~= nil
local ghostSpeed
local GhostHumanoid
local LocalHumanoid
local Subtitle

local function InstId(inst)
    return tostring(tonumber(inst.Data))
end

local function ReadU64(address, offset)
    local ok, value = pcall(memory.readu64, address, offset)
    return ok and value or nil
end

local function MemoryChildren(folder)
    if not childrenOffset or not childrenEndOffset then return folder:GetChildren() end

    local address = tonumber(folder.Data)
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

local function SetLine(id, text, color)
    local line = LineById[id]
    if line then
        line.Text = text
        line.Color = color
        return
    end
    line = {Text = text, Color = color}
    LineById[id] = line
    Lines[#Lines + 1] = line
end

local function RemoveLine(id)
    local line = LineById[id]
    if not line then return end
    LineById[id] = nil
    table.remove(Lines, table.find(Lines, line))
end

local function Notify(text)
    if bNotify then send_notification(text, "warning") end
end

local function Near(a, b)
    return math.abs(a - b) < .02
end

local function ShowType(name)
    if typeFound then return end
    typeFound = true
    RemoveLine("GhostFoundPartial")
    local text = "Ghost type found: " .. name
    Notify(text)
    SetLine("GhostFound", text, Colors.Red)
end

local function CheckEvidence()
    if typeFound then return end

    local count = 0
    local code = ""
    for _, key in EvidenceOrder do
        if Evidence[key] then
            count += 1
            code ..= key
        end
    end

    if count >= 4 then
        ShowType("Skinwalker")
    elseif count == 3 and not skinwalkerPartial then
        if code == "OrbFreezeInscript" or code == "SpiritBoxOrbInscript" then
            ShowType("Skinwalker")
        elseif code == "SpiritBoxOrbFreeze" then
            skinwalkerPartial = true
            Notify("Ghost type found: Ghoul")
            SetLine("GhostFoundPartial", "Ghost type found: Ghoul, WARNING: Possibly Skinwalker, try ruling out inscription", Colors.Red)
        elseif GhostCodes[code] then
            ShowType(GhostCodes[code])
        end
    end
end

local function ShowEvidence(key, label)
    if Evidence[key] then return end
    Evidence[key] = true
    local text = label .. " evidence found"
    Notify(text)
    SetLine(key, text, Colors.Green)
    CheckEvidence()
end

local customDifficulty = workspace:GetAttribute("Difficulty") == "Custom"
local defaultSpeed = tonumber(workspace:GetAttribute("DefaultWalkSpeed"))
local maxStamina = tonumber(workspace:GetAttribute("MaxStamina"))
local SirenSpeeds = defaultSpeed and {defaultSpeed * .8, defaultSpeed * 1.28, defaultSpeed * .4} or {}
local energy = tonumber(LocalPlayer:GetAttribute("Energy"))
local favoriteRoom = Ghost:GetAttribute("FavoriteRoom")

local function EnergyColor(value)
    if value == 0 then return Colors.Red end
    if value and value < 20 then return Colors.Orange end
    return Colors.White
end

local function SetHuntLine()
    if ghostHunting then
        SetLine("Hunt", "Ghost is currently hunting", Colors.Red)
    else
        SetLine("Hunt", "Ghost is not hunting", Colors.Blue)
    end
end

if speedEnabled then SetLine("GhostSpeed", "Ghost's speed: ?", Colors.White) end
SetLine("Energy", "Your energy: " .. tostring(energy), EnergyColor(energy))
SetLine("FavRoom", "Ghost's favorite room: " .. tostring(favoriteRoom), Colors.Blue)
ghostHunting = Ghost:GetAttribute("Hunting") == "true"
SetHuntLine()

if Ghost:GetAttribute("Gender") == "Male" then
    SetLine("Gender", "Keres and Siren can be ruled out", Colors.White)
end

if workspace:FindFirstChild("GhostOrb") then
    ShowEvidence("Orb", "Ghost orb")
else
    SetLine("OrbEvidence", "No ghost orb evidence, can be ruled out", Colors.White)
end

if Ghost:GetAttribute("Headless") == "true" then
    ShowType("Dullahan")
end

if not Ghost:FindFirstChild("GhostFootsteps") then
    ShowType("Umbra")
end

local function RefreshRefs()
    GhostHumanoid = Ghost:FindFirstChild("Humanoid")

    local char = LocalPlayer.Character
    LocalHumanoid = char and memory.rtti(char) == "RBX::ModelInstance" and char:FindFirstChild("Humanoid") or nil

    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    local subtitles = gui and gui:FindFirstChild("Subtitles")
    local holder = subtitles and subtitles:FindFirstChild("Holder")
    Subtitle = textOffset and holder and holder:FindFirstChild("TextLabel") or nil

    viewportY = Camera.ViewportSize.Y
end

local function ScanGhostParts()
    local parts = {}
    for _, name in BodyParts do
        local part = Ghost:FindFirstChild(name)
        if part then parts[#parts + 1] = {Part = part, Size = part.Size} end
    end
    GhostParts = parts
end

local function ScanHandprints()
    if not Handprints then return end

    local parts = {}
    local classes = {}
    for _, inst in MemoryChildren(Handprints) do
        local id = InstId(inst)
        local isPart = HandprintClass[id]
        if isPart == nil then isPart = inst.ClassName == "Part" end
        classes[id] = isPart
        if isPart then
            parts[id] = HandprintParts[id] or {Part = inst, Size = inst.Size}
        end
    end
    HandprintClass = classes
    HandprintParts = parts

    if next(parts) then ShowEvidence("UV", "UV handprints") end
end

local function UpdateSpeeds()
    if not speedEnabled then return end

    if GhostHumanoid then
        local speed = memory.readf32(GhostHumanoid, walkspeedOffset)
        if ghostSpeed == nil and (speed < 0 or speed > 50) then
            speedEnabled = false
            RemoveLine("GhostSpeed")
            print("Walkspeed offset looks wrong, speed tracking is disabled")
            return
        end

        if speed ~= ghostSpeed then
            ghostSpeed = speed
            local color = Colors.White
            if not customDifficulty then
                if not Near(speed, 10.5) then color = Colors.Orange end
                if Near(speed, 7.88) then
                    ShowType("Aswang")
                elseif Near(speed, 8.4) then
                    ShowType("Umbra")
                elseif Near(speed, 14) then
                    ShowType(Evidence.Orb and "Phantom" or "Oni")
                elseif not Near(speed, 3) then
                    ShowType("Wretch")
                end
            end
            SetLine("GhostSpeed", "Ghost's speed: " .. tostring(math.floor(speed * 100 + .5) / 100), color)
        end
    end

    if LocalHumanoid and not typeFound then
        local localSpeed = memory.readf32(LocalHumanoid, walkspeedOffset)
        for _, sirenSpeed in SirenSpeeds do
            if Near(localSpeed, sirenSpeed) then ShowType("Siren") end
        end
    end
end

local function UpdateSubtitle()
    if not Subtitle then return end

    local text = memory.readstring(Subtitle, textOffset)
    if SpiritBoxResponses[text] then
        ShowEvidence("SpiritBox", "Spirit Box")
    elseif text == "- HUMMING -" then
        ShowType("Siren")
    elseif text == "> Ghost Wail <" and ghostHunting then
        ShowType("Banshee")
    end
end

local function UpdateGhost()
    local hunting = Ghost:GetAttribute("Hunting") == "true"
    if hunting ~= ghostHunting then
        ghostHunting = hunting
        SetHuntLine()
    end

    local room = Ghost:GetAttribute("FavoriteRoom")
    if room ~= favoriteRoom then
        favoriteRoom = room
        Notify("Ghost's favorite room changed")
        SetLine("FavRoom", "Ghost's favorite room: " .. tostring(room), Colors.Blue)
    end

    if not Evidence.Laser and Ghost:GetAttribute("LaserVisible") == "true" then
        ShowEvidence("Laser", "Laser projector")
    end

    if not Evidence.EMF then
        local emfTime = Ghost:GetAttribute("LastEMFLevel5Time")
        if emfTime and tonumber(emfTime) ~= 0 then ShowEvidence("EMF", "EMF level 5") end
    end
end

local function UpdateEnergy()
    local value = tonumber(LocalPlayer:GetAttribute("Energy"))
    if value == energy then return end
    energy = value
    SetLine("Energy", "Your energy: " .. tostring(value), EnergyColor(value))
end

local function CheckRooms()
    if Evidence.Freeze or #RoomList == 0 then return end

    for _ = 1, 2 do
        roomIndex = roomIndex % #RoomList + 1
        local temperature = tonumber(RoomList[roomIndex]:GetAttribute("Temperature"))
        if temperature and temperature < 0 then
            ShowEvidence("Freeze", "Freezing temperatures")
            return
        end
    end
end

local function CheckItems()
    if not ItemsFolder or (Evidence.Inscript and Evidence.Wither) then return end

    local names = {}
    for _, inst in MemoryChildren(ItemsFolder) do
        local id = InstId(inst)
        local name = ItemNames[id]
        if name == nil then name = inst:GetAttribute("ItemName") or false end
        names[id] = name

        local wanted = (name == "Spirit Book" and not Evidence.Inscript and "Inscription") or (name == "Flower Pot" and not Evidence.Wither and "WitheredFlowers")
        if wanted and inst:GetAttribute("PhotoRewardAvailable") == "true" and inst:GetAttribute("PhotoRewardType") == wanted then
            if wanted == "Inscription" then
                ShowEvidence("Inscript", "Inscription")
            else
                ShowEvidence("Wither", "Wither")
            end
        end
    end
    ItemNames = names
end

local function CheckStatic()
    if not Evidence.Inscript and ScratchText and ScratchText:FindFirstChildOfClass("Model") then
        ShowEvidence("Inscript", "Inscription")
    end

    if not Evidence.Orb and workspace:FindFirstChild("GhostOrb") then
        RemoveLine("OrbEvidence")
        ShowEvidence("Orb", "Ghost orb")
    end
end

local function SyncFlags()
    for flag, apply in FlagSetters do
        local value = window:get(flag)
        if value ~= AppliedFlags[flag] then
            AppliedFlags[flag] = value
            apply(value)
        end
    end
end

local function Due(name, interval, now)
    if now < Timers[name] then return false end
    Timers[name] = now + interval
    return true
end

local function PreLocal()
    SyncFlags()

    local now = os.clock()
    if now - lastTick > 1 then
        HandprintParts = {}
        HandprintClass = {}
        for name in Timers do Timers[name] = 0 end
    end
    lastTick = now

    if Due("Refs", .5, now) then RefreshRefs() end
    if Due("Parts", 2, now) then ScanGhostParts() end
    if Due("Handprints", .25, now) then ScanHandprints() end

    UpdateSpeeds()
    UpdateSubtitle()

    if Due("Ghost", .25, now) then UpdateGhost() end
    if Due("Energy", .5, now) then UpdateEnergy() end
    if Due("RoomList", 10, now) then RoomList = Rooms:GetChildren() end
    if Due("Rooms", .1, now) then CheckRooms() end
    if Due("Items", 1, now) then CheckItems() end
    if Due("Static", 1, now) then CheckStatic() end

    if bInfStamina and maxStamina and Due("Stamina", .1, now) then
        LocalPlayer:SetAttribute("Stamina", maxStamina)
    end

    lastData = os.clock()
end

local pose = {Parent = true}

local function HighlightEntry(entry, color)
    local part = entry.Part
    pose.Position = part.Position
    pose.RightVector = part.RightVector
    pose.UpVector = part.UpVector
    pose.LookVector = part.LookVector
    pose.PartSize = entry.Size
    Highlight(pose, color, .2, .7, 1)
end

local function Render()
    local fresh = os.clock() - lastData < .5

    if bGhostESP and fresh then
        for _, entry in GhostParts do
            HighlightEntry(entry, ghostColor)
        end
    end

    if bHandprintESP and fresh then
        for _, entry in HandprintParts do
            HighlightEntry(entry, handprintColor)
        end
    end

    if bInfoText then
        local y = viewportY - 25
        for i = 1, #Lines do
            local line = Lines[i]
            y -= 20
            DrawingImmediate.OutlinedText(vector.create(25, y, 0), 20, line.Color, 1, line.Text, false, "Nunito")
        end
    end
end

window = UI.new({
    Title = "Andris: Demonology",
    Subtitle = "Evidence | ESP",
    Version = "2.0.1",
    Folder = "AndrisDemonology",
    Footer = "This script is discontinued!",
    UpdateNotice = {"V2.0.1", "This script now uses ok0f's V2 UI library."},
    OnUnload = function()
        preLocalConnect:Disconnect()
        renderConnect:Disconnect()
    end,
    OnReload = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/Demonology.lua"))()
    end,
})

do
    local visual = window:tab("Visual")
    local esp = visual:section("ESP")

    esp:toggle({Name = "Ghost ESP", Flag = "GhostESP", Default = true})
    FlagSetters.GhostESP = function(val)
        bGhostESP = val
    end

    esp:color({Name = "Ghost color", Flag = "GhostColor", Default = ghostColor})
    FlagSetters.GhostColor = function(val)
        ghostColor = val
    end

    esp:toggle({Name = "UV handprint ESP", Flag = "HandprintESP", Default = true})
    FlagSetters.HandprintESP = function(val)
        bHandprintESP = val
    end

    esp:color({Name = "Handprint color", Flag = "HandprintColor", Default = handprintColor})
    FlagSetters.HandprintColor = function(val)
        handprintColor = val
    end

    local info = visual:section("INFO")

    info:toggle({Name = "Show evidence and ghost info", Flag = "InfoText", Default = true})
    FlagSetters.InfoText = function(val)
        bInfoText = val
    end

    info:toggle({Name = "Notifications", Flag = "Notify", Default = true})
    FlagSetters.Notify = function(val)
        bNotify = val
    end

    local player = window:tab("Player")
    local movement = player:section("MOVEMENT")

    movement:toggle({Name = "Infinite stamina", Flag = "InfStamina", Default = true})
    FlagSetters.InfStamina = function(val)
        bInfStamina = val
    end
end

window:start()

preLocalConnect = RunService.PreLocal:Connect(PreLocal)
renderConnect = RunService.Render:Connect(Render)

print("Loaded")

else
    print("Not in a Demonology match")
end
