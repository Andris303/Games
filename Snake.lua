-- MADE ENTIRELY WITH AI

local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

--------------------------------------------------
-- SETTINGS
--------------------------------------------------

local GRID_WIDTH = 24
local GRID_HEIGHT = 18

local MOVE_DELAY = .11

local BG_COLOR = Color3.fromRGB(20, 20, 24)
local GRID_COLOR = Color3.fromRGB(45, 45, 52)
local BORDER_COLOR = Color3.fromRGB(180, 180, 190)

local SNAKE_COLOR = Color3.fromRGB(70, 210, 100)
local HEAD_COLOR = Color3.fromRGB(120, 255, 140)
local FOOD_COLOR = Color3.fromRGB(240, 70, 70)

local TEXT_COLOR = Color3.fromRGB(240, 240, 245)

--------------------------------------------------
-- STATE
--------------------------------------------------

local snake = {}
local food = {
    X = 1,
    Y = 1,
}

local direction = {
    X = 1,
    Y = 0,
}

local nextDirection = {
    X = 1,
    Y = 0,
}

local previousKeys = {}

local score = 0
local gameOver = false
local lastMove = os.clock()

--------------------------------------------------
-- DRAWING
--------------------------------------------------

local function FilledRect(x, y, width, height, color, opacity)
    DrawingImmediate.FilledRectangle(
        Vector2.new(x, y),
        Vector2.new(width, height),
        color,
        opacity or 1,
        0
    )
end

local function OutlineRect(x, y, width, height, color, thickness)
    DrawingImmediate.Rectangle(
        Vector2.new(x, y),
        Vector2.new(width, height),
        color,
        1,
        0,
        thickness or 1
    )
end

--------------------------------------------------
-- SNAKE
--------------------------------------------------

local function IsSnakeAt(x, y)
    for _, segment in snake do
        if segment.X == x
        and segment.Y == y then
            return true
        end
    end

    return false
end

local function SpawnFood()
    for _ = 1, 200 do
        local x = math.random(1, GRID_WIDTH)
        local y = math.random(1, GRID_HEIGHT)

        if not IsSnakeAt(x, y) then
            food.X = x
            food.Y = y

            return
        end
    end

    -- fallback if the board gets very full

    for y = 1, GRID_HEIGHT do
        for x = 1, GRID_WIDTH do
            if not IsSnakeAt(x, y) then
                food.X = x
                food.Y = y

                return
            end
        end
    end
end

local function Reset()
    local centerX = math.floor(GRID_WIDTH / 2)
    local centerY = math.floor(GRID_HEIGHT / 2)

    snake = {
        {
            X = centerX,
            Y = centerY,
        },

        {
            X = centerX - 1,
            Y = centerY,
        },

        {
            X = centerX - 2,
            Y = centerY,
        },

        {
            X = centerX - 3,
            Y = centerY,
        },
    }

    direction = {
        X = 1,
        Y = 0,
    }

    nextDirection = {
        X = 1,
        Y = 0,
    }

    score = 0
    gameOver = false

    lastMove = os.clock()

    SpawnFood()
end

--------------------------------------------------
-- MOVEMENT
--------------------------------------------------

local function SetDirection(x, y)
    -- cannot turn directly backwards

    if x == -direction.X
    and y == -direction.Y then
        return
    end

    nextDirection = {
        X = x,
        Y = y,
    }
end

local function MoveSnake()
    if gameOver then
        return
    end

    direction = {
        X = nextDirection.X,
        Y = nextDirection.Y,
    }

    local head = snake[1]

    local newX =
        head.X + direction.X

    local newY =
        head.Y + direction.Y

    --------------------------------------------------
    -- WALL
    --------------------------------------------------

    if newX < 1
    or newX > GRID_WIDTH
    or newY < 1
    or newY > GRID_HEIGHT then

        gameOver = true
        return
    end

    --------------------------------------------------
    -- FOOD
    --------------------------------------------------

    local eating =
        newX == food.X
        and newY == food.Y

    --------------------------------------------------
    -- SELF COLLISION
    --------------------------------------------------

    local lastCheck = #snake

    -- The tail disappears this frame, so moving
    -- onto the old tail position is valid.
    if not eating then
        lastCheck -= 1
    end

    for i = 1, lastCheck do
        local segment = snake[i]

        if segment.X == newX
        and segment.Y == newY then
            gameOver = true
            return
        end
    end

    --------------------------------------------------
    -- MOVE
    --------------------------------------------------

    table.insert(
        snake,
        1,
        {
            X = newX,
            Y = newY,
        }
    )

    if eating then
        score += 1
        SpawnFood()
    else
        table.remove(
            snake,
            #snake
        )
    end
end

--------------------------------------------------
-- INPUT
--------------------------------------------------

local function HandleNewKey(key)
    if key == "W"
    or key == "Up"
    or key == "UpArrow"
    or key == "ArrowUp" then

        SetDirection(0, -1)

    elseif key == "S"
    or key == "Down"
    or key == "DownArrow"
    or key == "ArrowDown" then

        SetDirection(0, 1)

    elseif key == "A"
    or key == "Left"
    or key == "LeftArrow"
    or key == "ArrowLeft" then

        SetDirection(-1, 0)

    elseif key == "D"
    or key == "Right"
    or key == "RightArrow"
    or key == "ArrowRight" then

        SetDirection(1, 0)

    elseif key == "R" then
        Reset()
    end
