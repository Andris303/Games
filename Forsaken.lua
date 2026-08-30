--!strict
--!optimize 2

-- Absolutely, you're right. Here's a complete script for Forsaken, that's made specifically for severe's lua enviroment. Keep in mind, that I am a large-language model (LLM) and I can't test the actual script. I will generate code for you, but you still have to test it, and ensure it functions properly. Here is a Forsaken script, built with Ingame ESP, and auto block, crafted to work exactly like you needed:

local offset = _G.LabelTextOffset or 0xdf8
local abspos = _G.AbsolutePosition or 0x10c
local abssize = _G.AbsoluteSize or 0x114

if game.GameId == 6331902150 then

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/UI.lua"))()
local h = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Map = workspace.Map
local Ingame = Map.Ingame
local Killers = workspace.Players.Killers
local Survivors = workspace.Players.Survivors
local ItemCache = {}
local bSurv = false
local bKill = false
local bInUI = false
local bESP = true
local bHighlight = true
local bTextName = true
local bAutoBlock = false
local bShowBlock = false
local bChangingBind = false
local bAutoParry = false
local bTempParry = false
local bShowLine = false
local bShowLocalLine = false
local bChanceAimbot = false
local bStopStam = false
local bShowTimer = false
local bAutoGen = false
local TempAutoGen = false
local AutoGenTimer = 0
local AutoGenTime = 4
local AutoGenRandom = 1
local LastPuzzleSignature
local KillerAbTime = {}
local KillerAb = {}
local ActiveAttacks = {}
local ActiveLines = {}
local PartCache = {}
local PartCacheRefresh = {}
local GeneratorCache = {}
local tempactive = false
local active = false
local bt = Drawing.new("Text")
local bt2 = Drawing.new("Text")
local bt3 = Drawing.new("Text")
local viewport = Camera.ViewportSize
local isguest = false
local FocusTimer = 0
local bBlockOnInv = false
local noliname
local window
local keybindlabel
local LastValueSync = 0
local LastAttackScan = 0
local delay_minus = 0
local LocalTeam = "None"
local tempstunning = false

local suc2, bool2 = pcall(function()
    return LocalPlayer.Character.Name == "Guest1337"
end)

if suc2 and bool2 then
    isguest = true
    bt.Text = "AUTO BLOCK"
    bt.Color = Color3.fromRGB(248,131,121)
else
    isguest = false
    bt.Color = Color3.fromRGB(109,129,150)
    bt.Text = "AUTO BLOCK (inactive)"
end

bt.Size = 30
bt.Font = 0
local length = bt.TextBounds.x
local height = bt.TextBounds.y
bt.Position = Vector2.new(viewport.x / 2 - length / 2, (viewport.y - viewport.y / 4) - height)
bt.Outline = true
bt.Visible = false

bt2.Text = "BLOCK"
bt2.Size = 35
bt2.Font = 0
local length2 = bt2.TextBounds.x
local height2 = bt2.TextBounds.y
bt2.Position = Vector2.new(viewport.x / 2 - length2 / 2, viewport.y / 2 - height2 / 2)
bt2.Color = Color3.fromRGB(255,25,25)
bt2.Outline = true
bt2.Visible = false

bt3.Text = "Real timer: 0:00"
bt3.Size = 30
bt3.Font = 0
local length3 = bt3.TextBounds.x
local height3 = bt3.TextBounds.y
bt3.Position = Vector2.new(viewport.x / 2 - length3 / 2, viewport.y / 10 - height3 / 2)
bt3.Color = Color3.fromRGB(214,181,136)
bt3.Outline = true
bt3.Visible = false

local codetable = {
    LeftShift = 0xa0,
    RightShift = 0xa1,
    LeftCtrl = 0xa2,
    RightCtrl = 0xa3,
    LeftAlt = 0xa4,
    RightAlt = 0xa5,
}

local function GetBinds()
    local ab1 = LocalPlayer.PlayerData.Settings.Keybinds.AltAbility1.Value
    local ab3 = LocalPlayer.PlayerData.Settings.Keybinds.AltAbility3.Value
    local sprint = LocalPlayer.PlayerData.Settings.Keybinds.Sprinting.Value
    
    return ab1, ab3, sprint
end

local function GetKeycode(str)
    if #str == 1 then
        return string.byte(string.upper(str))
    elseif codetable[str] then
        return codetable[str]
    end
end

local KEYBIND = "V"
local s, blockkeystr, parrykeystr, sprintkeystr = pcall(GetBinds)
local BLOCK_KEY, PARRY_KEY, SPRINT_KEY
if s then
    BLOCK_KEY = GetKeycode(blockkeystr)
    PARRY_KEY = GetKeycode(parrykeystr)
    SPRINT_KEY = GetKeycode(sprintkeystr)
end
local PARRY_DELAY = 0
local DELAY = 0
local ATTACK_LINGER = 35
local START_WIDTH = 7.5
local MAX_WIDTH = 13
local WIDTH_POINT = .75
local END_WIDTH = 5
local EXTRA_FORWARD = 4
local HEIGHT = 6
local ATTACK_LENGTH = 7.5
local EXTRA_HEIGHT = 1
local CLOSE_RADIUS = 5
local MIN_WIDTH_MULTIPLIER = .85

local EntSounds = {"rbxassetid://135854269153231", "rbxassetid://105934041806374", "rbxassetid://130247421279831", "rbxassetid://107039569833867", "rbxassetid://100150551345482", "rbxassetid://91488514366191", "rbxassetid://101739035738613", "rbxassetid://75675413747752", "rbxassetid://78992685630984", "rbxassetid://130994756001980", "rbxassetid://102799653891975"}
local MassInfSounds = {"rbxassetid://70845653728841", "rbxassetid://73504812754586", "rbxassetid://97061990471922", "rbxassetid://85647688284850", "rbxassetid://83349035240699"}
local RejuvSounds = {"rbxassetid://109351069746096", "rbxassetid://96908026446030", "rbxassetid://120877949577353", "rbxassetid://108829275072240", "rbxassetid://134770542596997", "rbxassetid://99174224422295", "rbxassetid://135436619867662", "rbxassetid://85069492524977", "rbxassetid://127962518201254", "rbxassetid://90613634629510"}
local CorruptSounds = {"rbxassetid://75210765058860", "rbxassetid://87883890694872", "rbxassetid://109525294317144", "rbxassetid://119285029803606", "rbxassetid://100163947838165", "rbxassetid://74901476984677", "rbxassetid://99582226869588", "rbxassetid://96733419994623", "rbxassetid://137444402376234", "rbxassetid://108685516047210"}

local SixerRig = {
    RigType = "R15",
    HumanoidRootPart = "HumanoidRootPart",
    Head = "Head",
    UpperTorso = "Body",
    LowerTorso = "Waist",
    RightUpperArm = "Right Arm",
    RightLowerArm = "Right lowerarm",
    RightHand = "Right hand",
    LeftUpperArm = "Left Arm",
    LeftLowerArm = "Left lowerarm",
    LeftHand = "Left Hand",
    RightUpperLeg = "Right Leg",
    LeftUpperLeg = "Left Leg",
    RightLowerLeg = "Right Lowleg",
    RightFoot = "Right Lowerleg",
    LeftLowerLeg = "Left Lowleg",
    LeftFoot = "Left Lowerleg",
}

local ColorPickers = {
    danger = "Projectile color",
    trap = "Trap color",
    slightdanger = "Passive trap color",
    neutral = "Clone color",
    azure = "Azure ability color",
    autoblock = "Auto block visual color",
    yellow = "Minion color",
    generator = "Generator color",
    medkit = "Medkit color",
    cola = "Bloxy cola color",
    lineprim = "Show projectile line color",
    linesec = "Show projectile text color",
}

local KillerData = {
    ["Default"] = {
        DELAY = 0,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 6,
    },
    ["c00lkidd"] = {
        DELAY = 0,
        CLOSE_RADIUS = 4,
        ATTACK_LINGER = 30,
        ATTACK_LENGTH = 5,
        HEIGHT = 6,
    },
    ["Slasher"] = {
        DELAY = 0,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 6,
    },
    ["JohnDoe"] = {
        DELAY = .2,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 6,
    },
    ["Noli"] = {
        DELAY = .15,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 8,
        HEIGHT = 6,
    },
    ["1x1x1x1"] = {
        DELAY = .2,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 6,
    },
    ["Sixer"] = {
        DELAY = .1,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 9.5,
        HEIGHT = 8,
    },
    ["Nosferatu"] = {
        DELAY = .1,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 8.5,
        HEIGHT = 6,
    },
    ["Azure"] = {
        DELAY = .02,
        CLOSE_RADIUS = 5,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 8.5,
        HEIGHT = 6,
    },
}

local c = {
    danger = Color3.fromRGB(224,17,95),
    slightdanger = Color3.fromRGB(198,115,115),
    neutral = Color3.fromRGB(109,129,150),
    generator = Color3.fromRGB(234,162,33),
    cola = Color3.fromRGB(45,104,196),
    medkit = Color3.fromRGB(255,29,141),
    trap = Color3.fromRGB(179,27,27),
    azure = Color3.fromRGB(127,0,255),
    yellow = Color3.fromRGB(241,195,56),
    autoblock = Color3.fromRGB(241,195,56),
    lineprim = Color3.fromRGB(179,27,27),
    linesec = Color3.fromRGB(241,195,56),
}

