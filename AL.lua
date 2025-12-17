--[[
	A I M L O C K
]]
    --- Configuration ---
local aimbotEnabled = false
local aimbotToggleKey = Enum.KeyCode.X -- Toggle aimbot with 'X' key
local aimbotFOV = 50 -- Degrees
local lockAccuracy = 0.25 -- 1 = snap, lower = smoother
local aimbotMaxRange = 500 -- Studs / Maximum distance to target

    --- Services and Variables ---

local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Camera = game.Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")
local function rainbowColor(obj)
    local hue = 0
    RunService.Heartbeat:Connect(function(dt)
	   hue = (hue + dt * 0.2) % 1
	   obj.Color = Color3.fromHSV(hue, 1, 1)
    end)
end

local FOVCircle = Drawing.new("Circle")
FOVCircle.Color = Color3.fromRGB(255, 0, 0)
FOVCircle.Thickness = 2
FOVCircle.NumSides = 32
FOVCircle.Radius = aimbotFOV / 2
FOVCircle.Visible = false
rainbowColor(FOVCircle)
local SnapLine = Drawing.new("Line")
SnapLine.Color = Color3.fromRGB(255, 0, 0)
SnapLine.Thickness = 2
SnapLine.Visible = false
rainbowColor(SnapLine)
local HeadDot = Drawing.new("Circle")
HeadDot.Color = Color3.fromRGB(255, 0, 0)
HeadDot.Thickness = 2
HeadDot.NumSides = 32
HeadDot.Radius = 5
HeadDot.Visible = false
rainbowColor(HeadDot)
local DistanceLabels = {}
    --- Functions ---

local function updateDistanceLabel(player, distance)
    if not DistanceLabels[player] then
        DistanceLabels[player] = Drawing.new("Text")
        DistanceLabels[player].Color = Color3.fromRGB(255, 255, 255)
        DistanceLabels[player].Size = 18
        DistanceLabels[player].Outline = true
        DistanceLabels[player].Center = true
    end
    
    local head = player.Character.Head
    local screenPoint, onScreen = Camera:WorldToViewportPoint(head.Position)
    if onScreen then
        DistanceLabels[player].Position = Vector2.new(screenPoint.X, screenPoint.Y - 40)
        DistanceLabels[player].Text = string.format("%.1f", distance) .. " studs"
        DistanceLabels[player].Transparency = 0.5
        DistanceLabels[player].Visible = true
    else
        DistanceLabels[player].Visible = false
    end
end

local function updateFOVCircle()
    local viewportSize = Camera.ViewportSize
    FOVCircle.Position = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    FOVCircle.Radius = aimbotFOV / 2
end

local function updateSnapLine(targetPosition)
    local viewportSize = Camera.ViewportSize
    SnapLine.From = Vector2.new(viewportSize.X / 2, viewportSize.Y / 2)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPosition)
    SnapLine.To = Vector2.new(screenPoint.X, screenPoint.Y)
    SnapLine.Visible = true
end

local function updateHeadDot(targetPosition)
    local screenPoint, onScreen = Camera:WorldToViewportPoint(targetPosition)
    HeadDot.Position = Vector2.new(screenPoint.X, screenPoint.Y)
    HeadDot.Visible = true
end

local function isTargetVisible(targetPart)
     -- Todo: Implement raycasting to check for visibility
    return true
end

local function getClosestPlayer()
    if not LocalPlayer.Character or not LocalPlayer.Character:FindFirstChild("HumanoidRootPart") then
        return nil, math.huge
    end

    local closestPlayer = nil
    local closestDistance = math.huge
    local screenCenter = Camera.ViewportSize / 2

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild("Head")
            and player.Character:FindFirstChild("HumanoidRootPart") then

            local head = player.Character.Head
            local root = player.Character.HumanoidRootPart

            local worldDistance = (root.Position - LocalPlayer.Character.HumanoidRootPart.Position).Magnitude
            if worldDistance > aimbotMaxRange then
                continue
            end

            local screenPos, onScreen = Camera:WorldToViewportPoint(head.Position)
            if not onScreen then
                continue
            end

            local screenDistance =
                (Vector2.new(screenPos.X, screenPos.Y) - screenCenter).Magnitude

            if screenDistance <= aimbotFOV / 2 and worldDistance < closestDistance then
                closestDistance = worldDistance
                closestPlayer = player
            end
        end
    end

    return closestPlayer, closestDistance
end
    --- Main Loop and Input Handling ---
UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
    if not gameProcessedEvent and input.KeyCode == aimbotToggleKey then
        aimbotEnabled = not aimbotEnabled
        FOVCircle.Visible = aimbotEnabled
        SnapLine.Visible = aimbotEnabled
        HeadDot.Visible = aimbotEnabled
    end
end)

RunService.RenderStepped:Connect(function()
    updateFOVCircle()

    local closestPlayer, shortestDistance = getClosestPlayer()

    for player, label in pairs(DistanceLabels) do
        if player.Character and player.Character:FindFirstChild("Head") then
            local distance = (player.Character.Head.Position - LocalPlayer.Character.HumanoidRootPart.Position).magnitude
            updateDistanceLabel(player, distance)
        else
            label.Visible = false
        end
    end

    if aimbotEnabled and closestPlayer and closestPlayer.Character and closestPlayer.Character:FindFirstChild("Head") then
        local head = closestPlayer.Character.Head
        updateSnapLine(head.Position)
        updateHeadDot(head.Position)
        local targetCFrame = CFrame.new(Camera.CFrame.Position, head.Position)
        Camera.CFrame = Camera.CFrame:Lerp(targetCFrame, lockAccuracy) 
        updateDistanceLabel(closestPlayer, shortestDistance)
    else
        SnapLine.Visible = false
        HeadDot.Visible = false
    end
end)
--- END OF FILE ---

