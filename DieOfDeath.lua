--!strict
--!optimize 2

local RobloxVersion = _G.RobloxVersion or game:GetClientVersion()
local offsetsOk, offsetsData = pcall(crypt.json.decode, game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json"))
local O = offsetsOk and type(offsetsData) == "table" and offsetsData.Offsets or {}
local activeAnimationsOffset = O.Animator and O.Animator.ActiveAnimations
local trackAnimationOffset = O.AnimationTrack and O.AnimationTrack.Animation
local trackAnimatorOffset = O.AnimationTrack and O.AnimationTrack.Animator
local labelTextOffset = O.GuiObject and O.GuiObject.Text
local animationIdOffset = O.Misc and O.Misc.AnimationId
local childrenOffset = O.Instance and O.Instance.ChildrenStart
local childrenEndOffset = O.Instance and O.Instance.ChildrenEnd
local animationsReady = activeAnimationsOffset and trackAnimationOffset and trackAnimatorOffset and animationIdOffset and labelTextOffset

if not animationsReady then
    print("No live offsets for " .. tostring(RobloxVersion) .. ", auto block is disabled")
end

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local bAutoBlock = false
local bNoSwingCD = false
local maximumStamina = 100
local appliedStamina
local blockBusy = false
local heldKey
local blockKey
local KillerFolder
local LocalChar
local LocalRoot
local localTeam
local SwingStates = {}
local KillerCache = {}
local Registered = {}
local Timers = {Refs = 0, Players = 0, Attributes = 0}
local lastTick = 0

local window
local preLocalConnect
local FlagSetters = {}
local AppliedFlags = {}

local attackDuration = .35
local startWidth = 7.5
local maxWidth = 13
local widthPoint = .75
local endWidth = 5
local baseExtraForward = 4
local height = 6
local attackLength = 7.5
local extraHeight = 1
local closeRadius = 3
local minWidthMultiplier = .85

local function InstId(inst)
    return tostring(tonumber(inst.Data))
end

local function IsPointer(value)
    return type(value) == "number" and value > 0x100000000
end

local function ReadU64(address, offset)
    local ok, value = pcall(memory.readu64, address, offset)
    return ok and value or nil
end

local function ValidCharacter(char)
    if not char then return nil end
    local ok, className = pcall(memory.rtti, char)
    if ok and className == "RBX::ModelInstance" then return char end
    return nil
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

local function NormalizeAnimationId(id)
    if not id then return nil end
    id = tostring(id)
    return id:match("%d+") or id
end

local function BuildAnimationNames(char)
    local names = {}
    local folder = char:FindFirstChild("Animations")
    if not folder then return names, false end

    for _, anim in folder:GetDescendants() do
        if anim:IsA("Animation") then
            local id = NormalizeAnimationId(memory.readstring(anim.Data, animationIdOffset))
            if id then names[id] = anim.Name end
        end
    end
    return names, true
end

local function FindSwing(animator, names)
    local animatorAddress = tonumber(animator.Data)
    local head = ReadU64(animatorAddress, activeAnimationsOffset)
    local count = ReadU64(animatorAddress, activeAnimationsOffset + 0x8)
    if not IsPointer(head) or not count or count == 0 or count > 256 then return nil end

    local node = ReadU64(head, 0)
    for _ = 1, count do
        if not IsPointer(node) or node == head then break end

        local track = ReadU64(node, 0x10)
        if IsPointer(track) and ReadU64(track, trackAnimatorOffset) == animatorAddress then
            local animation = ReadU64(track, trackAnimationOffset)
            if IsPointer(animation) then
                local id = NormalizeAnimationId(memory.readstring(animation, animationIdOffset))
                local name = names[id]
                if not name then
                    local ok, inst = pcall(pointer_to_userdata, animation)
                    name = ok and inst and inst.Name
                end
                if name == "Swing" then return track end
            end
        end

        node = ReadU64(node, 0)
    end
    return nil
end

local function ShouldBlock(kp, kl, lp, prog)
    local forward = vector.create(kl.x, 0, kl.z)
    if vector.magnitude(forward) == 0 then return false end

    forward = vector.normalize(forward)
    local offset = lp - kp
    local horizontalDistance = vector.magnitude(vector.create(offset.x, 0, offset.z))
    if horizontalDistance <= closeRadius and math.abs(offset.y) <= (height / 2 + extraHeight) then return true end

    local forwardDistance = vector.dot(offset, forward)
    if forwardDistance < -1 then return false end

    local extraForward = baseExtraForward
    if prog > .5 then extraForward = baseExtraForward - (2 * (prog - .5) / .5) end

    local maxForward = attackLength + extraForward
    if forwardDistance > maxForward then return false end

    local startHalfWidth = startWidth / 2
    local maxHalfWidth = maxWidth / 2
    local endHalfWidth = endWidth / 2
    local midDistance = maxForward * widthPoint
    local allowedHalfWidth

    if forwardDistance <= midDistance then
        local alpha = math.clamp(forwardDistance / midDistance, 0, 1)
        allowedHalfWidth = startHalfWidth + (maxHalfWidth - startHalfWidth) * alpha
    else
        local alpha = math.clamp((forwardDistance - midDistance) / (maxForward - midDistance), 0, 1)
        allowedHalfWidth = maxHalfWidth + (endHalfWidth - maxHalfWidth) * alpha
    end

    if prog > .5 then
        local narrowAlpha = (prog - .5) / .5
        allowedHalfWidth *= 1 - ((1 - minWidthMultiplier) * narrowAlpha)
    end

    if math.abs(offset.y) > (height / 2 + extraHeight) then return false end
    local right = vector.create(-forward.z, 0, forward.x)
    return math.abs(vector.dot(offset, right)) <= allowedHalfWidth
end

local function Block()
    if blockBusy or not blockKey then return false end
    local key = blockKey
    blockBusy = true
    heldKey = key

    task.spawn(function()
        keypress(key)
        task.wait(.08)
        keyrelease(key)
        heldKey = nil
        task.wait(.12)
        blockBusy = false
    end)
    return true
end

local function RefreshRefs()
    LocalChar = ValidCharacter(LocalPlayer.Character)
    LocalRoot = LocalChar and LocalChar:FindFirstChild("HumanoidRootPart")
    local parent = LocalChar and LocalChar.Parent
    localTeam = parent and parent.Name

    local assets = workspace:FindFirstChild("GameAssets")
    local teams = assets and assets:FindFirstChild("Teams")
    KillerFolder = teams and teams:FindFirstChild("Killer")

    local label = LocalPlayer:FindFirstChild("PlayerGui")
    for _, name in {"MainGui", "RoundUI", "PlayerUI", "Abilities", "Folder", "Block", "Input"} do
        label = label and label:FindFirstChild(name)
    end
    local blockLabel = labelTextOffset and label or nil

    blockKey = nil
    if blockLabel then
        local text = tostring(memory.readstring(blockLabel.Data, labelTextOffset)):upper()
        if #text == 1 then blockKey = string.byte(text) end
    end
end

local function RegisterPlayers()
    local current = {}

    for _, player in Players:GetChildren() do
        local char = ValidCharacter(player.Character)
        local charId = char and InstId(char)
        if charId then
            current[charId] = true
            if not Registered[charId] and char:FindFirstChildOfClass("Humanoid") then
                Registered[charId] = true
                ESP.AddPlayer(char, {Player = player, TeamType = "Parent"})
            end
        end
    end

    for id in Registered do
        if not current[id] then
            Registered[id] = nil
            ESP.RemovePlayer(id)
        end
    end
end

local function UpdateAttributes()
    if not LocalChar then return end

    if localTeam == "Killer" or localTeam == "Survivor" then
        local charId = InstId(LocalChar)
        if appliedStamina ~= charId .. ":" .. maximumStamina then
            appliedStamina = charId .. ":" .. maximumStamina
            LocalChar:SetAttribute("MaxStamina", maximumStamina)
        end
    end

    if bNoSwingCD and localTeam == "Killer" then
        LocalChar:SetAttribute("SwingCooldown", "")
        LocalChar:SetAttribute("EjectCooldown", "")
    end
end

local function GetKiller(char, id, now)
    local entry = KillerCache[id]
    if entry and (entry.Complete or now < entry.Retry) then return entry end

    local humanoid = char:FindFirstChildOfClass("Humanoid")
    local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
    local root = char:FindFirstChild("HumanoidRootPart")
    local names, complete = BuildAnimationNames(char)
    entry = {Animator = animator, Root = root, Names = names, Complete = complete and animator ~= nil and root ~= nil, Retry = now + 1}
    KillerCache[id] = entry
    return entry
end

local function UpdateAutoBlock(now)
    if not animationsReady or not KillerFolder then return end

    local seen = {}
    for _, char in MemoryChildren(KillerFolder) do
        local id = InstId(char)
        seen[id] = true

        local killer = GetKiller(char, id, now)
        local swing = killer.Animator and FindSwing(killer.Animator, killer.Names)
        if not swing then
            SwingStates[id] = nil
            continue
        end

        local state = SwingStates[id]
        if not state or state.Track ~= swing then
            state = {Track = swing, Started = now, Blocked = false}
            SwingStates[id] = state
        end

        if state.Blocked or not LocalRoot or not killer.Root then continue end

        local progress = math.clamp((now - state.Started) / attackDuration, 0, 1)
        if ShouldBlock(killer.Root.Position, killer.Root.LookVector, LocalRoot.Position, progress) and Block() then
            state.Blocked = true
        end
    end

    for id in KillerCache do
        if not seen[id] then
            KillerCache[id] = nil
            SwingStates[id] = nil
        end
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
        table.clear(SwingStates)
        table.clear(KillerCache)
        for name in Timers do Timers[name] = 0 end
    end
    lastTick = now

    if Due("Refs", .5, now) then RefreshRefs() end
    if Due("Players", .5, now) then RegisterPlayers() end
    if Due("Attributes", .05, now) then UpdateAttributes() end

    if bAutoBlock then UpdateAutoBlock(now) end
end

window = UI.new({
    Title = "Andris: Die of Death",
    Subtitle = "Support | Exploits",
    Version = "2.0.1",
    Folder = "AndrisDOD",
    Footer = "This script is in discontinued.",
    UpdateNotice = {"V2.0.0", "This script now uses ok0f's V2 UI library."},
    OnUnload = function()
        preLocalConnect:Disconnect()
        if heldKey then keyrelease(heldKey) end
        ESP.Clear()
        clear_model_data()
    end,
    OnReload = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/DieOfDeath.lua"))()
    end,
})

do
    local main = window:tab("Main")
    local combat = main:section("COMBAT")

    combat:toggle({Name = "Auto Block", Flag = "AutoBlock", Default = false})
    FlagSetters.AutoBlock = function(val)
        bAutoBlock = val
        if not val then table.clear(SwingStates) end
    end

    combat:toggle({Name = "No killer M1 cooldown", Flag = "NoSwingCD", Default = false})
    FlagSetters.NoSwingCD = function(val)
        bNoSwingCD = val
    end

    local movement = main:section("MOVEMENT")

    movement:slider({Name = "Maximum stamina", Flag = "MaxStamina", Min = 10, Max = 1000, Default = 100, Step = 5})
    FlagSetters.MaxStamina = function(val)
        maximumStamina = val
    end

    local visual = window:tab("Visual")
    local esp = visual:section("ESP")

    esp:label("ESP support requires ESP to be enabled in severe")

    esp:toggle({Name = "Enable ESP support", Flag = "ESP", Default = true})
    FlagSetters.ESP = function(val)
        ESP.SetEnabled(val)
    end
end

window:start()

preLocalConnect = RunService.PreLocal:Connect(PreLocal)

clear_model_data()

print("Loaded")
