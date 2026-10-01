--!strict
--!optimize 2

local watchKeybind = "B"
local parryKeybind = "V"
local watchDelay = .05
local parryLoopDelay = .01
local circleRadius = 25
local circleSegments = 24
local parrySafety = .1
local attackHeight = 7

local runId = (_G.AnimationWatcherRun or 0) + 1
_G.AnimationWatcherRun = runId

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/UI.lua"))()

local CircleColor = Color3.fromRGB(120,200,255)
local ParryColor = Color3.fromRGB(255,255,255)
local ParryAttackColor = Color3.fromRGB(255,165,0)

local offsets

do
    local ok, result = pcall(function()
        local robloxVersion = _G.RobloxVersion or game:GetClientVersion()
        return crypt.json.decode(game:HttpGet("https://offsets.imtheo.lol/" .. robloxVersion .. "/offsets.json")).Offsets
    end)

    if ok and type(result) == "table" and result.Animator and result.AnimationTrack and result.Misc then
        offsets = {
            ActiveAnimations = result.Animator.ActiveAnimations,
            TrackAnimation = result.AnimationTrack.Animation,
            TrackAnimator = result.AnimationTrack.Animator,
            AnimationId = result.Misc.AnimationId,
            NameContainer = result.Instance and result.Instance.NameContainer,
            Name = result.Instance and result.Instance.Name,
        }
    end
end

local target, targetId, targetName, targetRoot
local targetPosition
local keyHeld = false
local bWatching = false
local bPickingKey = false

local seenList = {}
local seenIds = {}
local savedAnimations = {}
local savedOrder = {}
local savedNames = {}
local nameCache = {}
local nameCacheSize = 0
local characterCache = {}
local characterCacheSize = 0
local trackStates = {}
local uiDirty = true

local bAutoParry = false
local bShowParry = false
local active = false
local tempActive = false
local parryMode = "default"
local parryKeyName = "F"
local matchMode = "Name"
local bTeamCheck = false
local teamCheckMode = "Player team"
local parryLength = 7.5
local parryWidth = 7.5
local parryDelay = 0
local parryWindup = 0
local parryAttackTime = .25
local activeAttacks = {}
local attackVisUntil = {}
local predictionData = {}
local predictionSize = 0
local parrySnapshot = {}
local localRoot, localPos, localSize
local viewport = Camera.ViewportSize
local viewportTimer = 0

local statusLabel = {Text = "AUTO PARRY", Size = 30, Color = Color3.fromRGB(248, 131, 121), Position = Vector2.new(0, 0), Visible = false}
local parryLabel = {Text = "PARRY", Size = 35, Color = Color3.fromRGB(255, 25, 25), Position = Vector2.new(0, 0), Visible = false}

local parryProfiles = {
    ["very-strict"] = {
        Shape = "Rectangle",
        RadiusMode = "Inner",
    },
    ["strict"] = {
        Shape = "Cone",
        Angle = 100,
        RadiusMode = "Inner",
    },
    ["default"] = {
        Shape = "Cone",
        Angle = 140,
        RadiusMode = "Inner",
    },
    ["permissive"] = {
        Shape = "Cone",
        Angle = 240,
        InnerRadius = 4.5,
        RadiusMode = "Inner",
    },
    ["always"] = {
        Shape = "Circle",
        RadiusMode = "Outer",
    },
}

local function InstId(inst)
    return tostring(tonumber(inst.Data))
end

local function IsKeyDown()
    for _, key in getpressedkeys() do
        if key == watchKeybind then return true end
    end
    return false
end

local function IsModel(inst)
    local ok, className = pcall(function()
        return memory.rtti(inst)
    end)
    return ok and type(className) == "string" and string.find(className, "Model") ~= nil
end

local function ClosestToCursor()
    local mouse = getmouseposition()
    local best, bestName, bestRoot, bestDistance = nil, nil, nil, math.huge

    for _, player in Players:GetChildren() do
        local char = player.Character
        if not char or not IsModel(char) then continue end

        local root = char:FindFirstChild("HumanoidRootPart")
        if not root then continue end

        local screen, visible = Camera:WorldToScreenPoint(root.Position)
        if not visible then continue end

        local dx, dy = screen.X - mouse.X, screen.Y - mouse.Y
        local distance = dx * dx + dy * dy
        if distance < bestDistance then
            best, bestName, bestRoot, bestDistance = char, player.Name, root, distance
        end
    end

    return best, bestName, bestRoot
end

