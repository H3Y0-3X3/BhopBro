--==============================================================
--  Real BHop — GUI + HUD + Разгон (Roblox LocalScript)
--==============================================================
local Players            = game:GetService("Players")
local RunService         = game:GetService("RunService")
local UserInputService   = game:GetService("UserInputService")
local TweenService       = game:GetService("TweenService")

local player = Players.LocalPlayer

--==============================================================
--  КОНФИГ
--==============================================================
local CONFIG = {
    AutoBhop      = true,
    Acceleration  = true,     -- разгон включён
    AccelRate     = 8,        -- +u/s за прыжок
    MaxSpeed      = 300,      -- верхний предел разгона
    JumpPower     = 50,
    Accent        = Color3.fromRGB(255, 160, 0),   -- оранжевый HL
    AccentDim     = Color3.fromRGB(255, 200, 120),
    Bg            = Color3.fromRGB(18, 18, 20),
    BgLight       = Color3.fromRGB(28, 28, 32),
    Text          = Color3.fromRGB(235, 235, 235),
    TextDim       = Color3.fromRGB(150, 150, 155),
    Font          = Enum.Font.Gotham,
    FontMono      = Enum.Font.Code,
}

--==============================================================
--  УТИЛИТЫ
--==============================================================
local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r or 8)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or CONFIG.Accent
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function padding(parent, px)
    local p = Instance.new("UIPadding")
    p.PaddingLeft   = UDim.new(0, px)
    p.PaddingRight  = UDim.new(0, px)
    p.PaddingTop    = UDim.new(0, px)
    p.PaddingBottom = UDim.new(0, px)
    p.Parent = parent
    return p
end

local function makeDraggable(frame, handle)
    handle = handle or frame
    local dragging, dragStart, startPos
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
        end
    end)
    handle.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            local delta = input.Position - dragStart
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
end

--==============================================================
--  ГЛАВНОЕ МЕНЮ
--==============================================================
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Real_BHop_UI"
screenGui.ResetOnSpawn = false
screenGui.IgnoreGuiInset = true
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player:WaitForChild("PlayerGui")

-- Тень/подложка
local shadow = Instance.new("Frame")
shadow.Size = UDim2.new(0, 320, 0, 420)
shadow.Position = UDim2.new(0, 40, 0, 80)
shadow.BackgroundColor3 = Color3.new(0, 0, 0)
shadow.BackgroundTransparency = 0.5
shadow.BorderSizePixel = 0
shadow.ZIndex = 0
shadow.Parent = screenGui
corner(shadow, 16)

-- Основной фрейм меню
local menu = Instance.new("Frame")
menu.Size = UDim2.new(0, 320, 0, 420)
menu.Position = UDim2.new(0, 30, 0, 70)
menu.BackgroundColor3 = CONFIG.Bg
menu.BorderSizePixel = 0
menu.ZIndex = 1
menu.Parent = screenGui
corner(menu, 14)
stroke(menu, CONFIG.Accent, 1, 0.5)
makeDraggable(menu)

-- Заголовок
local titleBar = Instance.new("Frame")
titleBar.Size = UDim2.new(1, 0, 0, 56)
titleBar.BackgroundColor3 = CONFIG.BgLight
titleBar.BorderSizePixel = 0
titleBar.ZIndex = 2
titleBar.Parent = menu
corner(titleBar, 14)

-- Маскируем нижние углы заголовка
local mask = Instance.new("Frame")
mask.Size = UDim2.new(1, 0, 0, 20)
mask.Position = UDim2.new(0, 0, 1, -20)
mask.BackgroundColor3 = CONFIG.BgLight
mask.BorderSizePixel = 0
mask.ZIndex = 2
mask.Parent = titleBar

-- Акцентная полоска
local accentBar = Instance.new("Frame")
accentBar.Size = UDim2.new(0, 4, 0, 28)
accentBar.Position = UDim2.new(0, 16, 0.5, -14)
accentBar.BackgroundColor3 = CONFIG.Accent
accentBar.BorderSizePixel = 0
accentBar.ZIndex = 3
accentBar.Parent = titleBar
corner(accentBar, 2)