local Names = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "VineModel", "GroundBulbModel", "GroundBulb", "BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile", "Medkit", "BloxyCola", "MisterBeast", "Noli"}
local SNames = {"BuildermanDispenser", "BuildermanSentry", "Pizza", "GraffitiCL", "CrystalProjectile", "TaphTripwire", "SubspaceTripmine"}
local KNames = {"SpikeCollision", "Shadow", "VineModel", "GroundBulbModel", "GroundBulb", "Medkit", "BloxyCola", "MisterBeast", "Noli", "Puddle"}
local PNames = {"TaphTripwire", "SubspaceTripmine", "Puddle", "Shockwave"}

local NameColors = {
    shockwave = "danger",
    Shockwave = "danger",
    Swords = "danger",
    SpikeCollision = "slightdanger",
    HumanoidRootProjectile = "danger",
    Voidstar = "danger",
    Bats = "danger",
    Shadow = "trap",
    VineModel = "trap",
    GroundBulbModel = "trap",
    GroundBulb = "trap",
    MisterBeast = "azure",
    Azure = "azure",
    Noli = "neutral",
    ["1x1x1x1Zombie"] = "yellow",
    Trail = "slightdanger",
    Shadows = "trap",
    Puddle = "slightdanger",
    FakeGenerator = "neutral",
    TaphTripwire = "trap",
    SubspaceTripmine = "danger",
    BuildermanDispenser = "slightdanger",
    BuildermanSentry = "trap",
    ["007n7"] = "neutral",
    Pizza = "slightdanger",
    GraffitiCL = "slightdanger",
    CrystalProjectile = "danger",
    Medkit = "medkit",
    BloxyCola = "cola",
}

local FullNames = {
    BuildermanDispenser = "Builderman Dispenser",
    BuildermanSentry = "Builderman Sentry",
    ["007n7"] = "007n7 Clone",
    Pizza = "Elliot Pizza",
    GraffitiCL = "Vee Graffiti",
    TaphTripwire = "Taph Tripwire",
    SubspaceTripmine = "Taph Mine",
    Shadow = "Digital Footprint",
    VineModel = "Azure Vine",
    GroundBulbModel = "Azure Bulb",
    GroundBulb = "Azure Bulb",
    MisterBeast = "Golem",
    ["1x1x1x1Zombie"] = "Zombie",
    FakeGenerator = "Fake Gen",
    Azure = "Azure",
    Noli = "Fake Noli",
    Medkit = "Medkit",
    BloxyCola = "Cola",
}

local BodyData = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

local function GetGenPer(num)
    if num == 21 then return "20%" end
    if num == 42 then return "40%" end
    if num == 63 then return "60%" end
    if num == 84 then return "80%" end
    return "0%"
end

local function GetPart(inst)
    local ClassName = inst.ClassName

    if ClassName == "Part" or ClassName == "UnionOperation" or ClassName == "MeshPart" then
        return inst
    end

    if inst:FindFirstChild("Humanoid") then
        local ReturnTable = {}

        for _, part in BodyData do
            local thething = inst:FindFirstChild(part)
            if thething then
                table.insert(ReturnTable, thething)
            end
        end

        if #ReturnTable ~= 0 then return ReturnTable end
    end

    local Name = inst.Name
    if Name == "MisterBeast" then return inst:FindFirstChildOfClass("MeshPart") end
    if Name == "VineModel" then return inst:FindFirstChild("Tentacle") end

    local s, p = pcall(function()
        return inst.PrimaryPart
    end)
    if s and p then return p end

    return inst:FindFirstChildOfClass("Part") or inst:FindFirstChildOfClass("MeshPart") or inst:FindFirstChildOfClass("UnionOperation")
end

local function RemoveCachedItem(id)
    ItemCache[id] = nil
    PartCache[id] = nil
    PartCacheRefresh[id] = nil
    GeneratorCache[id] = nil
end

local function Highlight(inst, color)
    local s, p = pcall(function()
        return inst.Position
    end)
    if s then
        h.Highlight(inst, color, .18, .7, .7)
    end
end

local function ShouldBlock(kp, kl, lp, prog)
    local forward = vector.create(kl.x, 0, kl.z)
    if vector.magnitude(forward) == 0 then
        return false
    end

    forward = forward / vector.magnitude(forward)
    local offset = lp - kp
    local horizontalOffset = vector.create(offset.x, 0, offset.z)
    local horizontalDistance = vector.magnitude(horizontalOffset)

    if horizontalDistance <= CLOSE_RADIUS and math.abs(offset.y) <= (HEIGHT / 2 + EXTRA_HEIGHT) then
        return true
    end

    local forwardDistance = vector.dot(offset, forward)
    if forwardDistance < -1 then
        return false
    end

    local extraForward = EXTRA_FORWARD
    if prog > .5 then
        extraForward = EXTRA_FORWARD - (2 * (prog - .5) / .5)
    end

    local maxForward = ATTACK_LENGTH + extraForward
    if forwardDistance > maxForward then
        return false
    end

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

    if math.abs(offset.y) > (HEIGHT / 2 + EXTRA_HEIGHT) then
        return false
    end

    local right = vector.create(-forward.z, 0, forward.x)
    local sideDistance = math.abs(vector.dot(offset, right))

    return sideDistance <= allowedHalfWidth
end

