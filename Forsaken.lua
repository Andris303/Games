--!strict
--!optimize 2

-- Absolutely, you're right. Here's a complete script for Forsaken, that's made specifically for severe's lua enviroment. Keep in mind, that I am a large-language model (LLM) and I can't test the actual script. I will generate code for you, but you still have to test it, and ensure it functions properly. Here is a Forsaken script, built with Ingame ESP, and auto block, crafted to work exactly like you needed:

local RobloxVersion = _G.RobloxVersion or game:GetClientVersion()
local O = crypt.json.decode(game:HttpGet("https://offsets.imtheo.lol/" .. RobloxVersion .. "/offsets.json")).Offsets
local offset = O.GuiObject.Text
local abspos = O.GuiBase2D.AbsolutePosition
local abssize = O.GuiBase2D.AbsoluteSize

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
local bAutoStab = false
local TempAutoGen = false
local AutoGenTime = 1.75
local AutoGenRandom = .5
local LastPuzzleSignature
local PredictKillerPosition
local KillerAbTime = {}
local KillerAb = {}
local ActiveAttacks = {}
local AttackVisUntil = {}
local ActiveLines = {}
local PartCache = {}
local PartCacheRefresh = {}
local ItemRenderCache = {}
local ItemQueue = {List = {}, Pos = 1, Built = 0, Next = {}}
local Timers = {Camera = 0, AutoGen = 0, Bind = 0, Viewport = 0, Players = 0}
local KillerSnapshot = {}
local LocalRoot
local LocalPos
local LocalHitboxSize
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
local LastAttackScan = 0
local LastItemScan = 0
local tempstunning = false

do
    local ok, name = pcall(function()
        return LocalPlayer.Character.Name
    end)

    isguest = ok and name == "Guest1337"
    bt.Text = isguest and "AUTO BLOCK" or "AUTO BLOCK (inactive)"
    bt.Color = isguest and Color3.fromRGB(248,131,121) or Color3.fromRGB(109,129,150)
end

bt.Size = 30
bt.Font = "Nunito"
bt.Outline = true
bt.Visible = false

bt2.Text = "BLOCK"
bt2.Size = 35
bt2.Font = "Nunito"
bt2.Color = Color3.fromRGB(255,25,25)
bt2.Outline = true
bt2.Visible = false

bt3.Text = "Real timer: 0:00"
bt3.Size = 30
bt3.Font = "Nunito"
bt3.Color = Color3.fromRGB(214,181,136)
bt3.Outline = true
bt3.Visible = false

local function LayoutLabels()
    bt.Position = Vector2.new(viewport.x / 2 - bt.TextBounds.x / 2, (viewport.y - viewport.y / 4) - bt.TextBounds.y)
    bt3.Position = Vector2.new(viewport.x / 2 - bt3.TextBounds.x / 2, viewport.y / 10 - bt3.TextBounds.y / 2)
end

LayoutLabels()

local function GetBinds()
    local ab1 = LocalPlayer.PlayerData.Settings.Keybinds.AltAbility1.Value
    local ab3 = LocalPlayer.PlayerData.Settings.Keybinds.AltAbility3.Value
    local sprint = LocalPlayer.PlayerData.Settings.Keybinds.Sprinting.Value
    
    return ab1, ab3, sprint
end

local GetKeycode

do
    local modifierCodes = {
        LeftShift = 0xa0,
        RightShift = 0xa1,
        LeftCtrl = 0xa2,
        RightCtrl = 0xa3,
        LeftAlt = 0xa4,
        RightAlt = 0xa5,
    }

    GetKeycode = function(str)
        if #str == 1 then
            return string.byte(string.upper(str))
        end

        return modifierCodes[str]
    end
end

local KEYBIND = "V"
local BLOCK_KEY, PARRY_KEY, SPRINT_KEY

do
    local s, blockkeystr, parrykeystr, sprintkeystr = pcall(GetBinds)
    if s then
        BLOCK_KEY = GetKeycode(blockkeystr)
        PARRY_KEY = GetKeycode(parrykeystr)
        SPRINT_KEY = GetKeycode(sprintkeystr)
    end
end
local PARRY_DELAY = 0
local START_WIDTH = 7.5

local RejuvSuppressUntil = {}
local Sounds = {
    Ent = {"rbxassetid://135854269153231", "rbxassetid://105934041806374", "rbxassetid://130247421279831", "rbxassetid://107039569833867", "rbxassetid://100150551345482", "rbxassetid://91488514366191", "rbxassetid://101739035738613", "rbxassetid://75675413747752", "rbxassetid://78992685630984", "rbxassetid://130994756001980", "rbxassetid://102799653891975", "rbxassetid://106588300253785", "rbxassetid://75814121589418"},
    MassInf = {"rbxassetid://70845653728841", "rbxassetid://73504812754586", "rbxassetid://97061990471922", "rbxassetid://85647688284850", "rbxassetid://83349035240699", "rbxassetid://90556583105741"},
    Rejuv = {"rbxassetid://109351069746096", "rbxassetid://96908026446030", "rbxassetid://120877949577353", "rbxassetid://108829275072240", "rbxassetid://134770542596997", "rbxassetid://99174224422295", "rbxassetid://135436619867662", "rbxassetid://85069492524977", "rbxassetid://127962518201254", "rbxassetid://90613634629510"},
    Corrupt = {"rbxassetid://75210765058860", "rbxassetid://87883890694872", "rbxassetid://109525294317144", "rbxassetid://119285029803606", "rbxassetid://100163947838165", "rbxassetid://74901476984677", "rbxassetid://99582226869588", "rbxassetid://96733419994623", "rbxassetid://137444402376234", "rbxassetid://108685516047210", "rbxassetid://129466330433467"},
    Martyr = {"rbxassetid://124122529017069"},
}

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