local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, -80, 1, 0)
title.Position = UDim2.new(0, 30, 0, 0)
title.BackgroundTransparency = 1
title.Text = "REAL  ·  BHOP"
title.Font = CONFIG.Font
title.TextSize = 18
title.TextColor3 = CONFIG.Text
title.TextXAlignment = Enum.TextXAlignment.Left
title.ZIndex = 3
title.Parent = titleBar

-- Кнопка закрытия
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 28, 0, 28)
closeBtn.Position = UDim2.new(1, -40, 0.5, -14)
closeBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 44)
closeBtn.Text = "✕"
closeBtn.TextColor3 = CONFIG.TextDim
closeBtn.Font = CONFIG.Font
closeBtn.TextSize = 16
closeBtn.AutoButtonColor = false
closeBtn.ZIndex = 3
closeBtn.Parent = titleBar
corner(closeBtn, 8)

closeBtn.MouseEnter:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(180, 50, 50), TextColor3 = Color3.new(1,1,1)}):Play()
end)
closeBtn.MouseLeave:Connect(function()
    TweenService:Create(closeBtn, TweenInfo.new(0.15), {BackgroundColor3 = Color3.fromRGB(40, 40, 44), TextColor3 = CONFIG.TextDim}):Play()
end)
closeBtn.MouseButton1Click:Connect(function()
    TweenService:Create(menu, TweenInfo.new(0.2), {Position = UDim2.new(0, 30, 0, 70 + 500)}):Play()
    TweenService:Create(shadow, TweenInfo.new(0.2), {Position = UDim2.new(0, 40, 0, 80 + 500)}):Play()
end)

-- Контейнер контента
local content = Instance.new("Frame")
content.Size = UDim2.new(1, -32, 1, -80)
content.Position = UDim2.new(0, 16, 0, 68)
content.BackgroundTransparency = 1
content.ZIndex = 2
content.Parent = menu

local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 12)
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = content

--==============================================================
--  КОМПОНЕНТЫ UI
--==============================================================
local function makeSectionLabel(text, order)
    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, 0, 0, 18)
    lbl.BackgroundTransparency = 1
    lbl.Text = text
    lbl.Font = CONFIG.Font
    lbl.TextSize = 11
    lbl.TextColor3 = CONFIG.TextDim
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.LayoutOrder = order
    lbl.ZIndex = 3
    lbl.Parent = content
    return lbl
end

local function makeToggle(name, initial, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 40)
    row.BackgroundColor3 = CONFIG.BgLight
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 3
    row.Parent = content
    corner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -70, 1, 0)
    lbl.Position = UDim2.new(0, 12, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = CONFIG.Font
    lbl.TextSize = 14
    lbl.TextColor3 = CONFIG.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(0, 40, 0, 20)
    track.Position = UDim2.new(1, -52, 0.5, -10)
    track.BackgroundColor3 = initial and CONFIG.Accent or Color3.fromRGB(50, 50, 55)
    track.BorderSizePixel = 0
    track.ZIndex = 4
    track.Parent = row
    corner(track, 10)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 16, 0, 16)
    knob.Position = initial and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 5
    knob.Parent = track
    corner(knob, 8)

    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(1, 0, 1, 0)
    btn.BackgroundTransparency = 1
    btn.Text = ""
    btn.ZIndex = 6
    btn.Parent = row

    local state = initial
    btn.MouseButton1Click:Connect(function()
        state = not state
        TweenService:Create(track, TweenInfo.new(0.15),
            {BackgroundColor3 = state and CONFIG.Accent or Color3.fromRGB(50, 50, 55)}):Play()
        TweenService:Create(knob, TweenInfo.new(0.15),
            {Position = state and UDim2.new(1, -18, 0, 2) or UDim2.new(0, 2, 0, 2)}):Play()
        if callback then callback(state) end
    end)
    return row
end