local function FindAnimator(char)
    local holder = char:FindFirstChildOfClass("Humanoid") or char:FindFirstChildOfClass("AnimationController")
    return holder and holder:FindFirstChildOfClass("Animator")
end

local function ReadStdString(address)
    local okSize, size = pcall(memory.readu64, address, 0x10)
    local okCapacity, capacity = pcall(memory.readu64, address, 0x18)
    if not okSize or not okCapacity or type(size) ~= "number" or type(capacity) ~= "number" then return nil end
    if size <= 0 or size > 100 or capacity < size then return nil end

    local stringAddress = address
    if capacity >= 16 then
        local okPointer, pointer = pcall(memory.readu64, address)
        if not okPointer or type(pointer) ~= "number" or pointer < 0x10000000000 or pointer >= 0x70000000000 then return nil end
        stringAddress = pointer
    end

    local ok, value = pcall(memory.readstring, stringAddress, 0)
    if not ok or type(value) ~= "string" then return nil end
    value = string.sub(value, 1, size)
    if not string.match(value, "^[%w%p ]+$") then return nil end
    return value
end

local function ReadInstanceName(address)
    if offsets.NameContainer then
        local ok, container = pcall(memory.readu64, address, offsets.NameContainer)
        if ok and type(container) == "number" and container > 0x100000000 then
            local name = ReadStdString(container + (offsets.Name or 0)) or ReadStdString(container)
            if name then return name end
        end
    end
    return "?"
end

local function AnimationName(pointer, id)
    local cached = nameCache[pointer]
    if cached and cached.Id == id then return cached.Name end

    if nameCacheSize > 2000 then
        table.clear(nameCache)
        nameCacheSize = 0
    end

    local name = ReadInstanceName(pointer)
    if not cached then nameCacheSize += 1 end
    nameCache[pointer] = {Id = id, Name = name}
    return name
end

local function ActiveAnimations(animator, withNames)
    local result = {}

    local animatorPointer = tonumber(animator.Data)
    local head = memory.readu64(animator, offsets.ActiveAnimations)
    local count = memory.readu64(animator, offsets.ActiveAnimations + 0x8)
    if not head or head == 0 or not count or count == 0 or count > 256 then return result end

    local node = memory.readu64(head)
    for _ = 1, count do
        if not node or node == 0 or node == head then break end

        local track = memory.readu64(node + 0x10)
        if track and track > 0x100000000 and memory.readu64(track + offsets.TrackAnimator) == animatorPointer then
            local animationPointer = memory.readu64(track + offsets.TrackAnimation)
            if animationPointer and animationPointer > 0x100000000 then
                local rawId = tostring(memory.readstring(animationPointer, offsets.AnimationId))
                local id = rawId:match("%d+") or rawId
                result[#result + 1] = {
                    Track = track,
                    Id = id,
                    Name = withNames and AnimationName(animationPointer, id) or nil,
                }
            end
        end

        node = memory.readu64(node)
    end

    return result
end

local function DisplayName(animation)
    if animation.Name and animation.Name ~= "?" then
        return animation.Name .. "  ID: " .. animation.Id
    end
    return "ID: " .. animation.Id
end

local window