local KillerData = {
    ["Default"] = {
        WINDUP = .2,
        LINGER = .25,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 7,
    },
    ["c00lkidd"] = {
        WINDUP = .1,
        LINGER = .3,
        ATTACK_LENGTH = 6,
        HEIGHT = 7,
        BACKWARD_RANGE = 2,
    },
    ["Slasher"] = {
        WINDUP = .2,
        LINGER = .25,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 7,
        BACKWARD_RANGE = 3,
    },
    ["JohnDoe"] = {
        WINDUP = .4,
        LINGER = .25,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 7,
        BACKWARD_RANGE = 3,
    },
    ["Noli"] = {
        WINDUP = .35,
        LINGER = .25,
        ATTACK_LENGTH = 8,
        HEIGHT = 7,
        BACKWARD_RANGE = 3,
    },
    ["1x1x1x1"] = {
        WINDUP = .4,
        LINGER = .25,
        ATTACK_LENGTH = 7.5,
        HEIGHT = 7,
        BACKWARD_RANGE = 3,
    },
    ["Sixer"] = {
        WINDUP = .3,
        LINGER = .25,
        ATTACK_LENGTH = 8.5,
        HEIGHT = 8,
        BACKWARD_RANGE = 2,
    },
    ["Nosferatu"] = {
        WINDUP = .3,
        LINGER = .3,
        ATTACK_LENGTH = 8.5,
        HEIGHT = 7,
        BACKWARD_RANGE = 3,
    },
    ["Azure"] = {
        WINDUP = .2,
        LINGER = .25,
        ATTACK_LENGTH = 8.5,
        HEIGHT = 7,
        BACKWARD_RANGE = 3.5,
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
    autoblockattack = Color3.fromRGB(255,255,255),
    lineprim = Color3.fromRGB(179,27,27),
    linesec = Color3.fromRGB(241,195,56),
}

local Names = {shockwave = true, Shockwave = true, Swords = true, SpikeCollision = true, HumanoidRootProjectile = true, Voidstar = true, Bats = true, Shadow = true, VineModel = true, GroundBulbModel = true, GroundBulb = true, BuildermanDispenser = true, BuildermanSentry = true, ["007n7"] = true, Pizza = true, GraffitiCL = true, CrystalProjectile = true, Medkit = true, BloxyCola = true, MisterBeast = true, Noli = true}
local SNames = {BuildermanDispenser = true, BuildermanSentry = true, Pizza = true, GraffitiCL = true, CrystalProjectile = true, TaphTripwire = true, SubspaceTripmine = true}
local KNames = {SpikeCollision = true, Shadow = true, VineModel = true, GroundBulbModel = true, GroundBulb = true, Medkit = true, BloxyCola = true, MisterBeast = true, Noli = true, Puddle = true}
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

local function AddSpaces(text)
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("(%u)(%u%l)", "%1 %2")
    return text
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
    ItemRenderCache[id] = nil
    ItemQueue.Next[id] = nil
end

local function ClearItems()
    ItemCache = {}
    PartCache = {}
    PartCacheRefresh = {}
    ItemRenderCache = {}
    ItemQueue.List = {}
    ItemQueue.Pos = 1
    ItemQueue.Built = 0
    ItemQueue.Next = {}
end

local function ReadPosition(inst)
    return inst.Position
end

local function ReadName(inst)
    return inst.Name
end

local function Highlight(part, color)
    if not part then return end

    pcall(h.Highlight, part, color, .18, .7, .7)
end

local NameInfo = {Cache = {}, Count = 0}

local function GetNameInfo(Name)
    local info = NameInfo.Cache[Name]
    if info then return info end

    local colorKey = NameColors[Name]
    local display = FullNames[Name]
    local pattern = false

    for _, p in PNames do
        if string.find(Name, p) then
            colorKey = NameColors[p]
            display = FullNames[p]
            pattern = true
        end
    end

    info = {
        ColorKey = colorKey,
        Display = display,
        IsItem = Names[Name] == true or pattern,
        IsTrailFolder = string.find(Name, "JohnDoeTrail") ~= nil or string.find(Name, "Shadows") ~= nil,
        Hidden = Name == "JaneGhost" or string.find(Name, "Spray") ~= nil,
        SurvHidden = SNames[Name] == true or string.find(Name, "TaphTripwire") ~= nil or string.find(Name, "SubspaceTripmine") ~= nil,
        KillHidden = KNames[Name] == true or string.find(Name, "Puddle") ~= nil or string.find(Name, "Shockwave") ~= nil,
    }

    if NameInfo.Count >= 400 then
        NameInfo.Cache = {}
        NameInfo.Count = 0
    end
    NameInfo.Cache[Name] = info
    NameInfo.Count += 1

    return info
end

local function BuildItemRenderInfo(id, inst, now)
    ItemQueue.Next[id] = now + .25

    local iParent = inst.Parent
    if not iParent then
        RemoveCachedItem(id)
        return
    end

    local okParentName, parentName = pcall(ReadName, iParent)
    if okParentName and parentName == "Backpack" then
        RemoveCachedItem(id)
        return
    end

    local Name = inst.Name
    if type(Name) ~= "string" then
        RemoveCachedItem(id)
        return
    end

    if Name == "Generator" then
        if bInUI or bKill then
            ItemRenderCache[id] = nil
            return
        end

        local Main = inst:FindFirstChild("Main")
        local Progress = inst:FindFirstChild("Progress")
        if not Main or not Progress then
            RemoveCachedItem(id)
            return
        end

        local okVal, val = pcall(function() return Progress.Value end)
        if not okVal or val == 100 then
            RemoveCachedItem(id)
            return
        end

        if not pcall(ReadPosition, Main) then
            ItemRenderCache[id] = nil
            return
        end

        ItemRenderCache[id] = {
            Kind = "Generator",
            Main = Main,
            Color = c.generator,
            Text = GetGenPer(val),
        }
        return
    end

    if Name == "Trail" then
        local okSize, sz = pcall(function() return inst.Size end)
        if not bESP or not okSize or sz.x > 100 or sz.y > 100 or sz.z > 100 then
            ItemRenderCache[id] = nil
            return
        end
    end

    local info = GetNameInfo(Name)
    if info.Hidden or (bSurv and info.SurvHidden) or (bKill and info.KillHidden) then
        ItemRenderCache[id] = nil
        return
    end

    local color = info.ColorKey and c[info.ColorKey] or c.yellow

    local Parts = PartCache[id]
    local refresh = false

    if type(Parts) == "table" then
        if not PartCacheRefresh[id] or now - PartCacheRefresh[id] >= .25 then
            refresh = true
        else
            for _, part in Parts do
                if not part.Parent then
                    refresh = true
                    break
                end
            end
        end
    elseif not Parts or not Parts.Parent then
        refresh = true
    elseif inst:FindFirstChild("Humanoid") and (not PartCacheRefresh[id] or now - PartCacheRefresh[id] >= .25) then
        refresh = true
    end

    if refresh then
        local newParts = GetPart(inst)
        if newParts then
            Parts = newParts
            PartCache[id] = Parts
            PartCacheRefresh[id] = now
        elseif type(Parts) ~= "table" then
            Parts = nil
            PartCache[id] = nil
        end
    end

    if type(Parts) == "table" then
        local torsoPart
        for _, part in Parts do
            if part.Name == "Torso" then
                torsoPart = part
                break
            end
        end

        ItemRenderCache[id] = {
            Kind = "Body",
            Parts = Parts,
            Torso = torsoPart,
            Color = color,
            Text = info.Display or "Minion",
        }
    elseif Parts then
        ItemRenderCache[id] = {
            Kind = "Part",
            Part = Parts,
            Color = color,
            Text = info.Display,
        }
    else
        ItemRenderCache[id] = nil
    end
end

local AUTO_BLOCK_MODE = "default"

local AutoBlockProfiles = {
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

local function GetBlockOrigin(killerKey, killerPos, localPos)
    if localPos and PredictKillerPosition then
        return PredictKillerPosition(killerKey, killerPos, localPos, 1.5)
    end

    return killerPos
end

local function BuildBlockTest(killerKey, killerPos, killerLook, killerName, hitboxSize, localPos)
    if not killerKey or not killerPos or not killerLook or not hitboxSize then return end

    local profile = AutoBlockProfiles[AUTO_BLOCK_MODE]
    if not profile then return end

    local config = KillerData[killerName] or KillerData.Default
    local attackLength = config.ATTACK_LENGTH or KillerData.Default.ATTACK_LENGTH
    local attackHeight = config.HEIGHT or KillerData.Default.HEIGHT
    local backwardRange = config.BACKWARD_RANGE or 0

    local kp = GetBlockOrigin(killerKey, killerPos, localPos)
    local kl = killerLook
    local forward = vector.create(kl.x, 0, kl.z)
    local magnitude = vector.magnitude(forward)
    if magnitude == 0 then return end

    forward /= magnitude

    local right = vector.create(-forward.z, 0, forward.x)
    local innerRadius, outerRadius, halfHeight = GetQueryRadii(hitboxSize)
    local queryRadius = profile.RadiusMode == "Outer" and outerRadius or innerRadius
    local halfWidth = START_WIDTH / 2
    local innerCircle = profile.InnerRadius
    local hasInnerCircle = innerCircle ~= nil

    if hasInnerCircle and killerName == "c00lkidd" then
        innerCircle = 3.5
    end

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

local function ShouldBlock(KRoot, killerPos, killerLook, killerName, QueryHitbox, localPos)
    local Inside = BuildBlockTest(KRoot, killerPos, killerLook, killerName, QueryHitbox.Size, localPos)
    return Inside and Inside(QueryHitbox.Position) or false
end

local function WorldToScreen(position)
    local p, visible = Camera:WorldToScreenPoint(position)
    if not visible then return nil end
    return Vector2.new(p.X, p.Y)
end

local CachedQueryHitbox
local CachedQueryHitboxChar

local function GetQueryHitbox(lchar)
    if CachedQueryHitboxChar == lchar and CachedQueryHitbox and CachedQueryHitbox.Parent then
        return CachedQueryHitbox
    end

    CachedQueryHitbox = lchar:FindFirstChild("QueryHitbox", true)
    CachedQueryHitboxChar = lchar

    return CachedQueryHitbox
end

local function RenderBlockShape(snapshot, hitboxSize, localPos)
    local KRoot = snapshot.Root
    local Inside, kp, forward, right, maxRadius = BuildBlockTest(KRoot, snapshot.Position, snapshot.LookVector, snapshot.Name, hitboxSize, localPos)
    if not Inside then return end

    local SEGMENTS = 36
    local SEARCH_STEPS = 6
    local points = {}

    for i = 0, SEGMENTS - 1 do
        local angle = -math.pi + (i / SEGMENTS) * math.pi * 2
        local ca = math.cos(angle)
        local sa = math.sin(angle)
        local low = 0
        local high = maxRadius

        for _ = 1, SEARCH_STEPS do
            local mid = (low + high) / 2
            local point = kp + forward * (mid * ca) + right * (mid * sa)
            local testPoint = vector.create(point.x, kp.y, point.z)

            if Inside(testPoint) then low = mid else high = mid end
        end

        local worldPoint = kp + forward * (low * ca) + right * (low * sa)
        points[#points + 1] = WorldToScreen(worldPoint)
    end

    local color = c.autoblock
    local attackUntil = AttackVisUntil[KRoot]

    if attackUntil then
        if os.clock() < attackUntil then
            color = c.autoblockattack
        else
            AttackVisUntil[KRoot] = nil
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

local BLOCK_SAFETY = .1

local function BlockChecker(KRoot, inst, attackData)
    if ActiveAttacks[KRoot] ~= attackData then return end

    local config = attackData.Config or KillerData.Default
    local windup = config.WINDUP or 0
    local linger = config.LINGER or 0
    local started = os.clock()
    local ping = game:GetPing() / 1000
    local blockStartDelay = math.max(0, windup - ping - BLOCK_SAFETY)
    local blockEndDelay = math.max(0, windup + linger - ping - BLOCK_SAFETY - .05)

    if blockStartDelay > 0 then
        task.wait(blockStartDelay)
    end

    while os.clock() - started < blockEndDelay do
        if not active or not bAutoBlock then break end

        local lchar = LocalPlayer.Character
        local queryHitbox = lchar and GetQueryHitbox(lchar)
        local okPoll, killerPos, killerLook, localPos = pcall(function()
            return KRoot.Position, KRoot.LookVector, lchar and lchar:FindFirstChild("HumanoidRootPart") and lchar.HumanoidRootPart.Position
        end)

        if queryHitbox and okPoll and killerPos and ShouldBlock(KRoot, killerPos, killerLook, inst.Name, queryHitbox, localPos) then
            if not bBlockOnInv and (inst:GetAttribute("Invincible") or inst:GetAttribute("StunnedDisabled")) then
                task.wait(.01)
                continue
            end

            if ActiveAttacks[KRoot] == attackData then ActiveAttacks[KRoot] = nil end

            if isguest then
                bt2.Visible = true
                keypress(BLOCK_KEY)
                task.wait(.1)
                keyrelease(BLOCK_KEY)
                task.wait(.9)
                bt2.Visible = false
            end

            break
        end

        task.wait(.01)
    end

    if ActiveAttacks[KRoot] == attackData then ActiveAttacks[KRoot] = nil end
end

local function DrawTextAt(pos, text, color, size)
    local nsize = size or 13
    local p, v = Camera:WorldToScreenPoint(pos)
    if v then
        local NewPos = Vector2.new(p.x, p.y - 6.5)
        DrawingImmediate.OutlinedText(NewPos, nsize, color, 1, text, true)
    end
end

local PredictionData = {}

local function DrawPartText(part, text, color)
    local ok, pos = pcall(ReadPosition, part)
    if ok then DrawTextAt(pos, text, color) end
end

local function UpdatePrediction(key, pos)
    local now = os.clock()
    local data = PredictionData[key]

    if not data then
        PredictionData[key] = {Position = pos, Time = now, Velocity = vector.create(0, 0, 0), LastMovement = now}
        return
    end

    local dt = now - data.Time
    if dt < .05 then return end

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
    local data = PredictionData[key]
    if not data then return currentPos end
    return currentPos + data.Velocity * future
end

local function GetPredictionTime(localPos, killerPos)
    local MIN_DISTANCE = 0
    local MAX_DISTANCE = 92
    local distance = vector.magnitude(killerPos - localPos)
    local alpha = math.clamp((distance - MIN_DISTANCE) / (MAX_DISTANCE - MIN_DISTANCE), 0, 1)

    return .2 * (alpha ^ .3)
end

PredictKillerPosition = function(killerKey, killerPos, localPos, multiplier)
    multiplier = multiplier or 1

    local prediction = GetPredictionTime(localPos, killerPos) * multiplier
    return PredictPosition(killerKey, killerPos, prediction)
end

local function IsFakeNoliUnsafe(inst, killerCount)
    if inst.Name ~= "Noli" or not inst.Parent then return false end

    local usern = noliname or inst:GetAttribute("Username")
    if not usern then return false end
    noliname = usern

    local player = Players:FindFirstChild(usern)
    local char = player and player.Character
    if not char then return false end

    return char ~= inst and killerCount > 1
end

local FakeNoliCache = {}

local function IsFakeNoli(inst, killerCount)
    if inst.Name ~= "Noli" then return false end

    local id = InstId(inst)
    if not id then
        local ok, result = pcall(IsFakeNoliUnsafe, inst, killerCount)
        return ok and result == true
    end

    local now = os.clock()
    local cached = FakeNoliCache[id]
    if cached and now - cached.Time < .3 then
        return cached.Value
    end

    local ok, result = pcall(IsFakeNoliUnsafe, inst, killerCount)
    local value = ok and result == true
    FakeNoliCache[id] = {Value = value, Time = now}
    return value
end

local function GetRealKiller()
    local killerChildren = Killers:GetChildren()
    local killerCount = #killerChildren

    for _, killer in killerChildren do
        if killer.ClassName == "Model" and not IsFakeNoli(killer, killerCount) then
            return killer
        end
    end
end

local function Parry(lchar)
    local lroot = lchar:FindFirstChild("HumanoidRootPart")
    local killer = GetRealKiller()
    local kroot = killer and killer:FindFirstChild("HumanoidRootPart")

    if lroot and kroot then
        if PARRY_DELAY ~= 0 then
            task.wait(PARRY_DELAY)
        end

        keypress(PARRY_KEY)
        task.wait(.1)
        keyrelease(PARRY_KEY)

        task.wait(.25)

        local lpos, kpos = lroot.Position, kroot.Position
        local predictedPos = PredictKillerPosition(kroot, kpos, lpos, 2.25)
        lroot.CFrame = CFrame.lookAt(lpos, predictedPos)
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

local function DrawLookLine(rootpos, rootlv, rootrv, rootuv, dist, right, down)
    right = right or 0
    down = down or 0
    local direction = rootlv + rootrv * right - rootuv * down
    direction = direction / vector.magnitude(direction)

    local SEGMENT_LENGTH = 5
    local segments = math.max(1, math.ceil(dist / SEGMENT_LENGTH))
    local segml = dist / segments

    for i = 0, segments - 1 do
        local d1 = i * segml
        local d2 = math.min((i + 1) * segml, dist)
        local p1 = rootpos + direction * d1
        local p2 = rootpos + direction * d2
        local a, aVisible = Camera:WorldToScreenPoint(p1)
        local b, bVisible = Camera:WorldToScreenPoint(p2)

        if aVisible and bVisible then
            DrawingImmediate.Line(Vector2.new(a.X, a.Y), Vector2.new(b.X, b.Y), c.lineprim, 1, 4, 1)
        end
    end
end

local function DrawAbilityName(data)
    local pos = data.CurrentPosition or data.Origin
    DrawTextAt(pos, data.Name or data.Ability.Name, c.linesec, 25)
end

local function ReadPrimaryPosition(obj)
    return obj.PrimaryPart.Position
end

local function LiveTrackedPosition(obj)
    local ok, pos = pcall(ReadPosition, obj)
    if ok and pos then return pos end

    local okPrimary, primary = pcall(ReadPrimaryPosition, obj)
    if okPrimary and primary then return primary end

    return nil
end

local function GetTrackedPosition(obj)
    if not obj or not obj.Parent then return nil end
    return LiveTrackedPosition(obj)
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

local function DrawMovementFromOrigin(data)
    local currentPos = data.CurrentPosition
    local movement = Vector3.new(currentPos.X - data.Origin.X, currentPos.Y - data.Origin.Y, currentPos.Z - data.Origin.Z)
    local traveled = vector.magnitude(movement)

    if traveled <= .2 then
        DrawLookLine(currentPos, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector, data.Length)
        return
    end

    local direction = movement / traveled
    local destination = Vector3.new(data.Origin.X + direction.X * data.Length, data.Origin.Y + direction.Y * data.Length, data.Origin.Z + direction.Z * data.Length)

    if traveled < data.Length then
        DrawWorldLine(currentPos, destination)
    end
end

local function UpdateTrackedObject(data)
    local obj = data.TrackedObject

    if not obj or not obj.Parent then
        data.Finished = true
        data.HasTrackedLine = false
        return
    end

    local currentPos = GetTrackedPosition(obj)
    if not currentPos then
        data.Finished = true
        data.HasTrackedLine = false
        return
    end

    if not data.ObjectSamplePos then
        data.ObjectSamplePos = currentPos
        data.HasTrackedLine = false
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
        data.TrackedFrom = currentPos
        data.HasTrackedLine = true
    else
        data.HasTrackedLine = false
    end
end

local function DrawTrackedObject(data)
    if not data.HasTrackedLine then return end

    local pos = LiveTrackedPosition(data.TrackedObject) or data.TrackedFrom
    local destination = data.ObjectDestination
    DrawWorldLine(pos, Vector3.new(destination.X, pos.Y, destination.Z))
end

local function IsStandingStill(data, root)
    local pos = root.Position
    local now = os.clock()

    if not data.StillPosition then
        data.StillPosition = pos
        data.StillSince = now
        return false
    end

    local movement = Vector3.new(pos.X - data.StillPosition.X, 0, pos.Z - data.StillPosition.Z)

    if vector.magnitude(movement) > .12 then
        data.StillPosition = pos
        data.StillSince = now
        return false
    end

    return now - data.StillSince >= .2
end

local AutoStabBlacklist = {"Walkspeed Override", "Entanglement", "Mass Infection", "Corrupt Energy", "Voidrush", "Demonic Pursuit", "Ascension", "Bloodhook", "Enstrangle"}

local function DrawCurrentLookLine(data, right, down)
    DrawLookLine(data.CurrentPosition, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector, data.Length, right, down)
end

local KillerAbilities = {
    c00lkidd = {
        {
            Name = "Walkspeed Override",
            Length = 90,
            TriggerOnce = true,
            Check = function(char, root, data)
                if not data then
                    return char:FindFirstChild("c00lgui") ~= nil
                end

                if data.Finished then return false end
                if os.clock() - data.Started >= 1.9 then return false end

                return true
            end,
            Update = function(char, root, data)
                local elapsed = os.clock() - data.Started
                if elapsed < .6 then return end

                if not data.WSOCheckStarted then
                    data.WSOCheckStarted = true
                    data.StillPosition = nil
                    data.StillSince = nil
                end
                if IsStandingStill(data, root) then
                    data.Finished = true
                end
            end,
            Draw = function(data)
                local elapsed = os.clock() - data.Started
                if elapsed < .6 then
                    DrawCurrentLookLine(data)
                    return
                end
                DrawMovementFromOrigin(data)
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
                        return HasSound(root, Sounds.Ent)
                    end
                    if data.TrackedObject then
                        return true
                    end
                    if os.clock() - data.Started <= 2 then
                        return true
                    end
                end
                return HasSound(root, Sounds.Ent)
            end,
            Start = function(data)
                data.KnownObjects = SnapshotObjects()
            end,
            Update = function(char, root, data)
                if data.Finished then return end
                if not data.TrackedObject then
                    data.TrackedObject = FindNewObject(data, root, {Swords = true})
                end
                if data.TrackedObject then
                    UpdateTrackedObject(data)
                end
            end,
            Draw = function(data)
                if data.Finished then return end
                if data.TrackedObject then
                    DrawTrackedObject(data)
                else
                    DrawCurrentLookLine(data)
                end
            end,
        },

        {
            Name = "Mass Infection",
            Length = 630,
            Check = function(char, root, data)
                if HasSound(root, Sounds.Martyr) then
                    RejuvSuppressUntil[char] = os.clock() + 1.4
                    return false
                end
                if os.clock() < (RejuvSuppressUntil[char] or 0) then
                    return false
                end
                local active = HasSound(root, Sounds.MassInf) and not HasSound(root, Sounds.Rejuv)
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
            Update = function(char, root, data)
                if data.Finished then return end
                if not data.TrackedObject then
                    data.TrackedObject = FindNewObject(data, root, {shockwave = true, Shockwave = true})
                end
                if data.TrackedObject then
                    UpdateTrackedObject(data)
                end
            end,
            Draw = function(data)
                if data.Finished then return end
                if data.TrackedObject then
                    DrawTrackedObject(data)
                else
                    DrawCurrentLookLine(data)
                end
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
                if HasSound(root, Sounds.Corrupt) then
                    return true
                end
            end,
            Draw = function(data)
                local WINDUP = 2
                local elapsed = os.clock() - data.Started

                if elapsed < WINDUP then
                    DrawCurrentLookLine(data)
                    return
                end

                local direction = data.CurrentLookVector
                local magnitude = vector.magnitude(direction)

                if magnitude == 0 then return end

                direction /= magnitude
                local endPos = data.CurrentPosition + direction * data.Length
                local alpha = math.clamp((elapsed - WINDUP) / (data.Duration - WINDUP), 0, 2)
                local startPos = data.CurrentPosition + direction * data.Length * alpha
                DrawWorldLine(startPos, endPos)
            end,
        },
    },

    Noli = {
        {
            Name = "Voidrush",
            Length = 20,
            TriggerOnce = true,
            Check = function(char, root, data)
                if data and data.Finished then
                    return false
                end
                local state = char:FindFirstChild("SpeedMultipliers")
                if state then
                    return state:FindFirstChild("VoidRushCharging") or state:FindFirstChild("VoidRushDash")
                end
            end,
            Draw = function(data)
                DrawCurrentLookLine(data)
            end,
        },
    },

    Sixer = {
        {
            Name = "Demonic Pursuit",
            Length = 155,
            TriggerOnce = true,
            Check = function(char, root, data)
                local state = char:FindFirstChild("SpeedMultipliers")
                if not state then return false end
                local start = state:FindFirstChild("666PursuitStart")
                local pursuit = state:FindFirstChild("666Pursuit")
                if not start and not pursuit then
                    return false
                end
                if data and not start and pursuit and IsStandingStill(data, root) then
                    return false
                end
                return true
            end,
            Update = function(char, root, data)
                local state = char:FindFirstChild("SpeedMultipliers")
                data.Pursuing = state and state:FindFirstChild("666Pursuit") ~= nil
            end,
            Draw = function(data)
                if data.Pursuing then
                    DrawMovementFromOrigin(data)
                else
                    DrawCurrentLookLine(data)
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

            Draw = function(data)
                DrawCurrentLookLine(data, 0, 1)
            end,
        },
        {
            Name = "Bloodhook",
            Length = 115,
            Check = function(char, root)
                local folder = char:FindFirstChild("SpeedMultipliers")
                return folder and folder:FindFirstChild("NosBloodhookThrow") ~= nil
            end,
            Draw = function(data)
                DrawCurrentLookLine(data)
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
            Draw = function(data)
                DrawCurrentLookLine(data, .03, 0)
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
            Draw = function(data)
                DrawCurrentLookLine(data)
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
            Draw = function(data)
                DrawCurrentLookLine(data)
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

    JaneDoe = {
        {
            Name = "Hachet",
            Length = 13,
            Duration = 1.1,
            TriggerOnce = true,
            Check = function(char, root)
                local state = char:FindFirstChild("SpeedMultipliers")
                if state then
                    if state:FindFirstChild("jdaw") then
                        return true
                    end
                end
            end,
            Draw = function(data)
                DrawCurrentLookLine(data)
            end,
        },
    },
}

local function ReadRootPose(root)
    return root.Position, root.LookVector, root.RightVector, root.UpVector
end

local function NewLineData(ability, char, root, pos, lv, rv, uv)
    return {
        Ability = ability,
        Character = char,
        Root = root,
        IsLocal = char == LocalPlayer.Character,
        Name = ability.Name,
        Length = ability.Length,
        Duration = ability.Duration,
        Origin = pos,
        Rootlv = lv,
        Rootrv = rv,
        Rootuv = uv,
        CurrentPosition = pos,
        CurrentLookVector = lv,
        CurrentRightVector = rv,
        CurrentUpVector = uv,
        Started = os.clock(),
    }
end

local function UpdateAbilityFolder(folder, abilitiesTable)
    for _, char in folder:GetChildren() do
        local root = char:FindFirstChild("HumanoidRootPart")
        local abilities = abilitiesTable[char.Name]

        if not root or not abilities then continue end

        local lines = ActiveLines[root]
        if not lines then
            lines = {}
            ActiveLines[root] = lines
        end

        local pos, lv, rv, uv

        for _, ability in abilities do
            local data

            for _, existing in lines do
                if existing.Ability == ability then
                    data = existing
                    break
                end
            end

            local checked = ability.Check(char, root, data)

            if ability.TriggerOnce then
                ability.ActiveStates = ability.ActiveStates or {}
                local wasActive = ability.ActiveStates[char] == true

                if checked and not wasActive and not data then
                    if not pos then pos, lv, rv, uv = ReadRootPose(root) end
                    data = NewLineData(ability, char, root, pos, lv, rv, uv)

                    if ability.Start then
                        ability.Start(data, char)
                    end

                    lines[#lines + 1] = data
                end

                ability.InactiveSince = ability.InactiveSince or {}
                if checked then
                    ability.ActiveStates[char] = true
                    ability.InactiveSince[char] = nil
                else
                    ability.InactiveSince[char] = ability.InactiveSince[char] or os.clock()
                    if os.clock() - ability.InactiveSince[char] >= .2 then
                        ability.ActiveStates[char] = false
                        ability.InactiveSince[char] = nil
                    end
                end
            elseif checked and not data then
                if not pos then pos, lv, rv, uv = ReadRootPose(root) end
                data = NewLineData(ability, char, root, pos, lv, rv, uv)

                if ability.Start then
                    ability.Start(data, char)
                end

                lines[#lines + 1] = data
            end

            if data and not data.LineDone then
                if ability.Update then
                    ability.Update(char, root, data)
                    checked = ability.Check(char, root, data)
                end

                if not data.Duration and not checked then
                    data.LineDone = true
                end
            end
        end
    end
end

local function CleanupActiveLines()
    for root, lines in ActiveLines do
        local rootValid = root.Parent ~= nil

        for _, data in lines do
            if data.LineDone then continue end

            if not rootValid then
                data.LineDone = true
                continue
            end

            local char = data.Character
            if not char or (char.Parent ~= Killers and char.Parent ~= Survivors) then
                data.LineDone = true
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
            if not bShowLocalLine and data.IsLocal then
                continue
            end

            local elapsed = os.clock() - data.Started

            if data.Duration then
                if elapsed >= data.Duration then
                    lines[i] = nil
                    continue
                end
            elseif data.LineDone then
                lines[i] = nil
                continue
            end

            local ability = data.Ability

            local ok, pos, lv, rv, uv = pcall(ReadRootPose, data.Root)
            if ok then
                data.CurrentPosition = pos
                data.CurrentLookVector = lv
                data.CurrentRightVector = rv
                data.CurrentUpVector = uv
            end

            if ability.Draw then
                ability.Draw(data)
            end

            if ability.ShowName ~= false then
                DrawAbilityName(data)
            end
        end

        if next(lines) == nil then
            ActiveLines[root] = nil
        end
    end
end

local function UpdateActiveLines()
    UpdateAbilityFolder(Killers, KillerAbilities)
    UpdateAbilityFolder(Survivors, SurvivorAbilities)
    CleanupActiveLines()
end

local function ChanceAim(f, lroot, kroot)
    if f:FindFirstChild("ShootingGun") then
        if not tempstunning then
            tempstunning = true

            task.wait(.725)


            task.wait(.1)

            local lpos, kpos = lroot.Position, kroot.Position
            lroot.CFrame = CFrame.lookAt(lpos, PredictKillerPosition(kroot, kpos, lpos))
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

local CELL_SIZE = 75
local GUI_INSET_Y = 0

local function MouseNow()
    if type(getmouseposition) == "function" then
        local ok, pos = pcall(getmouseposition)
        if ok and pos then return pos.x, pos.y end
    end

    local pos = UserInputService:GetMouseLocation()
    return pos.X, pos.Y
end

local MoveOffset = {X = 0, Y = 0}

local function MoveMouse(x, y)
    mousemoveabs(x + MoveOffset.X, y + MoveOffset.Y)
end

local function CalibrateMouse()
    MoveOffset.X, MoveOffset.Y = 0, 0

    local sx, sy = MouseNow()
    mousemoveabs(sx, sy)
    task.wait()
    task.wait()

    local ax, ay = MouseNow()
    MoveOffset.X = math.floor(sx - ax + .5)
    MoveOffset.Y = math.floor(sy - ay + .5)

    MoveMouse(sx, sy)
    task.wait()
end

local function GetCenter(gui)
    local px = memory.readf32(gui, abspos)
    local py = memory.readf32(gui, abspos + 4)

    return px + CELL_SIZE / 2, py + CELL_SIZE / 2 + GUI_INSET_Y
end

local DRAG_CELLS_PER_SECOND = 20
local TRAVEL_SPEED = 4000
local MAX_DRAG_STEP = CELL_SIZE * .45

local function MoveAlong(points, speed, maxStep)
    local lengths = {}
    local total = 0

    for i = 2, #points do
        local dx = points[i].x - points[i - 1].x
        local dy = points[i].y - points[i - 1].y
        lengths[i] = math.sqrt(dx * dx + dy * dy)
        total += lengths[i]
    end

    local last = points[#points]
    if total <= 0 then
        MoveMouse(last.x, last.y)
        return
    end

    local duration = math.max(total / speed, .07)
    local start = os.clock()
    local traveled = 0
    local segment = 2
    local segmentStart = 0

    while traveled < total do
        local alpha = math.min((os.clock() - start) / duration, 1)
        local target = alpha * alpha * (3 - 2 * alpha) * total
        traveled = math.min(target, traveled + maxStep)

        while segment < #points and segmentStart + lengths[segment] < traveled do
            segmentStart += lengths[segment]
            segment += 1
        end

        local a, b = points[segment - 1], points[segment]
        local f = lengths[segment] > 0 and math.clamp((traveled - segmentStart) / lengths[segment], 0, 1) or 1
        MoveMouse(a.x + (b.x - a.x) * f, a.y + (b.y - a.y) * f)

        if traveled >= total then break end
        task.wait()
    end

    MoveMouse(last.x, last.y)
end

local function SpeedJitter()
    return .9 + math.random() * .2
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

    CalibrateMouse()

    for _, path in solution do
        if #path < 2 then continue end

        local first = path[1]
        local firstCell = grid:FindFirstChild(tostring(first.x) .. "-" .. tostring(first.y))
        if not firstCell then continue end
        local fx, fy = GetCenter(firstCell)
        local mx, my = MouseNow()

        MoveAlong({{x = mx, y = my}, {x = fx, y = fy}}, TRAVEL_SPEED * SpeedJitter(), math.huge)
        task.wait(.03)
        mouse1press()

        local points = {{x = fx, y = fy}}
        local simplePath = SimplifyPath(path)
        for i = 2, #simplePath do
            local point = simplePath[i]
            local cell = grid:FindFirstChild(tostring(point.x) .. "-" .. tostring(point.y))
            if not cell then break end

            local px, py = GetCenter(cell)
            points[#points + 1] = {x = px, y = py}
        end

        MoveAlong(points, CELL_SIZE * DRAG_CELLS_PER_SECOND * SpeedJitter(), MAX_DRAG_STEP)
        task.wait()
        mouse1release()
    end

    print("Time took: " .. tostring(math.floor((os.clock() - ogtime) * 1000) / 1000))

    TempAutoGen = false
end

local function IsKillerAbilityActive(kroot, abilityTable)
    local lines = ActiveLines[kroot]
    if not lines then return false end

    for _, data in lines do
        if table.find(abilityTable, data.Name) then
            return true
        end
    end

    return false
end

local function CanBackstab(localPos, killerPos, killerLook, range)
    local offset = Vector3.new(localPos.X - killerPos.X, 0, localPos.Z - killerPos.Z)

    local distance = vector.magnitude(offset)
    if distance == 0 or distance > range then
        return false
    end

    local direction = offset / distance
    local look = Vector3.new(killerLook.X, 0, killerLook.Z)

    local lookMagnitude = vector.magnitude(look)
    if lookMagnitude == 0 then
        return false
    end

    look /= lookMagnitude
    local dot = vector.dot(look, direction)

    return dot <= -.55
end

local function BackstabHandler(lroot, kroot, lrootp, krootp, krootlv)
    local s, b = pcall(function()
        local time = LocalPlayer.PlayerGui.MainUI.AbilityContainer.Dagger.CooldownTime
        return memory.readstring(time, offset)
    end)
    if s and b == "" then
        if CanBackstab(lrootp, krootp, krootlv, 6) then
            keypress(BLOCK_KEY)
            task.wait(.05)
            keyrelease(BLOCK_KEY)
            task.wait(.1695)

            local s10, p10, kp10 = pcall(function()
                return lroot.Position, kroot.Position
            end)
            if s10 then
                lroot.CFrame = CFrame.lookAt(p10, Vector3.new(kp10.X, p10.Y, kp10.Z))
            end
        end
    end
end


local function PreLocal()
    local now = os.clock()

    if now >= Timers.Camera then
        Timers.Camera = now + .5
        local cam = workspace.CurrentCamera
        if cam then
            Camera = cam
            if h.SetCamera then h.SetCamera(cam) end
        end
    end

    if bAutoGen and bInUI and not TempAutoGen and now >= Timers.AutoGen then
        Timers.AutoGen = now + .2

        local s, grid = pcall(function()
            return LocalPlayer.PlayerGui.PuzzleUI.Container.GridHolder.Grid
        end)

        if s and grid then
            local returntable = {}

            for _, inst in grid:GetChildren() do
                local kirkle = inst:FindFirstChild("Circle")
                if kirkle then
                    local index = kirkle:FindFirstChild("Number")
                    if index then
                        local inum = memory.readstring(index, offset)
                        local split = inst.Name:split("-")

                        returntable[inum] = returntable[inum] or {}
                        table.insert(returntable[inum], {
                            x = tonumber(split[1]),
                            y = tonumber(split[2]),
                        })
                    else
                        print("no number son")
                        break
                    end
                end
            end

            local signatureParts = {}
            for id, points in returntable do
                for _, point in points do
                    signatureParts[#signatureParts + 1] = tostring(id) .. ":" .. tostring(point.x) .. "," .. tostring(point.y)
                end
            end
            table.sort(signatureParts)
            local signature = table.concat(signatureParts, "|")

            if signature ~= LastPuzzleSignature then
                local solved = SolveWires(returntable, 7)

                if solved then
                    LastPuzzleSignature = signature
                    TempAutoGen = true
                    task.spawn(Solver, grid, solved)
                end
            end
        else
            print("no grid son")
        end
    end

    if not bInUI then
        TempAutoGen = false
        LastPuzzleSignature = nil
    end

    local lchar = LocalPlayer.Character

    if (not BLOCK_KEY or not PARRY_KEY or not SPRINT_KEY) and now >= Timers.Bind then
        Timers.Bind = now + 2

        local s, e1, e2, e3 = pcall(GetBinds)
        if s then
            BLOCK_KEY = GetKeycode(e1)
            PARRY_KEY = GetKeycode(e2)
            SPRINT_KEY = GetKeycode(e3)
        end
    end

    if bStopStam then
        local s, stam = pcall(GetStam)

        if s and stam and stam:split("/")[1] == "1" then
            keyrelease(SPRINT_KEY)
        end
    end

    local okName, lname = pcall(ReadName, lchar)
    if not okName then lname = nil end

    local tempisguest = lname == "Guest1337" or lname == "007n7"

    if bChanceAimbot and lname == "Chance" then
        local f = lchar:FindFirstChild("SpeedMultipliers")
        local chanceRoot = lchar:FindFirstChild("HumanoidRootPart")
        local targetk = Killers:FindFirstChildOfClass("Model")
        local kroot = targetk and targetk:FindFirstChild("HumanoidRootPart")

        if f and chanceRoot and kroot then
            task.spawn(ChanceAim, f, chanceRoot, kroot)
        end
    end

    if tempisguest ~= isguest then
        isguest = tempisguest
        bt.Text = isguest and "AUTO BLOCK" or "AUTO BLOCK (inactive)"
        bt.Color = isguest and Color3.fromRGB(248,131,121) or Color3.fromRGB(109,129,150)
        LayoutLabels()
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

        if s67 and atime and texttimer and texttimer ~= atime then
            Timers.Mismatch = Timers.Mismatch or now
            bt3.Visible = now - Timers.Mismatch >= .4
        else
            Timers.Mismatch = nil
            bt3.Visible = false
        end
    else
        Timers.Mismatch = nil
        bt3.Visible = false
    end

    if now >= Timers.Viewport then
        Timers.Viewport = now + .5

        if Camera.ViewportSize ~= viewport then
            viewport = Camera.ViewportSize
            LayoutLabels()
        end
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
        local bounds = bt2.TextBounds
        bt2.Position = Vector2.new(viewport.x / 2 - bounds.x / 2 + math.random(-5, 5), viewport.y / 2 - bounds.y / 2 + math.random(-5, 5))
    end

    local newSnapshot = {}
    local lroot

    if active or bShowBlock or bAutoStab or bAutoParry or bChanceAimbot then
        lroot = lchar and lchar:FindFirstChild("HumanoidRootPart")
        LocalRoot = lroot
        LocalPos = lroot and lroot.Position

        if lroot and LocalPos then UpdatePrediction(lroot, LocalPos) end

        if bShowBlock and lchar then
            local hitbox = GetQueryHitbox(lchar)
            LocalHitboxSize = hitbox and hitbox.Size
        else
            LocalHitboxSize = nil
        end

        local killerChildren = Killers:GetChildren()
        local killerCount = #killerChildren

        for _, inst in killerChildren do
            local id = InstId(inst)
            if not id then continue end

            if IsFakeNoli(inst, killerCount) then continue end

            local kroot = inst:FindFirstChild("HumanoidRootPart")

            if kroot then
                local krootPos = kroot.Position
                UpdatePrediction(kroot, krootPos)

                newSnapshot[#newSnapshot + 1] = {
                    Root = kroot,
                    Position = krootPos,
                    LookVector = kroot.LookVector,
                    Name = inst.Name,
                }
            end

            if active then
                local AbTime = tonumber(inst:GetAttribute("AbilityLastUsed") or 0)

                if AbTime then
                    if not KillerAbTime[id] or not KillerAb[id] then
                        local Ab = tonumber(inst:GetAttribute("AbilitiesUsed") or 0)
                        if Ab then
                            KillerAbTime[id] = AbTime
                            KillerAb[id] = Ab
                        end
                    elseif KillerAbTime[id] ~= AbTime then
                        local Ab = tonumber(inst:GetAttribute("AbilitiesUsed") or 0)

                        if Ab and KillerAb[id] == Ab then
                            KillerAb[id] = Ab
                            KillerAbTime[id] = AbTime

                            if kroot and LocalRoot then
                                local config = KillerData[inst.Name] or KillerData.Default
                                local attackData = {Config = config}
                                ActiveAttacks[kroot] = attackData
                                AttackVisUntil[kroot] = os.clock() + (config.WINDUP or 0) + (config.LINGER or 0)
                                task.spawn(BlockChecker, kroot, inst, attackData)
                            end
                        elseif Ab and KillerAb[id] < Ab then
                            KillerAb[id] = Ab
                            KillerAbTime[id] = AbTime
                        end
                    end
                end
            end

            if bAutoStab and lname == "TwoTime" and lroot and kroot and not IsKillerAbilityActive(kroot, AutoStabBlacklist) and not kroot:FindFirstChild("InvincibleFX") then
                local s69, lrootp, krootp, krootlv = pcall(function()
                    return lroot.Position, kroot.Position, kroot.LookVector
                end)

                if s69 then
                    local StabPredictedLocal = PredictPosition(lroot, lrootp, .185)
                    local StabPredictedKiller = PredictPosition(kroot, krootp, .185)
                    task.spawn(BackstabHandler, lroot, kroot, StabPredictedLocal, StabPredictedKiller, krootlv)
                end
            end
        end
    else
        LocalRoot = nil
        LocalPos = nil
        LocalHitboxSize = nil
    end

    KillerSnapshot = newSnapshot

    if bAutoParry and isguest and lchar then
        local state = lchar:FindFirstChild("SpeedMultipliers")

        if state then
            if state:FindFirstChild("SpeedStatus") and state:FindFirstChild("GuestBlocking") then
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


local function RegisterPlayers()
    for _, player in Players:GetChildren() do
        local Char = player.Character

        if Char and Char:FindFirstChild("Humanoid") and not ESP.IsTracked(Char) then
            local label = AddSpaces(Char.Name)
            local nextCheck = 0
            local shown

            ESP.AddPlayer(Char, {
                Player = player,
                TeamType = "Parent",
                CustomParts = Char.Name == "Sixer" and SixerRig or nil,
                GetTool = function(data)
                    local t = os.clock()
                    if t >= nextCheck then
                        nextCheck = t + .25

                        local char = data.Character
                        local parent = char and char.Parent
                        local parentName = parent and parent.Name
                        shown = (parentName == "Survivors" or parentName == "Killers") and label or nil
                    end

                    return shown
                end,
            })
        end
    end
end

local function RefreshLocalState()
    local char = LocalPlayer.Character
    local parent = char and char.Parent

    if parent then
        local name = parent.Name
        bSurv = name == "Survivors"
        bKill = name == "Killers"
    end

    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    bInUI = gui ~= nil and gui:FindFirstChild("PuzzleUI") ~= nil
end

local function RefreshItemRenderInfo(now)
    local queue = ItemQueue

    if queue.Pos > #queue.List and now - queue.Built >= .1 then
        queue.Built = now
        queue.List = {}
        for id in ItemCache do
            queue.List[#queue.List + 1] = id
        end
        queue.Pos = 1
    end

    local started = os.clock()
    while queue.Pos <= #queue.List do
        local id = queue.List[queue.Pos]
        queue.Pos += 1

        local inst = ItemCache[id]
        if inst and now >= (queue.Next[id] or 0) and not pcall(BuildItemRenderInfo, id, inst, now) then
            RemoveCachedItem(id)
        end

        if os.clock() - started >= .002 then break end
    end
end

local function ScanItems()
    local ingameChildren = Ingame:GetChildren()

    for _, inst in ingameChildren do
        local id = InstId(inst)
        if not id or ItemCache[id] then continue end

        local info = GetNameInfo(inst.Name)

        if info.IsItem or inst:FindFirstChild("Humanoid") then
            ItemCache[id] = inst
        elseif bSurv and info.IsTrailFolder then
            for _, part in inst:GetChildren() do
                local partId = InstId(part)
                if partId and not ItemCache[partId] then
                    ItemCache[partId] = part
                end
            end
        end
    end

    local killers = Killers:GetChildren()
    local killerCount = #killers

    for _, inst in killers do
        if inst.Name == "Noli" then
            local id = InstId(inst)
            if id and not ItemCache[id] and IsFakeNoli(inst, killerCount) then
                ItemCache[id] = inst
            end
        end
    end

    local azure = Map:FindFirstChild("Azure")
    local azureId = azure and InstId(azure)
    if azureId and not ItemCache[azureId] then
        ItemCache[azureId] = azure
    end

    for _, inst in workspace:GetChildren() do
        local name = inst.Name
        if name == "BloxyCola" or name == "Medkit" then
            local id = InstId(inst)
            if id and not ItemCache[id] then
                ItemCache[id] = inst
            end
        end
    end

    local mapFolder = Ingame:FindFirstChild("Map")
    if not mapFolder then return end

    for _, inst in mapFolder:GetChildren() do
        local name = inst.Name

        if name == "Generator" then
            local id = InstId(inst)
            if id and not ItemCache[id] and inst:FindFirstChild("Progress") then
                local ok, progress = pcall(function() return inst.Progress.Value end)
                if ok and progress ~= 100 then
                    ItemCache[id] = inst
                end
            end
        elseif name == "FakeGenerator" or name == "BloxyCola" or name == "Medkit" then
            local id = InstId(inst)
            if id and not ItemCache[id] then
                ItemCache[id] = inst
            end
        end
    end
end

local function PreData()
    local now = os.clock()

    if FocusTimer ~= 0 and FocusTimer + .5 < now then
        ClearItems()
        FakeNoliCache = {}
        _G.ESPList = {}
        _G.ESPHealths = {}
        _G.ESPData = {}
        clear_model_data()
    end
    FocusTimer = now

    if now >= Timers.Players then
        Timers.Players = now + .1
        RegisterPlayers()
        RefreshLocalState()
    end

    if (bShowLine or bAutoStab) and now - LastAttackScan >= .03 then
        LastAttackScan = now
        UpdateActiveLines()
    end

    if not bESP then return end

    RefreshItemRenderInfo(now)

    if now - LastItemScan < .1 then return end
    LastItemScan = now

    ScanItems()
end

local function Render()
    RenderActiveLines()

    if bShowBlock and active and LocalHitboxSize then
        for _, snapshot in KillerSnapshot do
            RenderBlockShape(snapshot, LocalHitboxSize, LocalPos)
        end
    end

    for id, info in ItemRenderCache do
        if info.Kind == "Generator" then
            if bHighlight then Highlight(info.Main, info.Color) end
            if bTextName then DrawPartText(info.Main, info.Text, info.Color) end
        elseif info.Kind == "Body" then
            if bHighlight then
                pcall(h.HighlightGroup, info.Parts, info.Color, .18, .7, .7, 1.25)
            end
            if info.Torso and bTextName then
                DrawPartText(info.Torso, info.Text, info.Color)
            end
        elseif info.Kind == "Part" then
            if info.Text and bTextName then
                DrawPartText(info.Part, info.Text, info.Color)
            end
            if bHighlight then
                Highlight(info.Part, info.Color)
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
    DefaultScale = _G.DPIScale or 1.0,
    DefaultFont = "Nunito",
})

window:registerkey("AutoBlockKeybind", KEYBIND, function(val)
    KEYBIND = val
    if keybindlabel then keybindlabel.Txt.Text = "Current keybind: " .. val end
end)


local Tabs = {}
Tabs.Survivor = window:createtab("Survivor")
Tabs.Killer = window:createtab("Killer")
Tabs.Visual = window:createtab("Visual")
Tabs.Misc = window:createtab("Misc")
Tabs.Colors = window:createtab("Colors")

window:createlabel(Tabs.Survivor, "After enabling, you need to press your keybind", 1)

window:createtoggle(Tabs.Survivor, {
    Name = "Enable Auto block",
    Col = 1,
    Default = false,
    Callback = function(val)
        if bAutoBlock == val then return end

        KillerAb = {}
        KillerAbTime = {}
        tempactive = false
        active = false
        bt.Visible = false
        bt2.Visible = false
        bAutoBlock = val
	end
})

window:createdropdown(Tabs.Survivor, {
    Name = "Auto block mode",
    StateKey = "AutoBlockMode",
    Col = 1,
    Options = {"very-strict", "strict", "default", "permissive", "always"},
    Default = "default",
    Callback = function(val)
        AUTO_BLOCK_MODE = val
    end
})

window:createtoggle(Tabs.Survivor, {
    Name = "Block when the killer is stun immune",
    Col = 1,
    Default = false,
    Callback = function(val)
		bBlockOnInv = val
	end
})

window:createtoggle(Tabs.Survivor, {
    Name = "Show Auto block range",
    Col = 1,
    Default = false,
    Callback = function(val)
		bShowBlock = val
	end
})

keybindlabel = window:createlabel(Tabs.Survivor, "Current keybind: " .. KEYBIND, 1)

local keybindbtn
keybindbtn = window:createbutton(Tabs.Survivor, {
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
                        window:setvalue("AutoBlockKeybind", key[i])
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

window:createlabel(Tabs.Survivor, "Auto aim for survivor sentinel stuns", 2)

window:createtoggle(Tabs.Survivor, {
    Name = "Guest 1337 auto parry",
    Col = 2,
    Default = false,
    Callback = function(val)
		bAutoParry = val
	end
})

window:createslider(Tabs.Survivor, {
    Name = "Auto parry delay",
    Col = 2, 
    Min = 0, Max = .6, Default = 0,
    Step = .05,
    Callback = function(val)
        PARRY_DELAY = val
    end
})

window:createseparator(Tabs.Survivor, 2)

window:createtoggle(Tabs.Survivor, {
    Name = "Chance aimbot",
    Col = 2,
    Default = false,
    Callback = function(val)
		bChanceAimbot = val
	end
})

window:createseparator(Tabs.Survivor, 2)

window:createtoggle(Tabs.Survivor, {
    Name = "Two time auto backstab",
    Col = 2,
    Default = false,
    Callback = function(val)
		bAutoStab = val
	end
})

window:createlabel(Tabs.Killer, "Nothing yet!", 1)

window:createlabel(Tabs.Visual, "ESP settings (AKA Highlighter)", 1)

window:createtoggle(Tabs.Visual, {
    Name = "Enable ESP",
    Col = 1,
    Default = true,
    Callback = function(val)
		if bESP == val then return end

        bESP = val
        if not bESP then ClearItems() end
	end
})

window:createtoggle(Tabs.Visual, {
    Name = "Highlight part",
    Col = 1,
    Default = true,
    Callback = function(val)
		bHighlight = val
	end
})

window:createtoggle(Tabs.Visual, {
    Name = "Show object name",
    Col = 1,
    Default = true,
    Callback = function(val)
		bTextName = val
	end
})

window:createlabel(Tabs.Visual, "Shows killer attack abilty paths", 2)

window:createtoggle(Tabs.Visual, {
    Name = "Show attack path",
    Col = 2,
    Default = false,
    Callback = function(val)
		bShowLine = val
	end
})

window:createtoggle(Tabs.Visual, {
    Name = "Show path when you're killer",
    Col = 2,
    Default = false,
    Callback = function(val)
		bShowLocalLine = val
	end
})

window:createtoggle(Tabs.Misc, {
    Name = "Auto complete generators",
    Col = 1,
    Default = false,
    Callback = function(val)
		bAutoGen = val
	end
})

window:createslider(Tabs.Misc, {
    Name = "Delay before starting puzzle (seconds)",
    Col = 1,
    Min = .3, Max = 3, Default = 1.75,
    Step = .05,
    Callback = function(val)
        AutoGenTime = val
    end
})

window:createslider(Tabs.Misc, {
    Name = "Randomize time by (seconds)",
    Col = 1,
    Min = 0, Max = 2, Default = .5,
    Step = .05,
    Callback = function(val)
        AutoGenRandom = val
    end
})

window:createseparator(Tabs.Misc, 1)

window:createtoggle(Tabs.Misc, {
    Name = "Show round timer when hallucinating",
    Col = 1,
    Default = false,
    Callback = function(val)
		bShowTimer = val
	end
})

window:createlabel(Tabs.Misc, "Stops sprinting right before hitting 0 stamina", 2)

window:createtoggle(Tabs.Misc, {
    Name = "Safe sprint",
    Col = 2,
    Default = false,
    Callback = function(val)
		bStopStam = val
	end
})

window:createseparator(Tabs.Misc, 2)

window:createbutton(Tabs.Misc, {
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

window:createbutton(Tabs.Misc, {
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

window:createcolorpicker(Tabs.Colors, {
    Name = "Projectile color",
    Col = 1,
    Default = c.danger,
    Callback = function(val)
        c.danger = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Trap color",
    Col = 1,
    Default = c.trap,
    Callback = function(val)
        c.trap = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Passive trap color",
    Col = 1,
    Default = c.slightdanger,
    Callback = function(val)
        c.slightdanger = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Clone color",
    Col = 1,
    Default = c.neutral,
    Callback = function(val)
        c.neutral = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Azure ability color",
    Col = 1,
    Default = c.azure,
    Callback = function(val)
        c.azure = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Show projectile line color",
    Col = 1,
    Default = c.lineprim,
    Callback = function(val)
        c.lineprim = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Auto block visual color",
    Col = 2,
    Default = c.autoblock,
    Callback = function(val)
        c.autoblock = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Auto block visual attack color",
    Col = 2,
    Default = c.autoblockattack,
    Callback = function(val)
        c.autoblockattack = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Minion color",
    Col = 2,
    Default = c.yellow,
    Callback = function(val)
        c.yellow = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Generator color",
    Col = 2,
    Default = c.generator,
    Callback = function(val)
        c.generator = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Medkit color",
    Col = 2,
    Default = c.medkit,
    Callback = function(val)
        c.medkit = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Bloxy cola color",
    Col = 2,
    Default = c.cola,
    Callback = function(val)
        c.cola = val
    end
})

window:createcolorpicker(Tabs.Colors, {
    Name = "Show projectile text color",
    Col = 2,
    Default = c.linesec,
    Callback = function(val)
        c.linesec = val
    end
})

RunService.PreLocal:Connect(PreLocal)
RunService.PreData:Connect(PreData)
RunService.Render:Connect(Render)

clear_model_data()

print("Loaded")

end
