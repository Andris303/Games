--!optimize 2

local Hellgrid = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/Hellgrid.lua"))()

local V = vector.create
local voxel = .35
local worldSize = 14
local seaLevel = 2

local Grass = {96, 168, 64}
local Dirt = {122, 88, 58}
local Stone = {120, 120, 126}
local Sand = {214, 198, 140}
local Water = {64, 120, 210}
local Trunk = {104, 76, 46}
local Leaves = {58, 132, 52}
local Cloud = {240, 240, 245}

Hellgrid.SkyColor = {120, 170, 230}
Hellgrid.GroundColor = {84, 118, 70}
Hellgrid.FogDistance = 16
Hellgrid.LightDirection = vector.normalize(V(.5, .9, .35))
Hellgrid.WalkSpeed = 1.3
Hellgrid.SprintSpeed = 2.2
Hellgrid.StepHeight = .2
Hellgrid.JumpPower = 4.5
Hellgrid.Gravity = 15

local function HeightAt(i, j)
    if i < 0 or j < 0 or i >= worldSize or j >= worldSize then return 0 end
    local wave = math.sin(i * .45) * 1.3 + math.cos(j * .38) * 1.1 + math.sin((i + j) * .21) * .9
    return math.clamp(math.floor(3 + wave), 1, 6)
end

local function Covered(i, j, layer)
    return i >= 0 and j >= 0 and i < worldSize and j < worldSize and HeightAt(i, j) >= layer
end

for i = 0, worldSize - 1 do
    for j = 0, worldSize - 1 do
        local height = HeightAt(i, j)
        local bSandy = height <= seaLevel
        for layer = 1, height do
            local hidden = {
                Bottom = true,
                Top = layer < height,
                West = Covered(i - 1, j, layer),
                East = Covered(i + 1, j, layer),
                North = Covered(i, j - 1, layer),
                South = Covered(i, j + 1, layer),
            }
            if not (hidden.Top and hidden.West and hidden.East and hidden.North and hidden.South) then
                local color = bSandy and Sand or (height - layer >= 2 and Stone or Dirt)
                local cube = Hellgrid.new("Block", V((i + .5) * voxel, (layer - .5) * voxel, (j + .5) * voxel), V(voxel, voxel, voxel), color)
                cube.HiddenFaces = hidden
                if layer == height then
                    cube.FaceColors = {Top = bSandy and Sand or Grass}
                end
            end
        end
        if height < seaLevel then
            local water = Hellgrid.new("Block", V((i + .5) * voxel, seaLevel * voxel - .06, (j + .5) * voxel), V(voxel, .02, voxel), Water)
            water.CanCollide = false
            water.HiddenFaces = {Bottom = true, West = true, East = true, North = true, South = true}
        end
    end
end

local TreeVoxels = {}

local function VoxelKey(i, layer, j)
    return i .. "," .. layer .. "," .. j
end

local function AddTree(i, j)
    local base = HeightAt(i, j)
    for layer = base + 1, base + 3 do
        TreeVoxels[VoxelKey(i, layer, j)] = {I = i, Layer = layer, J = j, Color = Trunk}
    end
    for layer = base + 4, base + 5 do
        for di = -1, 1 do
            for dj = -1, 1 do
                TreeVoxels[VoxelKey(i + di, layer, j + dj)] = {I = i + di, Layer = layer, J = j + dj, Color = Leaves}
            end
        end
    end
    for _, offset in {{0, 0}, {1, 0}, {-1, 0}, {0, 1}, {0, -1}} do
        TreeVoxels[VoxelKey(i + offset[1], base + 6, j + offset[2])] = {I = i + offset[1], Layer = base + 6, J = j + offset[2], Color = Leaves}
    end
end

local function Solid(i, layer, j)
    return TreeVoxels[VoxelKey(i, layer, j)] ~= nil or Covered(i, j, layer)
end

AddTree(3, 10)
AddTree(10, 4)
AddTree(11, 11)

for _, cell in TreeVoxels do
    local i, layer, j = cell.I, cell.Layer, cell.J
    if Covered(i, j, layer) then continue end
    local hidden = {
        Top = Solid(i, layer + 1, j),
        Bottom = Solid(i, layer - 1, j),
        West = Solid(i - 1, layer, j),
        East = Solid(i + 1, layer, j),
        North = Solid(i, layer, j - 1),
        South = Solid(i, layer, j + 1),
    }
    if not (hidden.Top and hidden.Bottom and hidden.West and hidden.East and hidden.North and hidden.South) then
        local cube = Hellgrid.new("Block", V((i + .5) * voxel, (layer - .5) * voxel, (j + .5) * voxel), V(voxel, voxel, voxel), cell.Color)
        cube.HiddenFaces = hidden
    end
end

local clouds = {}
for index, spot in {V(1.2, 4, 1.5), V(4, 4.3, 3.2), V(2.5, 4.1, 4.4)} do
    local cloud = Hellgrid.new("Block", spot, V(1.4 + index * .2, .25, .8), Cloud)
    cloud.CanCollide = false
    clouds[index] = {Block = cloud, Origin = spot}
end

local center = math.floor(worldSize / 2)
Hellgrid.Teleport(V((center + .5) * voxel, HeightAt(center, center) * voxel, (center + .5) * voxel))

local time = 0
Hellgrid.OnUpdate = function(dt)
    time += dt
    for index, cloud in clouds do
        cloud.Block.Position = cloud.Origin + V(math.sin(time * .1 + index) * 1.5, 0, 0)
    end
end
