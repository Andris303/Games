--!strict
--!optimize 2

if game.GameId == 6331902150 then

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local Ingame = workspace.Map.Ingame
local Killers = workspace.Players.Killers

local KillerColor = Color3.fromRGB(196, 45, 32)
local SurvivorColor = Color3.fromRGB(32, 196, 93)
local BloxyColaColor = Color3.fromRGB(16, 167, 234)
local MedkitColor = Color3.fromRGB(177, 45, 146)
local MiscColor = Color3.fromRGB(228, 217, 211)
local GeneratorColor = Color3.fromRGB(234, 165, 16)

local ExactSkipESP = {"PlacementRange", "BuildermanSentryEffectRange", "BuildermanDispenserEffectRange", "Spike", "EndPoint", "Footstep", "CollisionHitbox", "QueryHitbox", "HaxxedBlade", "HumanoidRootPart", "CollisionGuard", "TheThing", "ExpressionHolder", "NoclipDetector", "BasicSlash", "SubspaceCenter", "Firebrand", "Beam", "Tentacle", "VoidstarCrown"}
local PartialSkipESP = {"Spray", "RespawnLocation"}
local ExactKillerESP = {"shockwave", "Shockwave", "Swords", "SpikeCollision", "HumanoidRootProjectile", "Voidstar", "Bats", "Shadow", "Noli"}
local PartialKillerESP = {"JohnDoeTrail", "Shadows", "Puddle", "Shockwave"}
local ExactSurvivorESP = {"BuildermanDispenser", "BuildermanSentry", "007n7", "Pizza", "GraffitiCL", "CrystalProjectile"}
local PartialSurvivorESP = {"TaphTripwire", "SubspaceTripmine"}

local Convex = {
    Scratch = {
        Points = {},
        Hull = {},
        Poly = {}
    },

    Static = {
        HWMPoints = 0,
        HWMHull = 0,
        HWMPoly = 0
    }
}

local function TruncateBuffer(Buffer, NewSize, HighWaterMark)
    for Index = NewSize + 1, HighWaterMark do
        Buffer[Index] = nil
    end
    return math.max(NewSize, HighWaterMark)
end

local function CrossDimension(OriginX, OriginY, PointAX, PointAY, PointBX, PointBY)
    return (PointAX - OriginX) * (PointBY - OriginY) - (PointAY - OriginY) * (PointBX - OriginX)
end

local function CalculateConvexHull(Points, PointCount, Outer)
    if PointCount == 0 then return 0 end
    if PointCount == 1 then Outer[1] = Points[1]; return 1 end
    if PointCount == 2 then Outer[1] = Points[1]; Outer[2] = Points[2]; return 2 end
    table.sort(Points, function(PointA, PointB)
        return PointA.X < PointB.X or (PointA.X == PointB.X and PointA.Y < PointB.Y)
    end)
    local Size = 0
    for Index = 1, PointCount do
        local Point = Points[Index]
        while Size >= 2 and CrossDimension(Outer[Size - 1].X, Outer[Size - 1].Y, Outer[Size].X, Outer[Size].Y, Point.X, Point.Y) <= 0 do
            Size = Size - 1
        end
        Size = Size + 1
        Outer[Size] = Point
    end
    local LowerHullSize = Size
    for Index = PointCount - 1, 1, -1 do
        local Point = Points[Index]
        while Size > LowerHullSize and CrossDimension(Outer[Size - 1].X, Outer[Size - 1].Y, Outer[Size].X, Outer[Size].Y, Point.X, Point.Y) <= 0 do
            Size = Size - 1
        end
        Size = Size + 1
        Outer[Size] = Point
    end
    return Size - 1
end

local function ProjectPartCorners(Part, WriteOffset)
    local PositionX = Part.Position.X
    local PositionY = Part.Position.Y
    local PositionZ = Part.Position.Z
    local HalfSizeX = Part.Size.X * 0.5
    local HalfSizeY = Part.Size.Y * 0.5
    local HalfSizeZ = Part.Size.Z * 0.5
    local RightVector = Part.RightVector
    local UpVector = Part.UpVector
    local LookVector = Part.LookVector
    local RightX = RightVector.X * HalfSizeX
    local RightY = RightVector.Y * HalfSizeX
    local RightZ = RightVector.Z * HalfSizeX
    local UpX = UpVector.X * HalfSizeY
    local UpY = UpVector.Y * HalfSizeY
    local UpZ = UpVector.Z * HalfSizeY
    local LookX = LookVector.X * HalfSizeZ
    local LookY = LookVector.Y * HalfSizeZ
    local LookZ = LookVector.Z * HalfSizeZ
    local SignR = 1
    for _ = 1, 2 do
        local SignU = 1
        for _ = 1, 2 do
            local SignL = 1
            for _ = 1, 2 do
                local WorldPoint = Vector3.new(
                    PositionX + SignR * RightX + SignU * UpX + SignL * LookX,
                    PositionY + SignR * RightY + SignU * UpY + SignL * LookY,
                    PositionZ + SignR * RightZ + SignU * UpZ + SignL * LookZ
                )
                local ScreenPoint, OnScreen = Camera:WorldToScreenPoint(WorldPoint)
                if OnScreen then
                    WriteOffset = WriteOffset + 1
                    local Slot = Convex.Scratch.Points[WriteOffset]
                    if Slot then
                        Slot.X = ScreenPoint.X
                        Slot.Y = ScreenPoint.Y
                    else
                        Convex.Scratch.Points[WriteOffset] = {X = ScreenPoint.X, Y = ScreenPoint.Y}
                    end
                end
                SignL = -1
            end
            SignU = -1
        end
        SignR = -1
    end
    return WriteOffset
