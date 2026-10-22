--!optimize 2

local RunService = game:GetService("RunService")
local Hellgrid = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Hellgrid.lua"))()

local runId = _G.HellgridRun
local V = vector.create
local voxel = .35
local worldSize = nil
local chunkSize = 8
local seed = 7
local seaLevel = 2
local maxGround = 10
local wallHeight = maxGround + 4
local treeCell = 6
local treeChance = .45
local treeWallMargin = 7
local cloudChance = .2
local orbChance = .01
local orbSpawnClearance = 3
local orbFreeX, orbFreeZ = nil, nil
local viewDistance = 6
local viewAngle = math.rad(75)
local nearRadius = 1
local generateBudget = .002

local Grass = {96, 168, 64}
local Dirt = {122, 88, 58}
local Stone = {120, 120, 126}
local Snow = {236, 238, 242}
local Sand = {214, 198, 140}
local Water = {64, 120, 210}
local Trunk = {104, 76, 46}
local Leaves = {58, 132, 52}
local Cloud = {214, 232, 255}
local Orb = {70, 140, 255}
local underwaterColor = Color3.fromRGB(28, 64, 140)

Hellgrid.Debug = true
Hellgrid.SkyColor = {120, 170, 230}
Hellgrid.GroundColor = nil
Hellgrid.FogColor = Hellgrid.SkyColor
Hellgrid.FogDistance = viewDistance
Hellgrid.OutlineDistance = 3
Hellgrid.LightDirection = vector.normalize(V(.5, .9, .35))
Hellgrid.WalkSpeed = 1.3
Hellgrid.SprintSpeed = 2.2
Hellgrid.StepHeight = .2
Hellgrid.JumpPower = 4.5
Hellgrid.Gravity = 15
Hellgrid.PlayerRadius = .14

local seedX, seedZ = seed * 17.31, seed * 29.77
local chunkWidth = chunkSize * voxel
local loadRadius = math.ceil(viewDistance / chunkWidth) + 1

local function Running()
    return _G.HellgridRun == runId
end

local function InWorld(i, j)
    return not worldSize or (i >= 0 and j >= 0 and i < worldSize and j < worldSize)
end

local function EdgeDistance(i, j)
    if not worldSize then return math.huge end
    return math.min(i, j, worldSize - 1 - i, worldSize - 1 - j)
end

local function IsWall(i, j)
    if not worldSize then return false end
    local thickness = math.clamp(3 + math.floor(math.noise(i * .15 + seedX, j * .15 + seedZ, 3.3) * 3 + .5), 2, 4)
    return EdgeDistance(i, j) < thickness
end

local function ComputeHeight(i, j)
    if IsWall(i, j) then
        local ridge = math.noise(i * .3 + seedZ, j * .3 + seedX, 1.7) * 6
        return wallHeight + math.clamp(math.floor(2 + ridge), 0, 4)
    end
    local n = math.noise(i * .04 + seedX, j * .04 + seedZ)
        + math.noise(i * .1 + seedZ, j * .1 + seedX) * .5
        + math.noise(i * .23 - seedX, j * .23 - seedZ) * .25
    return math.clamp(math.floor(4.5 + n * 6), 1, maxGround)
end

local heightCache, heightCacheSize = {}, 0

local function HeightAt(i, j)
    local key = i * 1048576 + j
    local height = heightCache[key]
    if height then return height end
    height = ComputeHeight(i, j)
    if heightCacheSize >= 50000 then
        table.clear(heightCache)
        heightCacheSize = 0
    end
    heightCache[key] = height
    heightCacheSize += 1
    return height
end

local function Covered(i, j, layer)
    if not InWorld(i, j) then return true end
    local height = HeightAt(i, j)
    return height >= layer or (height < seaLevel and layer <= seaLevel)
end

local function Hash(i, j, salt)
    local value = math.sin(i * 12.9898 + j * 78.233 + salt * 37.719 + seed) * 43758.5453
    return value - math.floor(value)
end

local function TreeAt(i, j)
    local ci, cj = math.floor(i / treeCell), math.floor(j / treeCell)
    if Hash(ci, cj, 1) > treeChance then return false end
    local ti = ci * treeCell + 1 + math.floor(Hash(ci, cj, 2) * (treeCell - 2))
    local tj = cj * treeCell + 1 + math.floor(Hash(ci, cj, 3) * (treeCell - 2))
    return ti == i and tj == j and EdgeDistance(i, j) >= treeWallMargin and HeightAt(i, j) > seaLevel
