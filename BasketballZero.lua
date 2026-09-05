local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")

local ESP = loadstring(game:HttpGet("https://raw.githubusercontent.com/Andris303/Libraries/refs/heads/main/ESP.lua"))()

local function AddSpaces(string)
	local result = ""

	for i = 1, #string do
		local char = string:sub(i, i)
		local prev = string:sub(i - 1, i - 1)
		local nextChar = string:sub(i + 1, i + 1)
		local isUpper = char:match("%u")
		local prevIsUpper = prev:match("%u")
		local prevIsLower = prev:match("%l")
		local nextIsLower = nextChar:match("%l")
		local shouldAddSpace = false

		if isUpper and i > 1 then
			if prevIsLower then
				shouldAddSpace = true
			elseif prevIsUpper and nextIsLower then
				shouldAddSpace = true
			end
		end

		if shouldAddSpace then
			result ..= " "
		end

		result ..= char
	end

	return result
end

local function PreData()
    for _, inst in Players:GetChildren() do
        local Char = inst.Character
        if not Char then return end
        if not Char:FindFirstChild("Humanoid") then return end

        if not ESP.IsTracked(Char) then
            ESP.AddPlayer(Char, {
                Player = inst,
                TeamType = "Player",
                GetTool = function(data)
                    local player = data.Player
                    local style = "None"
                    local zone = "None"
                    if player:FindFirstChild("Style") then
                        style = AddSpaces(player.Style.Value)
                    end
                    if player:FindFirstChild("Zone") then
                        zone = AddSpaces(player.Zone.Value)
                    end
                    return style .. " | " .. zone
                end,
            })
        end
    end
end

clear_model_data()

print("Loaded")

RunService.PreData:Connect(PreData)