local function makeSlider(name, min, max, initial, order, callback)
    local row = Instance.new("Frame")
    row.Size = UDim2.new(1, 0, 0, 54)
    row.BackgroundColor3 = CONFIG.BgLight
    row.BorderSizePixel = 0
    row.LayoutOrder = order
    row.ZIndex = 3
    row.Parent = content
    corner(row, 8)

    local lbl = Instance.new("TextLabel")
    lbl.Size = UDim2.new(1, -60, 0, 20)
    lbl.Position = UDim2.new(0, 12, 0, 6)
    lbl.BackgroundTransparency = 1
    lbl.Text = name
    lbl.Font = CONFIG.Font
    lbl.TextSize = 13
    lbl.TextColor3 = CONFIG.Text
    lbl.TextXAlignment = Enum.TextXAlignment.Left
    lbl.ZIndex = 4
    lbl.Parent = row

    local valLbl = Instance.new("TextLabel")
    valLbl.Size = UDim2.new(0, 50, 0, 20)
    valLbl.Position = UDim2.new(1, -60, 0, 6)
    valLbl.BackgroundTransparency = 1
    valLbl.Text = tostring(initial)
    valLbl.Font = CONFIG.FontMono
    valLbl.TextSize = 13
    valLbl.TextColor3 = CONFIG.Accent
    valLbl.TextXAlignment = Enum.TextXAlignment.Right
    valLbl.ZIndex = 4
    valLbl.Parent = row

    local track = Instance.new("Frame")
    track.Size = UDim2.new(1, -24, 0, 4)
    track.Position = UDim2.new(0, 12, 0, 38)
    track.BackgroundColor3 = Color3.fromRGB(50, 50, 55)
    track.BorderSizePixel = 0
    track.ZIndex = 4
    track.Parent = row
    corner(track, 2)

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new((initial - min) / (max - min), 0, 1, 0)
    fill.BackgroundColor3 = CONFIG.Accent
    fill.BorderSizePixel = 0
    fill.ZIndex = 5
    fill.Parent = track
    corner(fill, 2)

    local knob = Instance.new("Frame")
    knob.Size = UDim2.new(0, 12, 0, 12)
    knob.Position = UDim2.new((initial - min) / (max - min), -6, 0.5, -6)
    knob.BackgroundColor3 = Color3.new(1, 1, 1)
    knob.BorderSizePixel = 0
    knob.ZIndex = 6
    knob.Parent = track
    corner(knob, 6)

    local dragging = false
    local function updateFromX(x)
        local rel = math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
        local val = math.floor(min + (max - min) * rel + 0.5)
        fill.Size = UDim2.new(rel, 0, 1, 0)
        knob.Position = UDim2.new(rel, -6, 0.5, -6)
        valLbl.Text = tostring(val)
        if callback then callback(val) end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                      or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    return row
end

--==============================================================
--  НАПОЛНЕНИЕ МЕНЮ
--==============================================================
makeSectionLabel("MECHANICS", 1)

makeToggle("Auto BHop", CONFIG.AutoBhop, 2, function(v) CONFIG.AutoBhop = v end)
makeToggle("Acceleration", CONFIG.Acceleration, 3, function(v) CONFIG.Acceleration = v end)

makeSectionLabel("TUNING", 4)
makeSlider("Accel Rate", 1, 30, CONFIG.AccelRate, 5, function(v) CONFIG.AccelRate = v end)
makeSlider("Max Speed", 100, 600, CONFIG.MaxSpeed, 6, function(v) CONFIG.MaxSpeed = v end)
makeSlider("Jump Power", 30, 100, CONFIG.JumpPower, 7, function(v) CONFIG.JumpPower = v end)

--==============================================================
--  HUD СКОРОСТИ (HL-стиль)
--==============================================================
local hud = Instance.new("Frame")
hud.Size = UDim2.new(0, 200, 0, 64)
hud.Position = UDim2.new(1, -220, 1, -110)
hud.BackgroundColor3 = CONFIG.Bg
hud.BackgroundTransparency = 0.25
hud.BorderSizePixel = 0
hud.ZIndex = 5
hud.Parent = screenGui
corner(hud, 10)
stroke(hud, CONFIG.Accent, 1, 0.3)

local accent = Instance.new("Frame")
accent.Size = UDim2.new(0, 4, 0, 40)
accent.Position = UDim2.new(0, 8, 0.5, -20)
accent.BackgroundColor3 = CONFIG.Accent
accent.BorderSizePixel = 0
accent.ZIndex = 6
accent.Parent = hud
corner(accent, 2)