end

local function TreeVoxel(i, layer, j)
    for di = -1, 1 do
        for dj = -1, 1 do
            if TreeAt(i + di, j + dj) then
                local rise = layer - HeightAt(i + di, j + dj)
                if di == 0 and dj == 0 and rise >= 1 and rise <= 3 then return Trunk end
                if rise == 4 or rise == 5 then return Leaves end
                if rise == 6 and (di == 0 or dj == 0) then return Leaves end
            end
        end
    end
    return nil
end

local function Solid(i, layer, j)
    return Covered(i, j, layer) or TreeVoxel(i, layer, j) ~= nil
end

local sliceStart = os.clock()

local function Pace()
    if os.clock() - sliceStart >= generateBudget then
        task.wait()
        sliceStart = os.clock()
    end
    return Running()
end

local function AddColumn(blocks, i, j)
    local height = HeightAt(i, j)
    local bWall = IsWall(i, j)
    local bSandy = not bWall and height <= seaLevel
    for layer = 1, height do
        local hidden = {
            Bottom = true,
            Top = layer < height or height < seaLevel,
            West = Covered(i - 1, j, layer),
            East = Covered(i + 1, j, layer),
            North = Covered(i, j - 1, layer),
            South = Covered(i, j + 1, layer),
        }
        if not (hidden.Top and hidden.West and hidden.East and hidden.North and hidden.South) then
            local color = bSandy and Sand or ((bWall or height - layer >= 2) and Stone or Dirt)
            local cube = Hellgrid.new("Block", V((i + .5) * voxel, (layer - .5) * voxel, (j + .5) * voxel), V(voxel, voxel, voxel), color)
            cube.HiddenFaces = hidden
            if layer == height then
                local top = bSandy and Sand or Grass
                if bWall then top = height >= wallHeight + 3 and Snow or Stone end
                cube.FaceColors = {Top = top}
            end
            blocks[#blocks + 1] = cube
        end
    end

    if height < seaLevel then
        local water = Hellgrid.new("Block", V((i + .5) * voxel, seaLevel * voxel - .01, (j + .5) * voxel), V(voxel, .02, voxel), Water)
        water.CanCollide = false
        water.HiddenFaces = {Bottom = true, West = true, East = true, North = true, South = true}
        blocks[#blocks + 1] = water
    end

    local done = {}
    for di = -1, 1 do
        for dj = -1, 1 do
            if TreeAt(i + di, j + dj) then
                local base = HeightAt(i + di, j + dj)
                for rise = 1, 6 do
                    local layer = base + rise
                    if not done[layer] then
                        done[layer] = true
                        local color = TreeVoxel(i, layer, j)
                        if color and not Covered(i, j, layer) then
                            local hidden = {
                                Top = Solid(i, layer + 1, j),
                                Bottom = Solid(i, layer - 1, j),
                                West = Solid(i - 1, layer, j),
                                East = Solid(i + 1, layer, j),
                                North = Solid(i, layer, j - 1),
                                South = Solid(i, layer, j + 1),
                            }
                            if not (hidden.Top and hidden.Bottom and hidden.West and hidden.East and hidden.North and hidden.South) then
                                local cube = Hellgrid.new("Block", V((i + .5) * voxel, (layer - .5) * voxel, (j + .5) * voxel), V(voxel, voxel, voxel), color)
                                cube.HiddenFaces = hidden
                                blocks[#blocks + 1] = cube
                            end
                        end
                    end
                end
            end
        end
    end
end

local function GenerateChunk(cx, cz, bPaced)
    local chunk = {CX = cx, CZ = cz, Blocks = {}, Clouds = {}, Orbs = {}}
    for i = cx * chunkSize, cx * chunkSize + chunkSize - 1 do
        for j = cz * chunkSize, cz * chunkSize + chunkSize - 1 do
            if InWorld(i, j) then
                AddColumn(chunk.Blocks, i, j)
            end
            if bPaced and not Pace() then return nil end
        end
    end

    if Hash(cx, cz, 9) < cloudChance then
        local origin = V((cx + Hash(cx, cz, 10)) * chunkWidth, (wallHeight + 6) * voxel + Hash(cx, cz, 11), (cz + Hash(cx, cz, 12)) * chunkWidth)
        local cloud = Hellgrid.new("Block", origin, V(1.4 + Hash(cx, cz, 13) * 1.2, .25, .8 + Hash(cx, cz, 14) * .6), Cloud)
        cloud.CanCollide = false
        cloud.NoFog = true
        cloud.Unlit = true
        chunk.Clouds[1] = {Block = cloud, Origin = origin, Phase = Hash(cx, cz, 15) * 6.28}
    end

    local oi = cx * chunkSize + math.floor(Hash(cx, cz, 20) * chunkSize)
    local oj = cz * chunkSize + math.floor(Hash(cx, cz, 21) * chunkSize)
    local bNearSpawn = orbFreeX ~= nil and math.max(math.abs(cx - orbFreeX), math.abs(cz - orbFreeZ)) <= orbSpawnClearance
    if Hash(cx, cz, 19) < orbChance and not bNearSpawn and InWorld(oi, oj) and not IsWall(oi, oj) then
        local origin = V((oi + .5) * voxel, math.max(HeightAt(oi, oj), seaLevel) * voxel + .7, (oj + .5) * voxel)
        local orb = Hellgrid.new("Sphere", origin, V(.45, .45, .45), Orb)
        orb.CanCollide = false
        chunk.Orbs[1] = {Block = orb, Origin = origin, Phase = Hash(cx, cz, 22) * 6.28}
    end
    return chunk
end

local function ChunkInWorld(cx, cz)
    if not worldSize then return true end
    local lastChunk = math.floor((worldSize - 1) / chunkSize)
    return cx >= 0 and cz >= 0 and cx <= lastChunk and cz <= lastChunk
end

local function ChunkKey(cx, cz)
    return cx .. "," .. cz
end

local chunks = {}
local barriers = {}

if worldSize then
    local mapWidth = worldSize * voxel
    for _, side in {
        {V(mapWidth / 2, 30, -.1), V(mapWidth, 60, .2)},
        {V(mapWidth / 2, 30, mapWidth + .1), V(mapWidth, 60, .2)},
        {V(-.1, 30, mapWidth / 2), V(.2, 60, mapWidth)},
        {V(mapWidth + .1, 30, mapWidth / 2), V(.2, 60, mapWidth)},
    } do
        local barrier = Hellgrid.new("Block", side[1], side[2], Stone)
        barrier.Visible = false
        barriers[#barriers + 1] = barrier
    end
end

local function RefreshActive()
    local camera = Hellgrid.Camera
    local blocks = Hellgrid.Blocks
    table.clear(blocks)
    for _, barrier in barriers do
        blocks[#blocks + 1] = barrier
    end

    local forwardX, forwardZ = math.cos(camera.Yaw), math.sin(camera.Yaw)
    local coneAngle = math.min(math.pi, viewAngle + Hellgrid.TurnMargin + math.max(0, -camera.Pitch) * 1.5)
    local cosAngle = math.cos(coneAngle)
    local cosSquared = cosAngle * cosAngle
    local limit = (viewDistance + voxel) ^ 2
    local near = nearRadius ^ 2
    local chunkRadius = chunkWidth * .7072 + voxel

    for _, chunk in chunks do
        for _, cloud in chunk.Clouds do
            blocks[#blocks + 1] = cloud.Block
        end
        for _, orb in chunk.Orbs do
            blocks[#blocks + 1] = orb.Block
        end

        local centerX, centerZ = (chunk.CX + .5) * chunkWidth, (chunk.CZ + .5) * chunkWidth
        local cdx, cdz = centerX - camera.X, centerZ - camera.Z
        local distance = math.sqrt(cdx * cdx + cdz * cdz)
        local bNearby = distance - chunkRadius <= viewDistance
        if bNearby and distance > chunkRadius + nearRadius then
            local angle = math.acos(math.clamp((cdx * forwardX + cdz * forwardZ) / distance, -1, 1))
            bNearby = angle - math.asin(math.min(1, chunkRadius / distance)) <= coneAngle
        end

        if bNearby then
            for _, block in chunk.Blocks do
                local dx, dz = block.Position.x - camera.X, block.Position.z - camera.Z
                local distanceSquared = dx * dx + dz * dz
                if distanceSquared <= limit then
                    local ahead = dx * forwardX + dz * forwardZ
                    local bInCone
                    if cosAngle >= 0 then
                        bInCone = ahead > 0 and ahead * ahead >= cosSquared * distanceSquared
                    else
                        bInCone = ahead >= 0 or ahead * ahead <= cosSquared * distanceSquared
                    end
                    if distanceSquared <= near or bInCone then
                        blocks[#blocks + 1] = block
                    end
                end
            end
        end
    end
end

local function FindSpawn()
    local center = worldSize and math.floor(worldSize / 2) or 0
    for radius = 0, 40 do
        for di = -radius, radius do
            for dj = -radius, radius do
                if math.max(math.abs(di), math.abs(dj)) == radius then
                    local i, j = center + di, center + dj
                    if InWorld(i, j) and not IsWall(i, j) and HeightAt(i, j) > seaLevel then
                        local height = HeightAt(i, j)
                        local bFree = true
                        for ni = i - 1, i + 1 do
                            for nj = j - 1, j + 1 do
                                for layer = height + 1, height + 3 do
                                    if Solid(ni, layer, nj) then bFree = false end
                                end
                            end
                        end
                        if bFree then return i, j end
                    end
                end
            end
        end
    end
    return center, center
end

local spawnI, spawnJ = FindSpawn()
local spawnCX, spawnCZ = math.floor(spawnI / chunkSize), math.floor(spawnJ / chunkSize)
orbFreeX, orbFreeZ = spawnCX, spawnCZ
for dx = -1, 1 do
    for dz = -1, 1 do
        if ChunkInWorld(spawnCX + dx, spawnCZ + dz) then
            chunks[ChunkKey(spawnCX + dx, spawnCZ + dz)] = GenerateChunk(spawnCX + dx, spawnCZ + dz, false)
        end
    end
end

Hellgrid.Teleport(V((spawnI + .5) * voxel, HeightAt(spawnI, spawnJ) * voxel, (spawnJ + .5) * voxel))
Hellgrid.Camera.X, Hellgrid.Camera.Z = (spawnI + .5) * voxel, (spawnJ + .5) * voxel
Hellgrid.Camera.Pitch = 0
RefreshActive()

task.spawn(function()
    while Running() do
        local camera = Hellgrid.Camera
        local pcx, pcz = math.floor(camera.X / chunkWidth), math.floor(camera.Z / chunkWidth)

        for key, chunk in chunks do
            if math.max(math.abs(chunk.CX - pcx), math.abs(chunk.CZ - pcz)) > loadRadius + 1 then
                chunks[key] = nil
            end
        end

        local bestX, bestZ, bestDistance = nil, nil, math.huge
        for dx = -loadRadius, loadRadius do
            for dz = -loadRadius, loadRadius do
                local cx, cz = pcx + dx, pcz + dz
                local distance = dx * dx + dz * dz
                if distance < bestDistance and ChunkInWorld(cx, cz) and not chunks[ChunkKey(cx, cz)] then
                    bestX, bestZ, bestDistance = cx, cz, distance
                end
            end
        end

        if bestX then
            local chunk = GenerateChunk(bestX, bestZ, true)
            if chunk then
                chunks[ChunkKey(bestX, bestZ)] = chunk
            end
        else
            task.wait()
            sliceStart = os.clock()
        end
    end
end)

local time = 0
local bUnderwater = false
Hellgrid.OnUpdate = function(dt)
    time += dt
    local camera = Hellgrid.Camera
    local i, j = math.floor(camera.X / voxel), math.floor(camera.Z / voxel)
    bUnderwater = InWorld(i, j) and HeightAt(i, j) < seaLevel and camera.Y < seaLevel * voxel
    local player = Hellgrid.Player
    if InWorld(i, j) and player.Position.y < (HeightAt(i, j) - .5) * voxel then
        Hellgrid.Teleport(V(player.Position.x, HeightAt(i, j) * voxel, player.Position.z))
    end
    for _, chunk in chunks do
        for _, cloud in chunk.Clouds do
            cloud.Block.Position = cloud.Origin + V(math.sin(time * .1 + cloud.Phase) * 1.5, 0, 0)
        end
        for _, orb in chunk.Orbs do
            orb.Block.Yaw = time * 1.5 + orb.Phase
            orb.Block.Position = orb.Origin + V(0, math.sin(time * 2 + orb.Phase) * .08, 0)
        end
    end
    RefreshActive()
end

RunService.Render:Connect(function()
    if bUnderwater and Running() and Hellgrid.Active then
        DrawingImmediate.FilledRectangle(Vector2.new(0, 0), Vector2.new(10000, 10000), underwaterColor, 1, 0)
    end
end)
