local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local NPCs = workspace.NPCFolders

local runId = (_G.BattleBricksRun or 0) + 1
_G.BattleBricksRun = runId

local Units = {}
local Labels = {}
local DeletedRemotes = {}
local lastDepriverCheck = 0
local depriverCheckDelay = .1
local bAutoShoot = true
local shootClickDelay = .1
local shootTolerance = 8
local ShootPriority = {SuperStar = 1, BigStar = 2, Monitor = 3, SorcusBlade = 4, Core = 5}
local defaultShootPriority = 6
local currentShootTarget = nil
local nextShootClick = 0
local BoundsCache = {}
local boundsCount = 0

local font = "Nunito"
local loopDelay = .03
local statDelay = 0
local statReadsPerLoop = 1
local textSize = 20
local statTextSize = 16
local lineGap = 2
local separator = " | "
local cooldownHoldTime = .25
local nodeRetryDelay = 1

local ArmorColor = Color3.fromRGB(135, 150, 170)
local ResistColor = Color3.fromRGB(90, 160, 255)
local SeparatorColor = Color3.fromRGB(200, 200, 200)
local CooldownColor = Color3.fromRGB(255, 255, 255)

local function InstId(inst)
    if not inst or not inst.Parent then return nil end
    return tostring(tonumber(inst.Data))
end

local function TextWidth(text, size)
    local key = size .. "|" .. text
    local width = BoundsCache[key]
    if width then return width end

    local ok, bounds = pcall(DrawingImmediate.GetTextBounds, font, size, text)
    width = ok and bounds and bounds.X or #text * size * .5

    if boundsCount > 500 then
        table.clear(BoundsCache)
        boundsCount = 0
    end
    BoundsCache[key] = width
    boundsCount += 1

    return width
end

local function FormatStat(value)
    if value == nil then return "-" end
    if value == math.floor(value) then
        return tostring(value)
    end
    return string.format("%.2f", value)
end

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
            local name = ReadName(namePointer + 0x8)
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
    if not ok or type(value) ~= "number" or value ~= value or math.abs(value) > 1e9 then
        return nil
    end
    return value
end

local function ReadStat(inst, name)
    local okAddress, address = pcall(function()
        return tonumber(inst.Data)
    end)
    if not okAddress or not address then return nil end

    local entry = FindAttributeEntry(address, name)
    if not entry then return nil end
    return ReadEntryNumber(entry)
end

local function ReadCooldown(unit, inst, now)
    if not unit.AttributeNode then
        if unit.NodeTriedAt and now - unit.NodeTriedAt < nodeRetryDelay then return nil end
        unit.NodeTriedAt = now
        local address = tonumber(inst.Data)
        if not address then return nil end
        local _, node = FindAttributeEntry(address, "Armor")
        unit.AttributeNode = node
        if not node then return nil end
    end

    local entry, valid = SearchNode(unit.AttributeNode, "WaitToMove")
    if not valid then
        unit.AttributeNode = nil
        return nil
    end
    if not entry then return nil end

    local value = ReadEntryNumber(entry)
    return value and math.max(value, 0)
end

local function HealthColor(ratio)
    if ratio >= 2/3 then
        local alpha = (ratio - 2/3) * 3
        return Color3.fromRGB(255, 255, 0):Lerp(Color3.fromRGB(0, 255, 0), alpha)
    elseif ratio >= 1/3 then
        local alpha = (ratio - 1/3) * 3
        return Color3.fromRGB(255, 128, 0):Lerp(Color3.fromRGB(255, 255, 0), alpha)
    end

    local alpha = ratio * 3
    return Color3.fromRGB(255, 0, 0):Lerp(Color3.fromRGB(255, 128, 0), alpha)
end

local function ScanFolder(folder, now, seen, labels, budget)
    for _, inst in folder:GetChildren() do
        local id = InstId(inst)
        if not id then continue end

        seen[id] = true

        local unit = Units[id]
        if not unit then
            unit = {FirstSeen = now, StatsRead = false, ArmorText = "-", ResistText = "-"}
            Units[id] = unit
        end

        if not unit.Root or not unit.Humanoid then
            unit.Root = inst:FindFirstChild("HumanoidRootPart")
            unit.Humanoid = inst:FindFirstChild("Humanoid")
            if not unit.Root or not unit.Humanoid then continue end
        end

        local ok, pos, health, maxhealth = pcall(function()
            return unit.Root.Position, unit.Humanoid.Health, unit.Humanoid.MaxHealth
        end)
        if not ok or not pos or not health or not maxhealth then continue end
        if health <= 0 then continue end

        if not unit.StatsRead and budget.Left > 0 and now - unit.FirstSeen >= statDelay then
            budget.Left -= 1
            unit.StatsRead = true

            local armor = ReadStat(inst, "Armor")
            local resist = ReadStat(inst, "Resistance")
            unit.ArmorText = FormatStat(armor)
            unit.ResistText = FormatStat(resist) .. (resist and "%" or "")
        end

        health = math.floor(health * 100) / 100
        maxhealth = math.floor(maxhealth * 100) / 100
        local ratio = maxhealth > 0 and math.clamp(health / maxhealth, 0, 1) or 0

        local cooldown = ReadCooldown(unit, inst, now)
        if cooldown then
            if unit.LastCooldown and cooldown < unit.LastCooldown then
                unit.LastDropAt = now
            elseif unit.LastCooldown and cooldown > unit.LastCooldown then
                unit.LastDropAt = nil
            end
            unit.LastCooldown = cooldown
        end
        if not cooldown or cooldown <= 0 or not unit.LastDropAt or now - unit.LastDropAt > cooldownHoldTime then
            cooldown = nil
        end

        labels[#labels + 1] = {
            Root = unit.Root,
            CooldownText = cooldown and string.format("%.1fs", cooldown),
            Position = vector.create(pos.x, pos.y + 3, pos.z),
            Text = tostring(health) .. " / " .. tostring(maxhealth),
            Color = HealthColor(ratio),
            ArmorText = unit.ArmorText,
            ResistText = unit.ResistText,
        }
    end