local speedLbl = Instance.new("TextLabel")
speedLbl.Size = UDim2.new(1, -32, 0, 30)
speedLbl.Position = UDim2.new(0, 20, 0, 8)
speedLbl.BackgroundTransparency = 1
speedLbl.Text = "SPEED: 0"
speedLbl.Font = CONFIG.FontMono
speedLbl.TextSize = 22
speedLbl.TextColor3 = CONFIG.Accent
speedLbl.TextXAlignment = Enum.TextXAlignment.Left
speedLbl.ZIndex = 6
speedLbl.Parent = hud

local stateLbl = Instance.new("TextLabel")
stateLbl.Size = UDim2.new(1, -32, 0, 20)
stateLbl.Position = UDim2.new(0, 20, 0, 36)
stateLbl.BackgroundTransparency = 1
stateLbl.Text = "GROUND"
stateLbl.Font = CONFIG.FontMono
stateLbl.TextSize = 13
stateLbl.TextColor3 = CONFIG.TextDim
stateLbl.TextXAlignment = Enum.TextXAlignment.Left
stateLbl.ZIndex = 6
stateLbl.Parent = hud

--==============================================================
--  ЛОГИКА BHop + РАЗГОН
--==============================================================
local character, humanoid, rootPart
local currentSpeedMult = 1   -- накопленный множитель разгона
local lastOnGround = true

local function isOnGround()
    if not rootPart then return false end
    local params = RaycastParams.new()
    params.FilterDescendantsInstances = {character}
    params.FilterType = Enum.RaycastFilterType.Exclude
    local res = workspace:Raycast(rootPart.Position, Vector3.new(0, -6, 0), params)
    return res ~= nil
end

local function onCharacterAdded(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    currentSpeedMult = 1
    humanoid.UseJumpPower = true
    humanoid.JumpPower = CONFIG.JumpPower
end

if player.Character then onCharacterAdded(player.Character) end
player.CharacterAdded:Connect(onCharacterAdded)

RunService.Heartbeat:Connect(function(dt)
    if not character or not humanoid or not rootPart then return end
    if humanoid.Health <= 0 then return end

    local vel = rootPart.AssemblyLinearVelocity
    local hor = Vector3.new(vel.X, 0, vel.Z)
    local speed = hor.Magnitude
    local onGround = isOnGround()

    -- === РАЗГОН ===
    -- Пока игрок в воздухе и держит пробел — наращиваем скорость
    local holdingJump = UserInputService:IsKeyDown(Enum.KeyCode.Space)
    if CONFIG.Acceleration and holdingJump and not onGround then
        local boost = CONFIG.AccelRate * dt
        local newSpeed = math.min(speed + boost, CONFIG.MaxSpeed)
        if speed > 0.5 then
            local dir = hor.Unit
            rootPart.AssemblyLinearVelocity = Vector3.new(dir.X * newSpeed, vel.Y, dir.Z * newSpeed)
        end
    end

    -- === AUTO BHOP ===
    if CONFIG.AutoBhop and holdingJump and onGround then
        rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, CONFIG.JumpPower, vel.Z)
    end

    -- === ОГРАНИЧЕНИЕ ===
    if speed > CONFIG.MaxSpeed * 1.2 then
        local dir = hor.Unit
        rootPart.AssemblyLinearVelocity = Vector3.new(dir.X * CONFIG.MaxSpeed, vel.Y, dir.Z * CONFIG.MaxSpeed)
    end

    -- === HUD ===
    speedLbl.Text = "SPEED: " .. math.floor(speed)
    stateLbl.Text = onGround and "GROUND" or ("AIR  ▲  " .. math.floor(speed) .. " u/s")
    stateLbl.TextColor3 = onGround and CONFIG.TextDim or CONFIG.AccentDim

    -- Переключение цвета HUD-рамки при разгоне
    local t = math.clamp(speed / CONFIG.MaxSpeed, 0, 1)
    speedLbl.TextColor3 = Color3.fromRGB(
        255,
        math.floor(160 + t * 80),
        math.floor(t * 100))
end)
