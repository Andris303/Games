local Workspace = game:GetService("Workspace")
local Camera = Workspace.CurrentCamera
local DrawingLib = Drawing

local CurrentRooms = Workspace:WaitForChild("CurrentRooms")
local activeDrawings = {}
local espEnabled = true

-- Keybind toggle using native key polling (bypasses GetMouse and UserInputService)
task.spawn(function()
    local lastPressed = false
    while true do
        -- Check if 'B' key (KeyCode 0x42 / 66) is pressed
        local keyPressed = iskeypressed and (iskeypressed(Enum.KeyCode.B) or iskeypressed(0x42))
        
        if keyPressed and not lastPressed then
            espEnabled = not espEnabled
        end
        lastPressed = keyPressed
        task.wait(0.1)
    end
end)

local function createDoorMarker(door, roomName)
    if activeDrawings[door] then return end

    local textDraw = DrawingLib.new("Text")
    textDraw.Size = 15
    textDraw.Color = Color3.fromRGB(0, 255, 128)
    textDraw.Center = true
    textDraw.Outline = true
    textDraw.Visible = false
    
    activeDrawings[door] = textDraw

    task.spawn(function()
        while door and door.Parent do
            if espEnabled then
                local targetPart = door:IsA("Model") and (door.PrimaryPart or door:FindFirstChildWhichIsA("BasePart", true)) or door
                if targetPart then
                    local vector, onScreen = Camera:WorldToScreenPoint(targetPart.Position + Vector3.new(0, 3, 0))
                    if onScreen then
                        textDraw.Position = Vector2.new(vector.X, vector.Y)
                        textDraw.Text = "Door " .. tostring(roomName)
                        textDraw.Visible = true
                    else
                        textDraw.Visible = false
                    end
                else
                    textDraw.Visible = false
                end
            else
                textDraw.Visible = false
            end
            task.wait()
        end

        textDraw:Remove()
        activeDrawings[door] = nil
    end)
end

-- Fast polling loop for doors
task.spawn(function()
    while task.wait(0.1) do
        if CurrentRooms then
            for _, room in ipairs(CurrentRooms:GetChildren()) do
                local door = room:FindFirstChild("Door", true)
                if door then
                    createDoorMarker(door, room.Name)
                end
            end
        end
    end
end)
