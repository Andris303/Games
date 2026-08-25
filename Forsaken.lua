--!strict
--!optimize 2

-- Absolutely, you're right. Here's a complete script for Forsaken, that's made specifically for severe's lua enviroment. Keep in mind, that I am a large-language model (LLM) and I can't test the actual script. I will generate code for you, but you still have to test it, and ensure it functions properly. Here is a Forsaken script, built with Ingame ESP, and auto block, crafted to work exactly like you needed:

local offset = _G.LabelTextOffset or 0xdf8

if game.GameId == 6331902150 then

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()
local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/UI.lua"))()
local h = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Map = workspace.Map
local Ingame = Map.Ingame
local Killers = workspace.Players.Killers
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
local KillerAbTime = {}
local KillerAb = {}
local ActiveAttacks = {}
local ActiveLines = {}
local PartCache = {}
local GeneratorCache = {}
local tempactive = false
local active = false
local bt = Drawing.new("Text")
local bt2 = Drawing.new("Text")
local viewport = Camera.ViewportSize
local isguest = false
local FocusTimer = 0
local bBlockOnInv = false
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
bt2.Color = Color3.fromRGB(255, 25, 25)
bt2.Outline = true
bt2.Visible = false

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

local EntSounds = {"rbxassetid://135854269153231", "rbxassetid://105934041806374", "rbxassetid://130247421279831", "rbxassetid://107039569833867", "rbxassetid://100150551345482", "rbxassetid://91488514366191", "rbxassetid://101739035738613", "rbxassetid://75675413747752", "rbxassetid://78992685630984", "rbxassetid://130994756001980"}
local MassInfSounds = {"rbxassetid://70845653728841", "rbxassetid://73504812754586", "rbxassetid://97061990471922", "rbxassetid://85647688284850", "rbxassetid://83349035240699"}
local RejuvSounds = {"rbxassetid://109351069746096", "rbxassetid://96908026446030", "rbxassetid://120877949577353", "rbxassetid://108829275072240", "rbxassetid://134770542596997", "rbxassetid://99174224422295", "rbxassetid://135436619867662", "rbxassetid://85069492524977", "rbxassetid://127962518201254"}
local CorruptSounds = {"rbxassetid://75210765058860", "rbxassetid://87883890694872", "rbxassetid://109525294317144", "rbxassetid://119285029803606", "rbxassetid://100163947838165", "rbxassetid://74901476984677", "rbxassetid://99582226869588", "rbxassetid://96733419994623", "rbxassetid://137444402376234"}

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
local SNames = {"BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile", "TaphTripwire", "SubspaceTripmine"}
local KNames = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "VineModel", "GroundBulbModel", "GroundBulb", "Medkit", "BloxyCola", "MisterBeast", "Noli", "Puddle"}
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
    if num == 26 then return "25%" end
    if num == 52 then return "50%" end
    if num == 78 then return "75%" end
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
    local syncinv = window:getvalue("Block when the killer is stun immune")
    local syncesp = window:getvalue("Enable ESP")
    local syncshowb = window:getvalue("Show Auto block range")
    local synckeybind = window:getvalue("AutoBlockKeybind")
    local synchighlight = window:getvalue("Highlight part")
    local synctextname = window:getvalue("Show object name")
    local syncautoparry = window:getvalue("Guest 1337 auto parry")
    local syncparrydelay = window:getvalue("Auto parry delay")
    local syncshowline = window:getvalue("Show attack path")
    local syncshowlocalline = window:getvalue("Show path when you're killer")
    local syncchancestun = window:getvalue("Chance aimbot")
    local syncshowhidden = window:getvalue("Unhide playtime of all players")
    local syncstopstam = window:getvalue("Safe sprint")

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
    if bBlockOnInv ~= syncinv then
        bBlockOnInv = syncinv
    end
    if bShowBlock ~= syncshowb then
        bShowBlock = syncshowb
    end
    if bHighlight ~= synchighlight then
        bHighlight = synchighlight
    end
    if bTextName ~= synctextname then
        bTextName = synctextname
    end
    if bAutoParry ~= syncautoparry then
        bAutoParry = syncautoparry
    end
    if PARRY_DELAY ~= syncparrydelay then
        PARRY_DELAY = syncparrydelay
    end
    if bShowLine ~= syncshowline then
        bShowLine = syncshowline
    end
    if bShowLocalLine ~= syncshowlocalline then
        bShowLocalLine = syncshowlocalline
    end
    if bChanceAimbot ~= syncchancestun then
        bChanceAimbot = syncchancestun
    end
    if bShowhidden ~= syncshowhidden then
        bShowhidden = syncshowhidden
    end
    if bStopStam ~= syncstopstam then
        bStopStam = syncstopstam
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