local function RenderBlockShape(KRoot, LRoot, prog)
    if not KRoot or not LRoot then return end

    local kp = KRoot.Position
    local kl = KRoot.LookVector
    local forward = vector.create(kl.X, 0, kl.Z)

    if vector.magnitude(forward) == 0 then return end

    forward = forward / vector.magnitude(forward)
    local right = vector.create(-forward.Z, 0, forward.X)
    local extraForward = EXTRA_FORWARD

    if prog > .5 then
        extraForward = 4 - (2 * (prog - .5) / .5)
    end

    local maxForward = ATTACK_LENGTH + extraForward
    local startHalfWidth = START_WIDTH / 2
    local maxHalfWidth = MAX_WIDTH / 2
    local endHalfWidth = END_WIDTH / 2
    local midDistance = maxForward * WIDTH_POINT

    local function GetHalfWidth(distance)
        local thing
        if distance <= midDistance then
            local alpha = math.clamp(distance / midDistance, 0, 1)
            thing = startHalfWidth + (maxHalfWidth - startHalfWidth) * alpha
        else
            local alpha = math.clamp((distance - midDistance) / (maxForward - midDistance), 0, 1)
            thing = maxHalfWidth + (endHalfWidth - maxHalfWidth) * alpha
        end
        if prog > .5 then
            local narrowAlpha = (prog - .5) / .5
            local widthMultiplier = 1 - ((1 - MIN_WIDTH_MULTIPLIER) * narrowAlpha)
            thing *= widthMultiplier
        end
        return thing
    end

    local function WorldToScreen(position)
        local p, visible = Camera:WorldToScreenPoint(position)
        if not visible then
            return nil
        end
        return Vector2.new(p.X, p.Y)
    end

    local startLeft = kp - right * startHalfWidth
    local startRight = kp + right * startHalfWidth
    local midCenter = kp + forward * midDistance
    local midLeft = midCenter - right * GetHalfWidth(midDistance)
    local midRight = midCenter + right * GetHalfWidth(midDistance)
    local endCenter = kp + forward * maxForward
    local endLeft = endCenter - right * endHalfWidth
    local endRight = endCenter + right * endHalfWidth

    local points = {
        WorldToScreen(startLeft),
        WorldToScreen(midLeft),
        WorldToScreen(endLeft),
        WorldToScreen(endRight),
        WorldToScreen(midRight),
        WorldToScreen(startRight),
    }

    local fillOpacity = .2

    if points[1] and points[2] and points[3] and points[4] and points[5] and points[6] then
        DrawingImmediate.FilledTriangle(points[1], points[2], points[3], c.autoblock, fillOpacity)
        DrawingImmediate.FilledTriangle(points[1], points[3], points[4], c.autoblock, fillOpacity)
        DrawingImmediate.FilledTriangle(points[1], points[4], points[5], c.autoblock, fillOpacity)
        DrawingImmediate.FilledTriangle(points[1], points[5], points[6], c.autoblock, fillOpacity)
    end

    for i = 1, #points do
        local a = points[i]
        local b = points[i % #points + 1]
        if a and b then
            DrawingImmediate.Line(a, b, c.autoblock, 1, 2, 1)
        end
    end
end

local function BlockChecker(KRoot, LRoot, inst, attackData)
    if ActiveAttacks[KRoot] ~= attackData then return end

    if DELAY > 0 then
        local ping = game:GetPing()
        if ping < 150 then
            task.wait(DELAY)
        end
    end

    local c = 0

    while c <= ATTACK_LINGER do
        if not active or not bAutoBlock then break end
        c += 1
        local attackProgress = c / ATTACK_LINGER
        if ActiveAttacks[KRoot] then
            ActiveAttacks[KRoot].Progress = attackProgress
        end

        local s, t = pcall(function()
            return {
                kp = KRoot.Position,
                kl = KRoot.LookVector,
                lp = LRoot.Position,
            }
        end)
        if s and t then
            if ShouldBlock(t.kp, t.kl, t.lp, attackProgress) then
                if not bBlockOnInv then
                    if inst:GetAttribute("Invincible") or inst:GetAttribute("StunnedDisabled") then
                        task.wait(.01)
                        continue
                    end
                end

                if ActiveAttacks[KRoot] == attackData then
                    ActiveAttacks[KRoot] = nil
                end

                if isguest then
                    bt2.Visible = true
                    keypress(BLOCK_KEY)
                    task.wait(.1)
                    keyrelease(BLOCK_KEY)
                    task.wait(.9)
                end

                if ActiveAttacks[KRoot] == attackData then
                    bt2.Visible = false
                end

                break
            end
        end
        task.wait(.01)
    end
    if ActiveAttacks[KRoot] == attackData then
        ActiveAttacks[KRoot] = nil
    end
end

local function UpdateValues()
    local now = os.clock()
    if now - LastValueSync < .1 then
        return
    end
    LastValueSync = now

    local syncautoblock = window:getvalue("Enable Auto block")
    local syncesp = window:getvalue("Enable ESP")
    local synckeybind = window:getvalue("AutoBlockKeybind")
    local syncshowtimer = window:getvalue("Show round timer when hallucinating")

    bBlockOnInv = window:getvalue("Block when the killer is stun immune")
    bShowBlock = window:getvalue("Show Auto block range")
    bHighlight = window:getvalue("Highlight part")
    bTextName = window:getvalue("Show object name")
    bAutoParry = window:getvalue("Guest 1337 auto parry")
    PARRY_DELAY = window:getvalue("Auto parry delay")
    AutoGenTime = window:getvalue("Delay before starting puzzle (seconds)")
    AutoGenRandom = window:getvalue("Randomize time by (seconds)")
    bShowLine = window:getvalue("Show attack path")
    bShowLocalLine = window:getvalue("Show path when you're killer")
    bChanceAimbot = window:getvalue("Chance aimbot")
    bShowhidden = window:getvalue("Unhide playtime of all players")
    bStopStam = window:getvalue("Safe sprint")
    bAutoGen = window:getvalue("Auto complete generators")

    if bAutoBlock ~= syncautoblock then
        KillerAb = {}
        KillerAbTime = {}
        tempactive = false
		active = false
        bt.Visible = false
        bt2.Visible = false

        bAutoBlock = syncautoblock
    end
    if keybindlabel.Txt.Text ~= "Current keybind: " .. synckeybind then
        KEYBIND = synckeybind
        keybindlabel.Txt.Text = "Current keybind: " .. synckeybind
    end
    if bESP ~= syncesp then
        bESP = syncesp
		if not bESP then
			ItemCache = {}
            PartCache = {}
            GeneratorCache = {}
		end
    end
    if bShowTimer ~= syncshowtimer then
        bShowTimer = syncshowtimer
    end

    for name, inst in ColorPickers do
        local newval = window:getvalue(inst)
        if c[name] ~= newval then
            c[name] = newval
        end
    end
end

local function DrawText(part, text, color, size)
    local nsize = size or 13
    local s, pos = pcall(function()
        return part.Position
    end)
    if s then
        local p, v = Camera:WorldToScreenPoint(pos)
        if v then
            local NewPos = Vector2.new(p.x, p.y - 6.5)
            DrawingImmediate.OutlinedText(NewPos, nsize, color, 1, text, true)
        end
    end
end

local function PredictCurve(p1, t1, p2, t2, p3, t3, future)
    local t = t3 + future
    local d1 = (t1 - t2) * (t1 - t3)
    local d2 = (t2 - t1) * (t2 - t3)
    local d3 = (t3 - t1) * (t3 - t2)

    if d1 == 0 or d2 == 0 or d3 == 0 then
        return p3
    end

    local l1 = ((t - t2) * (t - t3)) / d1
    local l2 = ((t - t1) * (t - t3)) / d2
    local l3 = ((t - t1) * (t - t2)) / d3

    return p1 * l1 + p2 * l2 + p3 * l3
end

local function PredictPosition2(lroot, kroot, p1, t1)
    local p3 = kroot.Position
    local t3 = os.clock()

    local MIN_DISTANCE = 0
    local MAX_DISTANCE = 92

    local distance = vector.magnitude(p3 - lroot.Position)
    local alpha = math.clamp((distance - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE), 0,  1)

    local prediction = .2 * (alpha ^ .3)
    local dt = t3 - t1
    if dt <= 0 then
        return Vector3.new(p3.X, lroot.Position.Y, p3.Z)
    end
    local velocity = (p3 - p1) / dt
    local predictedPos = p3 + velocity * prediction

    return Vector3.new(predictedPos.X, lroot.Position.Y, predictedPos.Z)
end

local function Parry(lchar)
    local lroot = lchar:FindFirstChild("HumanoidRootPart")
    local killer = Killers:FindFirstChildOfClass("Model")
    local kroot = killer and killer:FindFirstChild("HumanoidRootPart")

    if lroot and kroot then
        if PARRY_DELAY ~= 0 then
            task.wait(PARRY_DELAY)
        end

        task.wait(.15)

        local p1 = kroot.Position
        local t1 = os.clock()

        keypress(PARRY_KEY)
        task.wait(.1)

        lroot.CFrame = CFrame.lookAt(lroot.Position, PredictPosition2(lroot, kroot, p1, t1))

        keyrelease(PARRY_KEY)
    end
end

local function DrawWorldLine(startPos, endPos)
    local offseta = endPos - startPos
    local dist = vector.magnitude(offseta)

    if dist <= 0 then return end

    local startScreen, startVisible = Camera:WorldToScreenPoint(startPos)
    local endScreen, endVisible = Camera:WorldToScreenPoint(endPos)

    if startVisible and endVisible then
        DrawingImmediate.Line(Vector2.new(startScreen.X, startScreen.Y), Vector2.new(endScreen.X, endScreen.Y), c.lineprim, 1, 4, 1)
        return
    end

    local direction = offseta / dist
    local SEGMENT_LENGTH = 5
    local segments = math.max(1, math.ceil(dist / SEGMENT_LENGTH))
    local segml = dist / segments

    for i = 0, segments - 1 do
        local d1 = i * segml
        local d2 = math.min((i + 1) * segml, dist)
        local p1 = startPos + direction * d1
        local p2 = startPos + direction * d2
        local a, aVisible = Camera:WorldToScreenPoint(p1)
        local b, bVisible = Camera:WorldToScreenPoint(p2)

        if aVisible and bVisible then
            DrawingImmediate.Line(Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), c.lineprim, 1, 4, 1)
        end
    end
end

local function DrawLookLine(root, dist, right, down)
    local startPos = root.Position
    right = right or 0
    down = down or 0
    local direction = root.LookVector + root.RightVector * right - root.UpVector * down
    direction = direction / vector.magnitude(direction)

    local SEGMENT_LENGTH = 5
    local segments = math.max(1, math.ceil(dist / SEGMENT_LENGTH))
    local segml = dist / segments

    for i = 0, segments - 1 do
        local d1 = i * segml
        local d2 = math.min((i + 1) * segml, dist)
        local p1 = startPos + direction * d1
        local p2 = startPos + direction * d2
        local a, aVisible = Camera:WorldToScreenPoint(p1)
        local b, bVisible = Camera:WorldToScreenPoint(p2)

        if aVisible and bVisible then
            DrawingImmediate.Line(Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), c.lineprim, 1, 4, 1)
        end
    end
end

local function DrawAbilityName(data, root)
    DrawText(root, data.Name or data.Ability.Name, c.linesec, 25)
end

local function GetTrackedPosition(obj)
    if not obj or not obj.Parent then
        return nil
    end

    local s, pos = pcall(function()
        return obj.Position
    end)

    if s and pos then
        return pos
    end

    local s2, primary = pcall(function()
        return obj.PrimaryPart.Position
    end)

    if s2 and primary then
        return primary
    end

    return nil
end

local function HasSound(root, sounds)
    for _, sound in sounds do
        if root:FindFirstChild(sound) then
            return true
        end
    end

    return false
end

local function SnapshotObjects()
    local result = {}

    for _, obj in Ingame:GetChildren() do
        result[obj] = true
    end

    return result
end

local function FindNewObject(data, root, names)
    for _, obj in Ingame:GetChildren() do
        if not data.KnownObjects[obj] and names[obj.Name] then
            local pos = GetTrackedPosition(obj)

            if pos and vector.magnitude(root.Position - pos) < 30 then
                return obj
            end
        end
    end
end

local function DrawMovementFromOrigin(data, root)
    local currentPos = root.Position
    local movement = Vector3.new(currentPos.X - data.Origin.X, currentPos.Y - data.Origin.Y, currentPos.Z - data.Origin.Z)
    local traveled = vector.magnitude(movement)

    if traveled <= .2 then
        DrawLookLine(root, data.Length)
        return
    end

    local direction = movement / traveled
    local destination = Vector3.new(data.Origin.X + direction.X * data.Length, data.Origin.Y + direction.Y * data.Length, data.Origin.Z + direction.Z * data.Length)

    if traveled < data.Length then
        DrawWorldLine(currentPos, destination)
    end
end

local function DrawTrackedObject(data)
    local obj = data.TrackedObject

    if not obj or not obj.Parent then
        data.Finished = true
        return
    end

    local currentPos = GetTrackedPosition(obj)
    if not currentPos then
        data.Finished = true
        return
    end

    if not data.ObjectSamplePos then
        data.ObjectSamplePos = currentPos
        return
    end

    if not data.ObjectDirection then
        local movement = Vector3.new(currentPos.X - data.ObjectSamplePos.X, 0, currentPos.Z - data.ObjectSamplePos.Z)

        local moved = vector.magnitude(movement)
        if moved >= .5 then
            data.ObjectDirection = movement / moved
            data.ObjectDestination = data.ObjectSamplePos + data.ObjectDirection * data.Length
        end
    end

    if data.ObjectDestination then
        DrawWorldLine(currentPos, Vector3.new(data.ObjectDestination.X, currentPos.Y, data.ObjectDestination.Z))
    end
