--!strict
--!optimize 2

if game.GameId == 6331902150 then

local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/UI.lua"))()

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
local bAutoBlock = false
local bChangingBind = false
local KillerAbTime = {}
local KillerAb = {}
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

local KEYBIND = "V"
local blockkeystr = _G.BlockKey or "Q"
local BLOCK_KEY = 0x51
local DELAY = 0
local ATTACK_LINGER = 50
local CLOSE_RADIUS = 3
local ATTACK_LENGTH = 7.5
local EXTRA_FORWARD = 4
local ATTACK_WIDTH = 5
local EXTRA_WIDTH = 3.5
local HEIGHT = 6
local EXTRA_HEIGHT = 1

if #blockkeystr == 1 then
    BLOCK_KEY = string.byte(string.upper(blockkeystr))
end

local KillerData = {
    ["C00lkid"] = {
        DELAY = 0,
        CLOSE_RADIUS = 3,
        ATTACK_LINGER = 35,
        ATTACK_LENGTH = 5,
    },
    ["Slasher"] = {
        DELAY = 0,
        CLOSE_RADIUS = 3,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 7.5,
    },
    ["JohnDoe"] = {
        DELAY = .2,
        CLOSE_RADIUS = 3,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 7.5,
    },
    ["Noli"] = {
        DELAY = .15,
        CLOSE_RADIUS = 3,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 8,
    },
    ["1x1x1x1"] = {
        DELAY = .2,
        CLOSE_RADIUS = 3,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 7.5,
    },
    ["Guest666"] = {
        DELAY = .1,
        CLOSE_RADIUS = 2,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 7.25,
    },
    ["Nosferatu"] = {
        DELAY = .1,
        CLOSE_RADIUS = 3,
        ATTACK_LINGER = 45,
        ATTACK_LENGTH = 8.5,
    },
    ["Azure"] = {
        DELAY = .02,
        CLOSE_RADIUS = 2,
        ATTACK_LINGER = 40,
        ATTACK_LENGTH = 8.5,
    },
}

local c = {
    danger = Color3.fromRGB(224,17,95),
    slightdanger = Color3.fromRGB(220,161,161),
    neutral = Color3.fromRGB(109,129,150),
    generator = Color3.fromRGB(234,162,33),
    cola = Color3.fromRGB(45,104,196),
    medkit = Color3.fromRGB(255,29,141),
    trap = Color3.fromRGB(179,27,27),
    azure = Color3.fromRGB(127,0,255),
    yellow = Color3.fromRGB(241,195,56),
}

local Names = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "VineModel", "GroundBulbModel", "BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile", "Medkit", "BloxyCola", "MisterBeast", "Noli"}
local SNames = {"BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile", "TaphTripwire", "SubspaceTripmine"}
local KNames = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "VineModel", "GroundBulbModel","Medkit", "BloxyCola", "MisterBeast", "Noli", "Puddle"}
local PNames = {"TaphTripwire", "SubspaceTripmine", "Puddle", "Shockwave"}

local NameColors = {
    shockwave = c.danger,
    Shockwave = c.danger,
    Swords = c.danger,
    SpikeCollision = c.neutral,
    HumanoidRootProjectile = c.danger,
    Voidstar = c.danger,
    Bats = c.danger,
    Shadow = c.trap,
    VineModel = c.trap,
    GroundBulbModel = c.trap,
    MisterBeast = c.azure,
    Azure = c.azure,
    Noli = c.neutral,
    ["1x1x1x1Zombie"] = c.yellow,
    JohnDoeTrail = c.slightdanger,
    Shadows = c.trap,
    Puddle = c.slightdanger,
    FakeGenerator = c.neutral,
    TaphTripwire = c.trap,
    SubspaceTripmine = c.danger,
    BuildermanDispenser = c.yellow,
    BuildermanSentry = c.trap,
    ["007n7"] = c.neutral,
    Pizza = c.yellow,
    GraffitiCL = c.yellow,
    CrystalProjectile = c.danger,
    Medkit = c.medkit,
    BloxyCola = c.cola,
}