local function PredictPosition(lroot, kroot, p1, t1, p2, t2)
    local p3 = kroot.Position
    local t3 = os.clock()
    local MIN_PREDICTION = 0
    local MAX_PREDICTION = .5
    local MIN_DISTANCE = 3
    local MAX_DISTANCE = 20
    local distance = vector.magnitude(p3 - lroot.Position)
    local alpha = math.clamp((distance - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE), 0, 1)
    local prediction = MIN_PREDICTION + (MAX_PREDICTION - MIN_PREDICTION) * alpha

    local predictedPos = PredictCurve(p1, t1, p2, t2, p3, t3, prediction)
    local tpos = Vector3.new(predictedPos.X, lroot.Position.Y, predictedPos.Z)
    
    return tpos
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
        return Vector3.new(
            p3.X,
            lroot.Position.Y,
            p3.Z
        )
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

        local p2 = kroot.Position
        local t2 = os.clock()

        keyrelease(PARRY_KEY)
        task.wait(.1)

        lroot.CFrame = CFrame.lookAt(lroot.Position, PredictPosition(lroot, kroot, p1, t1, p2, t2))
    end
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

local function ShouldUseMovementPath(data, kchar, kroot)
    local condition = data.SwitchCondition

    if condition == nil then
        return false
    end

    if type(condition) == "number" then
        return os.clock() - data.Started >= condition
    end

    if type(condition) == "function" then
        return condition(data, kchar, kroot)
    end

    return false
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

local function CheckAttack(inst, kroot, ignorer)
    local name = inst.Name

    local function IsIgnored(attack)
        if not ignorer then return false end
        if type(ignorer) == "table" then return ignorer[attack] == true end

        return ignorer == attack
    end

    if name == "c00lkidd" then
        if inst:FindFirstChild("c00lgui") and not IsIgnored("Walkspeed Override") then
            return "Walkspeed Override", 90, 0, 0, function(data)
                return os.clock() - data.Started >= .4
            end, 1.9
        else return false end
    elseif name == "1x1x1x1" then
        local Entanglement
        local MassInf
        local Rejuv

        if not IsIgnored("Entanglement") then
            for _, sound in EntSounds do
                if kroot:FindFirstChild(sound) then
                    Entanglement = true
                    break
                end
            end
        end

        if not IsIgnored("Mass Infection") then
            for _, sound in RejuvSounds do
                if kroot:FindFirstChild(sound) then
                    Rejuv = true
                    break
                end
            end

            for _, sound in MassInfSounds do
                if kroot:FindFirstChild(sound) then
                    MassInf = true
                    break
                end
            end
        end

        if Entanglement then
            return "Entanglement", 125, 0, 0, nil, nil, function(data)
                    for _, obj in Ingame:GetChildren() do
                        if obj.Name == "Swords" and not data.KnownObjects[obj] then
                            local s, p = pcall(function()
                                return obj.PrimaryPart.Position
                            end)
                            if s and p then
                                if vector.magnitude(kroot.Position - p) < 30 then
                                    return obj
                                end
                            end
                        end
                    end
                    return nil
                end
        elseif MassInf then
            return "Mass Infection", 630, 0, 0, nil, nil, function(data)
                    for _, obj in Ingame:GetChildren() do
                        if (obj.Name == "shockwave" or obj.Name == "Shockwave") and not data.KnownObjects[obj] then
                            local s, p = pcall(function()
                                return obj.PrimaryPart.Position
                            end)
                            if s and p then
                                if vector.magnitude(kroot.Position - p) < 30 then
                                    return obj
                                end
                            end
                        end
                    end
                    return nil
                end
        else return false end
    elseif name == "JohnDoe" then
        local CorruptEnergy

        if not IsIgnored("CorruptEnergy") then
            if not Ingame:FindFirstChild("SpikeCollision") then
                for _, sound in CorruptSounds do
                    if kroot:FindFirstChild(sound) then
                        CorruptEnergy = true
                        break
                    end
                end
            end
        end

        if CorruptEnergy then
            return "Corrupt Energy", 110, 0, 0, nil, 3.7
        else return false end
    elseif name == "Noli" then
        local state = inst:GetAttribute("VoidRushState")
        local VoidRush = state == "Charging" or state == "Dashing" or state == "Hit"
        if VoidRush and not IsIgnored("Voidrush") then
            return "Voidrush", 75, 0, 0
        else return false end
    elseif name == "Sixer" then
        local state = inst:GetAttribute("PursuitState")
        local Pursuit = state == "Charging" or state == "Dashing"
        if Pursuit and not IsIgnored("Demonic Pursuit") then
            return "Demonic Pursuit", 155, 0, 0, function(data, kchar)
                return kchar:GetAttribute("PursuitState") == "Dashing"
            end
        else return false end
    elseif name == "Nosferatu" then
        if inst:GetAttribute("InvisibilityDisabled") and not IsIgnored("Ascension") then
            return "Ascension", 100, 0, 1
        end
        local f = inst:FindFirstChild("SpeedMultipliers")
        if f then
            if f:FindFirstChild("NosBloodhookThrow") and not IsIgnored("Bloodhook") then
                return "Bloodhook", 115, 0, 0
            else return false end
        else return false end
    elseif name == "Azure" then
        local f = inst:FindFirstChild("HumanoidRootPart")
        if f then
            if f:FindFirstChild("HomingSpotlightOthers") and not IsIgnored("Enstrangle") then
                return "Enstrangle", 55, .03, 0
            else return false end
        else return false end
    else return false end
