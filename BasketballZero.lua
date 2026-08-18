local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Camera = workspace.CurrentCamera
local RunService = game:GetService("RunService")
local LocalTeam = "None"

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
    if type(workspace:GetChildren()) ~= "table" then return end
    if type(Players:GetChildren()) ~= "table" then return end 

    local Char = LocalPlayer.Character
    if not Char then return end

    for ID, inst in _G.ESPList do
        if not inst or not inst.Parent then
            if not _G.ESPData[ID]["LocalPlayer"] then
                ESP.RemovePlayer(ID)
            else
                clear_local_data()
            end
        else
            if not inst:FindFirstChild("Humanoid") then continue end
            if _G.ESPData[ID]["Health"] ~= inst.Humanoid.Health then
                if inst.Humanoid.Health <= 0 then
                    if not _G.ESPData[ID]["LocalPlayer"] then
                        ESP.RemovePlayer(ID)
                    else
                        clear_local_data()
                    end
                    continue
                end
                if not _G.ESPData[ID]["LocalPlayer"] then
                    ESP.EditHealth(ID, inst.Humanoid.Health)
                end
            end
            local plr = Players:FindFirstChild(inst.Name)
            if plr.Team then
                if not _G.ESPData[ID]["LocalPlayer"] and _G.ESPData[ID]["Teamname"] ~= plr.Team.Name then
                    ESP.RemovePlayer(ID)
                end
            end
            
            if is_team_check_active() and LocalTeam == _G.ESPData[ID]["Teamname"] then
                if not _G.ESPData[ID]["LocalPlayer"] then
                    ESP.RemovePlayer(ID)
                else
                    clear_local_data()
                end
            end
        end
    end

    if type(Players:GetChildren()) ~= "table" then return end

    for _, inst in Players:GetChildren() do
        if not inst or not inst.Parent then continue end

        local Char = inst.Character
        if not Char then continue end
        if not Char:FindFirstChild("Humanoid") then continue end

        local team = "Spectator"
        if inst.Team then
            team = inst.Team.Name
        end

        if is_team_check_active() and LocalTeam == team then continue end

        local style = "None"
        local zone = "None"

        if inst:FindFirstChild("Style") then
            style = AddSpaces(inst.Style.Value)
        end

        if inst:FindFirstChild("Zone") then
            zone = AddSpaces(inst.Zone.Value)
        end

        if inst == LocalPlayer then
            LocalTeam = team
        end

        ESP.AddPlayer(Char, inst == LocalPlayer, Char.Humanoid.Health, Char.Humanoid.MaxHealth, inst.Name, inst.DisplayName, inst.UserId, team, style .. " | " .. zone)
    end
end

clear_model_data()

print("Loaded")

RunService.PreData:Connect(PreData)