end

local function Update()
    --------------------------------------------------
    -- INPUT
    --------------------------------------------------

    local currentKeys = {}

    for _, key in getpressedkeys() do
        currentKeys[key] = true

        if not previousKeys[key] then
            HandleNewKey(key)
        end
    end

    previousKeys = currentKeys

    --------------------------------------------------
    -- MOVEMENT
    --------------------------------------------------

    local now = os.clock()

    if now - lastMove >= MOVE_DELAY then
        lastMove = now
        MoveSnake()
    end
end

--------------------------------------------------
-- RENDER
--------------------------------------------------

local function Render()
    local viewport =
        Camera.ViewportSize

    --------------------------------------------------
    -- AUTO-SCALE BOARD
    --------------------------------------------------

    local usableWidth =
        viewport.X - 40

    local usableHeight =
        viewport.Y - 100

    local cellSize =
        math.floor(
            math.min(
                usableWidth / GRID_WIDTH,
                usableHeight / GRID_HEIGHT
            )
        )

    cellSize =
        math.clamp(
            cellSize,
            8,
            28
        )

    local boardWidth =
        GRID_WIDTH * cellSize

    local boardHeight =
        GRID_HEIGHT * cellSize

    local startX =
        viewport.X / 2
        - boardWidth / 2

    local startY =
        viewport.Y / 2
        - boardHeight / 2
        + 15

    --------------------------------------------------
    -- TITLE
    --------------------------------------------------

    DrawingImmediate.OutlinedText(
        Vector2.new(
            viewport.X / 2,
            startY - 47
        ),
        25,
        TEXT_COLOR,
        1,
        "SNAKE",
        true
    )

    DrawingImmediate.OutlinedText(
        Vector2.new(
            viewport.X / 2,
            startY - 22
        ),
        16,
        TEXT_COLOR,
        1,
        "Score: " .. tostring(score),
        true
    )

    --------------------------------------------------
    -- BACKGROUND
    --------------------------------------------------

    FilledRect(
        startX,
        startY,
        boardWidth,
        boardHeight,
        BG_COLOR,
        1
    )

    --------------------------------------------------
    -- GRID
    --------------------------------------------------

    for x = 1, GRID_WIDTH - 1 do
        local px =
            startX + x * cellSize

        DrawingImmediate.Line(
            Vector2.new(
                px,
                startY
            ),

            Vector2.new(
                px,
                startY + boardHeight
            ),

            GRID_COLOR,
            .35,
            1,
            1
        )
    end

    for y = 1, GRID_HEIGHT - 1 do
        local py =
            startY + y * cellSize

        DrawingImmediate.Line(
            Vector2.new(
                startX,
                py
            ),

            Vector2.new(
                startX + boardWidth,
                py
            ),

            GRID_COLOR,
            .35,
            1,
            1
        )
    end

    --------------------------------------------------
    -- FOOD
    --------------------------------------------------

    local foodPadding =
        math.max(
            2,
            math.floor(cellSize * .18)
        )

    FilledRect(
        startX
            + (food.X - 1) * cellSize
            + foodPadding,

        startY
            + (food.Y - 1) * cellSize
            + foodPadding,

        cellSize
            - foodPadding * 2,

        cellSize
            - foodPadding * 2,

        FOOD_COLOR,
        1
    )

    --------------------------------------------------
    -- SNAKE
    --------------------------------------------------

    local snakePadding =
        math.max(
            1,
            math.floor(cellSize * .08)
        )

    for i, segment in snake do
        local color =
            i == 1
            and HEAD_COLOR
            or SNAKE_COLOR

        FilledRect(
            startX
                + (segment.X - 1)
                * cellSize
                + snakePadding,

            startY
                + (segment.Y - 1)
                * cellSize
                + snakePadding,

            cellSize
                - snakePadding * 2,

            cellSize
                - snakePadding * 2,

            color,
            1
        )
    end

    --------------------------------------------------
    -- BORDER
    --------------------------------------------------

    OutlineRect(
        startX,
        startY,
        boardWidth,
        boardHeight,
        BORDER_COLOR,
        2
    )

    --------------------------------------------------
    -- GAME OVER
    --------------------------------------------------

    if gameOver then
        FilledRect(
            startX,
            startY
                + boardHeight / 2
                - 35,

            boardWidth,
            70,

            Color3.fromRGB(
                10,
                10,
                12
            ),

            .8
        )

        DrawingImmediate.OutlinedText(
            Vector2.new(
                viewport.X / 2,
                startY
                    + boardHeight / 2
                    - 10
            ),

            26,
            FOOD_COLOR,
            1,
            "GAME OVER",
            true
        )

        DrawingImmediate.OutlinedText(
            Vector2.new(
                viewport.X / 2,
                startY
                    + boardHeight / 2
                    + 18
            ),

            15,
            TEXT_COLOR,
            1,
            "Press R to restart",
            true
        )
    end
end

--------------------------------------------------
-- START
--------------------------------------------------

Reset()

RunService.PreLocal:Connect(Update)
RunService.Render:Connect(Render)

print("Snake loaded - WASD to move, R to restart")
