-- ============================================================
-- REAL BHOP CORE (Source-style Air Accelerate)
-- Для Baseplate / Инжектора. Не требует GUI.
-- ============================================================

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local camera = Workspace.CurrentCamera

-- ============================================================
-- КОНФИГУРАЦИЯ (МЕНЯЙ ТОЛЬКО ЭТО)
-- ============================================================
local CONFIG = {
    -- Основные
    AutoBhop = true,            -- Авто-прыжок при зажатом пробеле
    JumpPower = 50,             -- Сила прыжка (стандарт Roblox = 50)
    
    -- Разгон (Source Engine style)
    AirAccelerate = 100,        -- Сила разгона в воздухе (чем больше, тем быстрее разгон)
    MaxAirSpeed = 350,          -- Максимальная скорость, до которой можно разогнаться (studs/s)
    AirCap = 30,                -- Потолок скорости, которую можно НАБРАТЬ за один прыжок (в units per second, ~0.8 * studs/s)
    
    -- Земля
    GroundSpeed = 16,           -- Обычная скорость на земле (WalkSpeed)
    
    -- Защита
    MaxTotalSpeed = 500,        -- Абсолютный предел, чтобы не улететь на орбиту
}
-- ============================================================

local character, humanoid, rootPart
local isGrounded = false
local jumpHeld = false

-- Утилита: плоский вектор (без Y)
local function flat(v)
    return Vector3.new(v.X, 0, v.Z)
end

-- Утилита: проверка земли через Raycast (надежнее, чем состояния Humanoid)
local function checkGrounded()
    if not character or not rootPart then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    local result = Workspace:Raycast(rootPart.Position, Vector3.new(0, -6, 0), params)
    return result ~= nil
end

-- Настройка персонажа
local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")
    
    humanoid.UseJumpPower = true
    humanoid.JumpPower = CONFIG.JumpPower
    humanoid.WalkSpeed = CONFIG.GroundSpeed
    
    -- КРИТИЧНО: отключаем встроенные состояния Jumping/Falling, чтобы Roblox
    -- не сбрасывал нашу скорость. Мы будем управлять физикой вручную.
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Jumping, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Freefall, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Landed, false)
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Running, false)
    
    -- Оставляем только Physics и минимальные состояния
    humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
    humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    
    print("[RealBhop] Character setup complete. State: Physics")
end

if player.Character then
    setupCharacter(player.Character)
end
player.CharacterAdded:Connect(setupCharacter)

-- Отслеживание пробела
UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        jumpHeld = true
    end
end)

UserInputService.InputEnded:Connect(function(input, gameProcessed)
    if gameProcessed then return end
    if input.KeyCode == Enum.KeyCode.Space then
        jumpHeld = false
    end
end)

-- Основной цикл физики
RunService.Heartbeat:Connect(function(dt)
    if not character or not humanoid or not rootPart then return end
    if humanoid.Health <= 0 then return end
    
    isGrounded = checkGrounded()
    
    local vel = rootPart.AssemblyLinearVelocity
    local flatVel = flat(vel)
    local currentSpeed = flatVel.Magnitude
    
    -- ============================================================
    -- 1. ЗЕМЛЯ: Обычное движение + Прыжок
    -- ============================================================
    if isGrounded then
        -- Убеждаемся, что мы в Physics (на случай если Roblox переключил)
        if humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
            humanoid:ChangeState(Enum.HumanoidStateType.Physics)
        end
        
        -- Авто-прыжок
        if CONFIG.AutoBhop and jumpHeld then
            -- Задаем вертикальную скорость напрямую
            rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, CONFIG.JumpPower, vel.Z)
        end
    end
    
    -- ============================================================
    -- 2. ВОЗДУХ: Source-style Air Accelerate (Разгон)
    -- ============================================================
    if not isGrounded then
        -- Получаем направление ввода игрока (WASD)
        local moveDir = humanoid.MoveDirection
        
        if moveDir.Magnitude > 0.1 and currentSpeed > 0.5 then
            -- Вычисляем "желаемую" скорость в направлении движения
            -- В Source engine разгон работает даже если ты не смотришь точно в направлении движения
            local wishDir = moveDir.Unit
            
            -- Текущая скорость в направлении wishDir (проекция)
            local currentInWishDir = flatVel:Dot(wishDir)
            
            -- Сколько можем добавить (Source формула)
            local addSpeed = CONFIG.AirCap - currentInWishDir
            
            if addSpeed > 0 then
                -- Ограничиваем добавку за кадр
                local accelSpeed = math.min(CONFIG.AirAccelerate * dt, addSpeed)
                
                -- Применяем ускорение
                local newFlatVel = flatVel + wishDir * accelSpeed
                
                -- Ограничиваем общую скорость
                if newFlatVel.Magnitude > CONFIG.MaxAirSpeed then
                    newFlatVel = newFlatVel.Unit * CONFIG.MaxAirSpeed
                end
                
                -- Применяем обратно, сохраняя вертикальную скорость
                rootPart.AssemblyLinearVelocity = Vector3.new(newFlatVel.X, vel.Y, newFlatVel.Z)
            end
        end
    end
    
    -- ============================================================
    -- 3. АБСОЛЮТНАЯ ЗАЩИТА
    -- ============================================================
    local finalVel = rootPart.AssemblyLinearVelocity
    local finalFlat = flat(finalVel)
    if finalFlat.Magnitude > CONFIG.MaxTotalSpeed then
        local dir = finalFlat.Unit
        rootPart.AssemblyLinearVelocity = Vector3.new(
            dir.X * CONFIG.MaxTotalSpeed,
            finalVel.Y,
            dir.Z * CONFIG.MaxTotalSpeed
        )
    end
end)

print("[RealBhop] Script loaded. AirAccelerate=" .. CONFIG.AirAccelerate .. ", MaxAirSpeed=" .. CONFIG.MaxAirSpeed)