end

local KillerAbilities = {
    c00lkidd = {
        {
            Name = "Walkspeed Override",
            Length = 90,
            Duration = 1.9,
            Check = function(char, root)
                return char:FindFirstChild("c00lgui") ~= nil
            end,
            Draw = function(data, char, root)
                if os.clock() - data.Started < .4 then
                    DrawLookLine(root, data.Length)
                else
                    DrawMovementFromOrigin(data, root)
                end
            end,
        },
    },


    ["1x1x1x1"] = {
        {
            Name = "Entanglement",
            Length = 125,
            Check = function(char, root, data)
                if data then
                    if data.Finished then
                        return HasSound(root, EntSounds)
                    end
                    if data.TrackedObject then
                        return true
                    end
                    if os.clock() - data.Started <= 2 then
                        return true
                    end
                end
                return HasSound(root, EntSounds)
            end,
            Start = function(data)
                data.KnownObjects = SnapshotObjects()
            end,
            Draw = function(data, char, root)
                if data.Finished then
                    return
                end
                if not data.TrackedObject then
                    data.TrackedObject = FindNewObject(data, root,
                        {
                            Swords = true,
                        }
                    )
                    if not data.TrackedObject then
                        DrawLookLine(root, data.Length)
                        return
                    end
                end
                DrawTrackedObject(data)
            end,
        },

        {
            Name = "Mass Infection",
            Length = 630,
            Check = function(char, root, data)
                local active = HasSound(root, MassInfSounds) and not HasSound(root, RejuvSounds)
                if data then
                    if data.Finished then
                        return active
                    end
                    if data.TrackedObject then
                        return true
                    end
                    if os.clock() - data.Started <= 2 then
                        return true
                    end
                end
                return active
            end,
            Start = function(data)
                data.KnownObjects = SnapshotObjects()
            end,
            Draw = function(data, char, root)
                if data.Finished then return end
                if not data.TrackedObject then
                    data.TrackedObject = FindNewObject(data, root,
                        {
                            shockwave = true,
                            Shockwave = true,
                        }
                    )
                    if not data.TrackedObject then
                        DrawLookLine(root, data.Length)
                        return
                    end
                end
                DrawTrackedObject(data)
            end,
        },
    },

    JohnDoe = {
        {
            Name = "Corrupt Energy",
            Length = 125,
            Duration = 3.5,
            TriggerOnce = true,
            Check = function(char, root)
                if HasSound(root, CorruptSounds) then
                    return true
                end
            end,
            Draw = function(data, char, root)
                local WINDUP = 2
                local elapsed = os.clock() - data.Started

                if elapsed < WINDUP then
                    DrawLookLine(root, data.Length)
                    return
                end

                local direction = root.LookVector
                local magnitude = vector.magnitude(direction)

                if magnitude == 0 then return end

                direction /= magnitude
                local endPos = root.Position + direction * data.Length
                local alpha = math.clamp((elapsed - WINDUP) / (data.Duration - WINDUP), 0, 2)
                local startPos = root.Position + direction * data.Length * alpha
                DrawWorldLine(startPos, endPos)
            end,
        },
    },

    Noli = {
        {
            Name = "Voidrush",
            Length = 20,
            Check = function(char, root)
                local state = char:FindFirstChild("SpeedMultipliers")
                if state then
                    return state:FindFirstChild("VoidRushCharging") or state:FindFirstChild("VoidRushDash") or state:FindFirstChild("VoidRushEndlag")
                end
            end,
            Draw = function(data, char, root)
                DrawLookLine(root, data.Length)
            end,
        },
    },

    Sixer = {
        {
            Name = "Demonic Pursuit",
            Length = 155,
            Check = function(char, root)
                local state = char:FindFirstChild("SpeedMultipliers")
                if state then
                    return state:FindFirstChild("666PursuitStart") or state:FindFirstChild("666Pursuit")
                end
            end,
            Draw = function(data, char, root)
                local state = char:FindFirstChild("SpeedMultipliers")
                if state then
                    if state:FindFirstChild("666Pursuit") then
                        DrawMovementFromOrigin(data, root)
                    else
                        DrawLookLine(root, data.Length)
                    end
                end
            end,
        },
    },

    Nosferatu = {
        {
            Name = "Ascension",
            Length = 120,

            Check = function(char, root, data)
                local state = char:FindFirstChild("SpeedMultipliers")
                local present
                if state then
                    present = state:FindFirstChild("NosFlying")
                end

                if present then
                    if data then
                        data.LastPresent = os.clock()
                    end

                    return true
                end

                if data and data.LastPresent then
                    return os.clock() - data.LastPresent <= 1.1
                end

                return false
            end,

            Draw = function(data, char, root)
                DrawLookLine(root, data.Length, 0, 1)
            end,
        },
        {
            Name = "Bloodhook",
            Length = 115,
            Check = function(char, root)
                local folder = char:FindFirstChild("SpeedMultipliers")
                return folder and folder:FindFirstChild("NosBloodhookThrow") ~= nil
            end,
            Draw = function(data, char, root)
                DrawLookLine(root, data.Length)
            end,
        },
    },

    Azure = {
        {
            Name = "Enstrangle",
            Length = 55,
            Check = function(char, root)
                return root:FindFirstChild("HomingSpotlightOthers") ~= nil
            end,
            Draw = function(data, char, root)
                DrawLookLine(root, data.Length, .03, 0)
            end,
        },
    },
}

local SurvivorAbilities = {
    Shedletsky = {
        {
            Name = "Slash",
            Length = 6,
            Check = function(char, root)
                local state = char:FindFirstChild("ResistanceMultipliers")
                if state then
                    local resist = state:FindFirstChild("ResistanceStatus")
                    if resist then
                        return resist.Value == 40
                    end
                end
            end,
            Draw = function(data, char, root)
                DrawLookLine(root, data.Length, 0, 0)
            end,
        },
    },

    Chance = {
        {
            Name = "One Shot",
            Length = 92,
            Duration = .925,
            TriggerOnce = true,
            Check = function(char, root)
                local state = char:FindFirstChild("Flintlock")
                if state then
                    return state.Transparency == 0
                end
            end,
            Draw = function(data, char, root)
                DrawLookLine(root, data.Length, 0, 0)
            end,
        },
    },

    Guest1337 = {
        {
            Name = "Block",
            Duration = .9,
            TriggerOnce = true,
            Check = function(char, root)
                if char == LocalPlayer.Character then return end

                local state = char:FindFirstChild("SpeedMultipliers")
                if state then
                    if state:FindFirstChild("GuestBlocking") then
                        return true
                    end
                end
            end,
        },
    },
}

