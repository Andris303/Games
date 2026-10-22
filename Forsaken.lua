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
local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()
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
local ItemQueue = {List = {}, Pos = 1, Built = 0, Next = {}, Fresh = {}}
local NonItems = {}
local RoundTimeLeft = nil
local Timers = {Camera = 0, AutoGen = 0, Bind = 0, Viewport = 0, Players = 0, QueryHitbox = 0, RoundTimeLeft = 0}
local KillerSnapshot = {}
local LocalRoot
local LocalPos
local LocalHitboxSize
local active = false
local bt = {Text = "AUTO BLOCK (inactive)", Size = 30, Color = Color3.fromRGB(109,129,150), Position = Vector2.new(0, 0), Visible = false}
local bt2 = {Text = "BLOCK", Size = 35, Color = Color3.fromRGB(255,25,25), Position = Vector2.new(0, 0), Visible = false}
local bt3 = {Text = "Real timer: 0:00", Size = 30, Color = Color3.fromRGB(214,181,136), Position = Vector2.new(0, 0), Visible = false}
local viewport = Camera.ViewportSize
local isguest = false
local FocusTimer = 0
local bParryOnInv = false
local noliname
local window
local FlagSetters = {}
local AppliedFlags = {}
local LastAttackScan = 0
local LastItemScan = 0
local bInRound = false
local tempstunning = false
local preLocalConnect
local preDataConnect
local renderConnect
local ReadNumberAttribute
local Profile = {Totals = {}, Counts = {}, Resets = 0, NextReport = os.clock() + 5, Found = {}}

function Profile.Add(name, started)
    Profile.Totals[name] = (Profile.Totals[name] or 0) + os.clock() - started
    Profile.Counts[name] = (Profile.Counts[name] or 0) + 1
end

local MemoryChildren

do
    local childrenOffset = O.Instance.ChildrenStart
    local childrenEndOffset = O.Instance.ChildrenEnd

    local function ReadU64(address, offset)
        local ok, value = pcall(memory.readu64, address, offset)
        return ok and value or nil
    end

    function MemoryChildren(folder)
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
end

do
    local ok, name = pcall(function()
        return LocalPlayer.Character.Name
    end)

    isguest = ok and name == "Guest1337"
    bt.Text = isguest and "AUTO BLOCK" or "AUTO BLOCK (inactive)"
    bt.Color = isguest and Color3.fromRGB(248,131,121) or Color3.fromRGB(109,129,150)
end

local function LayoutLabels()
    bt.Position = Vector2.new(viewport.x / 2, viewport.y * .75 - bt.Size)
    bt3.Position = Vector2.new(viewport.x / 2, viewport.y / 10 - bt3.Size / 2)
end

local Labels = {bt, bt2, bt3}
local TextFont = {Name = "Nunito"}

local function DrawLabels()
    for _, label in Labels do
        if label.Visible then
            DrawingImmediate.OutlinedText(label.Position, label.Size, label.Color, 1, label.Text, true, TextFont.Name)
        end
    end
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

local blockKey, parryKey, sprintKey

do
    local s, blockkeystr, parrykeystr, sprintkeystr = pcall(GetBinds)
    if s then
        blockKey = GetKeycode(blockkeystr)
        parryKey = GetKeycode(parrykeystr)
        sprintKey = GetKeycode(sprintkeystr)
    end
