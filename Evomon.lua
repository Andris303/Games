--!optimize 2
--!strict

if game.GameId == 9826885587 then

local severeui = loadstring(game:HttpGet("https://raw.githubusercontent.com/okdude42/ui-lib/refs/heads/main/SevereLib.lua"))()

local TextOffset = 0
local TextYVal = 0
local TextC = 0
local Texts = {}
local TextIds = {}

local BDone = false

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer

local test = Drawing.new("Text")
test.Text = "XYZ"
test.Size = 20
test.Font = 0
TextOffset = test.TextBounds.Y
TextYVal = Camera.ViewportSize.Y - 25
test:Remove()

local function AddText(id, text, color)
    if TextIds[id] then return end

    TextC += 1
    TextIds[id] = TextC
    TextYVal -= TextOffset

    Texts[id] = Drawing.new("Text")
    Texts[id].Text = text
    Texts[id].Size = 20
    Texts[id].Font = 0
    Texts[id].Position = Vector2.new(25, TextYVal)
    Texts[id].Color = color
    Texts[id].Visible = true
end

game.RunService.Render:Connect(function()
    if not LocalPlayer.Character then return end
    if not LocalPlayer.Character.PrimaryPart then return end
    local RootPartPos = LocalPlayer.Character.PrimaryPart.Position
    local X = math.floor(RootPartPos.X * 100) / 100
    local Y = math.floor(RootPartPos.Y * 100) / 100
    local Z = math.floor(RootPartPos.Z * 100) / 100
    local PosText = "Current Position: " .. X .. ", " .. Y .. ", " .. Z
    if not BDone then
        BDone = true
        AddText("PosText", PosText, Color3.fromRGB(222,222,222))
        return
    end
    if Texts["PosText"].Text ~= PosText then
        Texts["PosText"].Text = PosText
    end
end)

local GTime = 10
local BScript = true
local Counter = 1
local PositionNumber = 1
local CurrentThread

local window = severeui:createwindow({
    Title = "Evomon autofarm",
    Version = "v1",
    Keybind = "RightShift",
    ConfigFolder = "EvomonAutofarm",
    CustomResolution = Vector2.new(580, 360),
    DPIScale = 1.0,
    CompactSettings = false,
    DefaultTab = "Main", 
    TabAlignment = "Center",
    DefaultColor = Color3.fromRGB(28, 27, 31),
    DefaultAccent = Color3.fromRGB(208, 188, 255),
    DefaultSnowfall = true,
    DefaultScale = 1.0,
    DefaultFont = 5
})

local tabMain = window:createtab("Main")
local tabSettings = window:createtab("Settings")

window:createslider(tabMain, {
    Name = "Time between teleports (seconds)",
    Col = 1, 
    Min = 0, Max = 100, Default = 10,
    Step = 1,
    Callback = function(val)
        GTime = val
        if val == 0 then GTime = 0.1 end
    end
})

local function Autofarm()
    if not BScript then return end
    while true do
        local Char = LocalPlayer.Character
        if Char then
            local Root = Char:FindFirstChild("HumanoidRootPart")
            if Root then
                Root.Position = _G["Position" .. tostring(Counter)]
                Counter += 1
                if Counter == PositionNumber + 1 then Counter = 1 end
            end
        end
        task.wait(GTime)
    end
end

window:createbutton(tabMain, {
    Name = "Start autofarm",
    Col = 1,
    Callback = function()
        CurrentThread = task.spawn(Autofarm)
    end
})

window:createbutton(tabMain, {
    Name = "Stop autofarm",
    Col = 1,
    Callback = function()
        if not BScript then return end
        if CurrentThread then
            task.cancel(CurrentThread)
            CurrentThread = nil
        end
        Counter = 1
    end
})

local function GetLabelTexts(str, pos)
    return str .. tostring(math.floor(pos.X)) .. ", " .. tostring(math.floor(pos.Y)) .. ", " .. tostring(math.floor(pos.Z))
end

if _G.Position1 then
    window:createlabel(tabMain, "Current positions:", 2)
    window:createseparator(tabMain, 2)
    while true do
        local num = tostring(PositionNumber)
        if _G["Position" .. num] then
            window:createlabel(tabMain, GetLabelTexts("Position " .. num .. ": ", _G["Position" .. num]), 2)
            PositionNumber += 1
        else
            PositionNumber -= 1
            break
        end
    end
else
    BScript = false
    window:createlabel(tabMain, "No positions given, script won't function", 2)
end

end