end

local function DrawPolygon(Hull, Size, Color, Opacity)
    if Size < 3 then return end
    local Pivot = Vector2.new(Hull[1].X, Hull[1].Y)
    for Index = 2, Size - 1 do
        DrawingImmediate.FilledTriangle(Pivot, Vector2.new(Hull[Index].X, Hull[Index].Y), Vector2.new(Hull[Index + 1].X, Hull[Index + 1].Y), Color, Opacity)
    end
end

local function DrawOutline(Hull, Size, Color, Opacity, Thickness)
    if Size < 2 then return end
    for Index = 1, Size do
        local Entry = Hull[Index]
        Convex.Scratch.Poly[Index] = Vector2.new(Entry.X, Entry.Y)
    end
    Convex.Scratch.Poly[Size + 1] = Vector2.new(Hull[1].X, Hull[1].Y)
    Convex.Scratch.Poly[Size + 2] = nil
    if Size + 1 < Convex.Static.HWMPoly then
        for Index = Size + 2, Convex.Static.HWMPoly do
            Convex.Scratch.Poly[Index] = nil
        end
    end
    Convex.Static.HWMPoly = math.max(Convex.Static.HWMPoly, Size + 1)
    DrawingImmediate.Polyline(Convex.Scratch.Poly, Color, 0.5, 2)
end

local function Highlight(inst, color)
    local PointCount = 0
    PointCount = ProjectPartCorners(inst, PointCount)
    Convex.Static.HWMPoints = TruncateBuffer(Convex.Scratch.Points, PointCount, Convex.Static.HWMPoints)
    local Size = CalculateConvexHull(Convex.Scratch.Points, PointCount, Convex.Scratch.Hull)
    Convex.Static.HWMHull = TruncateBuffer(Convex.Scratch.Hull, Size, Convex.Static.HWMHull)
    DrawPolygon(Convex.Scratch.Hull, Size, color, 0.3)
    DrawOutline(Convex.Scratch.Hull, Size, color, 0.7, 0.7)
end

local function ColorHandle(inst, ETable, PTable, color)
    local success = false
    if table.find(ETable, inst.Name) or inst:FindFirstChild("HumanoidRootPart") then
        if ETable == ExactKillerESP and inst.Name == "007n7" then return false end
        if ETable == ExactKillerESP and inst.Name == "BuildermanDispenser" then return false end
        if inst:IsA("BasePart") then
            Highlight(inst, color)
        else
            for _, Part in ipairs(inst:GetChildren()) do
                if Part:IsA("BasePart") then
                    if table.find(ExactSkipESP, Part.Name) then continue end
                    for _, val in ipairs(PartialSkipESP) do
                        if string.find(Part.Name, val) then continue end
                    end
                    Highlight(Part, color)
                    success = true
                end
            end
        end
    end
    for _, val in ipairs(PTable) do
        if string.find(inst.Name, val) then
            if inst:IsA("BasePart") then
                Highlight(inst, color)
            else
                for _, Part in ipairs(inst:GetChildren()) do
                    if Part:IsA("BasePart") then
                        if table.find(ExactSkipESP, Part.Name) then continue end
                        for _, val in ipairs(PartialSkipESP) do
                            if string.find(Part.Name, val) then continue end
                        end
                        Highlight(Part, color)
                        success = true
                    end
                end
            end
        end
    end
    return success
end

local function Render()
    for _, inst in ipairs(Ingame:GetChildren()) do
        if table.find(ExactSkipESP, inst.Name) then continue end
        for _, val in ipairs(PartialSkipESP) do
            if string.find(inst.Name, val) then continue end
        end
        if ColorHandle(inst, ExactKillerESP, PartialKillerESP, KillerColor) then continue end
        if ColorHandle(inst, ExactSurvivorESP, PartialSurvivorESP, SurvivorColor) then continue end
    end
    
    for _, inst in ipairs(workspace:GetChildren()) do
        if inst.Name == "BloxyCola" then
            Highlight(inst.ItemRoot, BloxyColaColor)
        elseif inst.Name == "Medkit" then
            Highlight(inst.ItemRoot, MedkitColor)
        end
    end

    for _, inst in ipairs(Killers:GetChildren()) do
        if inst.Name == "Noli" and inst:GetAttribute("Username") then
            if not Players:FindFirstChild(inst:GetAttribute("Username")) then continue end
            if Players[inst:GetAttribute("Username")].Character ~= inst then
                ColorHandle(inst, ExactKillerESP, PartialKillerESP, KillerColor)
            end
        end
    end

    if not Ingame:FindFirstChild("Map") then return end

    for _, inst in ipairs(Ingame.Map:GetChildren()) do
        if inst.Name == "Generator" then
            if not inst:FindFirstChild("Main") then continue end
            if LocalPlayer:FindFirstChild("PlayerGui") then
                if LocalPlayer.PlayerGui:FindFirstChild("PuzzleUI") then continue end
            end
            if inst.Progress.Value == 100 then continue end
            Highlight(inst.Main, GeneratorColor)
        elseif inst.Name == "BloxyCola" then
            Highlight(inst.ItemRoot, BloxyColaColor)
        elseif inst.Name == "Medkit" then
            Highlight(inst.ItemRoot, MedkitColor)
        end
    end
end

RunService.Render:Connect(Render)

print("Loaded")

end
