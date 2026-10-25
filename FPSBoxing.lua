--!strict
--!optimize 2

local UI = loadstring(game:HttpGet("https://gitlab.com/okdude42/severe-scripts/-/raw/main/uilib2/SevereUI.luau?ref_type=heads"))()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

local gloveSkin = 1
local checkInterval = .5
local nextCheck = 0
local FlagSetters = {}
local AppliedFlags = {}
local window
local preLocalConnect

local function ApplySkin()
    if LocalPlayer:GetAttribute("GloveSkin") ~= gloveSkin then
        LocalPlayer:SetAttribute("GloveSkin", gloveSkin)
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
    if now >= nextCheck then
        nextCheck = now + checkInterval
        ApplySkin()
    end
end

window = UI.new({
    Title = "Andris: FPS Boxing",
    Subtitle = "Skin changer",
    Version = "1.0.0",
    Folder = "AndrisFPSBoxing",
    Footer = "Skin changer",
    OnUnload = function()
        preLocalConnect:Disconnect()
    end,
})

do
    local skins = window:tab("Skins"):section("GLOVES")

    skins:slider({Name = "Glove skin", Flag = "GloveSkin", Min = 1, Max = 32, Default = 1, Step = 1})
    FlagSetters.GloveSkin = function(val)
        gloveSkin = math.floor(val + .5)
        nextCheck = 0
    end
end

window:start()

preLocalConnect = RunService.PreLocal:Connect(PreLocal)

print("Loaded")