local function UpdateAbilityFolder(folder, abilitiesTable)
    for _, char in folder:GetChildren() do
        local root = char:FindFirstChild("HumanoidRootPart")
        local abilities = abilitiesTable[char.Name]

        if not root or not abilities then
            continue
        end

        local lines = ActiveLines[root]

        if not lines then
            lines = {}
            ActiveLines[root] = lines
        end

        for _, ability in abilities do
            local exists = false

            for _, data in lines do
                if data.Ability == ability then
                    exists = true
                    break
                end
            end

            local checked = ability.Check(char, root)
            if ability.TriggerOnce then
                ability.ActiveStates = ability.ActiveStates or {}
                local wasActive = ability.ActiveStates[char] == true

                if checked and not wasActive and not exists then
                    local data = {
                        Ability = ability,
                        Character = char,
                        Name = ability.Name,
                        Length = ability.Length,
                        Duration = ability.Duration,
                        Origin = root.Position,
                        Started = os.clock(),
                    }

                    if ability.Start then
                        ability.Start(data, char, root)
                    end

                    lines[#lines + 1] = data
                end

                ability.ActiveStates[char] = checked
            elseif checked and not exists then
                local data = {
                    Ability = ability,
                    Character = char,
                    Name = ability.Name,
                    Length = ability.Length,
                    Duration = ability.Duration,
                    Origin = root.Position,
                    Started = os.clock(),
                }

                if ability.Start then
                    ability.Start(data, char, root)
                end
                lines[#lines + 1] = data
            end
        end
    end
end

local function RenderActiveLines()
    if not bShowLine then
        return
    end

    for root, lines in ActiveLines do
        for i, data in lines do
            local char = data.Character
            local ability = data.Ability

            if not root.Parent or not char then
                lines[i] = nil
                continue
            end

            if char.Parent ~= Killers and char.Parent ~= Survivors then
                lines[i] = nil
                continue
            end

            if not bShowLocalLine and char == LocalPlayer.Character then
                continue
            end

            local elapsed = os.clock() - data.Started

            if data.Duration then
                if elapsed >= data.Duration then
                    lines[i] = nil
                    continue
                end
            elseif not ability.Check(char, root, data) then
                lines[i] = nil
                continue
            end

            if ability.Draw then
                ability.Draw(data, char, root)
            end

            if ability.ShowName ~= false then
                DrawAbilityName(data, root)
            end
        end

        if next(lines) == nil then
            ActiveLines[root] = nil
        end
    end
end

local function UpdateActiveLines()
    if not bShowLine then
        ActiveLines = {}
        return
    end

    UpdateAbilityFolder(Killers, KillerAbilities)
    UpdateAbilityFolder(Survivors, SurvivorAbilities)
end

local function ChanceAim(f, lroot, kroot)
    if f:FindFirstChild("ShootingGun") then
        if not tempstunning then
            tempstunning = true

            task.wait(.725)

            local p1 = kroot.Position
            local t1 = os.clock()

            task.wait(.1)

            lroot.CFrame = CFrame.lookAt(lroot.Position, PredictPosition2(lroot, kroot, p1, t1))
        end
    elseif tempstunning then
        tempstunning = false
    end
end

local function GetStam()
    return memory.readstring(LocalPlayer.PlayerGui.TemporaryUI.PlayerInfo.Bars.Stamina.Amount, offset)
end

local function SecondsToMinute(num)
    if not num then return end
    local min = tostring(math.floor(num / 60))
    local sec = tostring(math.floor(num % 60))
    
    if tonumber(sec) < 10 then
        sec = "0" .. sec
    end

    return min .. ":" .. sec
end

--LocalPlayer.PlayerGui.PuzzleUI.Container.GridHolder.Grid
--LocalPlayer.PlayerGui.PuzzleUI.Container.GridHolder.Grid.1-6.Circle

local function SolveWires(Endpoints, Size)
    Size = Size or 7

    local Directions = {{1, 0}, {-1, 0}, {0, 1}, {0, -1},}

    local Grid = {}
    local Wires = {}
    local Solution = {}

    for y = 1, Size do
        Grid[y] = {}

        for x = 1, Size do
            Grid[y][x] = false
        end
    end

    local function Key(x, y)
        return (y - 1) * Size + x
    end

    local function InBounds(x, y)
        return x >= 1
            and x <= Size
            and y >= 1
            and y <= Size
    end

    local function GetX(point)
        return point.x or point[1]
    end
    local function GetY(point)
        return point.y or point[2]
    end
    local function Manhattan(x1, y1, x2, y2)
        return math.abs(x1 - x2) + math.abs(y1 - y2)
    end

    local function CopyPath(path)
        local result = {}

        for i, point in path do
            result[i] = {
                x = point.x,
                y = point.y,
            }
        end

        return result
    end

    for id, points in Endpoints do
        if not points[1] or not points[2] then
            return nil, "Wire " .. tostring(id) .. " doesn't have 2 endpoints"
        end

        local ax = GetX(points[1])
        local ay = GetY(points[1])
        local bx = GetX(points[2])
        local by = GetY(points[2])

        if not ax or not ay or not bx or not by then
            return nil, "Invalid endpoint for " .. tostring(id)
        end
        if not InBounds(ax, ay) or not InBounds(bx, by) then
            return nil, "Endpoint outside board for " .. tostring(id)
        end
        if Grid[ay][ax] or Grid[by][bx] then
            return nil, "Two wires use the same endpoint"
        end

        local wire = {
            Id = id,
            AX = ax,
            AY = ay,
            BX = bx,
            BY = by,
        }

        Wires[#Wires + 1] = wire
        Grid[ay][ax] = wire
        Grid[by][bx] = wire
    end

    local function IsGoal(wire, x, y)
        return x == wire.BX and y == wire.BY
    end

    local function CanUse(wire, x, y)
        if not InBounds(x, y) then
            return false
        end

        if IsGoal(wire, x, y) then
            return true
        end

        return Grid[y][x] == false
    end

    local function CanReach(wire, startX, startY)
        local Queue = {{startX, startY}}

        local Head = 1
        local Visited = {}
        Visited[Key(startX, startY)] = true

        while Head <= #Queue do
            local pos = Queue[Head]
            Head += 1
            local x = pos[1]
            local y = pos[2]

            if IsGoal(wire, x, y) then
                return true
            end

            for _, dir in Directions do
                local nx = x + dir[1]
                local ny = y + dir[2]

                if InBounds(nx, ny) then
                    local key = Key(nx, ny)
                    if not Visited[key] and CanUse(wire, nx, ny) then
                        Visited[key] = true
                        Queue[#Queue + 1] = {nx, ny}
                    end
                end
            end
        end

        return false
    end

    local function AllReachable(Remaining)
        for _, wire in Remaining do
            if not CanReach(wire, wire.AX, wire.AY) then
                return false
            end
        end

        return true
    end

    local function CountExits(wire, x, y)
        local count = 0

        for _, dir in Directions do
            local nx = x + dir[1]
            local ny = y + dir[2]

            if CanUse(wire, nx, ny) then
                count += 1
            end
        end

        return count
    end

    local function ReachableArea(wire)
        local Queue = {{wire.AX, wire.AY}}

        local Head = 1
        local Visited = {}
        Visited[Key(wire.AX, wire.AY)] = true
        local count = 0
        local reachedGoal = false

        while Head <= #Queue do
            local pos = Queue[Head]
            Head += 1
            local x = pos[1]
            local y = pos[2]
            count += 1

            if IsGoal(wire, x, y) then
                reachedGoal = true
            end

            for _, dir in Directions do
                local nx = x + dir[1]
                local ny = y + dir[2]
                if InBounds(nx, ny) then
                    local key = Key(nx, ny)
                    if not Visited[key] and CanUse(wire, nx, ny) then
                        Visited[key] = true
                        Queue[#Queue + 1] = {nx, ny}
                    end
                end
            end
        end

        return reachedGoal, count
    end

    local function ChooseWire(Remaining)
        local bestIndex
        local bestExits
        local bestArea
        local bestDistance

        for i, wire in Remaining do
            local reachable, area = ReachableArea(wire)

            if not reachable then
                return nil
            end

            local exitsA = CountExits(wire, wire.AX, wire.AY)
            local exitsB = CountExits(wire, wire.BX, wire.BY)
            local exits = math.min(exitsA, exitsB)
            local distance = Manhattan(wire.AX, wire.AY, wire.BX, wire.BY)

            if not bestIndex or exits < bestExits or (exits == bestExits and area < bestArea) or (exits == bestExits and area == bestArea and distance < bestDistance) then
                bestIndex = i
                bestExits = exits
                bestArea = area
                bestDistance = distance
            end
        end

        return bestIndex
    end

    local function RemoveIndex(list, index)
        local result = {}

        for i, value in list do
            if i ~= index then
                result[#result + 1] = value
            end
        end

        return result
    end

    local SolveRemaining

    SolveRemaining = function(Remaining)
        if #Remaining == 0 then
            return true
        end

        local chosenIndex = ChooseWire(Remaining)
        if not chosenIndex then
            return false
        end

        local wire = Remaining[chosenIndex]
        local NextRemaining = RemoveIndex(Remaining, chosenIndex)

        if Manhattan(wire.AX, wire.AY, wire.BX, wire.BY) == 1 then
            Solution[wire.Id] = {{
                x = wire.AX,
                y = wire.AY,
            },
            {
                x = wire.BX,
                y = wire.BY,
            }}

            if SolveRemaining(NextRemaining) then
                return true
            end
            Solution[wire.Id] = nil

            return false
        end

        local Path = {{
            x = wire.AX,
            y = wire.AY,
        }}

        local PathVisited = {}
        PathVisited[Key(wire.AX, wire.AY)] = true

        local function SearchPath(x, y)
            if IsGoal(wire, x, y) then
                Solution[wire.Id] = CopyPath(Path)
                if SolveRemaining(NextRemaining) then
                    return true
                end
                Solution[wire.Id] = nil

                return false
            end

            local Neighbors = {}
            for _, dir in Directions do
                local nx = x + dir[1]
                local ny = y + dir[2]

                if InBounds(nx, ny) then
                    local key = Key(nx, ny)
                    if not PathVisited[key] and CanUse(wire, nx, ny) then
                        Neighbors[#Neighbors + 1] = {x = nx, y = ny, distance = Manhattan(nx, ny, wire.BX, wire.BY)}
                    end
                end
            end

            table.sort(Neighbors, function(a, b)
                return a.distance < b.distance
            end)

            for _, nextPos in Neighbors do
                local nx = nextPos.x
                local ny = nextPos.y
                local key = Key(nx, ny)
                local goal = IsGoal(wire, nx, ny)
                PathVisited[key] = true
                Path[#Path + 1] = {x = nx, y = ny,}

                if not goal then
                    Grid[ny][nx] = wire
                end

                local possible = true

                if not goal and not CanReach(wire, nx, ny) then
                    possible = false
                end
                if possible and not AllReachable(NextRemaining) then
                    possible = false
                end
                if possible and SearchPath(nx, ny) then
                    return true
                end
                if not goal then
                    Grid[ny][nx] = false
                end

                Path[#Path] = nil
                PathVisited[key] = nil
            end
            return false
        end

        return SearchPath(wire.AX, wire.AY)
    end

    local Remaining = {}
    for _, wire in Wires do
        Remaining[#Remaining + 1] = wire
    end

    if SolveRemaining(Remaining) then
        return Solution
    end

    return nil, "No solution found"
end

local function GetCenter(gui)
    local px = memory.readf32(gui, abspos)
    local py = memory.readf32(gui, abspos + 4)
    local sx = memory.readf32(gui, abssize)
    local sy = memory.readf32(gui, abssize + 4)

    return px + sx / 2, py + sy / 2
end

local function TweenMouse(s, x, y)
    local mouse = UserInputService:GetMouseLocation()
    local sx = mouse.X
    local sy = mouse.Y
    local start = os.clock()

    while true do
        local alpha = (os.clock() - start) / s
        if alpha >= 1 then
            break
        end

        local eased = alpha * alpha * (3 - 2 * alpha)
        local px = sx + (x - sx) * eased
        local py = sy + (y - sy) * eased
        mousemoveabs(px, py)
        task.wait()
    end

    mousemoveabs(x, y)
end

local function SimplifyPath(path)
    if #path <= 2 then
        return path
    end
    local result = {path[1]}
    local lastDX = path[2].x - path[1].x
    local lastDY = path[2].y - path[1].y

    for i = 2, #path - 1 do
        local current = path[i]
        local nextPoint = path[i + 1]
        local dx = nextPoint.x - current.x
        local dy = nextPoint.y - current.y
        if dx ~= lastDX or dy ~= lastDY then
            result[#result + 1] = current
        end

        lastDX = dx
        lastDY = dy
    end

    result[#result + 1] = path[#path]
    return result
end

local function Solver(grid, solution)
    local ogtime = os.clock()

    mouse1release()
    local time = math.floor(math.max(AutoGenTime + (math.random() * 2 - 1) * AutoGenRandom, .2) * 100) / 100
    task.wait(time)

    for _, path in solution do
        if #path < 2 then continue end

        local first = path[1]
        local firstCell = grid:FindFirstChild(tostring(first.x) .. "-" .. tostring(first.y))
        if not firstCell then continue end
        local fx, fy = GetCenter(firstCell)

        TweenMouse(.05, fx, fy)
        task.wait(.02)
        mouse1press()

        local simplePath = SimplifyPath(path)
        for i = 2, #simplePath do
            local point = simplePath[i]
            local cell = grid:FindFirstChild(tostring(point.x) .. "-" .. tostring(point.y))
            if not cell then break end

            local px, py = GetCenter(cell)

            local previous = simplePath[i - 1]
            local distance = math.abs(point.x - previous.x) + math.abs(point.y - previous.y)
            TweenMouse(.05 + .03 * distance, px, py)
            task.wait(.02)
        end

        mouse1release()
    end

    print("Time took: " .. tostring(math.floor((os.clock() - ogtime) * 1000) / 1000))

    TempAutoGen = false
end

local function PreLocal()
    UpdateValues()

    if bAutoGen and bInUI then
        if not TempAutoGen then
            local s, grid = pcall(function()
                return LocalPlayer.PlayerGui.PuzzleUI.Container.GridHolder.Grid
            end)
            if s and grid then
                local glist = grid:GetChildren()
                local returntable = {}
                for _, inst in glist do
                    local kirkle = inst:FindFirstChild("Circle")
                    if kirkle then
                        local index = kirkle:FindFirstChild("Number")
                        if index then
                            local inum = memory.readstring(index, offset)
                            local split = inst.Name:split("-")
                            local xv = tonumber(split[1])
                            local yv = tonumber(split[2])

                            returntable[inum] = returntable[inum] or {}
                            table.insert(returntable[inum], {
                                x = xv,
                                y = yv,
                            })
                        else
                            print("no number son")
                            TempAutoGen = false
                            break
                        end
                    end
                end

                local signatureParts = {}
                for id, points in returntable do
                    for _, point in points do
                        signatureParts[#signatureParts + 1] =
                            tostring(id) .. ":" .. tostring(point.x) .. "," .. tostring(point.y)
                    end
                end
                table.sort(signatureParts)
                local signature = table.concat(signatureParts, "|")
                if signature ~= LastPuzzleSignature then
                    local solved = SolveWires(returntable, 7)
                
                    if solved and grid then
                        LastPuzzleSignature = signature
                        TempAutoGen = true
                        task.spawn(Solver, grid, solved)
                    end
                end
            else
                print("no grid son")
            end
        end
    end
    if not bInUI then
        TempAutoGen = false
        LastPuzzleSignature = nil
    end

    if not BLOCK_KEY or not PARRY_KEY or not SPRINT_KEY then
        local s, e1, e2, e3 = pcall(GetBinds)

        if s then
            BLOCK_KEY = GetKeycode(e1)
            PARRY_KEY = GetKeycode(e2)
            SPRINT_KEY = GetKeycode(e3)
        end
    end

    if bStopStam then
        local s, stam = pcall(GetStam)

        if s and stam then
            local stamina = stam:split("/")[1]

            if stamina == "1" then
                keyrelease(SPRINT_KEY)
            end
        end
    end

    local tempisguest

    local suc, bool, lchar = pcall(function()
        return LocalPlayer.Character.Name, LocalPlayer.Character
    end)

    if suc and (bool == "Guest1337" or bool == "007n7") then
        tempisguest = true
    else
        tempisguest = false
    end

    if bChanceAimbot and suc and bool and lchar then
        if bool == "Chance" then
            local f = lchar:FindFirstChild("SpeedMultipliers")
            local lroot = lchar:FindFirstChild("HumanoidRootPart")
            local targetk = Killers:FindFirstChildOfClass("Model")
            if f and lroot and targetk then
                local kroot = targetk:FindFirstChild("HumanoidRootPart")
                if kroot then
                    task.spawn(ChanceAim, f, lroot, kroot)
                end
            end
        end
    end

    if tempisguest ~= isguest then
        isguest = tempisguest

        if isguest then
            bt.Color = Color3.fromRGB(248,131,121)
            bt.Text = "AUTO BLOCK"
            length = bt.TextBounds.x
            height = bt.TextBounds.y
            bt.Position = Vector2.new(viewport.x / 2 - length / 2, (viewport.y - viewport.y / 4) - height)
        else
            bt.Color = Color3.fromRGB(109,129,150)
            bt.Text = "AUTO BLOCK (inactive)"
            length = bt.TextBounds.x
            height = bt.TextBounds.y
            bt.Position = Vector2.new(viewport.x / 2 - length / 2, (viewport.y - viewport.y / 4) - height)
        end
    end

    if bShowTimer then
        local ctimer = game.ReplicatedStorage.RoundTimer:GetAttribute("TimeLeft")
        local texttimer = SecondsToMinute(ctimer)
        if ctimer then
            bt3.Text = "Real timer: " .. texttimer
        end

        local s67, atime = pcall(function()
            local timett = LocalPlayer.PlayerGui.RoundTimer.Main.Time
            return memory.readstring(timett, offset)
        end)

        if s67 and atime then
            if texttimer ~= atime then
                bt3.Visible = true
            else
                bt3.Visible = false
            end
        end
    end

    if Camera.ViewportSize ~= viewport then
        viewport = Camera.ViewportSize

        length = bt.TextBounds.x
        height = bt.TextBounds.y
        bt.Position = Vector2.new(viewport.x / 2 - length / 2, (viewport.y - viewport.y / 4) - height)

        length2 = bt2.TextBounds.x
        height2 = bt2.TextBounds.y
        bt2.Position = Vector2.new(viewport.x / 2 - length2 / 2, (viewport.y - viewport.y / 4) - height2)

        length3 = bt3.TextBounds.x
        height3 = bt3.TextBounds.y
        bt3.Position = Vector2.new(viewport.x / 2 - length3 / 2, (viewport.y - viewport.y / 4) - height3)
    end

    local pressed = false

    if bAutoBlock then
        for _, v in getpressedkeys() do
            if v == KEYBIND then
                pressed = true
                break
            end
        end
    end

    if pressed and not tempactive then
        tempactive = true
        active = not active
        bt.Visible = active

        KillerAbTime = {}
        KillerAb = {}

        if not active then
            bt2.Visible = false
        end
    elseif not pressed then
        tempactive = false
    end

    if bt2.Visible then
        local center = Vector2.new(viewport.x / 2 - length2 / 2, viewport.y / 2 - height2 / 2)
        bt2.Position = Vector2.new(center.x + math.random(-5, 5), center.y + math.random(-5, 5))
    end

    for _, inst in Killers:GetChildren() do
        local id = InstId(inst)
        if id then
            if KillerData[inst.Name] then
                DELAY = KillerData[inst.Name]["DELAY"]
                CLOSE_RADIUS = KillerData[inst.Name]["CLOSE_RADIUS"]
                ATTACK_LINGER = KillerData[inst.Name]["ATTACK_LINGER"]
                ATTACK_LENGTH = KillerData[inst.Name]["ATTACK_LENGTH"]
                HEIGHT = KillerData[inst.Name]["HEIGHT"]
            end
            local AbTime = tonumber(inst:GetAttribute("AbilityLastUsed") or 0)
            local Ab = tonumber(inst:GetAttribute("AbilitiesUsed") or 0)
            if not AbTime or not Ab then continue end
            if not KillerAbTime[id] or not KillerAb[id] then
                KillerAbTime[id] = AbTime
                KillerAb[id] = Ab
            elseif KillerAbTime[id] ~= AbTime and KillerAb[id] == Ab then
                KillerAb[id] = Ab
                KillerAbTime[id] = AbTime
                local LRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local KRoot = inst:FindFirstChild("HumanoidRootPart")
                if KRoot and LRoot then
                    if active then
                        local config = KillerData[inst.Name] or KillerData.Default
                        local attackData = {
                            LRoot = LRoot,
                            Progress = 0,
                            Config = config,
                        }
                        ActiveAttacks[KRoot] = attackData
                        task.spawn(BlockChecker, KRoot, LRoot, inst, attackData)
                    end
                end
            elseif KillerAbTime[id] ~= AbTime and tonumber(KillerAb[id]) < tonumber(Ab) then
                KillerAb[id] = Ab
                KillerAbTime[id] = AbTime
            end
        end
    end

    if bAutoParry and isguest then
        local lchar = LocalPlayer.Character
        local state = lchar:FindFirstChild("SpeedMultipliers")
        if state then
            if state:FindFirstChild("SpeedStatus") then
                if not bTempParry then
                    bTempParry = true
                    task.spawn(Parry, lchar)
                end
            elseif bTempParry then
                bTempParry = false
            end
        end
    end
end

local function PreData()
    if FocusTimer ~= 0 and FocusTimer + .5 < os.clock() then
        ItemCache = {}
        PartCache = {}
        GeneratorCache = {}
        _G.ESPList = {}
        _G.ESPHealths = {}
        _G.ESPData = {}
        clear_model_data()
    end
    FocusTimer = os.clock()

    for ID, inst in _G.ESPList do
        if not inst or not inst.Parent then
            if not _G.ESPData[ID]["LocalPlayer"] then
                ESP.RemovePlayer(ID)
            else
                clear_local_data()
            end
        else
            if not inst:FindFirstChild("Humanoid") then continue end
            local chealth = inst.Humanoid.Health
            local healthyavocado = math.floor(chealth)
            if healthyavocado == 0 then
                healthyavocado = 1
            end
            if _G.ESPData[ID]["Health"] ~= healthyavocado then
                if chealth <= 0 then
                    if not _G.ESPData[ID]["LocalPlayer"] then
                        ESP.RemovePlayer(ID)
                    else
                        clear_local_data()
                    end
                    continue
                end
                if not _G.ESPData[ID]["LocalPlayer"] then
                    ESP.EditHealth(ID, healthyavocado)
                end
            end
            if not _G.ESPData[ID]["LocalPlayer"] and _G.ESPData[ID]["Teamname"] ~= inst.Parent.Name then
                ESP.RemovePlayer(ID)
                continue
            end
            if is_team_check_active() and LocalTeam == _G.ESPData[ID]["Teamname"] then
                if not _G.ESPData[ID]["LocalPlayer"] then
                    ESP.RemovePlayer(ID)
                    continue
                else
                    clear_local_data()
                    continue
                end
            end
            if inst.Name == "Azure" then
                local coblation = inst:GetAttribute("Oblation")
                if coblation then
                    if tostring(_G.ESPData[ID]["Toolname"]) ~= tostring(math.floor(tonumber(coblation))) .. " Oblation" and tostring(_G.ESPData[ID]["Toolname"]) ~= "Golem ready" and not _G.ESPData[ID]["LocalPlayer"] then
                        ESP.RemovePlayer(ID)
                        continue
                    end
                end
            end
        end
    end

    for _, inst in Players:GetChildren() do
        if not inst or not inst.Parent then continue end

        local Char = inst.Character
        if not Char then continue end
        if not Char:FindFirstChild("Humanoid") then continue end

        local team = "Spectator"
        if Char.Parent then
            team = Char.Parent.Name
        end

        local tool
        if Char.Name == "Azure" then
            if tonumber(Char:GetAttribute("Oblation")) == 15 then
                tool = "Golem ready"
            else
                if Char:GetAttribute("Oblation") then
                    tool = tostring(math.floor(tonumber(Char:GetAttribute("Oblation")))) .. " Oblation"
                end
            end
        end
        
        if is_team_check_active() and LocalTeam == team then continue end

        if inst == LocalPlayer then
            LocalTeam = team
            continue
        end

        local h = Char.Humanoid.Health
        if h > 0 then
            local healthyavocado = math.floor(h)
            if healthyavocado == 0 then
                healthyavocado = 1
            end

            ESP.AddPlayer(Char, inst == LocalPlayer, healthyavocado, Char.Humanoid.MaxHealth, inst.Name, inst.DisplayName, inst.UserId, team, tool, nil, nil, (Char.Name == "Sixer" and SixerRig))
        end
    end

    local now = os.clock()
    if now - LastAttackScan >= .03 then
        LastAttackScan = now
        UpdateActiveLines()
    end

    if not bESP then return end

    if LocalPlayer.Character then
        if LocalPlayer.Character.Parent then
            local Name = LocalPlayer.Character.Parent.Name
            if Name == "Survivors" then
                bSurv = true
                bKill = false
            elseif Name == "Killers" then
                bSurv = false
                bKill = true
            else
                bSurv = false
                bKill = false
            end
        end
    end

    if LocalPlayer:FindFirstChild("PlayerGui") then
        if LocalPlayer.PlayerGui:FindFirstChild("PuzzleUI") then
            bInUI = true
        else
            bInUI = false
        end
    else
        bInUI = false
    end

    local IngameChildren = Ingame:GetChildren()

    for _, inst in IngameChildren do
        local id = InstId(inst)
        if not id then continue end
        if ItemCache[id] then continue end

        local Name = inst.Name
        if table.find(Names, Name) then
            ItemCache[id] = inst
            continue
        end

        for _, name in PNames do
            if string.find(Name, name) then
                ItemCache[id] = inst
                continue
            end
        end

        if inst:FindFirstChild("Humanoid") then
            ItemCache[id] = inst
            continue
        end
    end

    for _, inst in Killers:GetChildren() do
        if inst.Name == "Noli" and not ItemCache[InstId(inst)] then
            local usern = inst:GetAttribute("Username")
            if usern or noliname then
                if usern then
                    noliname = usern
                end
                if Players:FindFirstChild(noliname) then
                    if Players[noliname].Character ~= inst and InstId(inst) and #Killers:GetChildren() > 1 then
                        ItemCache[InstId(inst)] = inst
                        continue
                    end
                end
            end
        end
    end

    if Map:FindFirstChild("Azure") then
        local Azure = Map.Azure
        local id = InstId(Azure)
        if id and not ItemCache[id] then
            ItemCache[id] = Azure
        end
    end

    for _, inst in workspace:GetChildren() do
        local id = InstId(inst)
        if not id then continue end
        if ItemCache[id] then continue end

        local Name = inst.Name
        if Name == "BloxyCola" then
            ItemCache[id] = inst
        elseif Name == "Medkit" then
            ItemCache[id] = inst
        end
    end

    for _, inst in IngameChildren do
        local Name = inst.Name
        if type(Name) ~= "string" then continue end
        if bSurv and (string.find(Name, "JohnDoeTrail") or string.find(Name, "Shadows")) then
            for _, part in inst:GetChildren() do
                local id = InstId(part)
                if not id then continue end
                if ItemCache[id] then continue end

                ItemCache[id] = part
            end
        end
    end

    if not Ingame:FindFirstChild("Map") then return end

    for _, inst in Ingame.Map:GetChildren() do
        local id = InstId(inst)
        if not id then continue end
        if ItemCache[id] then continue end

        local Name = inst.Name
        if Name == "Generator" and inst:FindFirstChild("Progress") then
            local s, r = pcall(function()
                return inst.Progress.Value
            end)
            if s and r ~= 100 then
                ItemCache[id] = inst
            end
        elseif Name == "FakeGenerator" or Name == "BloxyCola" or Name == "Medkit" then
            ItemCache[id] = inst
        end
    end
end

local function Render()
    RenderActiveLines()

    if bShowBlock then
        for KRoot, data in ActiveAttacks do
            if KRoot and KRoot.Parent and data.LRoot and data.LRoot.Parent then
                RenderBlockShape(KRoot, data.LRoot, data.Progress)
            else
                ActiveAttacks[KRoot] = nil
            end
        end
    end

    for id, inst in ItemCache do
        local Name
        local iParent = inst.Parent
        if not inst or not iParent then
            RemoveCachedItem(id)
            continue
        else
            local s, r = pcall(function()
                return iParent.Name
            end)
            if s and r == "Backpack" then
                RemoveCachedItem(id)
                continue
            else
                Name = inst.Name
            end
        end

        if type(Name) ~= "string" then
            RemoveCachedItem(id)
            continue
        end

        if Name == "Generator" and (bInUI or bKill) then continue end

        if Name == "Generator" then
            local Main = inst:FindFirstChild("Main")
            local Progress = inst:FindFirstChild("Progress")

            if not Main or not Progress then
                RemoveCachedItem(id)
                continue
            end

            local val = Progress.Value

            if val == 100 then
                RemoveCachedItem(id)
                continue
            end

            if bHighlight then Highlight(Main, c.generator) end
            if bTextName then DrawText(Main, GetGenPer(val), c.generator) end
            continue
        end

        if Name == "Trail" then
            local sz = inst.Size
            if sz.x > 100 or sz.y > 100 or sz.z > 100 then continue end
        elseif Name == "JaneGhost" then
            continue
        end

        local colorKey = NameColors[Name]
        local color = colorKey and c[colorKey] or c.yellow
        local name = FullNames[Name]

        for _, v in PNames do
            if string.find(Name, v) then
                local colorKey = NameColors[v]
                color = colorKey and c[colorKey] or c.yellow
                name = FullNames[v]
            end
        end

        if bSurv and (table.find(SNames, Name) or string.find(Name, "TaphTripwire") or string.find(Name, "SubspaceTripmine")) then continue end
        if bKill and (table.find(KNames, Name) or string.find(Name, "Puddle") or string.find(Name, "Shockwave")) then continue end
        if string.find(Name, "Spray") then continue end

        local Parts = PartCache[id]

        if type(Parts) == "table" then
            local refresh = false
            if not PartCacheRefresh[id] or os.clock() - PartCacheRefresh[id] >= .25 then
                refresh = true
            else
                for _, part in Parts do
                    if not part or not part.Parent then
                        refresh = true
                        break
                    end
                end
            end
            if refresh then
                Parts = GetPart(inst)
                PartCache[id] = Parts
                PartCacheRefresh[id] = os.clock()
            end
        else
            local refresh = false
            if not Parts or not Parts.Parent then
                refresh = true
            elseif inst:FindFirstChild("Humanoid") then
                if not PartCacheRefresh[id] or os.clock() - PartCacheRefresh[id] >= .25 then
                    refresh = true
                end
            end
            if refresh then
                Parts = GetPart(inst)
                if Parts then
                    PartCache[id] = Parts
                    PartCacheRefresh[id] = os.clock()
                end
            end
        end

        if type(Parts) == "table" then
            if bHighlight then
                h.HighlightGroup(Parts, color, .18, .7, .7, 1.25)
            end
            for _, part in Parts do
                if part.Name == "Torso" then
                    if not name then
                        name = "Minion"
                    end
                    if bTextName then
                        DrawText(part, name, color)
                    end
                end
            end
        elseif Parts then
            if name then
                if bTextName then
                    DrawText(Parts, name, color)
                end
            end
            if bHighlight then
                Highlight(Parts, color)
            end
        end
    end
end

window = UI:createwindow({
    Title = "Forsaken | Andris",
    Version = "VX",
    Keybind = "RightShift",
    ConfigFolder = "AndrisForsaken",
    CustomResolution = Vector2.new(580, 360),
    DPIScale = 1.0,
    CompactSettings = false,
    DefaultTab = "Survivor", 
    TabAlignment = "Center",
    DefaultColor = Color3.fromRGB(28, 27, 31),
    DefaultAccent = Color3.fromRGB(208, 188, 255),
    DefaultSnowfall = true,
    DefaultScale = 1.0,
    DefaultFont = 0,
})

window:registerkey("AutoBlockKeybind", KEYBIND)
KEYBIND = window:getvalue("AutoBlockKeybind")

local tabSurvivor = window:createtab("Survivor")
local tabKiller = window:createtab("Killer")
local tabVisual = window:createtab("Visual")
local tabMisc = window:createtab("Misc")
local tabColors = window:createtab("Colors")

window:createlabel(tabMain, "After enabling, you need to press your keybind", 1)

window:createtoggle(tabSurvivor, {
    Name = "Enable Auto block",
    Col = 1,
    Default = false,
    Callback = function(val)
        KillerAb = {}
        KillerAbTime = {}
        tempactive = false
		active = false
        bt.Visible = false
        bt2.Visible = false

        bAutoBlock = val
	end
})

window:createtoggle(tabSurvivor, {
    Name = "Block when the killer is stun immune",
    Col = 1,
    Default = false,
    Callback = function(val)
		bBlockOnInv = val
	end
})

window:createtoggle(tabSurvivor, {
    Name = "Show Auto block range",
    Col = 1,
    Default = false,
    Callback = function(val)
		bShowBlock = val
	end
})

keybindlabel = window:createlabel(tabSurvivor, "Current keybind: " .. KEYBIND, 1)

local keybindbtn
keybindbtn = window:createbutton(tabSurvivor, {
    Name = "Change keybind",
    Col = 1,
    Callback = function()
        if bChangingBind then return end
        task.spawn(function()
            keybindbtn.Txt.Text = "Press any key.."
            bChangingBind = true
            local loop = true
            while loop do
                local key = getpressedkeys()

                for i, v in key do
                    if v ~= "LeftMouse" then
                        tempactive = true
                        KEYBIND = key[i]
                        window:setvalue("AutoBlockKeybind", KEYBIND)
                        keybindlabel.Txt.Text = "Current keybind: " .. KEYBIND
                        keybindbtn.Txt.Text = "Change keybind"
                        bChangingBind = false
                        send_notification("Keybind set to: " .. KEYBIND, "info")
                        loop = false
                        break
                    end
                end

                task.wait(.01)
            end
        end)
    end
})

window:createlabel(tabSurvivor, "Auto aim for survivor sentinel stuns", 2)

window:createtoggle(tabSurvivor, {
    Name = "Guest 1337 auto parry",
    Col = 2,
    Default = false,
    Callback = function(val)
		bAutoParry = val
	end
})

window:createslider(tabSurvivor, {
    Name = "Auto parry delay",
    Col = 2, 
    Min = 0, Max = .6, Default = 0,
    Step = .05,
    Callback = function(val)
        PARRY_DELAY = val
    end
})

window:createseparator(tabSurvivor, 2)

window:createtoggle(tabSurvivor, {
    Name = "Chance aimbot",
    Col = 2,
    Default = false,
    Callback = function(val)
		bChanceAimbot = val
	end
})

window:createlabel(tabKiller, "Nothing yet!", 1)

window:createlabel(tabVisual, "ESP settings (AKA Highlighter)", 1)

window:createtoggle(tabVisual, {
    Name = "Enable ESP",
    Col = 1,
    Default = true,
    Callback = function(val)
		bESP = val
		if not val then
			ItemCache = {}
            PartCache = {}
            GeneratorCache = {}
		end
	end
})

window:createtoggle(tabVisual, {
    Name = "Highlight part",
    Col = 1,
    Default = true,
    Callback = function(val)
		bHighlight = val
	end
})

window:createtoggle(tabVisual, {
    Name = "Show object name",
    Col = 1,
    Default = true,
    Callback = function(val)
		bTextName = val
	end
})

window:createlabel(tabVisual, "Shows killer attack abilty paths", 2)

window:createtoggle(tabVisual, {
    Name = "Show attack path",
    Col = 2,
    Default = false,
    Callback = function(val)
		bShowLine = val
	end
})

window:createtoggle(tabVisual, {
    Name = "Show path when you're killer",
    Col = 2,
    Default = false,
    Callback = function(val)
		bShowLocalLine = val
	end
})

window:createtoggle(tabMisc, {
    Name = "Auto complete generators",
    Col = 1,
    Default = false,
    Callback = function(val)
		bAutoGen = val
	end
})

window:createslider(tabMisc, {
    Name = "Delay before starting puzzle (seconds)",
    Col = 1,
    Min = .3, Max = 3, Default = 1.45,
    Step = .05,
    Callback = function(val)
        AutoGenTime = val
    end
})

window:createslider(tabMisc, {
    Name = "Randomize time by (seconds)",
    Col = 1,
    Min = 0, Max = 2, Default = .25,
    Step = .05,
    Callback = function(val)
        AutoGenRandom = val
    end
})

window:createseparator(tabMisc, 1)

window:createtoggle(tabMisc, {
    Name = "Show round timer when hallucinating",
    Col = 1,
    Default = false,
    Callback = function(val)
		bShowTimer = val
	end
})

window:createlabel(tabMisc, "Stops sprinting right before hitting 0 stamina", 2)

window:createtoggle(tabMisc, {
    Name = "Safe sprint",
    Col = 2,
    Default = false,
    Callback = function(val)
		bStopStam = val
	end
})

window:createseparator(tabMisc, 2)

window:createbutton(tabMisc, {
    Name = "Unhide playtime of all players",
    Col = 2,
    Callback = function(val)
        for _, inst in Players:GetChildren() do
            pcall(function()
                inst.PlayerData.Settings.Privacy.HidePlaytime.Value = false
            end)
        end
	end
})

window:createbutton(tabMisc, {
    Name = "Unhide killer and survivor wins of all players",
    Col = 2,
    Callback = function(val)
        for _, inst in Players:GetChildren() do
            pcall(function()
                inst.PlayerData.Settings.Privacy.HideKillerWins.Value = false
                inst.PlayerData.Settings.Privacy.HideSurvivorWins.Value = false
            end)
        end
	end
})

window:createcolorpicker(tabColors, {
    Name = "Projectile color",
    Col = 1,
    Default = c.danger,
})

window:createcolorpicker(tabColors, {
    Name = "Trap color",
    Col = 1,
    Default = c.trap,
})

window:createcolorpicker(tabColors, {
    Name = "Passive trap color",
    Col = 1,
    Default = c.slightdanger,
})

window:createcolorpicker(tabColors, {
    Name = "Clone color",
    Col = 1,
    Default = c.neutral,
})

window:createcolorpicker(tabColors, {
    Name = "Azure ability color",
    Col = 1,
    Default = c.azure,
})

window:createcolorpicker(tabColors, {
    Name = "Show projectile line color",
    Col = 1,
    Default = c.lineprim,
})

window:createcolorpicker(tabColors, {
    Name = "Auto block visual color",
    Col = 2,
    Default = c.autoblock,
})

window:createcolorpicker(tabColors, {
    Name = "Minion color",
    Col = 2,
    Default = c.yellow,
})

window:createcolorpicker(tabColors, {
    Name = "Generator color",
    Col = 2,
    Default = c.generator,
})

window:createcolorpicker(tabColors, {
    Name = "Medkit color",
    Col = 2,
    Default = c.medkit,
})

window:createcolorpicker(tabColors, {
    Name = "Bloxy cola color",
    Col = 2,
    Default = c.cola,
})

window:createcolorpicker(tabColors, {
    Name = "Show projectile text color",
    Col = 2,
    Default = c.linesec,
})

RunService.PreLocal:Connect(PreLocal)
RunService.PreData:Connect(PreData)
RunService.Render:Connect(Render)

clear_model_data()

print("Loaded")

end
