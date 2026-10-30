-- Real BHop + HL Style Speed HUD (Roblox LocalScript)
-- Поместить в StarterPlayerScripts или выполнить через executor

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

-- === НАСТРОЙКИ ===
local CONFIG = {
    AutoBhop = true,
    JumpPower = 50,
    SpeedLimit = 250,        -- ограничение скорости для предотвращения вылета
    HUD_Color = Color3.fromRGB(255, 160, 0), -- оранжевый HL
    HUD_Font = Enum.Font.Code,
}

-- === HUD (имитация Half-Life) ===
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "Real_BHop_HUD"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local hudFrame = Instance.new("Frame")
hudFrame.Size = UDim2.new(0, 200, 0, 60)
hudFrame.Position = UDim2.new(1, -220, 1, -100) -- правый нижний угол
hudFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
hudFrame.BackgroundTransparency = 0.7
hudFrame.BorderSizePixel = 1
hudFrame.BorderColor3 = CONFIG.HUD_Color
hudFrame.Parent = screenGui

local speedLabel = Instance.new("TextLabel")
speedLabel.Size = UDim2.new(1, -10, 0, 30)
speedLabel.Position = UDim2.new(0, 5, 0, 5)
speedLabel.BackgroundTransparency = 1
speedLabel.TextColor3 = CONFIG.HUD_Color
speedLabel.Font = CONFIG.HUD_Font
speedLabel.TextSize = 22
speedLabel.TextXAlignment = Enum.TextXAlignment.Left
speedLabel.Text = "SPEED: 0"
speedLabel.Parent = hudFrame

local stateLabel = Instance.new("TextLabel")
stateLabel.Size = UDim2.new(1, -10, 0, 20)
stateLabel.Position = UDim2.new(0, 5, 0, 32)
stateLabel.BackgroundTransparency = 1
stateLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
stateLabel.Font = CONFIG.HUD_Font
stateLabel.TextSize = 14
stateLabel.TextXAlignment = Enum.TextXAlignment.Left
stateLabel.Text = "GROUND"
stateLabel.Parent = hudFrame

-- === BHop логика ===
local character, humanoid, rootPart

local function onCharacterAdded(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    humanoid.UseJumpPower = true
    humanoid.JumpPower = CONFIG.JumpPower
    
    -- Переключение в Physics в воздухе для сохранения импульса
    humanoid.StateChanged:Connect(function(old, new)
        if new == Enum.HumanoidStateType.Jumping or new == Enum.HumanoidStateType.Freefall then
            -- Временно отключаем управление Humanoid, чтобы velocity не сбрасывалась
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        elseif new == Enum.HumanoidStateType.Physics then
            -- Проверка приземления через Raycast
            local params = RaycastParams.new()
            params.FilterDescendantsInstances = {char}
            params.FilterType = Enum.RaycastFilterType.Exclude
            local result = workspace:Raycast(rootPart.Position, Vector3.new(0, -5, 0), params)
            if result then
                humanoid:ChangeState(Enum.HumanoidStateType.Running)
            end
        end
    end)
end

if player.Character then
    onCharacterAdded(player.Character)
end
player.CharacterAdded:Connect(onCharacterAdded)

-- === Основной цикл (Auto Bhop + HUD) ===
RunService.Heartbeat:Connect(function(dt)
    if not character or not humanoid or not rootPart then return end
    if humanoid.Health <= 0 then return end
    
    local vel = rootPart.AssemblyLinearVelocity
    local horSpeed = Vector3.new(vel.X, 0, vel.Z).Magnitude
    local currentState = humanoid:GetState()
    
    -- HUD обновление
    speedLabel.Text = "SPEED: " .. math.floor(horSpeed)
    if currentState == Enum.HumanoidStateType.Physics or currentState == Enum.HumanoidStateType.Freefall then
        stateLabel.Text = "AIR ▲"
    else
        stateLabel.Text = "GROUND"
    end
    
    -- Ограничение скорости (защита от вылета)
    if horSpeed > CONFIG.SpeedLimit then
        local normalized = Vector3.new(vel.X, 0, vel.Z).Unit * CONFIG.SpeedLimit
        rootPart.AssemblyLinearVelocity = Vector3.new(normalized.X, vel.Y, normalized.Z)
    end
    
    -- Auto Bhop: удержание пробела = прыжок при касании земли
    if CONFIG.AutoBhop and UserInputService:IsKeyDown(Enum.KeyCode.Space) then
        -- Проверка земли через Raycast (не полагаемся на Humanoid:GetState, т.к. в Physics он не меняется)
        local params = RaycastParams.new()
        params.FilterDescendantsInstances = {character}
        params.FilterType = Enum.RaycastFilterType.Exclude
        local ground = workspace:Raycast(rootPart.Position, Vector3.new(0, -6, 0), params)
        
        if ground then
            -- Вручную задаём вертикальную скорость для прыжка
            rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, CONFIG.JumpPower, vel.Z)
        end
    end
end)