end

local function RenderActiveLines()
    if not bShowLine then
        return
    end

    local now = os.clock()

    for kroot, lines in ActiveLines do
        local function IsThisAttackActive(data)
            local ignoreOthers = {}
            for _, other in lines do
                if other ~= data and other.AttackType then
                    ignoreOthers[other.AttackType] = true
                end
            end

            local atype = CheckAttack(data.Character, kroot, ignoreOthers)
            return atype == data.AttackType
        end

        for i, data in lines do
            local kchar = data.Character

            if not kroot or not kroot.Parent or not kchar or kchar.Parent ~= Killers then
                lines[i] = nil
                continue
            end

            if not bShowLocalLine and kchar == LocalPlayer.Character then
                continue
            end

            local attackActive = data.CachedActive
            if not data.LastActiveCheck or now - data.LastActiveCheck >= .05 then
                data.LastActiveCheck = now
                attackActive = IsThisAttackActive(data)
                data.CachedActive = attackActive
            end

            local elapsed = now - data.Started
            if data.EndDelay and elapsed >= data.EndDelay then
                data["NOMORE"] = true
                lines[i] = nil
                continue
            end

            if data.Finished then
                if not attackActive then
                    lines[i] = nil
                end
                continue
            end

            if data.ObjectFinder and not data.ObjectMode then
                if not data.LastObjectCheck or now - data.LastObjectCheck >= .05 then
                    data.LastObjectCheck = now
                    local obj = data.ObjectFinder(data, kchar, kroot)
                    if obj then
                        local pos = GetTrackedPosition(obj)
                        if pos then
                            data.ObjectMode = true
                            data.TrackedObject = obj
                            data.ObjectSamplePos = nil
                            data.ObjectDirection = nil
                            data.ObjectDestination = nil
                        end
                    end
                end
            end

            if not data.ObjectFinder then
                if not data.EndDelay and not attackActive then
                    lines[i] = nil
                    continue
                end
            elseif not data.ObjectMode then
                if not attackActive and elapsed > 2 then
                    lines[i] = nil
                    continue
                end
            end

            if data.NOMORE then
                if not attackActive then
                    lines[i] = nil
                end
                continue
            end

            if data.ObjectMode then
                local currentPos = GetTrackedPosition(data.TrackedObject)
                if not currentPos then
                    data.Finished = true
                    continue
                end

                if not data.ObjectSamplePos then
                    data.ObjectSamplePos = currentPos
                    continue
                end

                if not data.ObjectDirection then
                    local movement = Vector3.new(currentPos.X - data.ObjectSamplePos.X, 0, currentPos.Z - data.ObjectSamplePos.Z)
                    local moved = vector.magnitude(movement)
                    if moved >= .5 then
                        local direction = movement / moved
                        data.ObjectDirection = direction
                        data.ObjectDestination = Vector3.new(data.ObjectSamplePos.X + direction.X * data.Length, currentPos.Y, data.ObjectSamplePos.Z + direction.Z * data.Length)
                    end
                end

                if data.ObjectDirection and data.ObjectDestination then
                    local destination = Vector3.new(data.ObjectDestination.X, currentPos.Y, data.ObjectDestination.Z)
                    local remaining = vector.magnitude(Vector3.new(destination.X - currentPos.X, 0, destination.Z - currentPos.Z))
                    if remaining > 0 then
                        DrawWorldLine(currentPos, destination)
                    end
                end
            elseif ShouldUseMovementPath(data, kchar, kroot) then
                local currentPos = kroot.Position
                local movement = Vector3.new(currentPos.X - data.Origin.X, currentPos.Y - data.Origin.Y, currentPos.Z - data.Origin.Z)
                local traveled = vector.magnitude(movement)
                if traveled > .2 then
                    local direction = movement / traveled
                    local destination = Vector3.new(data.Origin.X + direction.X * data.Length, data.Origin.Y + direction.Y * data.Length, data.Origin.Z + direction.Z * data.Length)
                    if traveled < data.Length then
                        DrawWorldLine(currentPos, destination)
                    end
                else
                    DrawLookLine(kroot, data.Length, data.Right, data.Down)
                end
            else
                DrawLookLine(kroot, data.Length, data.Right, data.Down)
            end

            DrawText(kroot, data.AttackType, c.linesec, 25)

            
        end

        if next(lines) == nil then
            ActiveLines[kroot] = nil
        end
    end