local FullNames = {
    BuildermanDispenser = "Builder Dispenser",
    BuildermanSentry = "Builder Sentry",
    ["007n7"] = "007n7 Clone",
    Pizza = "Elliot Pizza",
    GraffitiCL = "Vee Graffiti",
    TaphTripwire = "Taph Tripwire",
    SubspaceTripmine = "Taph Mine",
    Shadow = "John Trap",
    VineModel = "Azure Vine",
    GroundBulbModel = "Azure Bulb",
    MisterBeast = "Azure Golem",
    ["1x1x1x1Zombie"] = "Zombie",
    FakeGenerator = "Fake Generator",
    Azure = "Azure",
    Noli = "Fake Noli",
    Medkit = "Medkit",
    BloxyCola = "Cola",
}

local BodyData = {"Head", "Torso", "Right Arm", "Right Leg", "Left Arm", "Left Leg"}

local h = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Highlighter.lua"))()

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

    local Children = inst:GetChildren()

    if inst:FindFirstChild("Humanoid") then
        local ReturnTable = {}

        for _, part in BodyData do
            if inst:FindFirstChild(part) then
                table.insert(ReturnTable, inst[part])
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

    if prog > 0.5 then
        extraForward = 4 - (3 * (prog - 0.5) / 0.5)
    end

    local maxForward = ATTACK_LENGTH + extraForward

    if forwardDistance > maxForward then
        return false
    end

    local right = vector.create(-forward.z, 0, forward.x)
    local sideDistance = math.abs(vector.dot(offset, right))
    local alpha = math.clamp(forwardDistance / maxForward, 0, 1)
    local baseHalfWidth = ATTACK_WIDTH / 2
    local allowedHalfWidth = baseHalfWidth + (EXTRA_WIDTH * alpha)

    if math.abs(offset.y) > (HEIGHT / 2 + EXTRA_HEIGHT) then
        return false
    end

    if sideDistance <= allowedHalfWidth then
        return true
    else
        return false
    end
end

local function BlockChecker(KRoot, LRoot, inst)
    if DELAY > 0 then
        task.wait(DELAY)
    end
    local c = 0
    while c <= ATTACK_LINGER do
        if not active or not isguest or not bAutoBlock then break end
        c += 1
        local attackProgress = c / ATTACK_LINGER
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

                bt2.Visible = true
                keypress(BLOCK_KEY)
                task.wait(.2)
                keyrelease(BLOCK_KEY)
                task.wait(.8)
                bt2.Visible = false
                break
            end
        end
        task.wait(.01)
    end
end

local function PostLocal()
    local syncautoblock = window:getvalue("Enable Auto block")
    local syncinv = window:getvalue("Block when the killer is stun immune")
    local syncesp = window:getvalue("Enable ESP")
    local synckeybind = window:getvalue("AutoBlockKeybind")

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
		end
    end

    if bBlockOnInv ~= syncinv then
        bBlockOnInv = syncinv
    end

    local tempisguest

    local suc, bool = pcall(function()
        return LocalPlayer.Character.Name == "Guest1337"
    end)

    if suc and bool then
        tempisguest = true
    else
        tempisguest = false
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

    for _, v in getpressedkeys() do
        if v == KEYBIND then
            pressed = true
            break
        end
    end

    if bAutoBlock and pressed and not tempactive then
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
            end
            local AbTime = inst:GetAttribute("AbilityLastUsed")
            local Ab = inst:GetAttribute("AbilitiesUsed")
            if not AbTime or not Ab then continue end
            if not KillerAbTime[id] or not KillerAb[id] then
                KillerAbTime[id] = inst:GetAttribute("AbilityLastUsed")
                KillerAb[id] = inst:GetAttribute("AbilitiesUsed")
            elseif KillerAbTime[id] ~= AbTime and KillerAb[id] == Ab then
                KillerAb[id] = Ab
                KillerAbTime[id] = AbTime

                local LRoot = LocalPlayer.Character and LocalPlayer.Character:FindFirstChild("HumanoidRootPart")
                local KRoot = inst:FindFirstChild("HumanoidRootPart")
                if KRoot and LRoot then
                    if active and isguest then
                        task.spawn(BlockChecker, KRoot, LRoot, inst)
                    end
                end
            elseif KillerAbTime[id] ~= AbTime and KillerAb[id] < Ab then
                KillerAb[id] = Ab
                KillerAbTime[id] = AbTime
            end
        end
    end
