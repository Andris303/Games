--!strict
--!optimize 2

loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Attribute.lua"))()

local RobloxVersion = _G.RobloxVersion or "version-c5aecda2245e4fae"
local O = crypt.json.decode(game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json")).Offsets
local ActiveAnimations = O.Animator.ActiveAnimations
local TrackAnimation = O.AnimationTrack.Animation
local TrackAnimator = O.AnimationTrack.Animator
local LabelText = O.GuiObject.Text
local AnimationId = O.Misc.AnimationId

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local bAutoBlock = false
local bNoSwingCD = false
local blockBusy = false
local swingStates = {}
local list = {}
local SetSwingCD
local SetEjectCD
local lchar
local oldmaxstam = 100
local maximumstam = 100

local ATTACK_DURATION = .35
local START_WIDTH = 7.5
local MAX_WIDTH = 13
local WIDTH_POINT = .75
local END_WIDTH = 5
local EXTRA_FORWARD = 4
local HEIGHT = 6
local ATTACK_LENGTH = 7.5
local EXTRA_HEIGHT = 1
local CLOSE_RADIUS = 3
local MIN_WIDTH_MULTIPLIER = .85

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/UI.lua"))()

local function GetActiveAnimations(animator)
    local result = {}
    local animatorPtr = tonumber(animator.Data)
    local head = memory.readu64(animator, ActiveAnimations)
    local count = memory.readu64(animator, ActiveAnimations + 0x8)
    if not head or head == 0 or not count or count == 0 then return result end

    local node = memory.readu64(head)
    for _ = 1, count do
        if not node or node == 0 or node == head then break end
        local trackPtr = memory.readu64(node + 0x10)
        if trackPtr and trackPtr > 0x100000000 then
            local trackAnimator = memory.readu64(trackPtr + TrackAnimator)
            if trackAnimator == animatorPtr then
                local animationPtr = memory.readu64(trackPtr + TrackAnimation)
                if animationPtr and animationPtr > 0x100000000 then
                    local animation = pointer_to_userdata(animationPtr)
                    result[#result + 1] = {Track = trackPtr, Name = animation.Name, AnimationId = memory.readstring(animationPtr, AnimationId),}
                end
            end
        end
        node = memory.readu64(node)
    end
    return result
end

local function ShouldBlock(kp, kl, lp, prog)
    local forward = vector.create(kl.x, 0, kl.z)
    if vector.magnitude(forward) == 0 then return false end

    forward = forward / vector.magnitude(forward)
    local offset = lp - kp
    local horizontalOffset = vector.create(offset.x, 0, offset.z)
    local horizontalDistance = vector.magnitude(horizontalOffset)
    if horizontalDistance <= CLOSE_RADIUS and math.abs(offset.y) <= (HEIGHT / 2 + EXTRA_HEIGHT) then return true end

    local forwardDistance = vector.dot(offset, forward)
    if forwardDistance < -1 then return false end

    local extraForward = EXTRA_FORWARD
    if prog > .5 then extraForward = EXTRA_FORWARD - (2 * (prog - .5) / .5) end

    local maxForward = ATTACK_LENGTH + extraForward
    if forwardDistance > maxForward then return false end

    local startHalfWidth = START_WIDTH / 2
    local maxHalfWidth = MAX_WIDTH / 2
    local endHalfWidth = END_WIDTH / 2
    local midDistance = maxForward * WIDTH_POINT
    local allowedHalfWidth

    if forwardDistance <= midDistance then
        local alpha = math.clamp(forwardDistance / midDistance, 0, 1)
        allowedHalfWidth = startHalfWidth + (maxHalfWidth - startHalfWidth) * alpha
    else
        local alpha = math.clamp((forwardDistance - midDistance) / (maxForward - midDistance), 0, 1 )
        allowedHalfWidth = maxHalfWidth + (endHalfWidth - maxHalfWidth) * alpha
    end

    if prog > .5 then
        local narrowAlpha = (prog - .5) / .5
        local widthMultiplier = 1 - ((1 - MIN_WIDTH_MULTIPLIER) * narrowAlpha)
        allowedHalfWidth *= widthMultiplier
    end

    if math.abs(offset.y) > (HEIGHT / 2 + EXTRA_HEIGHT) then return false end
    local right = vector.create(-forward.z, 0, forward.x)
    local sideDistance = math.abs(vector.dot(offset, right))
    return sideDistance <= allowedHalfWidth
end

local function GetBlockKey()
    local ok, text = pcall(function()
        local label = LocalPlayer.PlayerGui.MainGui.RoundUI.PlayerUI.Abilities.Folder.Block.Input
        return memory.readstring(label.Data, LabelText)
    end)
    if not ok or not text then return nil end

    text = tostring(text):upper()
    if #text == 1 then return string.byte(text) end
    return nil
end

local function Block()
    if blockBusy then return false end
    local key = GetBlockKey()
    if not key then return false end
    blockBusy = true

    task.spawn(function()
        pcall(keypress, key)
        task.wait(.08)
        pcall(keyrelease, key)
        task.wait(.12)
        blockBusy = false
    end)
    return true
end

local function NormalizeAnimationId(id)
    if not id then return nil end
    id = tostring(id)
    return id:match("%d+") or id
end

local function BuildAnimationNames(char)
    local names = {}
    local folder = char:FindFirstChild("Animations")
    if not folder then return names end

    for _, anim in folder:GetDescendants() do
        if anim:IsA("Animation") then
            local id = NormalizeAnimationId(memory.readstring(anim.Data, AnimationId))
            if id then names[id] = anim.Name end
        end
    end
    return names
end

local function PreData()
    for _, inst in Players:GetChildren() do
        local char = inst.Character
        if not char then continue end
        if not char:FindFirstChildOfClass("Humanoid") then continue end
        if not ESP.IsTracked(char) then ESP.AddPlayer(char, {Player = inst, TeamType = "Parent",}) end
    end
end

local function PreLocal()
    local templist = {}
    local lchar = LocalPlayer.Character
    local lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")

    if bNoSwingCD then
        if SetSwingCD then SetSwingCD("") end
        if SetEjectCD then SetEjectCD("") end
    end

    for _, char in workspace.GameAssets.Teams.Killer:GetChildren() do
        local humanoid = char:FindFirstChildOfClass("Humanoid")
        local animator = humanoid and humanoid:FindFirstChildOfClass("Animator")
        local swing

        if animator then
            local animationNames = BuildAnimationNames(char)
            for _, animation in GetActiveAnimations(animator) do
                local id = NormalizeAnimationId(animation.AnimationId)
                local name = animationNames[id] or animation.Name
                if name == "Swing" then swing = animation break end
            end
        end

        if not swing then
            swingStates[char] = nil
            continue
        end

        templist[#templist + 1] = char
        local state = swingStates[char]

        -- A different track pointer means this is a new Swing, even if the previous Swing is still fading out.
        if not state or state.Track ~= swing.Track then
            state = {Track = swing.Track, Started = os.clock(), Progress = 0, Blocked = false,}
            swingStates[char] = state
        end

        state.Progress = math.clamp((os.clock() - state.Started) / ATTACK_DURATION, 0, 1)
        if not bAutoBlock or state.Blocked or not lroot then continue end

        local kroot = char:FindFirstChild("HumanoidRootPart")
        if not kroot then continue end

        local ok, shouldBlock = pcall(function()
            return ShouldBlock(kroot.Position, kroot.LookVector, lroot.Position, state.Progress)
        end)
        if ok and shouldBlock and Block() then state.Blocked = true end
    end

    list = templist
end

task.spawn(function()
    while true do
        local newlchar = LocalPlayer.Character
        local changedCharacter = newlchar ~= lchar

        if changedCharacter then
            lchar = newlchar
            SetSwingCD = nil
            SetEjectCD = nil
        end

        if lchar and lchar.Parent then
            local team = lchar.Parent.Name

            if team == "Killer" or team == "Survivor" then
                if changedCharacter or oldmaxstam ~= maximumstam then
                    oldmaxstam = maximumstam
                    lchar:FixedSetAttribute("MaxStamina", maximumstam)
                end
            end

            if team == "Killer" then
                SetSwingCD = lchar:PrepareAttributeSetter("SwingCooldown")
                SetEjectCD = lchar:PrepareAttributeSetter("EjectCooldown")
            else
                SetSwingCD = nil
                SetEjectCD = nil
            end
        end

        task.wait(.25)
    end
end)

local window = UI:createwindow({
    Title = "Die of Death | Andris",
    Version = "VX",
    Keybind = "RightShift",
    ConfigFolder = "AndrisDOD",
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

window:createtoggle(tabMain, {
    Name = "Auto Block",
    Col = 1,
    Default = false,
    Callback = function(val)
        bAutoBlock = val
        if not val then table.clear(swingStates) end
    end
})

window:createtoggle(tabMain, {
    Name = "No killer M1 cooldown",
    Col = 1,
    Default = false,
    Callback = function(val)
        bNoSwingCD = val
    end
})

window:createslider(tabMain, {
    Name = "Maximum stamina",
    Col = 2, 
    Min = 10, Max = 1000, Default = 100,
    Step = 5,
    Callback = function(val)
        maximumstam = val
    end
})

print("Loaded")

RunService.PreLocal:Connect(PreLocal)
RunService.PreData:Connect(PreData)