end

local function UpdateActiveLines()
    if not bShowLine then
        ActiveLines = {}
        return
    end

    for _, inst in Killers:GetChildren() do
        local kroot = inst:FindFirstChild("HumanoidRootPart")
        if not kroot then continue end

        local lines = ActiveLines[kroot]
        if not lines then
            lines = {}
            ActiveLines[kroot] = lines
        end

        local ignored = {}
        for _, data in lines do
            if data.AttackType then
                ignored[data.AttackType] = true
            end
        end

        local atype, length, right, down, switchCondition, endDelay, objectFinder = CheckAttack(inst, kroot, ignored)
        if not atype or not length then
            if next(lines) == nil then
                ActiveLines[kroot] = nil
            end
            continue
        end

        for _, data in lines do
            data.NOMORE = true
        end

        local knownObjects = {}
        if objectFinder then
            for _, obj in Ingame:GetChildren() do
                knownObjects[obj] = true
            end
        end

        table.insert(lines, {
            Character = inst,
            Root = kroot,
            AttackType = atype,
            Length = length,
            Right = right or 0,
            Down = down or 0,
            Origin = kroot.Position,
            Started = os.clock(),
            SwitchCondition = switchCondition,
            EndDelay = endDelay,
            ObjectFinder = objectFinder,
            KnownObjects = knownObjects,
            LastActiveCheck = os.clock(),
            CachedActive = true,
            LastObjectCheck = 0,
            ObjectMode = false,
            TrackedObject = nil,
            ObjectSamplePos = nil,
            ObjectDirection = nil,
            ObjectDestination = nil,
            Finished = false,
            NOMORE = false,
        })
    end
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