end

local function PreLocal()
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

    for _, inst in Ingame:GetChildren() do
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
            if Players[inst:GetAttribute("Username")].Character ~= inst and InstId(inst) and #Killers:GetChildren() > 1 then
                ItemCache[InstId(inst)] = inst
                continue
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

    for _, inst in Ingame:GetChildren() do
        local Name = inst.Name
        if string.find(Name, "JohnDoeTrail") or string.find(Name, "Shadows") then
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
    for id, inst in ItemCache do
        local Name
        if not inst or not inst.Parent then
            ItemCache[id] = nil
            continue
        else
            local s, r = pcall(function()
                return inst.Parent.Name
            end)
            if s and r == "Backpack" then
                ItemCache[id] = nil
                continue
            else
                Name = inst.Name
            end
        end

        if type(Name) ~= "string" then
            ItemCache[id] = nil
            continue
        end

        if Name == "Generator" and (bInUI or bKill) then continue end

        if Name == "Generator" then
            if not inst:FindFirstChild("Main") or not inst:FindFirstChild("Progress") then
                ItemCache[id] = nil
                continue
            end

            local Main = inst.Main
            local Progress = inst.Progress

            if Progress.Value == 100 then
                ItemCache[id] = nil
                continue
            end

            Highlight(Main, c.generator)
            local p, v = Camera:WorldToScreenPoint(Main.Position)
			if v then
				local NewPos = Vector2.new(p.x, p.y - 6.5)
				DrawingImmediate.OutlinedText(NewPos, 13, c.generator, 1, GetGenPer(Progress.Value), true)
			end
            continue
        end

        local Parts = GetPart(inst)

        local color = NameColors[Name] or c.yellow
        local name = FullNames[Name]
        for _, v in PNames do
            if string.find(Name, v) then
                color = NameColors[v]
                name = FullNames[v]
            end
        end

        if bSurv and (table.find(SNames, Name) or string.find(Name, "TaphTripwire") or string.find(Name, "SubspaceTripmine")) then continue end
        if bKill and (table.find(KNames, Name) or string.find(Name, "Puddle") or string.find(Name, "Shockwave")) then continue end
        if string.find(Name, "Spray") then continue end

        if type(Parts) == "table" then
            for _, part in Parts do
                if part.Name == "Torso" then
                    if not name then
                        name = "Minion"
                    end

                    local s, pos = pcall(function()
                        return part.Position
                    end)
                    if s then
                        local p, v = Camera:WorldToScreenPoint(pos)
                        if v then
                            local NewPos = Vector2.new(p.x, p.y - 6.5)
                            DrawingImmediate.OutlinedText(NewPos, 13, color, 1, name, true)
                        end
                    end
                end
                Highlight(part, color)
            end
        elseif Parts then
            if name then
                local s, pos = pcall(function()
                        return Parts.Position
                    end)
                if s then
                    local p, v = Camera:WorldToScreenPoint(pos)
                    if v then
                        local NewPos = Vector2.new(p.x, p.y - 6.5)
                        DrawingImmediate.OutlinedText(NewPos, 13, color, 1, name, true)
                    end
                end
            end
            Highlight(Parts, color)
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
local tabSettings = window:createtab("Settings")

window:createlabel(tabMain, "ESP settings (AKA Highlighter)", 1)

window:createtoggle(tabMain, {
    Name = "Enable ESP",
    Col = 1,
    Default = true,
    Callback = function(val)
		bESP = val
		if not val then
			ItemCache = {}
		end
	end
})

window:createlabel(tabMain, "After enabling, you need to press your keybind", 2)

window:createtoggle(tabMain, {
    Name = "Enable Auto block",
    Col = 2,
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
    Col = 2,
    Default = false,
    Callback = function(val)
		bBlockOnInv = val
	end
})

keybindlabel = window:createlabel(tabMain, "Current keybind: " .. KEYBIND, 2)

local keybindbtn
keybindbtn = window:createbutton(tabMain, {
    Name = "Change keybind",
    Col = 2,
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

RunService.PostLocal:Connect(PostLocal)
RunService.PreLocal:Connect(PreLocal)
RunService.Render:Connect(Render)

print("Loaded")

end