end
local parryDelay = 0
local parryLookupTime = .6
local parryUpAngle = 75
local parryHitRange = 11
local parryTiltStart = .25
local parryTiltReach = 4
local parryTiltSpeed = 100
local blockDelay = 0
local startWidth = 7.5

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
        windup = .2,
        linger = .25,
        attackLength = 7.5,
        height = 7,
    },
    ["c00lkidd"] = {
        windup = .1,
        linger = .3,
        attackLength = 6,
        height = 7,
        backwardRange = 2,
    },
    ["Slasher"] = {
        windup = .2,
        linger = .25,
        attackLength = 7.5,
        height = 7,
        backwardRange = 3,
    },
    ["JohnDoe"] = {
        windup = .4,
        linger = .25,
        attackLength = 7.5,
        height = 7,
        backwardRange = 3,
    },
    ["Noli"] = {
        windup = .35,
        linger = .25,
        attackLength = 8,
        height = 7,
        backwardRange = 3,
    },
    ["1x1x1x1"] = {
        windup = .4,
        linger = .25,
        attackLength = 7.5,
        height = 7,
        backwardRange = 3,
    },
    ["Sixer"] = {
        windup = .3,
        linger = .25,
        attackLength = 8.5,
        height = 8,
        backwardRange = 2,
    },
    ["Nosferatu"] = {
        windup = .3,
        linger = .3,
        attackLength = 8.5,
        height = 7,
        backwardRange = 3,
    },
    ["Azure"] = {
        windup = .2,
        linger = .25,
        attackLength = 8.5,
        height = 7,
        backwardRange = 3.5,
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
local KNames = {FakeGenerator = true, SpikeCollision = true, Shadow = true, VineModel = true, GroundBulbModel = true, GroundBulb = true, Medkit = true, BloxyCola = true, MisterBeast = true, Noli = true, Puddle = true}
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

local function ValidCharacter(char)
    if not char then return nil end
    local ok, className = pcall(function()
        return memory.rtti(char)
    end)
    if ok and type(className) == "string" and string.find(className, "Model") then
        return char
    end
    return nil
end

local function AddSpaces(text)
    text = text:gsub("(%l)(%u)", "%1 %2")
    text = text:gsub("(%u)(%u%l)", "%1 %2")
    return text
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
    ItemQueue.Fresh = {}
    NonItems = {}
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
        if not Main then
            RemoveCachedItem(id)
            return
        end

        if Main:FindFirstChild("generatorActivate") or not pcall(ReadPosition, Main) then
            ItemRenderCache[id] = nil
            return
        end

        ItemRenderCache[id] = {
            Kind = "Generator",
            Main = Main,
            Color = c.generator,
            Text = "Generator",
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

    local humanoid = inst:FindFirstChild("Humanoid")
    if humanoid and (tonumber(humanoid.Health) or 1) <= 0 then
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
    elseif humanoid and (not PartCacheRefresh[id] or now - PartCacheRefresh[id] >= .25) then
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
            Humanoid = humanoid,
            Color = color,
            Text = info.Display or "Minion",
        }
    elseif Parts then
        ItemRenderCache[id] = {
            Kind = "Part",
            Part = Parts,
            Humanoid = humanoid,
            Color = color,
            Text = info.Display,
        }
    else
        ItemRenderCache[id] = nil
    end
end

local autoBlockMode = "default"

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

    local profile = AutoBlockProfiles[autoBlockMode]
    if not profile then return end

    local config = KillerData[killerName] or KillerData.Default
    local attackLength = config.attackLength or KillerData.Default.attackLength
    local attackHeight = config.height or KillerData.Default.height
    local backwardRange = config.backwardRange or 0

    local kp = GetBlockOrigin(killerKey, killerPos, localPos)
    local kl = killerLook
    local forward = vector.create(kl.x, 0, kl.z)
    local magnitude = vector.magnitude(forward)
    if magnitude == 0 then return end

    forward /= magnitude

    local right = vector.create(-forward.z, 0, forward.x)
    local innerRadius, outerRadius, halfHeight = GetQueryRadii(hitboxSize)
    local queryRadius = profile.RadiusMode == "Outer" and outerRadius or innerRadius
    local halfWidth = startWidth / 2
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
    local charId = InstId(lchar)
    if charId and CachedQueryHitboxChar == charId then
        if CachedQueryHitbox and CachedQueryHitbox.Parent then
            return CachedQueryHitbox
        end

        if os.clock() < Timers.QueryHitbox then
            return nil
        end
    end

    Timers.QueryHitbox = os.clock() + .5
    CachedQueryHitbox = lchar:FindFirstChild("QueryHitbox", true)
    CachedQueryHitboxChar = charId

    return CachedQueryHitbox
end

local function RenderBlockShape(snapshot, hitboxSize, localPos)
    local KRoot = snapshot.Root
    local Inside, kp, forward, right, maxRadius = BuildBlockTest(KRoot, snapshot.Position, snapshot.LookVector, snapshot.Name, hitboxSize, localPos)
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

local blockSafety = .1

local function BlockChecker(KRoot, inst, attackData)
    if ActiveAttacks[KRoot] ~= attackData then return end

    local config = attackData.Config or KillerData.Default
    local windup = config.windup or 0
    local linger = config.linger or 0
    local started = os.clock()
    local ping = game:GetPing() / 1000
    local blockStartDelay = math.max(0, windup + blockDelay - ping - blockSafety)
    local blockEndDelay = math.max(0, windup + linger - ping - blockSafety - .05)

    if blockStartDelay > 0 then
        task.wait(blockStartDelay)
    end

    while os.clock() - started < blockEndDelay do
        if not active or not bAutoBlock or ActiveAttacks[KRoot] ~= attackData then break end

        local lchar = ValidCharacter(LocalPlayer.Character)
        local queryHitbox = lchar and GetQueryHitbox(lchar)
        local okPoll, killerPos, killerLook, localPos = pcall(function()
            return KRoot.Position, KRoot.LookVector, lchar and lchar:FindFirstChild("HumanoidRootPart") and lchar.HumanoidRootPart.Position
        end)

        if queryHitbox and okPoll and killerPos and ShouldBlock(KRoot, killerPos, killerLook, inst.Name, queryHitbox, localPos) then
            if ActiveAttacks[KRoot] == attackData then ActiveAttacks[KRoot] = nil end

            if isguest then
                bt2.Visible = true
                keypress(blockKey)
                task.wait(.1)
                keyrelease(blockKey)
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
        DrawingImmediate.OutlinedText(NewPos, nsize, color, 1, text, true, TextFont.Name)
    end
end

local PredictionData = {}

local function DrawPartText(part, text, color)
    local ok, pos = pcall(ReadPosition, part)
    if ok and pos then DrawTextAt(pos, text, color) end
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
    local minDistance = 0
    local maxDistance = 92
    local distance = vector.magnitude(killerPos - localPos)
    local alpha = math.clamp((distance - minDistance) / (maxDistance - minDistance), 0, 1)

    return .2 * (alpha ^ .3)
end

PredictKillerPosition = function(killerKey, killerPos, localPos, multiplier)
    multiplier = multiplier or 1

    local prediction = GetPredictionTime(localPos, killerPos) * multiplier
    return PredictPosition(killerKey, killerPos, prediction)
end

do
    local attributeRootOffset = 0x38
    local attributeStride = 0x58
    local attributeValueOffset = 0x18

    local function IsHeapPointer(value)
        return type(value) == "number" and value >= 0x10000000000 and value < 0x70000000000
    end

    local function ReadU64(address, offset)
        local ok, value = pcall(memory.readu64, address, offset)
        return ok and value or nil
    end

    local function ReadName(address)
        local size = ReadU64(address, 0x10)
        local capacity = ReadU64(address, 0x18)
        if not size or not capacity or size <= 0 or size > 64 then return "" end

        local stringAddress = address
        if capacity >= 16 then
            stringAddress = ReadU64(address, 0)
            if not IsHeapPointer(stringAddress) then return "" end
        end

        local ok, value = pcall(memory.readstring, stringAddress, 0)
        return ok and type(value) == "string" and value or ""
    end

    local function SearchEntries(first, packed, wantedName)
        if not IsHeapPointer(first) or not packed then return nil, false end

        local count = packed % 0x100000000
        local capacity = math.floor(packed / 0x100000000)
        if count <= 0 or count > capacity or capacity > 256 then return nil, false end

        local valid = false
        for i = 0, count - 1 do
            local entry = first + i * attributeStride
            local namePointer = ReadU64(entry, 0)
            if IsHeapPointer(namePointer) then
                local name = ReadName(namePointer)
                if name == "" then name = ReadName(namePointer + 0x8) end
                if name ~= "" then
                    valid = true
                    if name == wantedName then return entry, true end
                end
            end
        end

        return nil, valid
    end

    local function SearchNode(node, wantedName)
        local first, packed = ReadU64(node, 0x8), ReadU64(node, 0x10)
        if first and packed then
            local entry, valid = SearchEntries(first, packed, wantedName)
            if entry or valid then return entry, valid end
        end

        packed, first = ReadU64(node, 0x8), ReadU64(node, 0x18)
        if first and packed then
            return SearchEntries(first, packed, wantedName)
        end

        return nil, false
    end

    local function FindAttributeEntry(address, wantedName)
        local root = ReadU64(address, attributeRootOffset)
        if not IsHeapPointer(root) then return nil end

        local queue = {root}
        local visited = {}
        local index = 1

        while index <= #queue and index <= 64 do
            local node = queue[index]
            index += 1

            if not visited[node] then
                visited[node] = true

                local entry = SearchNode(node, wantedName)
                if entry then return entry, node end

                for _, offset in {0x0, 0x10} do
                    local pointer = ReadU64(node, offset)
                    if IsHeapPointer(pointer) and not visited[pointer] then
                        queue[#queue + 1] = pointer
                    end
                end
            end
        end

        return nil
    end

    local function ReadEntryNumber(entry)
        local ok, value = pcall(memory.readf64, entry + attributeValueOffset)
        if not ok or type(value) ~= "number" or value ~= value or math.abs(value) > 1e12 then
            return nil
        end
        return value
    end

    local nodes = {}
    local misses = {}
    local modes = {}
    local mismatches = {}

    local function ReadMemory(inst, id, name)
        local node = nodes[id]
        if node then
            local entry, valid = SearchNode(node, name)
            if valid then return entry and ReadEntryNumber(entry) end
            nodes[id] = nil
        end

        local now = os.clock()
        local missedAt = misses[id]
        if missedAt and now - missedAt < 1 then return nil, true end

        local address = tonumber(inst.Data)
        if not address then return nil end

        local entry
        entry, node = FindAttributeEntry(address, name)
        if not node then
            misses[id] = now
            return nil
        end
        misses[id] = nil
        nodes[id] = node
        return entry and ReadEntryNumber(entry)
    end

    local function ReadAttribute(inst, name)
        return tonumber(inst:GetAttribute(name) or 0) or 0
    end

    function ReadNumberAttribute(inst, id, name)
        local mode = modes[id]
        if mode == "Memory" then
            return ReadMemory(inst, id, name) or ReadAttribute(inst, name)
        end

        local value = ReadAttribute(inst, name)
        if mode == "Attribute" or value == 0 then return value end

        local memoryValue, skipped = ReadMemory(inst, id, name)
        if skipped then return value end
        if memoryValue and math.abs(memoryValue - value) < .001 then
            modes[id] = "Memory"
            KillerAbTime[id] = nil
            KillerAb[id] = nil
            print("Attribute reader: reading " .. inst.Name .. "'s attributes from memory")
            return memoryValue
        end

        mismatches[id] = (mismatches[id] or 0) + 1
        if mismatches[id] >= 5 then
            modes[id] = "Attribute"
            print(string.format("Attribute reader: memory read failed for %s (memory %s, GetAttribute %s), using GetAttribute", inst.Name, tostring(memoryValue), tostring(value)))
        end
        return value
    end
end

local function IsFakeNoliUnsafe(inst, username, killerCount)
    username = username or inst:GetAttribute("Username")
    if username then noliname = username end
    username = username or noliname
    if not username or killerCount <= 1 then return false, username end

    local player = Players:FindFirstChild(username)
    local char = player and ValidCharacter(player.Character)
    local charId = char and InstId(char)
    return charId ~= nil and charId ~= InstId(inst), username
end

local FakeNoliCache = {}

local function IsFakeNoli(inst, killerCount)
    if inst.Name ~= "Noli" then return false end

    local id = InstId(inst)
    if not id then return false end

    local now = os.clock()
    local cached = FakeNoliCache[id]
    if cached and now - cached.Time < .3 then
        return cached.Value
    end

    local ok, result, username = pcall(IsFakeNoliUnsafe, inst, cached and cached.Username, killerCount)
    local value = ok and result == true
    FakeNoliCache[id] = {Value = value, Time = now, Username = ok and username or nil}
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
        if parryDelay ~= 0 then
            task.wait(parryDelay)
        end

        if not bParryOnInv then
            local ok, immune = pcall(function()
                return killer:GetAttribute("Invincible") or killer:GetAttribute("StunnedDisabled")
            end)
            if ok and immune then return end
        end

        local aimTime = .35
        local approachEnd = 1.1
        local tiltEnabled = parryUpAngle > 0
        local up = vector.create(0, 1, 0)
        local pitch = math.rad(parryUpAngle)
        local cosPitch, sinPitch = math.cos(pitch), math.sin(pitch)
        local released, aimed = false, false
        local forward, pitchAt, hitAt
        local killerParts, oldHits = {}, {}

        local function SetKillerCollision(enabled)
            for _, part in killerParts do
                pcall(function()
                    part.CanCollide = enabled
                end)
            end
        end

        local function FindHits(onHit)
            local fov = lchar:FindFirstChild("FOVMultipliers")
            if not fov then return end
            for _, child in MemoryChildren(fov) do
                if child.Name == "HitRegistered" then
                    local id = InstId(child)
                    if id then onHit(id) end
                end
            end
        end

        FindHits(function(id)
            oldHits[id] = true
        end)

        keypress(parryKey)
        local start = os.clock()
        local lastNow = start

        while lroot.Parent and kroot.Parent do
            local now = os.clock()
            local elapsed = now - start

            if pitchAt then
                FindHits(function(id)
                    if not oldHits[id] then
                        hitAt = elapsed
                    end
                end)
            end

            if hitAt then
                break
            elseif pitchAt then
                if now >= pitchAt + parryLookupTime then
                    break
                end
            elseif aimed or elapsed >= approachEnd then
                break
            end

            if not released and elapsed >= .1 then
                keyrelease(parryKey)
                released = true
            end

            local lpos, kpos = lroot.Position, kroot.Position

            local frameDt = math.min(now - lastNow, .05)
            lastNow = now

            local flat = vector.create(kpos.X - lpos.X, 0, kpos.Z - lpos.Z)
            local dist = vector.magnitude(flat)

            if not pitchAt and elapsed >= parryTiltStart then
                if tiltEnabled and dist <= parryHitRange then
                    pitchAt = now

                    pcall(function()
                        for _, part in killer:GetDescendants() do
                            if (part.ClassName == "Part" or part.ClassName == "MeshPart") and part.CanCollide then
                                killerParts[#killerParts + 1] = part
                            end
                        end
                    end)
                elseif elapsed >= aimTime then
                    local predictedPos = PredictKillerPosition(kroot, kpos, lpos, 2.25)
                    local predictOffset = predictedPos - kpos
                    local predictLen = vector.magnitude(predictOffset)
                    local maxOffset = dist * .5
                    if predictLen > maxOffset then
                        predictedPos = kpos + predictOffset * (maxOffset / predictLen)
                    end
                    local aimPos = vector.create(predictedPos.X, lpos.Y, predictedPos.Z)
                    if vector.magnitude(aimPos - lpos) > .01 then
                        lroot.CFrame = CFrame.lookAt(lpos, aimPos)
                    end
                    aimed = true
                end
            end

            if pitchAt then
                if dist > .01 then
                    forward = flat / dist
                end
                forward = forward or vector.create(0, 0, -1)

                SetKillerCollision(false)

                local pos = lpos
                local step = math.min(parryTiltSpeed * frameDt, dist - parryTiltReach)
                if step > 0 then
                    pos = lpos + forward * step
                end

                local look = forward * cosPitch + up * sinPitch
                local lookUp = up * cosPitch - forward * sinPitch
                lroot.CFrame = CFrame.lookAt(pos, pos + look, lookUp)
            end
            task.wait()
        end

        if not released then
            keyrelease(parryKey)
        end

        if forward and lroot.Parent then
            local lpos = lroot.Position
            lroot.CFrame = CFrame.lookAt(lpos, lpos + forward)
        end
        SetKillerCollision(true)
    end
end

local AutoStabBlacklist, RenderActiveLines, UpdateActiveLines

do
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
        local segmentLength = 5
        local segments = math.max(1, math.ceil(dist / segmentLength))
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

        local segmentLength = 5
        local segments = math.max(1, math.ceil(dist / segmentLength))
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

        for _, obj in MemoryChildren(Ingame) do
            local id = InstId(obj)
            if id then result[id] = true end
        end

        return result
    end

    local function FindNewObject(data, root, names)
        for _, obj in MemoryChildren(Ingame) do
            if names[obj.Name] and not data.KnownObjects[InstId(obj)] then
                local pos = GetTrackedPosition(obj)

                if pos and vector.magnitude(root.Position - pos) < 30 then
                    return obj
                end
            end
        end
    end

    local function DrawMovementFromOrigin(data)
        local currentPos = data.CurrentPosition
        local movement = Vector3.new(currentPos.X - data.Origin.X, 0, currentPos.Z - data.Origin.Z)
        local traveled = vector.magnitude(movement)

        if traveled <= 2 then
            DrawLookLine(currentPos, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector, data.Length)
            return
        end

        local direction = movement / traveled
        local destination = Vector3.new(data.Origin.X + direction.X * data.Length, currentPos.Y, data.Origin.Z + direction.Z * data.Length)

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

    local function HasLeftOrigin(data, root)
        if data.LeftOrigin then return true end

        local pos = root.Position
        local dx, dz = pos.X - data.Origin.X, pos.Z - data.Origin.Z
        if dx * dx + dz * dz > 4 then
            data.LeftOrigin = true
            data.StillPosition = nil
            data.StillSince = nil
        end

        return data.LeftOrigin == true
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

    AutoStabBlacklist = {"Walkspeed Override", "Entanglement", "Mass Infection", "Corrupt Energy", "Voidrush", "Demonic Pursuit", "Ascension", "Bloodhook", "Enstrangle"}

    local ascensionFeetOffset = 3

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
                    if os.clock() - data.Started < .6 then return end

                    if HasLeftOrigin(data, root) and IsStandingStill(data, root) then
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
                    local windup = 2
                    local elapsed = os.clock() - data.Started

                    if elapsed < windup then
                        DrawCurrentLookLine(data)
                        return
                    end

                    local direction = data.CurrentLookVector
                    local magnitude = vector.magnitude(direction)

                    if magnitude == 0 then return end

                    direction /= magnitude
                    local endPos = data.CurrentPosition + direction * data.Length
                    local alpha = math.clamp((elapsed - windup) / (data.Duration - windup), 0, 2)
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
                    if data and not start and pursuit and data.LeftOrigin and IsStandingStill(data, root) then
                        return false
                    end
                    return true
                end,
                Update = function(char, root, data)
                    local state = char:FindFirstChild("SpeedMultipliers")
                    data.Pursuing = state and state:FindFirstChild("666Pursuit") ~= nil
                    if data.Pursuing then HasLeftOrigin(data, root) end
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
                    local dist = data.Length

                    if LocalPos then
                        local direction = data.CurrentLookVector - data.CurrentUpVector
                        local magnitude = vector.magnitude(direction)
                        if magnitude == 0 then return end

                        local dropY = direction.Y / magnitude
                        local feetY = LocalPos.Y - ascensionFeetOffset

                        if dropY < 0 then
                            dist = math.min(dist, (feetY - data.CurrentPosition.Y) / dropY)
                        end
                    end

                    if dist <= 0 then return end
                    DrawLookLine(data.CurrentPosition, data.CurrentLookVector, data.CurrentRightVector, data.CurrentUpVector, dist, 0, 1)
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
                    if InstId(char) == InstId(ValidCharacter(LocalPlayer.Character)) then return end

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
            IsLocal = InstId(char) == InstId(ValidCharacter(LocalPlayer.Character)),
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

    local function UpdateAbility(ability, char, root, lines, pose)
        local data

        for _, existing in lines do
            if existing.Ability == ability then
                data = existing
                break
            end
        end

        local triggered = ability.Check(char, root)

        local function Create()
            if not pose.Position then
                pose.Position, pose.Look, pose.Right, pose.Up = ReadRootPose(root)
            end

            data = NewLineData(ability, char, root, pose.Position, pose.Look, pose.Right, pose.Up)

            if ability.Start then
                ability.Start(data, char)
            end

            lines[#lines + 1] = data
        end

        if ability.TriggerOnce then
            ability.ActiveStates = ability.ActiveStates or {}
            ability.InactiveSince = ability.InactiveSince or {}

            if triggered and not ability.ActiveStates[char] and not data then
                Create()
            end

            if triggered then
                ability.ActiveStates[char] = true
                ability.InactiveSince[char] = nil
            else
                ability.InactiveSince[char] = ability.InactiveSince[char] or os.clock()
                if os.clock() - ability.InactiveSince[char] >= .2 then
                    ability.ActiveStates[char] = false
                    ability.InactiveSince[char] = nil
                end
            end
        elseif triggered and not data then
            Create()
        end

        if data and not data.LineDone then
            if ability.Update then
                ability.Update(char, root, data)
            end

            if not data.Duration and not ability.Check(char, root, data) then
                data.LineDone = true
            end
        end
    end

    local function UpdateAbilityFolder(folder, abilitiesTable, seenRoots)
        for _, char in folder:GetChildren() do
            local abilities = abilitiesTable[char.Name]
            if not abilities then continue end

            local root = char:FindFirstChild("HumanoidRootPart")
            if not root then continue end
            seenRoots[root] = true

            local lines = ActiveLines[root]
            if not lines then
                lines = {}
                ActiveLines[root] = lines
            end

            local pose = {}

            for _, ability in abilities do
                pcall(UpdateAbility, ability, char, root, lines, pose)
            end
        end
    end

    local function CleanupActiveLines(seenRoots)
        for root in ActiveLines do
            if not seenRoots[root] then
                ActiveLines[root] = nil
            end
        end
    end

    function RenderActiveLines()
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
                if ok and pos and lv and rv and uv then
                    data.CurrentPosition = pos
                    data.CurrentLookVector = lv
                    data.CurrentRightVector = rv
                    data.CurrentUpVector = uv
                end

                if ability.Draw then
                    pcall(ability.Draw, data)
                end

                if ability.ShowName ~= false then
                    pcall(DrawAbilityName, data)
                end
            end

            if next(lines) == nil then
                ActiveLines[root] = nil
            end
        end
    end

    function UpdateActiveLines()
        local seenRoots = {}
        UpdateAbilityFolder(Killers, KillerAbilities, seenRoots)
        UpdateAbilityFolder(Survivors, SurvivorAbilities, seenRoots)
        CleanupActiveLines(seenRoots)
    end
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

local SolveWires, Solver

do
    function SolveWires(Endpoints, Size)
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

    local cellSize = 75
    local guiInsetY = 0

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

        return px + cellSize / 2, py + cellSize / 2 + guiInsetY
    end

    local dragCellsPerSecond = 20
    local travelSpeed = 4000
    local maxDragStep = cellSize * .45

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

    function Solver(grid, solution)
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

            MoveAlong({{x = mx, y = my}, {x = fx, y = fy}}, travelSpeed * SpeedJitter(), math.huge)
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

            MoveAlong(points, cellSize * dragCellsPerSecond * SpeedJitter(), maxDragStep)
            task.wait()
            mouse1release()
        end

        print("Time took: " .. tostring(math.floor((os.clock() - ogtime) * 1000) / 1000))

        TempAutoGen = false
    end
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

local function BackstabHandler(killer, lroot, kroot, lrootp, krootp, krootlv)
    if not CanBackstab(lrootp, krootp, krootlv, 6) then return end

    local okImmune, immune = pcall(function()
        return killer:GetAttribute("Invincible") or killer:GetAttribute("StunnedDisabled")
    end)
    if not okImmune or immune then return end

    local s, b = pcall(function()
        local time = LocalPlayer.PlayerGui.MainUI.AbilityContainer.Dagger.CooldownTime
        return memory.readstring(time, offset)
    end)
    if not s or b ~= "" then return end

    keypress(blockKey)
    task.wait(.05)
    keyrelease(blockKey)
    task.wait(.1695)

    local s10, p10, kp10 = pcall(function()
        return lroot.Position, kroot.Position
    end)
    if s10 then
        lroot.CFrame = CFrame.lookAt(p10, Vector3.new(kp10.X, p10.Y, kp10.Z))
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

local function PreLocal()
    SyncFlags()
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

    local lchar = ValidCharacter(LocalPlayer.Character)

    if (not blockKey or not parryKey or not sprintKey) and now >= Timers.Bind then
        Timers.Bind = now + 2

        local s, e1, e2, e3 = pcall(GetBinds)
        if s then
            blockKey = GetKeycode(e1)
            parryKey = GetKeycode(e2)
            sprintKey = GetKeycode(e3)
        end
    end

    if bStopStam then
        local s, stam = pcall(GetStam)

        if s and stam and stam:split("/")[1] == "1" then
            keyrelease(sprintKey)
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
        if now >= Timers.RoundTimeLeft then
            Timers.RoundTimeLeft = now + .25
            RoundTimeLeft = game.ReplicatedStorage.RoundTimer:GetAttribute("TimeLeft")
        end
        local ctimer = RoundTimeLeft
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

    if bt2.Visible then
        bt2.Position = Vector2.new(viewport.x / 2 + math.random(-5, 5), viewport.y / 2 - bt2.Size / 2 + math.random(-5, 5))
    end

    local newSnapshot = {}
    local lroot

    if bInRound and (active or bShowBlock or bAutoStab or bAutoParry or bChanceAimbot) then
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
                local AbTime = ReadNumberAttribute(inst, id, "AbilityLastUsed")

                if AbTime then
                    if not KillerAbTime[id] or not KillerAb[id] then
                        local Ab = ReadNumberAttribute(inst, id, "AbilitiesUsed")
                        if Ab then
                            KillerAbTime[id] = AbTime
                            KillerAb[id] = Ab
                        end
                    elseif KillerAbTime[id] ~= AbTime then
                        local Ab = ReadNumberAttribute(inst, id, "AbilitiesUsed")

                        if Ab and KillerAb[id] == Ab then
                            KillerAb[id] = Ab
                            KillerAbTime[id] = AbTime

                            local previous = kroot and ActiveAttacks[kroot]
                            if kroot and LocalRoot and not (previous and now - previous.Started < .2) then
                                local config = KillerData[inst.Name] or KillerData.Default
                                local attackData = {Config = config, Started = now}
                                ActiveAttacks[kroot] = attackData
                                AttackVisUntil[kroot] = os.clock() + (config.windup or 0) + (config.linger or 0)
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
                    task.spawn(BackstabHandler, inst, lroot, kroot, StabPredictedLocal, StabPredictedKiller, krootlv)
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


local ItemLabels = {BloxyCola = "COLA"}

local function GetCarriedItems(player, char)
    local items = {}

    for _, container in {char, player:FindFirstChild("Backpack")} do
        if container then
            for _, child in container:GetChildren() do
                if child.ClassName == "Tool" then
                    items[#items + 1] = ItemLabels[child.Name] or string.upper(AddSpaces(child.Name))
                end
            end
        end
    end

    if #items == 0 then return nil end
    return table.concat(items, ", ")
end

local function GetOblation(player, char)
    local value = char:GetAttribute("Oblation")
    if type(value) ~= "number" then
        value = player:GetAttribute("Oblation")
    end
    if type(value) ~= "number" then return nil end

    return tostring(math.floor(math.clamp(value / 15, 0, 1) * 100 + .5)) .. "%"
end

local RegisterPlayers

do
    local registered = {}

    function RegisterPlayers()
        local current = {}

        for _, player in Players:GetChildren() do
            local Char = ValidCharacter(player.Character)
            local charId = Char and InstId(Char)
            if charId then current[charId] = true end

            if charId and Char:FindFirstChild("Humanoid") and not ESP.IsTracked(Char) then
                registered[charId] = true
                local label = AddSpaces(Char.Name)
                local isAzure = Char.Name == "Azure"
                local nextCheck = 0
                local nextExtra = 0
                local inRound = false
                local extra

                ESP.AddPlayer(Char, {
                    Player = player,
                    TeamType = "Parent",
                    CustomParts = Char.Name == "Sixer" and SixerRig or nil,
                    GetTool = function(data)
                        local t = os.clock()
                        local char = data.Character

                        if t >= nextCheck then
                            nextCheck = t + .25

                            local parent = char and char.Parent
                            local parentName = parent and parent.Name
                            inRound = parentName == "Survivors" or parentName == "Killers"
                        end

                        if not inRound then return nil end

                        if t >= nextExtra then
                            nextExtra = t + 1

                            local ok, result = pcall(function()
                                if isAzure then
                                    return GetOblation(player, char)
                                end
                                return GetCarriedItems(player, char)
                            end)
                            extra = ok and result or nil
                        end

                        return extra and (label .. ": " .. extra) or label
                    end,
                })
            end
        end

        for charId in registered do
            if not current[charId] then
                registered[charId] = nil
                ESP.RemovePlayer(charId)
            end
        end
    end
end

local function RefreshLocalState()
    local char = ValidCharacter(LocalPlayer.Character)
    local parent = char and char.Parent

    local name = parent and parent.Name
    bSurv = name == "Survivors"
    bKill = name == "Killers"

    local gui = LocalPlayer:FindFirstChild("PlayerGui")
    bInUI = gui ~= nil and gui:FindFirstChild("PuzzleUI") ~= nil
end

local function AddItem(id, inst)
    ItemCache[id] = inst
    ItemQueue.Fresh[#ItemQueue.Fresh + 1] = id
    local name = inst.Name
    Profile.Found[id] = {Name = name, At = os.clock()}
    local parent = inst.Parent
    print(string.format("[ESP] found %s (id %s, parent %s)", tostring(name), id, parent and tostring(parent.Name) or "nil"))
end

local function ReportDrawn(id)
    local found = Profile.Found[id]
    if found and ItemRenderCache[id] then
        Profile.Found[id] = nil
        print(string.format("[ESP] drawing %s, %.2fs after it was found", tostring(found.Name), os.clock() - found.At))
    end
end

local function RefreshItemRenderInfo(now)
    local queue = ItemQueue
    local started = os.clock()

    while #queue.Fresh > 0 do
        local id = table.remove(queue.Fresh)
        local inst = ItemCache[id]
        if inst and not pcall(BuildItemRenderInfo, id, inst, now) then
            RemoveCachedItem(id)
        end
        ReportDrawn(id)

        if os.clock() - started >= .002 then return end
    end

    if queue.Pos > #queue.List and now - queue.Built >= .1 then
        queue.Built = now
        queue.List = {}
        for id in ItemCache do
            queue.List[#queue.List + 1] = id
        end
        queue.Pos = 1
    end

    while queue.Pos <= #queue.List do
        local id = queue.List[queue.Pos]
        queue.Pos += 1

        local inst = ItemCache[id]
        if inst and now >= (queue.Next[id] or 0) and not pcall(BuildItemRenderInfo, id, inst, now) then
            RemoveCachedItem(id)
        end
        ReportDrawn(id)

        if os.clock() - started >= .002 then break end
    end
end

local function ScanItems()
    local now = os.clock()
    local ingameChildren = MemoryChildren(Ingame)
    local nonItems = {}
    local present = {}

    for _, inst in ingameChildren do
        local id = InstId(inst)
        if not id then continue end
        present[id] = true
        if ItemCache[id] then continue end

        local seenAt = NonItems[id]
        if seenAt and now - seenAt > 1 then
            nonItems[id] = seenAt
            continue
        end

        local info = GetNameInfo(inst.Name)
        local okHumanoid, humanoid = false, nil
        if not info.IsItem then
            okHumanoid, humanoid = pcall(function()
                return inst:FindFirstChild("Humanoid")
            end)
        end

        if info.IsItem or (okHumanoid and humanoid) then
            AddItem(id, inst)
        elseif not bKill and info.IsTrailFolder then
            for _, part in MemoryChildren(inst) do
                local partId = InstId(part)
                if partId then
                    present[partId] = true
                    if not ItemCache[partId] then
                        AddItem(partId, part)
                    end
                end
            end
        elseif not info.IsTrailFolder then
            if not seenAt then
                print(string.format("[ESP] ignored %s (%s)", tostring(inst.Name), tostring(inst.ClassName)))
            end
            nonItems[id] = seenAt or now
        end
    end
    NonItems = nonItems
    Profile.Add("ScanIngame", now)

    local killers = Killers:GetChildren()
    local killerCount = #killers

    for _, inst in killers do
        if inst.Name == "Noli" then
            local id = InstId(inst)
            if id then
                present[id] = true
                if not ItemCache[id] and IsFakeNoli(inst, killerCount) then
                    AddItem(id, inst)
                end
            end
        end
    end

    local started = os.clock()
    local azure = Map:FindFirstChild("Azure")
    local azureId = azure and InstId(azure)
    if azureId then
        present[azureId] = true
        if not ItemCache[azureId] then
            AddItem(azureId, azure)
        end
    end

    for _, inst in MemoryChildren(workspace) do
        local name = inst.Name
        if name == "BloxyCola" or name == "Medkit" then
            local id = InstId(inst)
            if id then
                present[id] = true
                if not ItemCache[id] then
                    AddItem(id, inst)
                end
            end
        end
    end

    Profile.Add("ScanWorkspace", started)

    started = os.clock()
    local mapFolder = Ingame:FindFirstChild("Map")
    if mapFolder then
        for _, inst in MemoryChildren(mapFolder) do
            local name = inst.Name

            if name == "Generator" then
                local id = InstId(inst)
                if id then
                    present[id] = true
                    if not ItemCache[id] then
                        AddItem(id, inst)
                    end
                end
            elseif name == "FakeGenerator" or name == "BloxyCola" or name == "Medkit" then
                local id = InstId(inst)
                if id then
                    present[id] = true
                    if not ItemCache[id] then
                        AddItem(id, inst)
                    end
                end
            end
        end
    end

    Profile.Add("ScanMap", started)

    for id in ItemCache do
        if not present[id] then
            RemoveCachedItem(id)
        end
    end

    for id, info in ItemRenderCache do
        if info.Humanoid then
            local ok, health = pcall(function()
                return info.Humanoid.Health
            end)
            if not ok or (tonumber(health) or 1) <= 0 then
                ItemRenderCache[id] = nil
            end
        end
    end
end

local function PreData()
    local now = os.clock()

    if FocusTimer ~= 0 and FocusTimer + .5 < now then
        Profile.Resets += 1
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
        local started = os.clock()
        RegisterPlayers()
        RefreshLocalState()
        Profile.Add("Players", started)

        local inRound = Ingame:FindFirstChild("Map") ~= nil
        if bInRound and not inRound then
            ActiveLines = {}
        end
        bInRound = inRound
    end

    if bInRound and (bShowLine or bAutoStab) then
        if now - LastAttackScan >= .03 then
            LastAttackScan = now
            local started = os.clock()
            pcall(UpdateActiveLines)
            Profile.Add("AttackLines", started)
        end
    elseif next(ActiveLines) then
        ActiveLines = {}
    end

    if now >= Profile.NextReport then
        local elapsed = now - Profile.NextReport + 5
        Profile.NextReport = now + 5
        local parts = {}
        for _, name in {"PreLocal", "PreData", "Render", "Players", "AttackLines", "Build", "Scan", "ScanIngame", "ScanWorkspace", "ScanMap"} do
            local count = Profile.Counts[name] or 0
            local total = (Profile.Totals[name] or 0) * 1000
            parts[#parts + 1] = string.format("%s %.0f/s %.2fms avg %.1fms/s", name, count / elapsed, count > 0 and total / count or 0, total / elapsed)
        end
        local cached, drawn, queued = 0, 0, #ItemQueue.List - ItemQueue.Pos + 1
        for _ in ItemCache do cached += 1 end
        for _ in ItemRenderCache do drawn += 1 end
        print("[Profile] " .. table.concat(parts, " | "))
        print(string.format("[Profile] items cached %d, drawn %d, waiting in queue %d, fresh %d, full resets %d", cached, drawn, math.max(queued, 0), #ItemQueue.Fresh, Profile.Resets))
        Profile.Totals, Profile.Counts, Profile.Resets = {}, {}, 0
    end

    if not bESP then return end

    local started = os.clock()
    RefreshItemRenderInfo(now)
    Profile.Add("Build", started)

    if now - LastItemScan < .1 then return end
    LastItemScan = now

    started = os.clock()
    ScanItems()
    Profile.Add("Scan", started)
end

local function Render()
    DrawLabels()

    if LocalRoot then
        local ok, pos = pcall(ReadPosition, LocalRoot)
        if ok and pos then LocalPos = pos end
    end

    RenderActiveLines()

    if bShowBlock and active and LocalHitboxSize then
        for _, snapshot in KillerSnapshot do
            local ok, pos, look = pcall(function()
                return snapshot.Root.Position, snapshot.Root.LookVector
            end)
            if ok and pos and look then
                snapshot.Position = pos
                snapshot.LookVector = look
            end
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

window = UI.new({
    Title = "Andris: Forsaken",
    Subtitle = "Support | Exploits",
    Version = "3.4.1",
    Folder = "AndrisForsaken",
    Footer = "This script is in active development! New features releasing soon",
    UpdateNotice = {"V3.4.1", "This script now uses ok0f's V2 UI library."},
    OnUnload = function()
        preLocalConnect:Disconnect()
        preDataConnect:Disconnect()
        renderConnect:Disconnect()
        ESP.Clear()
        clear_model_data()
    end,
    OnReload = function()
        loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Games/refs/heads/main/Forsaken.lua"))()
    end,
})

do
    local survivor = window:tab("Survivor")
    local autoBlock = survivor:section("AUTO BLOCK")

    autoBlock:toggle({Name = "Enable Auto block", Flag = "AutoBlock", Default = false})
    FlagSetters.AutoBlock = function(val)
        if bAutoBlock == val then return end

        KillerAb = {}
        KillerAbTime = {}
        active = val
        bt.Visible = val
        bt2.Visible = false
        bAutoBlock = val
    end

    autoBlock:dropdown({
        Name = "Auto block mode",
        Flag = "AutoBlockMode",
        Values = {"very-strict", "strict", "default", "permissive", "always"},
        Default = "default",
    })
    FlagSetters.AutoBlockMode = function(val)
        autoBlockMode = val
    end

    autoBlock:slider({Name = "Auto block delay", Flag = "AutoBlockDelay", Min = 0, Max = .5, Default = 0, Step = .01})
    FlagSetters.AutoBlockDelay = function(val)
        blockDelay = val
    end

    autoBlock:toggle({Name = "Show Auto block range", Flag = "ShowBlock", Default = false})
    FlagSetters.ShowBlock = function(val)
        bShowBlock = val
    end

    local abilities = survivor:section("ABILITIES")

    abilities:label("Auto aim for survivor sentinel stuns")

    abilities:toggle({Name = "Guest 1337 auto parry", Flag = "AutoParry", Default = false})
    FlagSetters.AutoParry = function(val)
        bAutoParry = val
    end

    abilities:slider({Name = "Auto parry delay", Flag = "ParryDelay", Min = 0, Max = .6, Default = 0, Step = .05})
    FlagSetters.ParryDelay = function(val)
        parryDelay = val
    end

    abilities:slider({Name = "Auto parry upwards angle (fling killer, blatant)", Flag = "ParryUpAngle", Min = 0, Max = 90, Default = 0, Step = 5})
    FlagSetters.ParryUpAngle = function(val)
        parryUpAngle = val
    end

    abilities:toggle({Name = "Parry when the killer is stun immune", Flag = "ParryOnInv", Default = false})
    FlagSetters.ParryOnInv = function(val)
        bParryOnInv = val
    end

    abilities:toggle({Name = "Chance aimbot", Flag = "ChanceAimbot", Default = false})
    FlagSetters.ChanceAimbot = function(val)
        bChanceAimbot = val
    end

    abilities:toggle({Name = "Two time auto backstab", Flag = "AutoStab", Default = false})
    FlagSetters.AutoStab = function(val)
        bAutoStab = val
    end

    window:tab("Killer"):label("Nothing yet!")

    local visual = window:tab("Visual")
    local esp = visual:section("ESP")

    esp:label("ESP settings (AKA Highlighter)")

    esp:toggle({Name = "Enable ESP", Flag = "ESP", Default = true})
    FlagSetters.ESP = function(val)
        if bESP == val then return end

        bESP = val
        if not bESP then ClearItems() end
    end

    esp:toggle({Name = "Highlight part", Flag = "Highlight", Default = true})
    FlagSetters.Highlight = function(val)
        bHighlight = val
    end

    esp:toggle({Name = "Show object name", Flag = "TextName", Default = true})
    FlagSetters.TextName = function(val)
        bTextName = val
    end

    local paths = visual:section("ATTACK PATHS")

    paths:label("Shows killer attack abilty paths")

    paths:toggle({Name = "Show attack path", Flag = "ShowLine", Default = false})
    FlagSetters.ShowLine = function(val)
        bShowLine = val
    end

    paths:toggle({Name = "Show path when you're killer", Flag = "ShowLocalLine", Default = false})
    FlagSetters.ShowLocalLine = function(val)
        bShowLocalLine = val
    end

    local misc = window:tab("Misc")
    local generators = misc:section("GENERATORS")

    generators:toggle({Name = "Auto complete generators", Flag = "AutoGen", Default = false})
    FlagSetters.AutoGen = function(val)
        -- Disabled
    end

    generators:slider({Name = "Delay before starting puzzle (seconds)", Flag = "AutoGenTime", Min = .3, Max = 3, Default = 1.75, Step = .05})
    FlagSetters.AutoGenTime = function(val)
        AutoGenTime = val
    end

    generators:slider({Name = "Randomize time by (seconds)", Flag = "AutoGenRandom", Min = 0, Max = 2, Default = .5, Step = .05})
    FlagSetters.AutoGenRandom = function(val)
        AutoGenRandom = val
    end

    local other = misc:section("OTHER")

    other:toggle({Name = "Show round timer on bloodhunt", Flag = "ShowTimer", Default = false})
    FlagSetters.ShowTimer = function(val)
        bShowTimer = val
    end

    other:label("Stops sprinting right before hitting 0 stamina")

    other:toggle({Name = "Safe sprint", Flag = "StopStam", Default = false})
    FlagSetters.StopStam = function(val)
        bStopStam = val
    end

    other:button({
        Name = "Unhide playtime of all players",
        Callback = function()
            for _, inst in Players:GetChildren() do
                pcall(function()
                    inst.PlayerData.Settings.Privacy.HidePlaytime.Value = false
                end)
            end
        end,
    })

    other:button({
        Name = "Unhide killer and survivor wins of all players",
        Callback = function()
            for _, inst in Players:GetChildren() do
                pcall(function()
                    inst.PlayerData.Settings.Privacy.HideKillerWins.Value = false
                    inst.PlayerData.Settings.Privacy.HideSurvivorWins.Value = false
                end)
            end
        end,
    })

    local colors = window:tab("Colors")
    local colorSections = {colors:section("ABILITIES"), colors:section("OTHER")}

    for _, entry in {
        {1, "Projectile color", "danger"},
        {1, "Trap color", "trap"},
        {1, "Passive trap color", "slightdanger"},
        {1, "Clone color", "neutral"},
        {1, "Azure ability color", "azure"},
        {1, "Show projectile line color", "lineprim"},
        {2, "Auto block visual color", "autoblock"},
        {2, "Auto block visual attack color", "autoblockattack"},
        {2, "Minion color", "yellow"},
        {2, "Generator color", "generator"},
        {2, "Medkit color", "medkit"},
        {2, "Bloxy cola color", "cola"},
        {2, "Show projectile text color", "linesec"},
    } do
        local key = entry[3]
        local flag = "Color_" .. key
        colorSections[entry[1]]:color({Name = entry[2], Flag = flag, Default = c[key]})
        FlagSetters[flag] = function(val)
            c[key] = val
        end
    end
end

window:start()

preLocalConnect = RunService.PreLocal:Connect(function()
    local started = os.clock()
    PreLocal()
    Profile.Add("PreLocal", started)
end)
preDataConnect = RunService.PreData:Connect(function()
    local started = os.clock()
    PreData()
    Profile.Add("PreData", started)
end)
renderConnect = RunService.Render:Connect(function()
    local started = os.clock()
    Render()
    Profile.Add("Render", started)
end)

clear_model_data()

print("Loaded")

end