local function ApplySaved(list)
    local animations, order, names = {}, {}, {}

    if type(list) == "table" then
        for _, saved in list do
            local id = type(saved) == "table" and saved.Id and tostring(saved.Id)
            if id and not animations[id] then
                local name = saved.Name and tostring(saved.Name) or nil
                animations[id] = {Id = id, Name = name}
                order[#order + 1] = id
                if name and name ~= "?" then
                    names[name] = true
                end
            end
        end
    end

    savedAnimations, savedOrder, savedNames = animations, order, names
    uiDirty = true
end

local function SavedList()
    local list = {}
    for _, id in savedOrder do
        local saved = savedAnimations[id]
        list[#list + 1] = {Id = saved.Id, Name = saved.Name}
    end
    return list
end

local function ToggleSaved(animation)
    local list = SavedList()

    if savedAnimations[animation.Id] then
        for i, saved in list do
            if saved.Id == animation.Id then
                table.remove(list, i)
                break
            end
        end
    else
        list[#list + 1] = {Id = animation.Id, Name = animation.Name}
    end

    ApplySaved(list)
    window:setvalue("SavedAnimations", list)
end

local modifierCodes = {
    Space = 0x20,
    LeftShift = 0xa0,
    RightShift = 0xa1,
    LeftCtrl = 0xa2,
    RightCtrl = 0xa3,
    LeftAlt = 0xa4,
    RightAlt = 0xa5,
}

local function GetKeycode(name)
    if #name == 1 then
        return string.byte(string.upper(name))
    end
    return modifierCodes[name]
end

local mouseButtons = {
    LeftMouse = {Press = mouse1press, Release = mouse1release},
    RightMouse = {Press = mouse2press, Release = mouse2release},
}

local function CanPress(name)
    return mouseButtons[name] ~= nil or GetKeycode(name) ~= nil
end

local function PressKey(name)
    local button = mouseButtons[name]
    if button then
        pcall(button.Press)
        task.wait(.1)
        pcall(button.Release)
        return
    end

    local keycode = GetKeycode(name)
    if not keycode then return end
    pcall(keypress, keycode)
    task.wait(.1)
    pcall(keyrelease, keycode)
end

local function IsSaved(animation)
    if savedAnimations[animation.Id] then return true end
    return matchMode == "Name" and animation.Name ~= nil and savedNames[animation.Name] == true
end

local function Notify(text)
    pcall(send_notification, text, "info")
end

local function ClearTarget()
    target, targetId, targetRoot, targetPosition = nil, nil, nil, nil
end

window = UI:createwindow({
    Title = "Animation Watcher | Andris",
    Version = "VX",
    Keybind = "RightShift",
    ConfigFolder = "AndrisAnimationWatcher",
    CustomResolution = Vector2.new(580, 375),
    DPIScale = _G.DPIScale or 1.0,
    CompactSettings = false,
    DefaultTab = "Watcher",
    TabAlignment = "Center",
    DefaultColor = Color3.fromRGB(28, 27, 31),
    DefaultAccent = Color3.fromRGB(208, 188, 255),
    DefaultSnowfall = true,
    DefaultScale = 1.0,
    DefaultFont = 0,
})

local keybindLabel
local watchKeybindLabel
local parryKeyLabel

local function IsPressed(name)
    for _, key in getpressedkeys() do
        if key == name then return true end
    end
    return false
end

local function PickKey(button, idleText, apply, bAllowMouse)
    if bPickingKey then return end
    bPickingKey = true

    task.spawn(function()
        button.Txt.Text = "Press any key.."
        if bAllowMouse then
            while IsPressed("LeftMouse") do
                task.wait(.01)
            end
        end

        while true do
            local picked
            for _, key in getpressedkeys() do
                if bAllowMouse or key ~= "LeftMouse" then
                    picked = key
                    break
                end
            end

            if picked then
                apply(picked)
                button.Txt.Text = idleText
                bPickingKey = false
                return
            end

            task.wait(.01)
        end
    end)
end

window:registerkey("SavedAnimations", {}, function(val)
    ApplySaved(val)
end)

window:registerkey("ParryKey", parryKeyName, function(val)
    parryKeyName = tostring(val)
    if parryKeyLabel then parryKeyLabel.Txt.Text = "Parry key: " .. parryKeyName end
end)

window:registerkey("AutoParryKeybind", parryKeybind, function(val)
    parryKeybind = val
    if keybindLabel then keybindLabel.Txt.Text = "Current keybind: " .. val end
end)

window:registerkey("WatchKeybind", watchKeybind, function(val)
    watchKeybind = val
    if watchKeybindLabel then watchKeybindLabel.Txt.Text = "Select keybind: " .. val end
    uiDirty = true
end)

local tabWatcher = window:createtab("Watcher")
local tabParry = window:createtab("Auto Parry")
local tabSettings = window:createtab("Parry Settings")

local watchLabel = window:createtextlabel(tabWatcher, "Click Start watching to begin", 1)

window:createlabel(tabWatcher, "Click an animation to save it", 2)

watchKeybindLabel = window:createlabel(tabWatcher, "Select keybind: " .. watchKeybind, 2)

local watchKeybindButton
watchKeybindButton = window:createbutton(tabWatcher, {
    Name = "Change select keybind",
    Col = 2,
    Callback = function()
        PickKey(watchKeybindButton, "Change select keybind", function(key)
            keyHeld = true
            window:setvalue("WatchKeybind", key)
            pcall(send_notification, "Select keybind set to: " .. key, "info")
        end)
    end
})

local watchButton
watchButton = window:createbutton(tabWatcher, {
    Name = "Start watching",
    Col = 2,
    Callback = function()
        bWatching = not bWatching
        ClearTarget()

        local text = bWatching and "Stop watching" or "Start watching"
        watchButton.BaseText = text
        watchButton.Txt.Text = text

        if bWatching then
            Notify("Press " .. watchKeybind .. " to select the player closest to your cursor")
        else
            Notify("Stopped watching")
        end
        uiDirty = true
    end
})

window:createbutton(tabWatcher, {
    Name = "Clear list",
    Col = 2,
    Callback = function()
        seenList = {}
        seenIds = {}
        uiDirty = true
    end
})

local savedLabel = window:createtextlabel(tabParry, "No saved animations", 1)

window:createlabel(tabParry, "After enabling, you need to press your keybind", 2)

window:createtoggle(tabParry, {
    Name = "Enable Auto parry",
    Col = 2,
    Default = false,
    Callback = function(val)
        if bAutoParry == val then return end

        table.clear(activeAttacks)
        table.clear(trackStates)
        tempActive = false
        active = false
        statusLabel.Visible = false
        parryLabel.Visible = false
        bAutoParry = val
    end
})

window:createtoggle(tabParry, {
    Name = "Show Auto parry range",
    Col = 2,
    Default = false,
    Callback = function(val)
        bShowParry = val
    end
})

window:createdropdown(tabParry, {
    Name = "Match animations by",
    StateKey = "AutoParryMatch",
    Col = 2,
    Options = {"ID", "Name"},
    Default = "Name",
    Callback = function(val)
        matchMode = val
    end
})

window:createtoggle(tabParry, {
    Name = "Team check",
    Col = 2,
    Default = false,
    Callback = function(val)
        bTeamCheck = val
    end
})

window:createdropdown(tabParry, {
    Name = "Team check type",
    StateKey = "AutoParryTeamCheck",
    Col = 2,
    Options = {"Player team", "Parent name"},
    Default = "Player team",
    Callback = function(val)
        teamCheckMode = val
    end
})

parryKeyLabel = window:createlabel(tabParry, "Parry key: " .. parryKeyName, 2)

local parryKeyButton
parryKeyButton = window:createbutton(tabParry, {
    Name = "Change parry key",
    Col = 2,
    Callback = function()
        PickKey(parryKeyButton, "Change parry key", function(key)
            if not CanPress(key) then
                pcall(send_notification, key .. " cannot be pressed, pick a letter, Space, a modifier key or a mouse button", "error")
                return
            end
            window:setvalue("ParryKey", key)
            pcall(send_notification, "Parry key set to: " .. key, "info")
        end, true)
    end
})

keybindLabel = window:createlabel(tabParry, "Current keybind: " .. parryKeybind, 2)

local keybindButton
keybindButton = window:createbutton(tabParry, {
    Name = "Change keybind",
    Col = 2,
    Callback = function()
        PickKey(keybindButton, "Change keybind", function(key)
            tempActive = true
            window:setvalue("AutoParryKeybind", key)
            pcall(send_notification, "Keybind set to: " .. key, "info")
        end)
    end
})

window:createdropdown(tabSettings, {
    Name = "Auto parry type",
    StateKey = "AutoParryMode",
    Col = 1,
    Options = {"very-strict", "strict", "default", "permissive", "always"},
    Default = "default",
    Callback = function(val)
        parryMode = val
    end
})

window:createslider(tabSettings, {
    Name = "Auto parry length",
    Col = 1,
    Min = 1, Max = 30, Default = 7.5,
    Step = .5,
    Callback = function(val)
        parryLength = val
    end
})

window:createslider(tabSettings, {
    Name = "Auto parry width",
    Col = 1,
    Min = 1, Max = 30, Default = 7.5,
    Step = .5,
    Callback = function(val)
        parryWidth = val
    end
})

window:createslider(tabSettings, {
    Name = "Auto parry delay",
    Col = 2,
    Min = 0, Max = 1, Default = 0,
    Step = .01,
    Callback = function(val)
        parryDelay = val
    end
})

window:createslider(tabSettings, {
    Name = "Auto parry windup",
    Col = 2,
    Min = 0, Max = 2, Default = 0,
    Step = .01,
    Callback = function(val)
        parryWindup = val
    end
})

window:createslider(tabSettings, {
    Name = "Auto parry attack time",
    Col = 2,
    Min = .05, Max = 2, Default = .25,
    Step = .01,
    Callback = function(val)
        parryAttackTime = val
    end
})

local function CreatePool(tab, onClick)
    local pool = {Tab = tab, Buttons = {}, Items = {}}

    function pool.Show(items, textFor)
        pool.Items = items
        for i, item in items do
            local button = pool.Buttons[i]
            if not button then
                local index = i
                button = window:createbutton(tab, {
                    Name = "",
                    Col = 1,
                    Callback = function()
                        local current = pool.Items[index]
                        if current then onClick(current) end
                    end
                })
                pool.Buttons[i] = button
            end

            local text = textFor(item)
            button.BaseText = text
            button.Txt.Text = text
            button.Tab = tab
        end

        for i = #items + 1, #pool.Buttons do
            pool.Buttons[i].Tab = nil
        end
    end

    return pool
end

local watchPool = CreatePool(tabWatcher, ToggleSaved)
local savedPool = CreatePool(tabParry, ToggleSaved)

local function RefreshUI()
    uiDirty = false

    if target then
        watchLabel.Txt.Text = "Watching " .. targetName .. (targetName == LocalPlayer.Name and " (you)" or "")
    elseif bWatching then
        watchLabel.Txt.Text = "Press " .. watchKeybind .. " near a player to select them"
    else
        watchLabel.Txt.Text = "Click Start watching to begin"
    end

    watchPool.Show(seenList, function(animation)
        return (savedAnimations[animation.Id] and "Saved: " or "") .. DisplayName(animation)
    end)

    local savedList = {}
    for _, id in savedOrder do
        savedList[#savedList + 1] = savedAnimations[id]
    end

    savedLabel.Txt.Text = #savedList == 0 and "No saved animations" or "Saved animations, click to remove"
    savedPool.Show(savedList, DisplayName)
end

local function Select()
    local char, name, root = ClosestToCursor()

    if char and target and InstId(char) == targetId then
        Notify("Deselected " .. targetName .. ", press " .. watchKeybind .. " to select a player")
        ClearTarget()
        uiDirty = true
        return
    end

    if not char then
        Notify("No player near your cursor")
        return
    end

    target, targetName, targetRoot = char, name, root
    targetId = InstId(char)
    targetPosition = nil
    seenList = {}
    seenIds = {}
    uiDirty = true

    Notify("Watching " .. name .. (name == LocalPlayer.Name and " (you)" or ""))
end

local function WatchStep()
    local held = bWatching and not bPickingKey and IsKeyDown()
    if held and not keyHeld then
        Select()
    end
    keyHeld = held

    if target and bWatching then
        if not target.Parent or not IsModel(target) then
            Notify(tostring(targetName) .. " is gone, press " .. watchKeybind .. " to select a player")
            ClearTarget()
            uiDirty = true
        else
            local okPosition, position = pcall(function()
                return targetRoot.Position
            end)
            targetPosition = okPosition and position or nil

            if offsets then
                local animator = FindAnimator(target)
                local ok, list = false, nil
                if animator then
                    ok, list = pcall(ActiveAnimations, animator, true)
                end

                if ok then
                    for _, animation in list do
                        if not seenIds[animation.Id] then
                            seenIds[animation.Id] = true
                            table.insert(seenList, 1, {Id = animation.Id, Name = animation.Name})
                            uiDirty = true
                        end
                    end
                end
            end
        end
    end

    if uiDirty then
        RefreshUI()
    end
end

local function CharacterParts(char, player)
    local id = InstId(char)
    local now = os.clock()
    local cached = characterCache[id]
    if cached and now < cached.Expires then return cached end

    if not cached then
        if characterCacheSize > 200 then
            table.clear(characterCache)
            characterCacheSize = 0
        end
        characterCacheSize += 1
    end

    local root = char:FindFirstChild("HumanoidRootPart")
    local okSize, size = pcall(function()
        return root.Size
    end)
    local okTeam, teamName = pcall(function()
        local team = player.Team
        return team and team.Name
    end)
    local okParent, parentName = pcall(function()
        local parent = char.Parent
        return parent and parent.Name
    end)

    cached = {
        Id = id,
        Root = root,
        Size = okSize and size or nil,
        TeamName = okTeam and teamName or nil,
        ParentName = okParent and parentName or nil,
        Animator = FindAnimator(char),
        Expires = now + 1,
    }
    characterCache[id] = cached
    return cached
end

local function UpdatePrediction(key, pos)
    local now = os.clock()
    local data = predictionData[key]

    if not data then
        if predictionSize > 200 then
            table.clear(predictionData)
            predictionSize = 0
        end
        predictionSize += 1
        predictionData[key] = {Position = pos, Time = now, Velocity = vector.create(0, 0, 0), LastMovement = now}
        return
    end

    local dt = now - data.Time
    if dt < .05 then return end

    if dt > 1 then
        data.Position = pos
        data.Time = now
        data.Velocity = vector.create(0, 0, 0)
        data.LastMovement = now
        return
    end

    local delta = pos - data.Position
    local moved = vector.magnitude(delta)

    if moved > .03 then
        local measuredVelocity = delta / dt

        data.Velocity = data.Velocity * .5 + measuredVelocity * .5
        data.LastMovement = now
    elseif now - data.LastMovement > .25 then
        data.Velocity *= .7

        if vector.magnitude(data.Velocity) < .5 then
            data.Velocity = vector.create(0, 0, 0)
        end
    end

    data.Position = pos
    data.Time = now
end

local function PredictPosition(key, currentPos, future)
    local data = predictionData[key]
    if not data then return currentPos end
    return currentPos + data.Velocity * future
end

local function GetPredictionTime(localPosition, attackerPos)
    local minDistance = 0
    local maxDistance = 92
    local distance = vector.magnitude(attackerPos - localPosition)
    local alpha = math.clamp((distance - minDistance) / (maxDistance - minDistance), 0, 1)

    return .2 * (alpha ^ .3)
end

local function PredictAttackerPosition(key, attackerPos, localPosition, multiplier)
    multiplier = multiplier or 1

    local prediction = GetPredictionTime(localPosition, attackerPos) * multiplier
    return PredictPosition(key, attackerPos, prediction)
end

local function GetQueryRadii(size)
    local hx = size.x / 2
    local hz = size.z / 2
    local inner = math.min(hx, hz)
    local outer = math.sqrt(hx * hx + hz * hz)

    return inner, outer, size.y / 2
end

local function DistanceToRectangle(forwardDistance, sideDistance, length, halfWidth, backward)
    backward = backward or 0

    local closestForward = math.clamp(forwardDistance, -backward, length)
    local closestSide = math.clamp(sideDistance, -halfWidth, halfWidth)

    local df = forwardDistance - closestForward
    local ds = sideDistance - closestSide

    return math.sqrt(df * df + ds * ds)
end

local function GetParryOrigin(key, attackerPos, localPosition)
    if localPosition then
        return PredictAttackerPosition(key, attackerPos, localPosition, 1.5)
    end

    return attackerPos
end

local function BuildParryTest(key, attackerPos, attackerLook, hitboxSize, localPosition)
    if not key or not attackerPos or not attackerLook or not hitboxSize then return end

    local profile = parryProfiles[parryMode]
    if not profile then return end

    local attackLength = parryLength
    local backwardRange = 0

    local kp = GetParryOrigin(key, attackerPos, localPosition)
    local kl = attackerLook
    local forward = vector.create(kl.x, 0, kl.z)
    local magnitude = vector.magnitude(forward)
    if magnitude == 0 then return end

    forward /= magnitude

    local right = vector.create(-forward.z, 0, forward.x)
    local innerRadius, outerRadius, halfHeight = GetQueryRadii(hitboxSize)
    local queryRadius = profile.RadiusMode == "Outer" and outerRadius or innerRadius
    local halfWidth = parryWidth / 2
    local innerCircle = profile.InnerRadius
    local hasInnerCircle = innerCircle ~= nil

    local function Inside(lp)
        local offset = lp - kp
        local horizontal = vector.create(offset.x, 0, offset.z)
        local distance = vector.magnitude(horizontal)
        local forwardDistance = vector.dot(offset, forward)
        local sideDistance = vector.dot(offset, right)

        if math.abs(offset.y) > attackHeight / 2 + halfHeight then return false end

        if profile.Shape == "Rectangle" then
            return DistanceToRectangle(forwardDistance, sideDistance, attackLength, halfWidth) <= queryRadius
        end

        if profile.Shape == "Circle" then
            return distance <= attackLength + queryRadius
        end

        if hasInnerCircle and distance <= innerCircle + queryRadius then return true end

        if DistanceToRectangle(forwardDistance, sideDistance, attackLength, halfWidth, backwardRange) <= queryRadius then
            return true
        end

        if distance > attackLength + queryRadius then return false end
        if distance <= queryRadius then return true end

        local halfAngle = math.rad(profile.Angle / 2)
        local anglePadding = math.asin(math.clamp(queryRadius / distance, 0, 1))
        local allowedAngle = math.min(math.pi, halfAngle + anglePadding)

        return forwardDistance / distance >= math.cos(allowedAngle)
    end

    local rectRadius = math.sqrt((math.max(attackLength, backwardRange) + queryRadius) ^ 2 + (halfWidth + queryRadius) ^ 2)
    local maxRadius = math.max(attackLength + queryRadius, hasInnerCircle and (innerCircle + queryRadius) or 0, rectRadius) + 1

    return Inside, kp, forward, right, maxRadius
end

local function ShouldParry(key, attackerPos, attackerLook, hitboxSize, localPosition)
    local Inside = BuildParryTest(key, attackerPos, attackerLook, hitboxSize, localPosition)
    return Inside and Inside(localPosition) or false
end

local function WorldToScreen(position)
    local p, visible = Camera:WorldToScreenPoint(position)
    if not visible then return nil end
    return Vector2.new(p.X, p.Y)
end

local function RenderParryShape(snapshot)
    local key = snapshot.Key
    local Inside, kp, forward, right, maxRadius = BuildParryTest(key, snapshot.Position, snapshot.LookVector, localSize, localPos)
    if not Inside then return end

    local segments = 36
    local searchSteps = 6
    local points = {}

    for i = 0, segments - 1 do
        local angle = -math.pi + (i / segments) * math.pi * 2
        local ca = math.cos(angle)
        local sa = math.sin(angle)
        local low = 0
        local high = maxRadius

        for _ = 1, searchSteps do
            local mid = (low + high) / 2
            local point = kp + forward * (mid * ca) + right * (mid * sa)
            local testPoint = vector.create(point.x, kp.y, point.z)

            if Inside(testPoint) then low = mid else high = mid end
        end

        local worldPoint = kp + forward * (low * ca) + right * (low * sa)
        points[#points + 1] = WorldToScreen(worldPoint)
    end

    local color = ParryColor
    local attackUntil = attackVisUntil[key]

    if attackUntil then
        if os.clock() < attackUntil then
            color = ParryAttackColor
        else
            attackVisUntil[key] = nil
        end
    end

    local center = WorldToScreen(kp)
    if center then
        for i = 1, #points do
            local a = points[i]
            local b = points[i % #points + 1]
            if a and b then DrawingImmediate.FilledTriangle(center, a, b, color, .15) end
        end
    end

    for i = 1, #points do
        local a = points[i]
        local b = points[i % #points + 1]
        if a and b then DrawingImmediate.Line(a, b, color, 1, 2, 1) end
    end
end

local function IsTeammate(localParts, parts)
    if not bTeamCheck then return false end

    local mine, theirs
    if teamCheckMode == "Parent name" then
        mine, theirs = localParts.ParentName, parts.ParentName
    else
        mine, theirs = localParts.TeamName, parts.TeamName
    end

    return mine ~= nil and mine == theirs
end

local function ParryChecker(key, root, attackData)
    if activeAttacks[key] ~= attackData then return end

    local started = os.clock()
    local okPing, ping = pcall(function()
        return game:GetPing() / 1000
    end)
    if not okPing or type(ping) ~= "number" then ping = 0 end

    local parryStartDelay = math.max(0, parryWindup + parryDelay - ping - parrySafety)
    local parryEndDelay = math.max(0, parryWindup + parryDelay + parryAttackTime - ping - parrySafety - .05)

    if parryStartDelay > 0 then
        task.wait(parryStartDelay)
    end

    while os.clock() - started < parryEndDelay do
        if not active or not bAutoParry or activeAttacks[key] ~= attackData then break end

        local localChar = LocalPlayer.Character
        local localParts = localChar and IsModel(localChar) and CharacterParts(localChar, LocalPlayer)
        local okPoll, attackerPos, attackerLook, localPosition = pcall(function()
            return root.Position, root.LookVector, localParts.Root.Position
        end)

        if okPoll and attackerPos and localParts.Size and ShouldParry(key, attackerPos, attackerLook, localParts.Size, localPosition) then
            if activeAttacks[key] == attackData then activeAttacks[key] = nil end

            parryLabel.Visible = true
            PressKey(parryKeyName)
            task.wait(.9)
            parryLabel.Visible = false

            break
        end

        task.wait(.01)
    end

    if activeAttacks[key] == attackData then activeAttacks[key] = nil end
end

local function ParryStep()
    local now = os.clock()

    if now >= viewportTimer then
        viewportTimer = now + .5
        local okView, view = pcall(function()
            return Camera.ViewportSize
        end)
        if okView and view then viewport = view end
        statusLabel.Position = Vector2.new(viewport.X / 2, viewport.Y * .75 - statusLabel.Size)
    end

    local pressed = false

    if bAutoParry and not bPickingKey then
        for _, key in getpressedkeys() do
            if key == parryKeybind then
                pressed = true
                break
            end
        end
    end

    if pressed and not tempActive then
        tempActive = true
        active = not active
        statusLabel.Visible = active
        table.clear(activeAttacks)
        table.clear(trackStates)

        if not active then
            parryLabel.Visible = false
        end
    elseif not pressed then
        tempActive = false
    end

    if parryLabel.Visible then
        parryLabel.Position = Vector2.new(viewport.X / 2 + math.random(-5, 5), viewport.Y / 2 - parryLabel.Size / 2 + math.random(-5, 5))
    end

    if not bAutoParry or not active or not offsets then
        parrySnapshot = {}
        localRoot, localPos, localSize = nil, nil, nil
        if next(trackStates) then table.clear(trackStates) end
        return
    end

    local localChar = LocalPlayer.Character
    local localParts = localChar and IsModel(localChar) and CharacterParts(localChar, LocalPlayer)
    if not localParts or not localParts.Root then
        parrySnapshot = {}
        localRoot, localPos, localSize = nil, nil, nil
        return
    end

    local myPosition = localParts.Root.Position
    localRoot, localPos, localSize = localParts.Root, myPosition, localParts.Size

    local watchSaved = #savedOrder > 0
    local seenTracks = {}
    local snapshot = {}

    for _, player in Players:GetChildren() do
        if player == LocalPlayer then continue end

        local char = player.Character
        if not char or not IsModel(char) then continue end

        local parts = CharacterParts(char, player)
        local root = parts.Root
        if not root or IsTeammate(localParts, parts) then continue end

        local okRoot, rootPosition, rootLook = pcall(function()
            return root.Position, root.LookVector
        end)
        if not okRoot or not rootPosition then
            parts.Expires = 0
            continue
        end

        UpdatePrediction(parts.Id, rootPosition)

        snapshot[#snapshot + 1] = {Key = parts.Id, Root = root, Position = rootPosition, LookVector = rootLook}

        if not watchSaved or not parts.Animator then continue end

        local ok, list = pcall(ActiveAnimations, parts.Animator, matchMode == "Name")
        if not ok then
            parts.Expires = 0
            continue
        end

        for _, animation in list do
            if not IsSaved(animation) then continue end

            local track = animation.Track
            seenTracks[track] = true
            if trackStates[track] then continue end
            trackStates[track] = true

            local previous = activeAttacks[parts.Id]
            if previous and now - previous.Started < .2 then continue end

            local attackData = {Started = now}
            activeAttacks[parts.Id] = attackData
            attackVisUntil[parts.Id] = now + parryWindup + parryDelay + parryAttackTime
            task.spawn(ParryChecker, parts.Id, root, attackData)
        end
    end

    for track in trackStates do
        if not seenTracks[track] then
            trackStates[track] = nil
        end
    end

    parrySnapshot = snapshot
end

task.spawn(function()
    while _G.AnimationWatcherRun == runId do
        pcall(WatchStep)
        task.wait(watchDelay)
    end
end)

task.spawn(function()
    while _G.AnimationWatcherRun == runId do
        pcall(ParryStep)
        task.wait(parryLoopDelay)
    end
end)

RunService.Render:Connect(function()
    if _G.AnimationWatcherRun ~= runId then return end

    for _, label in {statusLabel, parryLabel} do
        if label.Visible then
            DrawingImmediate.OutlinedText(label.Position, label.Size, label.Color, 1, label.Text, true)
        end
    end

    if bShowParry and active and localSize then
        if localRoot then
            local ok, pos = pcall(function()
                return localRoot.Position
            end)
            if ok and pos then localPos = pos end
        end

        for _, snapshot in parrySnapshot do
            local ok, pos, look = pcall(function()
                return snapshot.Root.Position, snapshot.Root.LookVector
            end)
            if ok and pos and look then
                snapshot.Position = pos
                snapshot.LookVector = look
            end
            RenderParryShape(snapshot)
        end
    end

    if targetRoot and targetPosition then
        local ok, pos = pcall(function()
            return targetRoot.Position
        end)
        if ok and pos then targetPosition = pos end
    end

    if not targetPosition then return end

    local center, visible = Camera:WorldToScreenPoint(targetPosition)
    if not visible then return end

    local last
    for i = 0, circleSegments do
        local angle = i / circleSegments * math.pi * 2
        local point = Vector2.new(center.X + math.cos(angle) * circleRadius, center.Y + math.sin(angle) * circleRadius)
        if last then
            DrawingImmediate.Line(last, point, CircleColor, 1, 1, 2)
        end
        last = point
    end
end)

print("Loaded")