end

local function Scan()
    local enemies = NPCs:FindFirstChild("EnemyFolder")
    local friendlies = NPCs:FindFirstChild("FriendlyFolder")
    if not enemies or not friendlies then
        Units = {}
        Labels = {}
        return
    end

    local now = os.clock()
    local seen = {}
    local labels = {}
    local budget = {Left = statReadsPerLoop}

    ScanFolder(enemies, now, seen, labels, budget)
    ScanFolder(friendlies, now, seen, labels, budget)

    for id in Units do
        if not seen[id] then
            Units[id] = nil
        end
    end

    Labels = labels
end

local function Render()
    if _G.BattleBricksRun ~= runId then return end

    for _, label in Labels do
        local p, v = Camera:WorldToScreenPoint(label.Position)
        if v then
            local statY = p.y - statTextSize / 2
            local healthY = statY - textSize - lineGap

            local healthWidth = TextWidth(label.Text, textSize)
            DrawingImmediate.OutlinedText(Vector2.new(p.x - healthWidth / 2, healthY), textSize, label.Color, 1, label.Text, false, font)

            local armorWidth = TextWidth(label.ArmorText, statTextSize)
            local separatorWidth = TextWidth(separator, statTextSize)
            local resistWidth = TextWidth(label.ResistText, statTextSize)

            local x = p.x - (armorWidth + separatorWidth + resistWidth) / 2
            DrawingImmediate.OutlinedText(Vector2.new(x, statY), statTextSize, ArmorColor, 1, label.ArmorText, false, font)
            x += armorWidth
            DrawingImmediate.OutlinedText(Vector2.new(x, statY), statTextSize, SeparatorColor, 1, separator, false, font)
            x += separatorWidth
            DrawingImmediate.OutlinedText(Vector2.new(x, statY), statTextSize, ResistColor, 1, label.ResistText, false, font)
        end

        local cooldownText = label.CooldownText
        if cooldownText then
            local rootPoint, rootVisible = Camera:WorldToScreenPoint(label.Root.Position)
            if rootVisible then
                local cooldownWidth = TextWidth(cooldownText, textSize)
                DrawingImmediate.OutlinedText(Vector2.new(rootPoint.x - cooldownWidth / 2, rootPoint.y - textSize / 2), textSize, CooldownColor, 1, cooldownText, false, font)
            end
        end
    end
end

task.spawn(function()
    while _G.BattleBricksRun == runId do
        pcall(Scan)
        task.wait(loopDelay)
    end
end)

local function DisableDeprivers()
    if _G.BattleBricksRun ~= runId then return end
    local now = os.clock()
    if now - lastDepriverCheck < depriverCheckDelay then return end
    lastDepriverCheck = now

    local ui = LocalPlayer.PlayerGui:FindFirstChild("ChustUI")
    local remote = ui and ui:FindFirstChild("RemoteEvent")
    local id = InstId(remote)
    if id and not DeletedRemotes[id] then
        DeletedRemotes[id] = true
        remote:Destroy()
        print("Deleted a depriver remote")
    end
end

local function AimPart(inst)
    if inst:IsA("BasePart") then return inst end
    if inst:IsA("Model") then return inst.PrimaryPart end
    return nil
end

local function ShootPoint(inst)
    if not inst or not inst.Parent then return nil end
    local part = AimPart(inst)
    if not part then return nil end
    local point, visible = Camera:WorldToScreenPoint(part.Position)
    if not visible then return nil end
    local viewport = Camera.ViewportSize
    if point.x < 0 or point.y < 0 or point.x > viewport.x or point.y > viewport.y then return nil end
    return point
end

local function ShootRank(inst)
    return ShootPriority[inst.Name] or defaultShootPriority
end

local function PickShootTarget(folder, currentId)
    local best, bestRank, bestPoint = nil, math.huge, nil
    local current, currentPoint = nil, nil
    for _, inst in folder:GetChildren() do
        local point = ShootPoint(inst)
        if point then
            local rank = ShootRank(inst)
            if rank < bestRank then
                best, bestRank, bestPoint = inst, rank, point
            end
            if currentId and InstId(inst) == currentId then
                current, currentPoint = inst, point
            end
        end
    end
    return best, bestPoint, current, currentPoint
end

local function AutoShoot()
    if not bAutoShoot or not isrbxactive() then return end
    local folder = workspace:FindFirstChild("Shootable")
    if not folder then
        currentShootTarget = nil
        return
    end

    local best, bestPoint, current, point = PickShootTarget(folder, currentShootTarget)
    if not current or (best and ShootRank(best) < ShootRank(current)) then
        current, point = best, bestPoint
    end
    currentShootTarget = current and InstId(current)
    if not point then return end

    local mouse = getmouseposition()
    local dx, dy = point.x - mouse.x, point.y - mouse.y
    if math.abs(dx) > shootTolerance or math.abs(dy) > shootTolerance then
        mousemoverel(math.floor(dx + .5), math.floor(dy + .5))
        return
    end

    local now = os.clock()
    if now - nextShootClick > shootClickDelay then
        nextShootClick = now
    end
    if now >= nextShootClick then
        nextShootClick += shootClickDelay
        mouse1click()
    end
end

local function OnPreLocal()
    if _G.BattleBricksRun ~= runId then return end
    DisableDeprivers()
    AutoShoot()
end

print("Loaded")

RunService.Render:Connect(Render)
RunService.PreLocal:Connect(OnPreLocal)
