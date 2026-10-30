-- ============================================================
-- REAL BHOP CORE (Source-style) — R6 / Baseplate
-- Полный контроль физики. Инжектор / LocalScript.
-- ============================================================
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local player = Players.LocalPlayer
local character, humanoid, rootPart
local jumpHeld = false

-- ============================================================
-- НАСТРОЙКИ (меняй тут)
-- ============================================================
local CONFIG = {
    AutoBhop       = true,
    JumpPower      = 50,
    WalkSpeed      = 16,

    -- Разгон (Source-style Air Accelerate)
    AirAccelerate  = 100,   -- сила разгона
    AirCap         = 30,    -- потолок скорости, которую можно НАБРАТЬ за кадр (в studs/s)
    MaxAirSpeed    = 400,   -- максимальная горизонтальная скорость

    -- Защита
    MaxTotalSpeed  = 500,
}
-- ============================================================

local function flat(v) return Vector3.new(v.X, 0, v.Z) end

local function isGrounded()
    if not rootPart or not character then return false end
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = {character}
    return Workspace:Raycast(rootPart.Position, Vector3.new(0, -6, 0), params) ~= nil
end

local function setupCharacter(char)
    character = char
    humanoid = char:WaitForChild("Humanoid")
    rootPart = char:WaitForChild("HumanoidRootPart")

    humanoid.UseJumpPower = true
    humanoid.JumpPower = CONFIG.JumpPower
    humanoid.WalkSpeed = CONFIG.WalkSpeed

    -- КРИТИЧНО: отключаем все состояния, кроме Physics.
    -- Это заставляет Humanoid перестать сбрасывать AssemblyLinearVelocity.
    pcall(function()
        for _, state in ipairs({
            Enum.HumanoidStateType.Jumping,
            Enum.HumanoidStateType.Freefall,
            Enum.HumanoidStateType.Landed,
            Enum.HumanoidStateType.Running,
            Enum.HumanoidStateType.Climbing,
            Enum.HumanoidStateType.Seated,
        }) do
            humanoid:SetStateEnabled(state, false)
        end
        humanoid:SetStateEnabled(Enum.HumanoidStateType.Physics, true)
        humanoid:ChangeState(Enum.HumanoidStateType.Physics)
    end)
end

if player.Character then setupCharacter(player.Character) end
player.CharacterAdded:Connect(setupCharacter)

-- Ввод
UserInputService.InputBegan:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then jumpHeld = true end
end)
UserInputService.InputEnded:Connect(function(input, gp)
    if gp then return end
    if input.KeyCode == Enum.KeyCode.Space then jumpHeld = false end
end)

-- ============================================================
-- ОСНОВНОЙ ЦИКЛ
-- ============================================================
RunService.Heartbeat:Connect(function(dt)
    if not character or not humanoid or not rootPart or not rootPart.Parent then return end
    if humanoid.Health <= 0 then return end

    -- Принудительно держим Physics
    if humanoid:GetState() ~= Enum.HumanoidStateType.Physics then
        pcall(function() humanoid:ChangeState(Enum.HumanoidStateType.Physics) end)
    end

    local grounded = isGrounded()
    local vel = rootPart.AssemblyLinearVelocity
    local flatVel = flat(vel)
    local speed = flatVel.Magnitude

    -- ---------- ЗЕМЛЯ ----------
    if grounded then
        if CONFIG.AutoBhop and jumpHeld then
            -- Прыжок: сохраняем горизонталь, задаём вертикаль
            rootPart.AssemblyLinearVelocity = Vector3.new(vel.X, CONFIG.JumpPower, vel.Z)
        end
        return
    end

    -- ---------- ВОЗДУХ: РАЗГОН ----------
    local moveDir = humanoid.MoveDirection
    if moveDir.Magnitude > 0.1 then
        local wishDir = moveDir.Unit
        local currentInWishDir = flatVel:Dot(wishDir)
        local addSpeed = CONFIG.AirCap - currentInWishDir

        if addSpeed > 0 then
            -- Source формула: ускорение пропорционально dt и ограничено addSpeed
            local accelSpeed = math.min(CONFIG.AirAccelerate * dt, addSpeed)
            local newFlat = flatVel + wishDir * accelSpeed

            -- Ограничение максимальной скорости
            if newFlat.Magnitude > CONFIG.MaxAirSpeed then
                newFlat = newFlat.Unit * CONFIG.MaxAirSpeed
            end

            rootPart.AssemblyLinearVelocity = Vector3.new(newFlat.X, vel.Y, newFlat.Z)
        end
    end

    -- ---------- ЗАЩИТА ----------
    local fv = rootPart.AssemblyLinearVelocity
    local ff = flat(fv)
    if ff.Magnitude > CONFIG.MaxTotalSpeed then
        local d = ff.Unit
        rootPart.AssemblyLinearVelocity = Vector3.new(d.X * CONFIG.MaxTotalSpeed, fv.Y, d.Z * CONFIG.MaxTotalSpeed)
    end
end)