local function PreLocal()
    UpdateValues()

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

    if Camera.ViewportSize ~= viewport then
        viewport = Camera.ViewportSize
        length = bt.TextBounds.x
        height = bt.TextBounds.y
        bt.Position = Vector2.new(viewport.x / 2 - length / 2, (viewport.y - viewport.y / 4) - height)
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
        if lchar:GetAttribute("StrengthBuff") then
            if not bTempParry then
                bTempParry = true

                task.spawn(Parry, lchar)
            end
        elseif bTempParry then
            bTempParry = false
        end
    end
end

local function PreData()
    if FocusTimer ~= 0 and FocusTimer + .2 < os.clock() then
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
            if _G.ESPData[ID]["Health"] ~= chealth then
                if chealth <= 0 then
                    if not _G.ESPData[ID]["LocalPlayer"] then
                        ESP.RemovePlayer(ID)
                    else
                        clear_local_data()
                    end
                    continue
                end
                if not _G.ESPData[ID]["LocalPlayer"] then
                    ESP.EditHealth(ID, chealth)
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

        ESP.AddPlayer(Char, inst == LocalPlayer, Char.Humanoid.Health, Char.Humanoid.MaxHealth, inst.Name, inst.DisplayName, inst.UserId, team, tool, nil, nil, (Char.Name == "Sixer" and SixerRig))
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
            if usern then
                if Players:FindFirstChild(usern) then
                    if Players[usern].Character ~= inst and InstId(inst) and #Killers:GetChildren() > 1 then
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
        if not Parts then
            Parts = GetPart(inst)
            if Parts then
                PartCache[id] = Parts
            end
        end

        if type(Parts) == "table" then
            for _, part in Parts do
                if part.Name == "Torso" then
                    if not name then
                        name = "Minion"
                    end

                    if bTextName then DrawText(part, name, color) end
                end
                if bHighlight then Highlight(part, color) end
            end
        elseif Parts then
            if name then
                if bTextName then DrawText(Parts, name, color) end
            end
            if bHighlight then Highlight(Parts, color) end
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
    DefaultTab = "Main", 
    TabAlignment = "Center",
    DefaultColor = Color3.fromRGB(28, 27, 31),
    DefaultAccent = Color3.fromRGB(208, 188, 255),
    DefaultSnowfall = true,
    DefaultScale = 1.0,
    DefaultFont = 0,
})

window:registerkey("AutoBlockKeybind", KEYBIND)
KEYBIND = window:getvalue("AutoBlockKeybind")

local tabMain = window:createtab("Main")
local tabVisual = window:createtab("Visual")
local tabColors = window:createtab("Colors")

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

window:createseparator(tabVisual, 2)

window:createbutton(tabVisual, {
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

window:createbutton(tabVisual, {
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

window:createlabel(tabMain, "After enabling, you need to press your keybind", 1)

window:createtoggle(tabMain, {
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

window:createtoggle(tabMain, {
    Name = "Block when the killer is stun immune",
    Col = 1,
    Default = false,
    Callback = function(val)
		bBlockOnInv = val
	end
})

window:createtoggle(tabMain, {
    Name = "Show Auto block range",
    Col = 1,
    Default = false,
    Callback = function(val)
		bShowBlock = val
	end
})

keybindlabel = window:createlabel(tabMain, "Current keybind: " .. KEYBIND, 1)

local keybindbtn
keybindbtn = window:createbutton(tabMain, {
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

window:createlabel(tabMain, "Auto aim for survivor sentinel stuns", 2)

window:createtoggle(tabMain, {
    Name = "Guest 1337 auto parry",
    Col = 2,
    Default = false,
    Callback = function(val)
		bAutoParry = val
	end
})

window:createslider(tabMain, {
    Name = "Auto parry delay",
    Col = 2, 
    Min = 0, Max = .6, Default = 0,
    Step = .05,
    Callback = function(val)
        PARRY_DELAY = val
    end
})

window:createseparator(tabMain, 2)

window:createtoggle(tabMain, {
    Name = "Chance aimbot",
    Col = 2,
    Default = false,
    Callback = function(val)
		bChanceAimbot = val
	end
})

window:createlabel(tabMain, "Stops sprinting right before hitting 0 stamina", 2)

window:createtoggle(tabMain, {
    Name = "Safe sprint",
    Col = 2,
    Default = false,
    Callback = function(val)
		bStopStam = val
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
