local workspace = game.Workspace
local runservice = game.RunService
local players = game.Players
local localplayer = players.LocalPlayer
local camera = workspace.CurrentCamera
local uis = game:GetService("UserInputService")

local v3 = vector.create
local keypress = keypress
local keyrelease = keyrelease
local getpressedkeys = getpressedkeys

local target_key = "c"
local range = 11
local dash_range = 18
local dash_offset = 12

local F_KEY = 0x46
local BLOCK_LINGER = 0.17

local target_player = nil
local blocking = false
local last_key_states = {}
local last_m1_values = {}
local last_threat_time = 0

local render_state = {
    my_root = nil,
    t_root = nil,
    range = range,
    dashing = false,
    targeting = false,
}

local char_folder = workspace:FindFirstChild("Characters")

local function setblock(state)
    if state == blocking then return end
    blocking = state
    if state then keypress(F_KEY) else keyrelease(F_KEY) end
end

local function was_key_pressed(key)
    local keys = getpressedkeys()
    local is_down = false
    local k_low = key:lower()
    for i = 1, #keys do
        if keys[i]:lower() == k_low then
            is_down = true
            break
        end
    end
    local pressed = is_down and not last_key_states[key]
    last_key_states[key] = is_down
    return pressed
end

local function get_closest_to_cursor()
    if not char_folder then return nil end
    local closest = nil
    local dist_sq = 50000
    local mouse_loc = uis:GetMouseLocation()

    local children = char_folder:GetChildren()
    for i = 1, #children do
        local char = children[i]
        if char ~= localplayer.Character then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                local s_pos, on_screen = camera:WorldToScreenPoint(hrp.Position)
                if on_screen then
                    local dx, dy = s_pos.X - mouse_loc.X, s_pos.Y - mouse_loc.Y
                    local d_sq = (dx * dx) + (dy * dy)
                    if d_sq < dist_sq then
                        dist_sq = d_sq
                        closest = char
                    end
                end
            end
        end
    end
    return closest
end

local function draw_visuals(my_root, t_root, current_range, is_dashing, targeting)
    local col = targeting and Color3.new(0, 1, 0) or Color3.new(1, 0, 0)
    local segs = 18
    local step = 6.28318 / segs
    local center = my_root.Position
    if is_dashing and t_root then
        center = t_root.Position + (t_root.CFrame.LookVector * dash_offset)
    end

    local last_p = nil
    for i = 0, segs do
        local ang = i * step
        local wpos = v3(center.X + math.cos(ang) * current_range, center.Y - 3, center.Z + math.sin(ang) * current_range)
        local p, on_screen = camera:WorldToScreenPoint(wpos)
        if last_p and on_screen then
            DrawingImmediate.Line(last_p, Vector2.new(p.X, p.Y), col, 1, 1)
        end
        last_p = Vector2.new(p.X, p.Y)
    end

    if targeting and t_root then
        local head_pos = t_root.Position + v3(0, 4.5, 0)
        local s_pos, on_screen = camera:WorldToScreenPoint(head_pos)
        if on_screen then
            DrawingImmediate.OutlinedText(Vector2.new(s_pos.X, s_pos.Y), 18, Color3.new(1, 0.2, 0.2), 1, "Target", true, "Interum")
        end
    end
end

runservice.PreLocal:Connect(function()
    local now = tick()
    if was_key_pressed(target_key) then
        target_player = (not target_player) and get_closest_to_cursor() or nil
        if not target_player then setblock(false) end
    end

    local my_char = localplayer.Character
    local my_root = my_char and my_char:FindFirstChild("HumanoidRootPart")
    render_state.my_root = my_root
    if not my_root then
        render_state.t_root = nil
        return
    end

    local active_range = range
    local threat_detected = false
    local is_dashing = false
    local t_root = nil

    if target_player and target_player.Parent == char_folder then
        t_root = target_player:FindFirstChild("HumanoidRootPart")
        local info = target_player:FindFirstChild("Info")

        if t_root and info then
            local has_inskill = info:FindFirstChild("InSkill")
            local has_nojump = info:FindFirstChild("NoJump")
            local has_nosprint = info:FindFirstChild("NoSprint")
            local has_stun = info:FindFirstChild("Stun")
            local has_chase = info:FindFirstChild("DisableChase")

            if has_inskill and has_nojump and has_nosprint then
                threat_detected = true
            end

            local current_m1 = target_player:GetAttribute("CurrentM1") or 0
            if current_m1 ~= last_m1_values[target_player] then
                threat_detected = true
                last_m1_values[target_player] = current_m1
            end

            if has_inskill and has_stun and has_chase then
                is_dashing = true
                active_range = dash_range
                threat_detected = true
            end

            if threat_detected then
                last_threat_time = now
            end

            local check_pos = t_root.Position
            if is_dashing then check_pos = check_pos + (t_root.CFrame.LookVector * dash_offset) end

            local my_pos = my_root.Position
            local dx = check_pos.X - my_pos.X
            local dy = check_pos.Y - my_pos.Y
            local dz = check_pos.Z - my_pos.Z
            local dist_sq = (dx*dx + dy*dy + dz*dz)

            if dist_sq <= (active_range * active_range) then
                if threat_detected or (now - last_threat_time < BLOCK_LINGER) then
                    setblock(true)
                else
                    setblock(false)
                end
            else
                setblock(false)
            end
        end
    else
        setblock(false)
    end

    render_state.t_root = t_root
    render_state.range = active_range
    render_state.dashing = is_dashing
    render_state.targeting = target_player ~= nil
end)

runservice.Render:Connect(function()
    local my_root = render_state.my_root
    if not my_root then return end

    pcall(draw_visuals, my_root, render_state.t_root, render_state.range, render_state.dashing, render_state.targeting)
end)
