-- Lua | Roblox Luau LocalScript | Violence District | HANX HUB (ANDROID READY)
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local LP = Players.LocalPlayer

KILLER_RANGE = 12
local PLAYER_PALLET_RANGE = 8
local KILLER_PALLET_RANGE = 6
local UsedPallets = setmetatable({}, { __mode = "k" })

pcall(function()
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.PlayerList, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Captures, false)
StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Health, false)
end)

-- ============================================================
-- LOGIKA ESP HANX HUB
-- ============================================================
local ESP = { Master = false, Player = false, Killer = false, Name = false, Distance = false, Outline = false, ItemIcon = false, Status = false, HookCount = false, KillerWarn = false, MaxDistance = 1000, Generator = false, GeneratorName = true, Pallet = false, Hook = false, Gate = false, Window = false, SCP = false }
local ESPColors = { Player = Color3.fromRGB(60, 255, 60), Killer = Color3.fromRGB(255, 60, 60), Generator = Color3.fromRGB(255, 255, 0), GeneratorDone = Color3.fromRGB(0, 255, 0), Pallet = Color3.fromRGB(60, 255, 255), Hook = Color3.fromRGB(255, 105, 180), Gate = Color3.fromRGB(255, 255, 255), Window = Color3.fromRGB(60, 255, 255), SCP = Color3.fromRGB(255, 0, 255) }
local MapData = { Generators = {}, Windows = {}, Pallets = {}, Hooks = {}, Gates = {}, SCPs = {} }
local espConn = nil
local scanCooldown = 0

local function getDistance(pos)
local hrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
return hrp and (pos - hrp.Position).Magnitude or math.huge
end

local function ScanMap(force)
if not force and tick() - scanCooldown < 2 then return end
scanCooldown = tick()
table.clear(MapData.Generators); table.clear(MapData.Windows); table.clear(MapData.Pallets)
table.clear(MapData.Hooks); table.clear(MapData.Gates); table.clear(MapData.SCPs)
local map = workspace:FindFirstChild("Map") or workspace
for i, desc in ipairs(map:GetDescendants()) do
if i % 200 == 0 then task.wait() end
if desc:IsA("Model") then
local n = string.lower(desc.Name)
if n == "generator" then
local body = desc:FindFirstChild("GeneratorBody") or desc:FindFirstChildWhichIsA("BasePart")
if body then table.insert(MapData.Generators, {model = desc, part = body}) end
elseif n == "hook" and desc:FindFirstChild("HookPoint") then table.insert(MapData.Hooks, desc)
elseif n == "gate" and desc:FindFirstChild("ExitLever") then table.insert(MapData.Gates, desc)
elseif n == "window" then table.insert(MapData.Windows, desc) end
elseif desc:IsA("BasePart") and desc.Name == "PrimaryPartPallet" then
if desc.Parent and not table.find(MapData.Pallets, desc.Parent) then table.insert(MapData.Pallets, desc.Parent) end
end
end
end

local function CreateESP(parent, typeName, options)
if not parent then return end
local name, info, color, offsetY = options.name or "", options.infoRich or "", options.color or Color3.new(1,1,1), options.offsetY or 4
local billboard = parent:FindFirstChild(typeName)
if not billboard then
billboard = Instance.new("BillboardGui")
billboard.Name = typeName; billboard.AlwaysOnTop = true; billboard.Size = UDim2.new(0, 220, 0, 34)
billboard.StudsOffset = Vector3.new(0, offsetY, 0); billboard.Parent = parent
local box = Instance.new("Frame"); box.Name = "Box"; box.BackgroundTransparency = 1; box.Size = UDim2.new(1, 0, 1, 0); box.Parent = billboard
local row1 = Instance.new("Frame"); row1.Name = "Row1"; row1.BackgroundTransparency = 1; row1.Size = UDim2.new(0, 0, 0, 16); row1.AutomaticSize = Enum.AutomaticSize.XY; row1.Parent = box
local layout1 = Instance.new("UIListLayout", row1); layout1.FillDirection = Enum.FillDirection.Horizontal; layout1.HorizontalAlignment = Enum.HorizontalAlignment.Center
local nameLbl = Instance.new("TextLabel"); nameLbl.Name = "Name"; nameLbl.BackgroundTransparency = 1; nameLbl.AutomaticSize = Enum.AutomaticSize.XY; nameLbl.Font = Enum.Font.GothamBold; nameLbl.TextSize = 12; nameLbl.TextStrokeTransparency = 0; nameLbl.Parent = row1
local infoLbl = Instance.new("TextLabel"); infoLbl.Name = "Info"; infoLbl.BackgroundTransparency = 1; infoLbl.AutomaticSize = Enum.AutomaticSize.XY; infoLbl.Font = Enum.Font.GothamBold; infoLbl.TextSize = 11; infoLbl.RichText = true; infoLbl.TextStrokeTransparency = 0; infoLbl.Parent = box
end
local box = billboard:FindFirstChild("Box"); if not box then return end
local row1 = box:FindFirstChild("Row1")
local nameLbl = row1 and row1:FindFirstChild("Name")
local infoLbl = box:FindFirstChild("Info")
if nameLbl then nameLbl.Text = name; nameLbl.TextColor3 = color end
if infoLbl then infoLbl.Text = info; infoLbl.Visible = info ~= "" end
end

local function ClearAllESP()
for _, plr in ipairs(Players:GetPlayers()) do
if plr.Character then
for _, name in ipairs({"PEH", "PE_Text", "KEH", "KE_Text"}) do
local obj = plr.Character:FindFirstChild(name); if obj then obj:Destroy() end
end
end
end
for _, obj in ipairs(workspace:GetDescendants()) do
if obj.Name == "GEH" or obj.Name == "GE_Text" or obj.Name == "PalletEH" or obj.Name == "HookEH" or obj.Name == "GateEH" or obj.Name == "WindowEH" or obj.Name == "SCPEH" then
if obj.Parent then obj:Destroy() end
end
end
end

local function updatePlayerESP()
if not ESP.Master then return end
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LP and plr.Character then
local isKiller = plr.Team and plr.Team.Name == "Killer"
local shouldRender = isKiller and ESP.Killer or not isKiller and ESP.Player
local hrp = plr.Character:FindFirstChild("HumanoidRootPart")
if not hrp or getDistance(hrp.Position) > ESP.MaxDistance then shouldRender = false end
local hlName = isKiller and "KEH" or "PEH"
local textName = isKiller and "KE_Text" or "PE_Text"
if shouldRender then
local hl = plr.Character:FindFirstChild(hlName)
if not hl then hl = Instance.new("Highlight"); hl.Name = hlName; hl.Parent = plr.Character end
local c = isKiller and ESPColors.Killer or ESPColors.Player
hl.FillColor = c; hl.OutlineColor = c; hl.FillTransparency = ESP.Outline and 1 or 0.5; hl.OutlineTransparency = 0
local nText = ESP.Name and plr.Name or ""
local infoParts = {}
if ESP.Distance and hrp then table.insert(infoParts, string.format("%dm", math.floor(getDistance(hrp.Position)))) end
CreateESP(plr.Character, textName, { name = nText, infoRich = table.concat(infoParts, " · "), color = c, offsetY = 4 })
else
for _, objName in ipairs({hlName, textName}) do local obj = plr.Character:FindFirstChild(objName); if obj then obj:Destroy() end end
end
end
end
end

local function updateStaticESP()
if not ESP.Master then return end
if ESP.Generator then
for _, gen in ipairs(MapData.Generators) do
if gen.model and gen.model.Parent then
local prog = gen.model:GetAttribute("RepairProgress") or 0
local pct = math.clamp(math.floor(prog), 0, 100)
local c = ESPColors.Generator:Lerp(ESPColors.GeneratorDone, pct/100)
local hl = gen.model:FindFirstChild("GEH")
if not hl then hl = Instance.new("Highlight"); hl.Name = "GEH"; hl.Parent = gen.model end
hl.FillColor = c; hl.OutlineColor = c; hl.FillTransparency = ESP.Outline and 1 or 0.5; hl.OutlineTransparency = 0
if ESP.GeneratorName and gen.part then
local txt = pct >= 100 and "DONE" or string.format("%d%%", pct)
CreateESP(gen.part, "GE_Text", { name = "GEN", infoRich = string.format("<font color='#FF8000'>%s</font>", txt), color = ESPColors.Generator, offsetY = gen.part.Size.Y/2 + 1 })
end
end
end
end
end

local function startESPLoop()
if espConn then espConn:Disconnect() end
espConn = RunService.Heartbeat:Connect(function()
updatePlayerESP()
updateStaticESP()
end)
end

-- ============================================================
-- LOGIKA AUTO AIM PISTOL
-- ============================================================
local PistolConfig = { Enabled = false, Laser = true, WallCheck = false, TargetMode = "Killer", LaserBeam = nil, IsAiming = false, TouchInput = nil }
local function pistolIsKiller(p) return p and p.Team and p.Team.Name == "Killer" end
local function pistolIsSurvivor(p) return p and p.Team and p.Team.Name == "Survivors" end
local function pistolGetEvent() local remotes = ReplicatedStorage:FindFirstChild("Remotes"); local items = remotes and remotes:FindFirstChild("Items"); local tof = items and items:FindFirstChild("Twist of Fate"); return tof and tof:FindFirstChild("Fire") end
local function pistolGetGunObject()
    local char = LP.Character
    if not char then return nil end
    local base = char:FindFirstChild("Twist of Fate", true)
    if not base then return nil end
    local rightArm = base:FindFirstChild("Right Arm", true)
    if rightArm then
        local gunPart = rightArm:FindFirstChild("gun", true) or rightArm:FindFirstChild("EmperorGun", true)
        if gunPart then return gunPart end
    end
    return base
end
local function pistolGetOrigin(gunObj)
    if not gunObj then return nil end
    local muzzleNames = { "muzzle", "muzzleattachment", "firepoint", "barrelend", "barrel" }
    for _, obj in ipairs(gunObj:GetDescendants()) do
        local n = string.lower(obj.Name):gsub("[%s_%-]", "")
        if obj:IsA("Attachment") then
            for _, wanted in ipairs(muzzleNames) do
                if n == wanted then return obj.WorldPosition end
            end
        elseif obj:IsA("BasePart") then
            for _, wanted in ipairs(muzzleNames) do
                if n == wanted then return obj.Position end
            end
        end
    end
    if gunObj:IsA("BasePart") then return gunObj.Position end
    local part = gunObj:FindFirstChildWhichIsA("BasePart", true)
    return part and part.Position or nil
end
local function pistolIsVisible(originPos, targetPos, targetChar)
local dir = targetPos - originPos; local dist = dir.Magnitude; if dist < 0.1 then return true end
local params = RaycastParams.new(); params.FilterType = Enum.RaycastFilterType.Exclude
local ex = {}; if LP.Character then table.insert(ex, LP.Character) end; if targetChar then table.insert(ex, targetChar) end; if PistolConfig.LaserBeam then table.insert(ex, PistolConfig.LaserBeam) end
params.FilterDescendantsInstances = ex
return workspace:Raycast(originPos, dir.Unit * dist, params) == nil
end
local function pistolGetTargetPos()
local gunObj = pistolGetGunObject(); local char = LP.Character; if not gunObj or not char then return nil, nil end
local hrp = char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil, nil end
local myPos = hrp.Position
local originPos
pcall(function() originPos = pistolGetOrigin(gunObj) end)
if not originPos then
    local arm = char:FindFirstChild("RightHand") or char:FindFirstChild("Right Arm")
    originPos = arm and arm.Position or (myPos + Vector3.new(0, 1.5, 0))
end
local function pick(torso, targetChar) local targetPos = torso.Position; if PistolConfig.WallCheck and not pistolIsVisible(originPos, targetPos, targetChar) then return nil, nil end; return originPos, targetPos end
if PistolConfig.TargetMode == "Killer" then
local closest, closestChar, shortDist = nil, nil, math.huge
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LP and pistolIsKiller(plr) and plr.Character then
local hum = plr.Character:FindFirstChildOfClass("Humanoid")
local torso = plr.Character:FindFirstChild("UpperTorso") or plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("HumanoidRootPart")
if hum and hum.Health > 0 and torso then
    local d = (myPos - torso.Position).Magnitude
    if d < shortDist then shortDist = d; closest = torso; closestChar = plr.Character end
end
end
end
if not closest then return nil, nil end
return pick(closest, closestChar)
else
local cam = workspace.CurrentCamera; local camLook = cam.CFrame.LookVector; local best, bestChar, bestDot = nil, nil, -math.huge
for _, plr in ipairs(Players:GetPlayers()) do
if plr ~= LP and pistolIsSurvivor(plr) and plr.Character then
local hum = plr.Character:FindFirstChildOfClass("Humanoid")
local torso = plr.Character:FindFirstChild("UpperTorso") or plr.Character:FindFirstChild("Torso") or plr.Character:FindFirstChild("HumanoidRootPart")
if hum and hum.Health > 0 and torso then
local dir = torso.Position - cam.CFrame.Position
if dir.Magnitude > 0.1 then local dot = camLook:Dot(dir.Unit); if dot > 0.5 and dot > bestDot then bestDot = dot; best = torso; bestChar = plr.Character end end
end
end
end
if not best then return nil, nil end
return pick(best, bestChar)
end
end
local function pistolUpdateLaser(originPos, targetPos)
if not PistolConfig.LaserBeam then
local laser = Instance.new("Part"); laser.Name = "HANX_PistolLaser"; laser.Anchored = true; laser.CanCollide = false; laser.CanTouch = false; laser.CastShadow = false; laser.Material = Enum.Material.Neon; laser.Color = Color3.fromRGB(255, 105, 180); laser.Parent = workspace; PistolConfig.LaserBeam = laser
end
local dist = (targetPos - originPos).Magnitude; PistolConfig.LaserBeam.Size = Vector3.new(0.05, 0.05, dist); PistolConfig.LaserBeam.CFrame = CFrame.new((originPos + targetPos) / 2, targetPos); PistolConfig.LaserBeam.Transparency = 0
end
local function pistolDoShoot()
if not PistolConfig.Enabled then return end
local originPos, targetPos = pistolGetTargetPos(); if not originPos or not targetPos then return end
local ev = pistolGetEvent(); local gunObj = pistolGetGunObject(); if not ev or not gunObj then return end
local dir = targetPos - originPos; if dir.Magnitude < 0.1 then return end
pcall(function() ev:FireServer(gunObj, dir.Unit) end)
end
local function pistolGetMobileBtn() local m = LP.PlayerGui:FindFirstChild("Survivor-mob"); local ctrl = m and m:FindFirstChild("Controls"); return ctrl and ctrl:FindFirstChild("Gui-mob") end
local function pistolTouchOnBtn(input) local b = pistolGetMobileBtn(); if not b or not b.Visible then return false end; local pos, ap, sz = input.Position, b.AbsolutePosition, b.AbsoluteSize; return pos.X >= ap.X and pos.X <= ap.X + sz.X and pos.Y >= ap.Y and pos.Y <= ap.Y + sz.Y end
RunService.Heartbeat:Connect(function()
if not PistolConfig.Enabled or not PistolConfig.Laser then
    if PistolConfig.LaserBeam then PistolConfig.LaserBeam.Transparency = 1 end
    return
end
local originPos, targetPos = pistolGetTargetPos()
if originPos and targetPos then
    pistolUpdateLaser(originPos, targetPos)
elseif PistolConfig.LaserBeam then
    PistolConfig.LaserBeam.Transparency = 1
end
end)
UIS.InputBegan:Connect(function(input, gp)
if gp or not PistolConfig.Enabled then return end
if input.UserInputType == Enum.UserInputType.MouseButton1 or (input.UserInputType == Enum.UserInputType.Touch and pistolTouchOnBtn(input)) then PistolConfig.IsAiming = true; if input.UserInputType == Enum.UserInputType.Touch then PistolConfig.TouchInput = input end; pistolDoShoot() end
end)
UIS.InputEnded:Connect(function(input)
if input.UserInputType == Enum.UserInputType.MouseButton1 or input == PistolConfig.TouchInput then PistolConfig.IsAiming = false; if input == PistolConfig.TouchInput then PistolConfig.TouchInput = nil end; if PistolConfig.LaserBeam then PistolConfig.LaserBeam.Transparency = 1 end end
end)

-- ============================================================
-- LOGIKA AUTO AIM VEIL
-- ============================================================
local VeilConfig = {
    Enabled = false, ShowLaser = true, FOV = 150, SpearSpeed = 165,
    Gravity = workspace.Gravity * 0.5, MaxDist = 200, AutoPredict = false,
    TargetPart = "Torso", chargingSpear = false, touchInput = nil,
    attackCooldown = false, LaserBeam = nil, velocityCache = {},
    LockedTarget = nil, LockedTargetUntil = 0
}

local function veilGetTargetPart(char)
    if not char then return nil end
    if VeilConfig.TargetPart == "Head" then return char:FindFirstChild("Head") end
    if VeilConfig.TargetPart == "Root" then return char:FindFirstChild("HumanoidRootPart") end
    return char:FindFirstChild("Torso") or char:FindFirstChild("UpperTorso") or char:FindFirstChild("HumanoidRootPart")
end

local function veilIsValidTarget(player, character, part)
    if not player or player == LP or player.Parent ~= Players then return false end
    if not player.Team or player.Team.Name ~= "Survivors" then return false end
    if not character or player.Character ~= character or not character:IsDescendantOf(workspace) then return false end
    local hum = character:FindFirstChildOfClass("Humanoid")
    if not hum or hum.Health <= 0 then return false end
    if not part or not part:IsA("BasePart") or not part:IsDescendantOf(character) then return false end
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    return myRoot ~= nil and (part.Position - myRoot.Position).Magnitude <= VeilConfig.MaxDist
end

local function veilGetVelocity(part, player)
    if not part or not player then return Vector3.zero end
    local pos, now = part.Position, os.clock()
    local cache = VeilConfig.velocityCache[player]
    if not cache or cache.character ~= player.Character or cache.part ~= part then
        VeilConfig.velocityCache[player] = {
            character = player.Character, part = part, lastPos = pos,
            lastTime = now, velocity = Vector3.zero
        }
        return Vector3.zero
    end
    local dt = now - cache.lastTime
    if dt >= 1 / 120 and dt <= 0.25 then
        local raw = (pos - cache.lastPos) / dt
        if raw.Magnitude <= 90 then cache.velocity = cache.velocity:Lerp(raw, 0.55) end
    else
        cache.velocity = Vector3.zero
    end
    cache.lastPos, cache.lastTime = pos, now
    return cache.velocity
end

local function veilGetClosestSurvivor()
    local myRoot = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
    local cam = workspace.CurrentCamera
    if not myRoot or not cam then return nil end
    local center = Vector2.new(cam.ViewportSize.X / 2, cam.ViewportSize.Y / 2)
    local now = os.clock()

    local locked = VeilConfig.LockedTarget
    if locked and now < VeilConfig.LockedTargetUntil then
        local player = locked.Player
        local character = player and player.Character
        local part = character and veilGetTargetPart(character)
        if veilIsValidTarget(player, character, part) then
            local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
            local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
            if onScreen and screenDistance <= VeilConfig.FOV * 1.25 then
                locked.Character, locked.Part = character, part
                return locked
            end
        end
        VeilConfig.LockedTarget = nil
    end

    local bestDist, bestTarget = VeilConfig.FOV, nil
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Team and player.Team.Name == "Survivors" and player.Character then
            local character = player.Character
            local part = veilGetTargetPart(character)
            if veilIsValidTarget(player, character, part) then
                local screenPos, onScreen = cam:WorldToViewportPoint(part.Position)
                if onScreen then
                    local screenDistance = (Vector2.new(screenPos.X, screenPos.Y) - center).Magnitude
                    if screenDistance < bestDist then
                        bestDist = screenDistance
                        bestTarget = { Player = player, Character = character, Part = part }
                    end
                end
            end
        end
    end
    VeilConfig.LockedTarget = bestTarget
    VeilConfig.LockedTargetUntil = bestTarget and (now + 0.35) or 0
    return bestTarget
end

local function veilGetAimPoint(startPos, targetInfo)
    if not targetInfo or not veilIsValidTarget(targetInfo.Player, targetInfo.Character, targetInfo.Part) then return nil end
    local part = targetInfo.Part
    local targetPos = part.Position
    local velocity = VeilConfig.AutoPredict and veilGetVelocity(part, targetInfo.Player) or Vector3.zero
    local speed = math.max(VeilConfig.SpearSpeed, 1)
    local flightTime = (targetPos - startPos).Magnitude / speed
    for _ = 1, 3 do
        local predicted = targetPos + velocity * flightTime
        flightTime = (predicted - startPos).Magnitude / speed
    end
    local predictedPos = targetPos + velocity * flightTime
    local gravity = math.max(0, VeilConfig.Gravity)
    return predictedPos + Vector3.new(0, 0.5 * gravity * flightTime * flightTime, 0)
end

local function veilFire()
    if not VeilConfig.Enabled or VeilConfig.attackCooldown then return end
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    if not myHum or myHum.Health <= 0 or myChar:GetAttribute("spearmode") ~= true then return end
    local startPart = myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart")
    if not startPart then return end

    local startPos = startPart.Position
    local targetInfo = veilGetClosestSurvivor()
    local aimPoint = veilGetAimPoint(startPos, targetInfo)
    if not aimPoint then return end
    local delta = aimPoint - startPos
    if delta.Magnitude < 0.1 then return end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local killers = remotes and remotes:FindFirstChild("Killers")
    local veil = killers and killers:FindFirstChild("Veil")
    local fireRemote = veil and veil:FindFirstChild("Spearthrow")
    if not fireRemote or not (fireRemote:IsA("RemoteEvent") or fireRemote:IsA("UnreliableRemoteEvent")) then return end

    local fired = pcall(function()
        fireRemote:FireServer(delta.Unit, VeilConfig.SpearSpeed, startPos)
    end)
    if fired then
        VeilConfig.attackCooldown = true
        task.delay(2, function() VeilConfig.attackCooldown = false end)
    end
end

UIS.InputBegan:Connect(function(input, gp)
    local isTouch = input.UserInputType == Enum.UserInputType.Touch
    if gp and not isTouch then return end
    local char = LP.Character
    if not VeilConfig.Enabled or not char or char:GetAttribute("spearmode") ~= true then return end

    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        VeilConfig.chargingSpear = true
    elseif isTouch then
        local pg = LP:FindFirstChildOfClass("PlayerGui")
        local mobile = pg and pg:FindFirstChild("Slasher-mob")
        local controls = mobile and mobile:FindFirstChild("Controls")
        local attackButton = controls and controls:FindFirstChild("attack")
        if attackButton and attackButton.Visible then
            local pos, ap, size = input.Position, attackButton.AbsolutePosition, attackButton.AbsoluteSize
            if pos.X >= ap.X and pos.X <= ap.X + size.X and pos.Y >= ap.Y and pos.Y <= ap.Y + size.Y then
                VeilConfig.chargingSpear = true
                VeilConfig.touchInput = input
            end
        end
    end
end)

UIS.InputEnded:Connect(function(input)
    if VeilConfig.chargingSpear
        and (input == VeilConfig.touchInput or input.UserInputType == Enum.UserInputType.MouseButton1) then
        VeilConfig.chargingSpear = false
        if VeilConfig.touchInput == input then VeilConfig.touchInput = nil end
        veilFire()
    end
end)

RunService.RenderStepped:Connect(function()
    local myChar = LP.Character
    local isSpearMode = myChar and myChar:GetAttribute("spearmode") == true
    if not (VeilConfig.chargingSpear and VeilConfig.Enabled and isSpearMode and VeilConfig.ShowLaser) then
        if VeilConfig.LaserBeam then VeilConfig.LaserBeam.Transparency = 1 end
        return
    end

    local target = veilGetClosestSurvivor()
    if not target then
        if VeilConfig.LaserBeam then VeilConfig.LaserBeam.Transparency = 1 end
        return
    end

    if not VeilConfig.LaserBeam then
        local laser = Instance.new("Part")
        laser.Name = "HANX_VeilLaser"
        laser.Anchored = true
        laser.CanCollide = false
        laser.CanTouch = false
        laser.CanQuery = false
        laser.CastShadow = false
        laser.Material = Enum.Material.Neon
        laser.Color = Color3.fromRGB(255, 160, 215)
        laser.Parent = workspace
        VeilConfig.LaserBeam = laser
    end

    local originPart = myChar:FindFirstChild("Head") or myChar:FindFirstChild("HumanoidRootPart")
    local aimPoint = originPart and veilGetAimPoint(originPart.Position, target)
    if aimPoint then
        local originPos = originPart.Position
        local dist = (aimPoint - originPos).Magnitude
        if dist > 0.1 then
            VeilConfig.LaserBeam.Size = Vector3.new(0.16, 0.16, dist)
            VeilConfig.LaserBeam.CFrame = CFrame.new((originPos + aimPoint) / 2, aimPoint)
            VeilConfig.LaserBeam.Transparency = 0.3
        end
    else
        VeilConfig.LaserBeam.Transparency = 1
    end
end)

-- MIMIW AUTO PARRY (ANIMATION-DRIVEN)
-- ============================================================
local AutoParryConfig = { Enabled = false, Range = 18, Delay = 0.08, Cooldown = 0.45, KeyIndex = 1, KillerOnly = true, Facing = true }
local AutoParryKeys = {
    {"F", Enum.KeyCode.F}, {"Q", Enum.KeyCode.Q},
    {"E", Enum.KeyCode.E}, {"R", Enum.KeyCode.R}
}

local ParryAttackAnims = {
    ["rbxassetid://122812055447896"] = true, -- Veil lunge
    ["rbxassetid://133963973694098"] = true, -- Mayers Basic
    ["rbxassetid://117042998468241"] = true, -- Mayers lunge
    ["rbxassetid://135002183282873"] = true, -- Cure lunge
    ["rbxassetid://121216847022485"] = true, -- Cure Basic
    ["rbxassetid://132817836308238"] = true, -- Jeff Basic
    ["rbxassetid://129784271201071"] = true, -- Jeff lunge
    ["rbxassetid://82666958311998"] = true, -- Jeff Frenzy
    ["rbxassetid://78432063483146"] = true, -- Abyssal Basic
    ["rbxassetid://118907603246885"] = true, -- Abyssal lunge
    ["rbxassetid://139369275981139"] = true, -- Jason Basic
    ["rbxassetid://110355011987939"] = true, -- Jason lunge
    ["rbxassetid://111920872708571"] = true, -- Masked Basic
    ["rbxassetid://105374834496520"] = true, -- Masked lunge
    ["rbxassetid://138720291317243"] = true, -- Masked Tony
    ["rbxassetid://106871536134254"] = true, -- Masked Alex
    ["rbxassetid://130593238885843"] = true, -- Masked Cobra
    ["rbxassetid://115244153053858"] = true, -- Masked Cobra lunge
    ["rbxassetid://74968262036854"] = true, -- Hidden Basic
    ["rbxassetid://113255068724446"] = true, -- Hidden lunge
    ["rbxassetid://98163597193511"] = true, -- Hidden S1
    ["rbxassetid://80411309607666"] = true, -- Abyssal S1
}

local tbl5 = {
    ["122812055447896"] = "Veil lunge",
    ["133963973694098"] = "Mayers Basic",
    ["117042998468241"] = "Mayers lunge",
    ["135002183282873"] = "Cure lunge",
    ["121216847022485"] = "Cure Basic",
    ["132817836308238"] = "Jeff Basic",
    ["129784271201071"] = "Jeff lunge",
    ["82666958311998"] = "Jeff Frenzy",
    ["78432063483146"] = "Abyssal Basic",
    ["118907603246885"] = "Abyssal lunge",
    ["139369275981139"] = "Jason Basic",
    ["110355011987939"] = "Jason lunge",
    ["111920872708571"] = "Masked Basic",
    ["105374834496520"] = "Masked lunge",
    ["138720291317243"] = "Masked Tony",
    ["106871536134254"] = "Masked Alex",
    ["130593238885843"] = "Masked Cobra",
    ["115244153053858"] = "Masked Cobra lunge",
    ["74968262036854"] = "Hidden Basic",
    ["113255068724446"] = "Hidden lunge",
    ["98163597193511"] = "Hidden S1",
    ["80411309607666"] = "Abyssal S1",
}

local AutoParrySeen = setmetatable({}, { __mode = "k" })
local AutoParryLast = 0
local AutoParryCount = 0
local AutoParryWasDowned = false
local AutoParryVisuals = { Gui = nil, Label = nil, RangePart = nil }

local function AutoParryPress()
    local key = AutoParryKeys[AutoParryConfig.KeyIndex]
    if not key then return false end

    local ok = pcall(function()
        VirtualInputManager:SendKeyEvent(true, key[2], false, game)
        task.wait(0.05)
        VirtualInputManager:SendKeyEvent(false, key[2], false, game)
    end)

    if not ok and keypress and keyrelease then
        local vk = string.byte(key[1])
        local fallbackOk = pcall(function()
            keypress(vk)
            task.wait(0.05)
            keyrelease(vk)
        end)
        ok = fallbackOk
    end

    if ok then AutoParryCount += 1 end
    return ok
end

local function AutoParryCreateVisuals()
    local playerGui = LP:FindFirstChildOfClass("PlayerGui")
    if not playerGui then return end

    local gui = playerGui:FindFirstChild("HANX_AutoParryStatus")
    if not gui then
        gui = Instance.new("ScreenGui")
        gui.Name = "HANX_AutoParryStatus"
        gui.ResetOnSpawn = false
        gui.IgnoreGuiInset = true
        gui.Parent = playerGui

        local label = Instance.new("TextLabel")
        label.Name = "Cooldown"
        label.AnchorPoint = Vector2.new(1, 0)
        label.Position = UDim2.new(1, -16, 0, 72)
        label.Size = UDim2.new(0, 150, 0, 25)
        label.BackgroundColor3 = Color3.fromRGB(15, 18, 24)
        label.BackgroundTransparency = 0.25
        label.BorderSizePixel = 0
        label.Font = Enum.Font.GothamSemibold
        label.TextSize = 12
        label.TextColor3 = Color3.fromRGB(120, 255, 170)
        label.TextStrokeTransparency = 0.75
        label.Text = "PARRY READY"
        label.Parent = gui

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 6)
        corner.Parent = label
    end

    AutoParryVisuals.Gui = gui
    AutoParryVisuals.Label = gui:FindFirstChild("Cooldown")
end

local function AutoParryUpdateVisuals(root)
    if not AutoParryConfig.Enabled then
        if AutoParryVisuals.Gui then AutoParryVisuals.Gui.Enabled = false end
        if AutoParryVisuals.RangePart then AutoParryVisuals.RangePart.Transparency = 1 end
        return
    end

    AutoParryCreateVisuals()
    if AutoParryVisuals.Gui then AutoParryVisuals.Gui.Enabled = true end

    local remaining = math.max(0, AutoParryConfig.Cooldown - (os.clock() - AutoParryLast))
    if AutoParryVisuals.Label then
        if remaining > 0 then
            AutoParryVisuals.Label.Text = string.format("PARRY %.1fs", remaining)
            AutoParryVisuals.Label.TextColor3 = Color3.fromRGB(255, 205, 105)
        else
            AutoParryVisuals.Label.Text = "PARRY READY"
            AutoParryVisuals.Label.TextColor3 = Color3.fromRGB(120, 255, 170)
        end
    end

    if root and root.Parent then
        if not AutoParryVisuals.RangePart then
            local ring = Instance.new("Part")
            ring.Name = "HANX_AutoParryRange"
            ring.Shape = Enum.PartType.Cylinder
            ring.Anchored = true
            ring.CanCollide = false
            ring.CanTouch = false
            ring.CanQuery = false
            ring.CastShadow = false
            ring.Material = Enum.Material.Neon
            ring.Color = Color3.fromRGB(80, 190, 255)
            ring.Transparency = 0.82
            ring.Parent = workspace
            AutoParryVisuals.RangePart = ring
        end

        local ring = AutoParryVisuals.RangePart
        ring.Size = Vector3.new(0.06, AutoParryConfig.Range * 2, AutoParryConfig.Range * 2)
        ring.CFrame = root.CFrame * CFrame.new(0, -2.8, 0) * CFrame.Angles(0, 0, math.rad(90))
        ring.Transparency = 0.82
    elseif AutoParryVisuals.RangePart then
        AutoParryVisuals.RangePart.Transparency = 1
    end
end

local function AutoParryIsDowned(char, hum)
    if not char or not hum or hum.Health <= 0 or hum.PlatformStand then return true end

    for name, value in pairs(char:GetAttributes()) do
        local n = string.lower(tostring(name))
        if (n:find("knock") or n:find("downed") or n:find("carried")
            or n:find("carry") or n:find("grab") or n:find("hooked")
            or n:find("incap")) and value == true then
            return true
        end
    end

    for _, obj in ipairs(char:GetDescendants()) do
        if obj:IsA("BoolValue") and obj.Value then
            local n = string.lower(obj.Name)
            if n:find("knock") or n:find("downed") or n:find("carried")
                or n:find("carry") or n:find("grab") or n:find("hooked")
                or n:find("incap") then
                return true
            end
        end
    end
    return false
end

local function AutoParryAnimationId(track)
    local animation = track and track.Animation
    if not animation then return nil end
    local id = tostring(animation.AnimationId or "")
    local digits = id:match("(%d+)")
    return digits and ("rbxassetid://" .. digits) or nil
end

local function AutoParryIsAttack(track)
    if not track or not track.IsPlaying or track.Looped or not track.Animation then return false end
    local animationId = AutoParryAnimationId(track)
    if not animationId or not ParryAttackAnims[animationId] then return false end

    if track.Length > 0 then
        local activeWindow = math.min(0.65, math.max(0.2, track.Length * 0.45))
        if track.TimePosition > activeWindow then return false end
    elseif track.TimePosition > 0.35 then
        return false
    end

    return track.WeightCurrent >= 0.2
end

local function AutoParryGoodTarget(player)
    if not AutoParryConfig.KillerOnly then return true end
    local teamName = player.Team and player.Team.Name:lower() or ""
    if not teamName:find("killer", 1, true) then return false end
    if player.Team and LP.Team and player.Team == LP.Team then return false end
    return true
end

RunService.Heartbeat:Connect(function()
    local myChar = LP.Character
    local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
    local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")

    AutoParryUpdateVisuals(myRoot)
    if not AutoParryConfig.Enabled then return end

    if AutoParryIsDowned(myChar, myHum) then
        AutoParryWasDowned = true
        table.clear(AutoParrySeen)
        return
    elseif AutoParryWasDowned then
        table.clear(AutoParrySeen)
        AutoParryWasDowned = false
        AutoParryLast = 0
    end
    if not myRoot then return end

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Character and AutoParryGoodTarget(player) then
            local targetChar = player.Character
            local targetRoot = targetChar:FindFirstChild("HumanoidRootPart")
            local targetHum = targetChar:FindFirstChildOfClass("Humanoid")
            local animator = targetHum and targetHum:FindFirstChildOfClass("Animator")

            if targetRoot and targetHum and targetHum.Health > 0 and animator then
                local offset = myRoot.Position - targetRoot.Position
                local distance = offset.Magnitude

                if distance <= AutoParryConfig.Range and distance > 0.1 then
                    local flatOffset = Vector3.new(offset.X, 0, offset.Z)
                    local facingDot = -1
                    if flatOffset.Magnitude > 0.1 then
                        facingDot = targetRoot.CFrame.LookVector:Dot(flatOffset.Unit)
                    end

                    if not AutoParryConfig.Facing or facingDot >= 0.2 then
                        for _, track in ipairs(animator:GetPlayingAnimationTracks()) do
                            if not AutoParrySeen[track] and AutoParryIsAttack(track)
                                and os.clock() - AutoParryLast >= AutoParryConfig.Cooldown then

                                AutoParrySeen[track] = true
                                AutoParryLast = os.clock()
                                local capturedChar = myChar
                                local capturedTarget = targetChar

                                task.delay(AutoParryConfig.Delay, function()
                                    local currentChar = LP.Character
                                    local currentHum = currentChar and currentChar:FindFirstChildOfClass("Humanoid")
                                    local currentRoot = currentChar and currentChar:FindFirstChild("HumanoidRootPart")
                                    local liveTargetRoot = capturedTarget and capturedTarget:FindFirstChild("HumanoidRootPart")
                                    local stillInRange = currentRoot and liveTargetRoot
                                        and (currentRoot.Position - liveTargetRoot.Position).Magnitude <= AutoParryConfig.Range

                                    if AutoParryConfig.Enabled and currentChar == capturedChar
                                        and not AutoParryIsDowned(currentChar, currentHum)
                                        and capturedTarget and capturedTarget.Parent
                                        and stillInRange then
                                        AutoParryPress()
                                    end
                                end)
                                break
                            end
                        end
                    end
                end
            end
        end
    end
end)

-- FIXED SKILL CHECK (VISUAL UI ONLY)
-- ============================================================
local SkillCheckState = { Enabled = false, Mode = "Legit", Busy = false, RandomMode_IsNormal = false, HeartbeatConn = nil }

local function SK_FindButton()
    local pg = LP:FindFirstChild("PlayerGui"); if not pg then return nil end
    local sm = pg:FindFirstChild("Survivor-mob"); if not sm then return nil end
    local ctrl = sm:FindFirstChild("Controls"); if not ctrl then return nil end
    local act = ctrl:FindFirstChild("action"); local chk = act or ctrl:FindFirstChild("check"); return chk
end

local function SK_Trigger()
    local btn = SK_FindButton()
    if btn and btn:IsA("GuiObject") and btn.Visible and btn.Parent then
        pcall(function()
            if firesignal then firesignal(btn.MouseButton1Down); task.wait(0.005); firesignal(btn.MouseButton1Up)
            else local ap, sz = btn.AbsolutePosition, btn.AbsoluteSize; local gi = game:GetService("GuiService"):GetGuiInset(); local id = 8822 + math.random(1, 9999); VirtualInputManager:SendTouchEvent(id, 0, ap.X + sz.X/2 + gi.X, ap.Y + sz.Y/2 + gi.Y); task.wait(0.005); VirtualInputManager:SendTouchEvent(id, 2, ap.X + sz.X/2 + gi.X, ap.Y + sz.Y/2 + gi.Y) end
        end); return true
    end
    pcall(function() VirtualInputManager:SendKeyEvent(true, Enum.KeyCode.Space, false, game); task.wait(0.005); VirtualInputManager:SendKeyEvent(false, Enum.KeyCode.Space, false, game) end); return true
end

local function SK_Watch()
    if SkillCheckState.HeartbeatConn then SkillCheckState.HeartbeatConn:Disconnect(); SkillCheckState.HeartbeatConn = nil end
    SkillCheckState.HeartbeatConn = RunService.Heartbeat:Connect(function()
        if not SkillCheckState.Enabled or SkillCheckState.Busy then return end
        local pg = LP:FindFirstChild("PlayerGui"); if not pg then return end
        local scp = pg:FindFirstChild("SkillCheckPromptGui"); if not scp then return end
        local check = scp:FindFirstChild("Check"); if not check or not check.Visible or not check.Parent then return end
        local line = check:FindFirstChild("Line"); local goal = check:FindFirstChild("Goal"); if not line or not goal then return end
       
        -- Murni Legit (hanya mengecek jarum masuk zona hijau)
        local lr = line.Rotation % 360; local gr = goal.Rotation % 360; local lo, hi
        lo = (gr + 116) % 360; hi = (gr + 140) % 360 -- Zona hijau standar
        local inWindow; if hi < lo then inWindow = (lr >= lo or lr <= hi) else inWindow = (lr >= lo and lr <= hi) end

        if inWindow then
            SkillCheckState.Busy = true
            task.spawn(function()
                task.wait(0.02) -- Jeda natural
                SK_Trigger()
                task.wait(0.05)
                SkillCheckState.Busy = false
            end)
        end
    end)
end

-- ============================================================
-- FAST VAULT INTEGRATION (NO BUG)
-- ============================================================
local FastVaultEnabled = false
local ControllerModule
local VaultRemote

task.spawn(function()
    if not game:IsLoaded() then pcall(function() game.Loaded:Wait() end) end
    local controller
    for attempt = 1, 15 do
        local ok, result = pcall(function()
            local modules = ReplicatedStorage:WaitForChild("Modules", 5)
            if not modules then return nil end
            local survivors = modules:WaitForChild("Survivors", 5)
            if not survivors then return nil end
            local module = survivors:WaitForChild("SurvivorAnimationsController", 5)
            if not module then return nil end
            return require(module)
        end)
        if ok and result then controller = result break end
        task.wait(1)
    end
    if not controller then return end
    ControllerModule = controller

    pcall(function()
        local remotes = ReplicatedStorage:WaitForChild("Remotes", 10)
        if not remotes then return end
        local window = remotes:WaitForChild("Window", 5)
        if not window then return end
        VaultRemote = window:WaitForChild("fastvault", 5)
    end)

    local OriginalFacing = controller._isFacingStraightEnough
    local OriginalVault  = controller._onVaultAnimation

    if type(OriginalFacing) ~= "function" or type(OriginalVault) ~= "function" then return end

    controller._isFacingStraightEnough = function(self, part1, part2, angle)
        if not FastVaultEnabled then return OriginalFacing(self, part1, part2, angle) end
        pcall(function() if self.character then self.character:SetAttribute("speed", 30) end end)
        return true, 0
    end

    controller._onVaultAnimation = function(self, vaultPoint, sprinting, requestId)
        if not FastVaultEnabled then return OriginalVault(self, vaultPoint, sprinting, requestId) end
        if self.isVaulting then return end
        if self.isSlidingPallet ~= nil then self.isSlidingPallet = false end
                if self.character then pcall(function() self.character:SetAttribute("vaultspeed", 2.0) end) end
        local packed = table.pack(pcall(function() return OriginalVault(self, vaultPoint, true, requestId) end))
        if not packed[1] then if self.character then pcall(function() self.character:SetAttribute("vaultspeed", 1) end) end; return end
        task.delay(0.15, function()
            if not self.isVaulting then return end
            if self.activeVaultTrack then pcall(function() self.activeVaultTrack:Stop() end) end
            if self.humanoidRootPart and vaultPoint and typeof(vaultPoint) == "Instance" and vaultPoint:IsA("BasePart") then pcall(function() self.humanoidRootPart.CFrame = vaultPoint.CFrame * CFrame.new(0, 2, -1) end) end
            if self.VaultCompleteEvent then pcall(function() self.VaultCompleteEvent:FireServer(vaultPoint, true, requestId, self.character) end) end
            self.isVaulting = false
            if self.humanoid then pcall(function() self.humanoid.AutoRotate = true end) end
            if type(self._finishVaultOrSlideSpeed) == "function" then pcall(function() self:_finishVaultOrSlideSpeed(true) end) end
            if type(self._checkConditions) == "function" then pcall(function() self:_checkConditions() end) end
        end)
        task.delay(1.0, function() if self.character then pcall(function() self.character:SetAttribute("vaultspeed", 1) end) end end)
        return table.unpack(packed, 2, packed.n)
    end
    task.spawn(function() while task.wait(0.5) do if FastVaultEnabled and VaultRemote then pcall(function() VaultRemote:FireServer(LP) end) end end end)
end)

-- ============================================================
-- UI LIBRARY HANX HUB (ANDROID FIXED)
-- ============================================================
local Theme = { Bg = Color3.fromRGB(12, 12, 16), Panel = Color3.fromRGB(18, 18, 24), Card = Color3.fromRGB(24, 24, 32), CardHover = Color3.fromRGB(32, 32, 42), Border = Color3.fromRGB(48, 48, 58), Text = Color3.fromRGB(240, 240, 245), TextMuted = Color3.fromRGB(140, 140, 155), Accent = Color3.fromRGB(160, 80, 255), Font = Enum.Font.Gotham, FontMedium = Enum.Font.GothamMedium, FontBold = Enum.Font.GothamBold, }
local function mk(class, props) local obj = Instance.new(class); for k, v in pairs(props or {}) do obj[k] = v end; return obj end
local function corner(parent, r) mk("UICorner", { CornerRadius = UDim.new(0, r or 6), Parent = parent }) end
local function stroke(parent, color, thickness) return mk("UIStroke", { Color = color or Theme.Border, Thickness = thickness or 1, Parent = parent }) end
local function dragify(frame, handle)
local dragging, dragStart, startPos
handle.InputBegan:Connect(function(input) if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = true; dragStart = input.Position; startPos = frame.Position; local conn; conn = input.Changed:Connect(function() if input.UserInputState == Enum.UserInputState.End then dragging = false; if conn then conn:Disconnect(); conn = nil end end end) end end)
UIS.InputChanged:Connect(function(input) if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then local delta = input.Position - dragStart; frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y) end end)
end

local UI = {}; UI.__index = UI
local SearchRegistry = {}
function UI.new()
local self = setmetatable({}, UI)
-- FIX ANDROID: Pindah dari CoreGui ke PlayerGui
local parent = LP:WaitForChild("PlayerGui")
local old = parent:FindFirstChild("HanxHubUI"); if old then old:Destroy() end
self.Gui = mk("ScreenGui", { Name = "HanxHubUI", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 999, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = parent })
-- FIX ANDROID: Ukuran diubah jadi muat di HP
local W, H = 340, 240
local root = mk("Frame", { Name = "Root", Size = UDim2.fromOffset(W, H), Position = UDim2.new(0.5, -W/2, 0.5, -H/2), BackgroundColor3 = Theme.Bg, BorderSizePixel = 0, Parent = self.Gui, ZIndex = 10 })
corner(root, 12); stroke(root, Theme.Border, 1)
local bgLayer = mk("Frame", { Name = "NeonBackground", Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(5, 3, 12), BorderSizePixel = 0, BackgroundTransparency = 0.22, ClipsDescendants = true, Parent = root, ZIndex = 10 })
corner(bgLayer, 12)
local bgGradient = mk("UIGradient", { Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(8, 3, 20)), ColorSequenceKeypoint.new(0.45, Color3.fromRGB(25, 5, 48)), ColorSequenceKeypoint.new(1, Color3.fromRGB(5, 3, 14)) }), Rotation = 125, Parent = bgLayer })
local function NeonGlow(pos, size, color, transparency)
local glow = mk("Frame", { Size = UDim2.fromOffset(size, size), Position = pos, BackgroundColor3 = color, BackgroundTransparency = transparency, BorderSizePixel = 0, Parent = bgLayer, ZIndex = 10 })
corner(glow, size)
mk("UIGradient", { Rotation = 45, Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, color), ColorSequenceKeypoint.new(1, Color3.fromRGB(15, 5, 30)) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.15), NumberSequenceKeypoint.new(1, 0.8) }), Parent = glow })
return glow
end
local glow1 = NeonGlow(UDim2.new(-0.12, 0, -0.35, 0), 440, Color3.fromRGB(145, 35, 255), 0.72)
local glow2 = NeonGlow(UDim2.new(0.72, 0, 0.55, 0), 430, Color3.fromRGB(100, 20, 230), 0.76)
local glow3 = NeonGlow(UDim2.new(0.35, 0, -0.65, 0), 320, Color3.fromRGB(80, 20, 160), 0.82)
for i = 1, 8 do local line = mk("Frame", { Name = "NeonLine", Size = UDim2.fromOffset(3, 330), Position = UDim2.new(i * 0.14 - 0.1, 0, 0.48, 0), Rotation = 45, BackgroundColor3 = Color3.fromRGB(155, 55, 255), BackgroundTransparency = 0.68, BorderSizePixel = 0, Parent = bgLayer, ZIndex = 10 }); mk("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0.15), NumberSequenceKeypoint.new(1, 1) }), Parent = line }) end
for i = 1, 24 do local dot = mk("Frame", { Size = UDim2.fromOffset(math.random(2, 4), math.random(2, 4)), Position = UDim2.fromScale(math.random(5, 95) / 100, math.random(10, 95) / 100), BackgroundColor3 = Color3.fromRGB(190, 110, 255), BackgroundTransparency = 0.25, BorderSizePixel = 0, Parent = bgLayer, ZIndex = 10 }); corner(dot, 5) end
task.spawn(function() while bgLayer.Parent do TweenService:Create(glow1, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.84}):Play(); TweenService:Create(glow2, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.65}):Play(); task.wait(3); if not bgLayer.Parent then break end; TweenService:Create(glow1, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.68}):Play(); TweenService:Create(glow2, TweenInfo.new(3, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {BackgroundTransparency = 0.82}):Play(); task.wait(3) end end)
local topBar = mk("Frame", { Size = UDim2.new(1, 0, 0, 64), BackgroundTransparency = 1, Parent = root, ZIndex = 11 })
dragify(root, topBar)
mk("TextLabel", { Size = UDim2.fromOffset(200, 20), Position = UDim2.fromOffset(20, 16), BackgroundTransparency = 1, Text = "HANX HUB", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 18, TextXAlignment = Enum.TextXAlignment.Left, Parent = topBar, ZIndex = 12 })
mk("TextLabel", { Size = UDim2.fromOffset(200, 14), Position = UDim2.fromOffset(20, 36), BackgroundTransparency = 1, Text = "Violence District", TextColor3 = Theme.Accent, Font = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = topBar, ZIndex = 12 })
local minBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -76, 0, 18), BackgroundColor3 = Theme.Panel, Text = "−", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 18, AutoButtonColor = false, Parent = topBar, ZIndex = 12 }); corner(minBtn, 6); stroke(minBtn, Theme.Border, 1)
local closeBtn = mk("TextButton", { Size = UDim2.fromOffset(28, 28), Position = UDim2.new(1, -40, 0, 18), BackgroundColor3 = Theme.Panel, Text = "×", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 20, AutoButtonColor = false, Parent = topBar, ZIndex = 12 }); corner(closeBtn, 6); stroke(closeBtn, Theme.Border, 1)
local tray = mk("TextButton", { Size = UDim2.fromOffset(120, 36), Position = UDim2.new(0.5, -60, 0, 20), BackgroundColor3 = Theme.Card, Text = "HANX HUB", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 12, Visible = false, Parent = self.Gui, ZIndex = 20 }); corner(tray, 8); stroke(tray, Theme.Border, 1)
local minimized = false; local function toggleMin() minimized = not minimized; root.Visible = not minimized; tray.Visible = minimized end
minBtn.MouseButton1Click:Connect(toggleMin); tray.MouseButton1Click:Connect(toggleMin); closeBtn.MouseButton1Click:Connect(function() self.Gui:Destroy() end)
local sidebar = mk("Frame", { Size = UDim2.new(0, 200, 1, -74), Position = UDim2.new(0, 10, 0, 64), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 0.4, BorderSizePixel = 0, Parent = root, ZIndex = 11 }); corner(sidebar, 10); stroke(sidebar, Theme.Border, 1)
local searchBar = mk("Frame", { Name = "SearchBar", Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = Theme.Bg, BackgroundTransparency = 0.35, BorderSizePixel = 0, Parent = sidebar, ZIndex = 13 }); corner(searchBar, 8); stroke(searchBar, Theme.Border, 1)
self.GlobalSearchBox = mk("TextBox", { Name = "FeatureSearch", Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(10, 0), BackgroundTransparency = 1, Text = "", PlaceholderText = "Search features...", PlaceholderColor3 = Theme.TextMuted, TextColor3 = Theme.Text, Font = Theme.Font, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Left, ClearTextOnFocus = false, Parent = searchBar, ZIndex = 14 })
local navList = mk("Frame", { Size = UDim2.new(1, -20, 1, -122), Position = UDim2.fromOffset(10, 52), BackgroundTransparency = 1, Parent = sidebar, ZIndex = 12 }); mk("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder, Parent = navList })
local profile = mk("Frame", { Size = UDim2.new(1, -20, 0, 54), Position = UDim2.new(0, 10, 1, -64), BackgroundColor3 = Theme.Card, BackgroundTransparency = 0.3, Parent = sidebar, ZIndex = 12 }); corner(profile, 8); stroke(profile, Theme.Border, 1)
local avatar = mk("ImageLabel", { Size = UDim2.fromOffset(34, 34), Position = UDim2.fromOffset(10, 10), BackgroundColor3 = Theme.Bg, Parent = profile, ZIndex = 13 }); corner(avatar, 17)
task.spawn(function() local ok, url = pcall(function() return Players:GetUserThumbnailAsync(LP.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size150x150) end); if ok then avatar.Image = url end end)
mk("TextLabel", { Size = UDim2.new(1, -54, 0, 16), Position = UDim2.fromOffset(54, 12), BackgroundTransparency = 1, Text = LP.DisplayName, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = profile, ZIndex = 13 })
mk("TextLabel", { Size = UDim2.new(1, -54, 0, 14), Position = UDim2.fromOffset(54, 28), BackgroundTransparency = 1, Text = "@" .. LP.Name, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 10, TextXAlignment = Enum.TextXAlignment.Left, Parent = profile, ZIndex = 13 })
local content = mk("Frame", { Size = UDim2.new(1, -220, 1, -74), Position = UDim2.new(0, 210, 0, 64), BackgroundTransparency = 1, BorderSizePixel = 0, ClipsDescendants = true, Parent = root, ZIndex = 11 }); mk("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 20), PaddingLeft = UDim.new(0, 4), PaddingRight = UDim.new(0, 10), Parent = content })
self.Tabs = {}; self.ActiveTab = nil; self.Content = content
local function ApplyFeatureSearch(query)
query = string.lower(query or ""); local searching = query ~= ""; local cardMatches, pageMatches = {}, {}
for _, item in ipairs(SearchRegistry) do local match = searching and string.find(string.lower(item.Name), query, 1, true) ~= nil; item.Row.Visible = not searching or match; if match then cardMatches[item.Card] = true; pageMatches[item.Page] = true end end
for _, item in ipairs(SearchRegistry) do item.Card.Visible = not searching or cardMatches[item.Card] == true end
local firstMatch = nil; for _, tab in ipairs(self.Tabs) do local matched = not searching or pageMatches[tab.Page] == true; tab.Btn.Visible = matched; if matched and not firstMatch then firstMatch = tab end end
if searching then self.ActiveTab = firstMatch elseif not self.ActiveTab then self.ActiveTab = self.Tabs[1] end
for _, tab in ipairs(self.Tabs) do local active = tab == self.ActiveTab; tab.Page.Visible = active; tab.Indicator.Visible = active; tab.Btn.BackgroundTransparency = active and 0.85 or 1; local label = tab.Btn:FindFirstChildOfClass("TextLabel"); if label then label.TextColor3 = active and Theme.Text or Theme.TextMuted end end
end
self.GlobalSearchBox:GetPropertyChangedSignal("Text"):Connect(function() ApplyFeatureSearch(self.GlobalSearchBox.Text) end)
function self:AddTab(name)
local btn = mk("TextButton", { Size = UDim2.new(1, 0, 0, 36), BackgroundColor3 = Theme.Panel, BackgroundTransparency = 1, BorderSizePixel = 0, Text = "", AutoButtonColor = false, Parent = navList, ZIndex = 13 }); corner(btn, 6)
local indicator = mk("Frame", { Size = UDim2.new(0, 3, 0, 18), Position = UDim2.new(0, -6, 0.5, -9), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = btn, ZIndex = 14, Visible = false }); corner(indicator, 2)
mk("TextLabel", { Size = UDim2.new(1, -20, 1, 0), Position = UDim2.fromOffset(16, 0), BackgroundTransparency = 1, Text = name, TextColor3 = Theme.TextMuted, Font = Theme.FontMedium, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = btn, ZIndex = 14 })
local page = mk("ScrollingFrame", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, BorderSizePixel = 0, ScrollBarThickness = 2, ScrollBarImageColor3 = Theme.Border, CanvasSize = UDim2.new(0, 0, 0, 0), AutomaticCanvasSize = Enum.AutomaticSize.Y, Visible = false, Parent = content, ZIndex = 12 })
mk("UIPadding", { PaddingTop = UDim.new(0, 2), PaddingBottom = UDim.new(0, 10), PaddingLeft = UDim.new(0, 2), PaddingRight = UDim.new(0, 6), Parent = page }); mk("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 400), CellPadding = UDim2.fromOffset(12, 12), SortOrder = Enum.SortOrder.LayoutOrder, FillDirectionMaxCells = 2, Parent = page })
local tab = { Btn = btn, Page = page, Indicator = indicator, Name = name }; table.insert(self.Tabs, tab)
btn.MouseEnter:Connect(function() if self.ActiveTab ~= tab then TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 0.55 }):Play() end end)
btn.MouseLeave:Connect(function() if self.ActiveTab ~= tab then TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundTransparency = 1 }):Play() end end)
btn.MouseButton1Click:Connect(function() for _, t in ipairs(self.Tabs) do t.Page.Visible = false; t.Indicator.Visible = false; t.Btn.BackgroundTransparency = 1; t.Btn:FindFirstChildOfClass("TextLabel").TextColor3 = Theme.TextMuted end; page.Visible = true; indicator.Visible = true; btn.BackgroundTransparency = 0.85; btn:FindFirstChildOfClass("TextLabel").TextColor3 = Theme.Text; self.ActiveTab = tab end)
if #self.Tabs == 1 then btn:FindFirstChildOfClass("TextLabel").TextColor3 = Theme.Text; indicator.Visible = true; btn.BackgroundTransparency = 0.85; page.Visible = true; self.ActiveTab = tab end; return tab
end
return self
end
function UI:AddCard(page, icon, title)
local card = mk("Frame", { Size = UDim2.new(1, 0, 0, 440), AutomaticSize = Enum.AutomaticSize.None, BackgroundColor3 = Color3.fromRGB(19, 13, 30), BackgroundTransparency = 0.08, BorderSizePixel = 0, Parent = page, ZIndex = 13 }); corner(card, 10); stroke(card, Color3.fromRGB(145, 55, 255), 1.4).Transparency = 0.12
mk("UIPadding", { PaddingTop = UDim.new(0, 12), PaddingBottom = UDim.new(0, 12), PaddingLeft = UDim.new(0, 14), PaddingRight = UDim.new(0, 14), Parent = card }); mk("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = card })
local header = mk("Frame", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); mk("TextLabel", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = tostring(icon) .. " " .. tostring(title), TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 13, TextXAlignment = Enum.TextXAlignment.Left, Parent = header, ZIndex = 15 }); mk("Frame", { Size = UDim2.new(1, 0, 0, 1), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = card, ZIndex = 14 }); return card
end
function UI:AddToggle(card, label, default, callback)
local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = row, Card = card, Page = card.Parent })
mk("TextLabel", { Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })
local state = default == true; local statusLabel = mk("TextLabel", { Size = UDim2.fromOffset(40, 16), Position = UDim2.new(1, -90, 0.5, -8), BackgroundTransparency = 1, Text = state and "ON" or "OFF", TextColor3 = state and Theme.Accent or Theme.TextMuted, Font = Theme.FontBold, TextSize = 11, TextXAlignment = Enum.TextXAlignment.Right, Parent = row, ZIndex = 15 })
local track = mk("Frame", { Size = UDim2.fromOffset(40, 20), Position = UDim2.new(1, -40, 0.5, -10), BackgroundColor3 = state and Theme.Accent or Theme.Border, BorderSizePixel = 0, Parent = row, ZIndex = 15 }); corner(track, 10)
local knob = mk("Frame", { Size = UDim2.fromOffset(16, 16), Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = state and Theme.Bg or Theme.Text, BorderSizePixel = 0, Parent = track, ZIndex = 16 }); corner(knob, 8)
local hit = mk("TextButton", { Size = UDim2.new(1, 0, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row, ZIndex = 17 })
hit.MouseButton1Click:Connect(function() state = not state; statusLabel.Text = state and "ON" or "OFF"; statusLabel.TextColor3 = state and Theme.Accent or Theme.TextMuted; TweenService:Create(track, TweenInfo.new(0.18), { BackgroundColor3 = state and Theme.Accent or Theme.Border }):Play(); TweenService:Create(knob, TweenInfo.new(0.18), { Position = state and UDim2.new(1, -18, 0.5, -8) or UDim2.new(0, 2, 0.5, -8), BackgroundColor3 = state and Theme.Bg or Theme.Text }):Play(); if callback then callback(state) end end)
end
function UI:AddSlider(card, label, min, max, default, callback)
local wrap = mk("Frame", { Size = UDim2.new(1, 0, 0, 42), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = wrap, Card = card, Page = card.Parent })
mk("TextLabel", { Size = UDim2.new(1, -60, 0, 18), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = wrap, ZIndex = 15 })
local valLabel = mk("TextLabel", { Size = UDim2.fromOffset(50, 18), Position = UDim2.new(1, -50, 0, 0), BackgroundTransparency = 1, Text = tostring(default), TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Right, Parent = wrap, ZIndex = 15 })
local track = mk("Frame", { Size = UDim2.new(1, 0, 0, 4), Position = UDim2.new(0, 0, 0, 26), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = wrap, ZIndex = 15 }); corner(track, 2)
local fill = mk("Frame", { Size = UDim2.new((default - min) / (max - min), 0, 1, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track, ZIndex = 16 }); corner(fill, 2)
local dot = mk("Frame", { Size = UDim2.fromOffset(14, 14), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new((default - min) / (max - min), 0, 0.5, 0), BackgroundColor3 = Theme.Accent, BorderSizePixel = 0, Parent = track, ZIndex = 17 }); corner(dot, 7); stroke(dot, Theme.Bg, 2)
local dragging = false
local function setFromX(px) local rel = math.clamp((px - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1); local val = math.floor(min + (max - min) * rel + 0.5); fill.Size = UDim2.new(rel, 0, 1, 0); dot.Position = UDim2.new(rel, 0, 0.5, 0); valLabel.Text = tostring(val); if callback then callback(val) end end
track.InputBegan:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = true; setFromX(i.Position.X) end end)
UIS.InputChanged:Connect(function(i) if dragging and (i.UserInputType == Enum.UserInputType.MouseMovement or i.UserInputType == Enum.UserInputType.Touch) then setFromX(i.Position.X) end end)
UIS.InputEnded:Connect(function(i) if i.UserInputType == Enum.UserInputType.MouseButton1 or i.UserInputType == Enum.UserInputType.Touch then dragging = false end end)
end
function UI:AddCheckbox(card, label, default, color, callback, colorCallback)
local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 28), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = row, Card = card, Page = card.Parent })
local box = mk("Frame", { Size = UDim2.fromOffset(18, 18), Position = UDim2.new(0, 0, 0.5, -9), BackgroundColor3 = Theme.Border, BorderSizePixel = 0, Parent = row, ZIndex = 15 }); corner(box, 4)
local check = mk("TextLabel", { Size = UDim2.fromScale(1, 1), BackgroundTransparency = 1, Text = "✓", TextColor3 = color or Theme.Accent, Font = Theme.FontBold, TextSize = 12, Visible = default == true, Parent = box, ZIndex = 16 })
mk("TextLabel", { Size = UDim2.new(1, -60, 1, 0), Position = UDim2.fromOffset(28, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })
local colorDot = mk("TextButton", { Size = UDim2.fromOffset(12, 12), Position = UDim2.new(1, -12, 0.5, -6), BackgroundColor3 = color or Theme.Accent, Text = "", BorderSizePixel = 0, Parent = row, ZIndex = 16 }); corner(colorDot, 6); stroke(colorDot, Theme.Bg, 1)
local state = default == true
local hit = mk("TextButton", { Size = UDim2.new(1, -30, 1, 0), BackgroundTransparency = 1, Text = "", Parent = row, ZIndex = 17 })
hit.MouseButton1Click:Connect(function() state = not state; check.Visible = state; if callback then callback(state) end end)
colorDot.MouseButton1Click:Connect(function() if colorCallback then if typeof(ColorPicker) == "function" or (syn and syn.ColorPicker) then local picker = ColorPicker or syn.ColorPicker; local newColor = picker(colorDot.BackgroundColor3); if newColor then colorDot.BackgroundColor3 = newColor; check.TextColor3 = newColor; colorCallback(newColor) end else local randomColor = Color3.fromRGB(math.random(0, 255), math.random(0, 255), math.random(0, 255)); colorDot.BackgroundColor3 = randomColor; check.TextColor3 = randomColor; colorCallback(randomColor) end end end)
end
function UI:AddDropdown(card, label, options, default, callback)
local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = card, ZIndex = 14 }); table.insert(SearchRegistry, { Name = label, Row = row, Card = card, Page = card.Parent })
mk("TextLabel", { Size = UDim2.new(1, -70, 1, 0), BackgroundTransparency = 1, Text = label, TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })
local btn = mk("TextButton", { Size = UDim2.fromOffset(70, 24), Position = UDim2.new(1, -70, 0.5, -12), BackgroundColor3 = Theme.Bg, Text = default, TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, Parent = row, ZIndex = 15 }); corner(btn, 6); stroke(btn, Theme.Border, 1)
local idx = 1; for i, v in ipairs(options) do if v == default then idx = i break end end
btn.MouseButton1Click:Connect(function() idx = idx % #options + 1; btn.Text = options[idx]; if callback then callback(options[idx]) end end)
end

-- ============================================================
-- BUILD UI & MOUNT FEATURES
-- ============================================================
local Window = UI.new()
local TabMain = Window:AddTab("Main")
local TabSurvivor = Window:AddTab("Survivor")
local TabKiller = Window:AddTab("Killer")
local TabVisual = Window:AddTab("Visual")
local TabTeleport = Window:AddTab("Teleport")
local TabSettings = Window:AddTab("Settings")

local function SetTabCardHeight(tab, height) local grid = tab.Page:FindFirstChildOfClass("UIGridLayout"); if grid then grid.CellSize = UDim2.new(0.5, -6, 0, height) end end
SetTabCardHeight(TabMain, 440); SetTabCardHeight(TabSurvivor, 458); SetTabCardHeight(TabKiller, 440); SetTabCardHeight(TabVisual, 440); SetTabCardHeight(TabTeleport, 440); SetTabCardHeight(TabSettings, 440)

-- ============================================================
-- TELEPORT
-- ============================================================
local TP = { Generators = {}, Hooks = {}, Gates = {}, Pallets = {}, Windows = {}, Idx = { Generator = 1, Hook = 1, Gate = 1, Pallet = 1, Window = 1 }, ScanCooldown = 0 }
local function TP_Scan(force)
if not force and tick() - TP.ScanCooldown < 2 then return end
TP.ScanCooldown = tick(); table.clear(TP.Generators); table.clear(TP.Hooks); table.clear(TP.Gates); table.clear(TP.Pallets); table.clear(TP.Windows)
local map = workspace:FindFirstChild("Map") or workspace
for i, desc in ipairs(map:GetDescendants()) do
if i % 200 == 0 then task.wait() end
if desc:IsA("Model") then local n = string.lower(desc.Name)
if n == "generator" then local body = desc:FindFirstChild("GeneratorBody") or desc:FindFirstChildWhichIsA("BasePart"); if body then table.insert(TP.Generators, { model = desc, part = body }) end
elseif n == "hook" and desc:FindFirstChild("HookPoint") then table.insert(TP.Hooks, desc)
elseif n == "gate" and desc:FindFirstChild("ExitLever") then table.insert(TP.Gates, desc)
elseif n == "window" then table.insert(TP.Windows, desc) end
elseif desc:IsA("BasePart") and desc.Name == "PrimaryPartPallet" then local parent = desc.Parent; if parent and not table.find(TP.Pallets, parent) then table.insert(TP.Pallets, parent) end end
end
end
local function TP_To(part) local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp or not part or not part:IsA("BasePart") then return false end; pcall(function() hrp.CFrame = part.CFrame + Vector3.new(0, 3, 0) end); return true end
local function TP_Cycle(category, pickPartFn, label)
local list = TP[category]; if #list == 0 then TP_Scan(true) end
if #list == 0 then pcall(function() StarterGui:SetCore("SendNotification", { Title = "Teleport", Text = label .. " tidak ditemukan!", Duration = 2 }) end); return end
if TP.Idx[category] > #list then TP.Idx[category] = 1 end
local entry = list[TP.Idx[category]]; local part = entry and pickPartFn(entry)
if part then TP_To(part); pcall(function() StarterGui:SetCore("SendNotification", { Title = "Teleport " .. label, Text = TP.Idx[category] .. " / " .. #list, Duration = 1.2 }) end) end
TP.Idx[category] = TP.Idx[category] + 1
end
local tpMapCard = Window:AddCard(TabTeleport.Page, "◈", "Teleport Map")
local refreshBtn = mk("TextButton", { Size = UDim2.new(1, -12, 0, 32), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = "⟳ REFRESH MAP CACHE", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, Parent = tpMapCard, ZIndex = 15 }); corner(refreshBtn, 8); stroke(refreshBtn, Color3.fromRGB(160, 80, 255), 1)
refreshBtn.MouseButton1Click:Connect(function() TP.Idx.Generator, TP.Idx.Hook, TP.Idx.Gate, TP.Idx.Pallet, TP.Idx.Window = 1, 1, 1, 1, 1; TP_Scan(true); pcall(function() StarterGui:SetCore("SendNotification", { Title = "Refresh", Text = string.format("%d gen · %d hook · %d gate · %d pallet · %d window", #TP.Generators, #TP.Hooks, #TP.Gates, #TP.Pallets, #TP.Windows), Duration = 2.5 }) end) end)
local function TP_Button(parent, label, category, pickPartFn)
local btn = mk("TextButton", { Size = UDim2.new(1, -12, 0, 34), BackgroundColor3 = Color3.fromRGB(24, 18, 34), BorderSizePixel = 0, Text = label .. " ›", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, Parent = parent, ZIndex = 15 }); corner(btn, 8); stroke(btn, Color3.fromRGB(160, 80, 255), 1)
btn.MouseEnter:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(44, 28, 62) }):Play() end); btn.MouseLeave:Connect(function() TweenService:Create(btn, TweenInfo.new(0.12), { BackgroundColor3 = Color3.fromRGB(24, 18, 34) }):Play() end)
btn.MouseButton1Click:Connect(function() TP_Cycle(category, pickPartFn, label) end); return btn
end
TP_Button(tpMapCard, "TELEPORT TO GENERATOR", "Generators", function(e) return e.part end)
TP_Button(tpMapCard, "TELEPORT TO HOOK", "Hooks", function(e) return e:FindFirstChild("HookPoint") or e:FindFirstChildWhichIsA("BasePart") end)
TP_Button(tpMapCard, "TELEPORT TO GATE", "Gates", function(e) return e:FindFirstChildWhichIsA("BasePart") end)
TP_Button(tpMapCard, "TELEPORT TO PALLET", "Pallets", function(e) return e:FindFirstChild("PrimaryPartPallet") or e:FindFirstChildWhichIsA("BasePart") end)
TP_Button(tpMapCard, "TELEPORT TO WINDOW", "Windows", function(e) return e:FindFirstChild("Bottom") or e:FindFirstChildWhichIsA("BasePart") end)

local tpPlayerCard = Window:AddCard(TabTeleport.Page, "☻", "Teleport Player")
local tpSelectedPlayer = nil
local tpPlayerDropdown
local function TP_ListPlayers() local names = {}; for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then table.insert(names, p.Name) end end; table.sort(names); return names end
do
local row = mk("Frame", { Size = UDim2.new(1, 0, 0, 32), BackgroundTransparency = 1, Parent = tpPlayerCard, ZIndex = 14 }); table.insert(SearchRegistry, { Name = "Teleport Player Target", Row = row, Card = tpPlayerCard, Page = tpPlayerCard.Parent })
mk("TextLabel", { Size = UDim2.new(1, -100, 1, 0), BackgroundTransparency = 1, Text = "Pilih Player", TextColor3 = Theme.TextMuted, Font = Theme.Font, TextSize = 12, TextXAlignment = Enum.TextXAlignment.Left, Parent = row, ZIndex = 15 })
local btn = mk("TextButton", { Size = UDim2.fromOffset(90, 24), Position = UDim2.new(1, -90, 0.5, -12), BackgroundColor3 = Theme.Bg, Text = "-", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, Parent = row, ZIndex = 15 }); corner(btn, 6); stroke(btn, Theme.Border, 1)
local options = TP_ListPlayers(); local idx = 1; if #options > 0 then tpSelectedPlayer = options[1]; btn.Text = options[1] end
btn.MouseButton1Click:Connect(function() options = TP_ListPlayers(); if #options == 0 then btn.Text = "-"; tpSelectedPlayer = nil; return end; idx = idx % #options + 1; btn.Text = options[idx]; tpSelectedPlayer = options[idx] end)
tpPlayerDropdown = { Btn = btn, Refresh = function() options = TP_ListPlayers() end }
end
local tpRefresh = mk("TextButton", { Size = UDim2.new(1, -12, 0, 32), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = "⟳ REFRESH PLAYER LIST", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, Parent = tpPlayerCard, ZIndex = 15 }); corner(tpRefresh, 8); stroke(tpRefresh, Color3.fromRGB(160, 80, 255), 1)
tpRefresh.MouseButton1Click:Connect(function() if tpPlayerDropdown and tpPlayerDropdown.Refresh then tpPlayerDropdown.Refresh() end; pcall(function() StarterGui:SetCore("SendNotification", { Title = "Refresh", Text = #TP_ListPlayers() .. " player ditemukan.", Duration = 2 }) end) end)
local tpGo = mk("TextButton", { Size = UDim2.new(1, -12, 0, 34), BackgroundColor3 = Color3.fromRGB(24, 18, 34), BorderSizePixel = 0, Text = "TELEPORT TO PLAYER ›", TextColor3 = Theme.Text, Font = Theme.FontBold, TextSize = 11, AutoButtonColor = false, Parent = tpPlayerCard, ZIndex = 15 }); corner(tpGo, 8); stroke(tpGo, Color3.fromRGB(160, 80, 255), 1)
tpGo.MouseButton1Click:Connect(function() if not tpSelectedPlayer or tpSelectedPlayer == "" then return end; local target = Players:FindFirstChild(tpSelectedPlayer); if not target or not target.Character then return end; local thrp = target.Character:FindFirstChild("HumanoidRootPart"); local myhrp = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart"); if not thrp or not myhrp then return end; myhrp.CFrame = thrp.CFrame + Vector3.new(0, 3, 0) end)
task.spawn(function() task.wait(2); TP_Scan(true) end)
workspace.ChildAdded:Connect(function(child) if child.Name == "Map" then task.wait(1); TP_Scan(true) end end)

-- ============================================================
-- KILLER EXTRAS
-- ============================================================
local KillerExtras = { AutoStalk = { Enabled = false, Range = 150, Conn = nil, LastFire = 0 }, CounterParry = { Enabled = false, Distance = 15, Interval = 0.3, AnimId = "rbxassetid://117042998468241", Thread = nil, Track = nil }, NoSlowdown = { Enabled = false }, }
local function KE_GetRole() if not LP.Team then return "Unknown" end; local n = LP.Team.Name; if n == "Killer" then return "Killer" end; if n == "Survivors" then return "Survivor" end; return "Spectator" end
local function KE_StalkRemote() local r = ReplicatedStorage:FindFirstChild("Remotes"); local k = r and r:FindFirstChild("Killers"); local s = k and k:FindFirstChild("Stalker"); return s and s:FindFirstChild("StartStalking") end
local function KE_FindStalkTarget()
local char = LP.Character; local hrp = char and char:FindFirstChild("HumanoidRootPart"); if not hrp then return nil end; local best, short = nil, math.huge
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Character then local hum = p.Character:FindFirstChildOfClass("Humanoid"); local phrp = p.Character:FindFirstChild("HumanoidRootPart"); if hum and phrp and hum.Health > 30 then local d = (phrp.Position - hrp.Position).Magnitude; if d <= KillerExtras.AutoStalk.Range and d < short then short = d; best = p end end end end; return best
end
local function KE_StartStalk()
if KillerExtras.AutoStalk.Conn then return end
KillerExtras.AutoStalk.Conn = RunService.Heartbeat:Connect(function() if not KillerExtras.AutoStalk.Enabled then return end; if KE_GetRole() ~= "Killer" then return end; local now = tick(); if now - KillerExtras.AutoStalk.LastFire < 0.35 then return end; local target = KE_FindStalkTarget(); if not target then return end; local remote = KE_StalkRemote(); if not remote then return end; KillerExtras.AutoStalk.LastFire = now; pcall(function() remote:FireServer(target) end) end)
end
local function KE_StopStalk() KillerExtras.AutoStalk.Enabled = false; if KillerExtras.AutoStalk.Conn then KillerExtras.AutoStalk.Conn:Disconnect(); KillerExtras.AutoStalk.Conn = nil end end
local function KE_StopCounterParry() KillerExtras.CounterParry.Enabled = false; if KillerExtras.CounterParry.Thread then task.cancel(KillerExtras.CounterParry.Thread); KillerExtras.CounterParry.Thread = nil end; if KillerExtras.CounterParry.Track then pcall(function() KillerExtras.CounterParry.Track:Stop() end); KillerExtras.CounterParry.Track = nil end end
local function KE_StartCounterParry()
if KillerExtras.CounterParry.Thread then return end
KillerExtras.CounterParry.Thread = task.spawn(function()
while KillerExtras.CounterParry.Enabled do
local char = LP.Character
if char and char.Parent and KE_GetRole() == "Killer" then
local hum = char:FindFirstChildOfClass("Humanoid"); local animator = hum and hum:FindFirstChildOfClass("Animator"); local hrp = char:FindFirstChild("HumanoidRootPart")
if animator and hrp then
if not KillerExtras.CounterParry.Track or not KillerExtras.CounterParry.Track.Parent then local ok, track = pcall(function() local a = Instance.new("Animation"); a.AnimationId = KillerExtras.CounterParry.AnimId; return animator:LoadAnimation(a) end); if ok then KillerExtras.CounterParry.Track = track end end
if KillerExtras.CounterParry.Track then
local found = false
for _, p in ipairs(Players:GetPlayers()) do if p ~= LP and p.Team and p.Team.Name == "Survivors" and p.Character then local phrp = p.Character:FindFirstChild("HumanoidRootPart"); if phrp and (phrp.Position - hrp.Position).Magnitude <= KillerExtras.CounterParry.Distance then found = true; break end end end
if found then pcall(function() KillerExtras.CounterParry.Track:Play(); KillerExtras.CounterParry.Track:AdjustWeight(0) end); task.wait(0.05); pcall(function() KillerExtras.CounterParry.Track:Stop() end) end
end
end
end
task.wait(KillerExtras.CounterParry.Interval)
end
KillerExtras.CounterParry.Thread = nil
end)
end
task.spawn(function() while true do task.wait(0.2); if KillerExtras.NoSlowdown.Enabled and KE_GetRole() == "Killer" then local char = LP.Character; local hum = char and char:FindFirstChildOfClass("Humanoid"); if hum and hum.WalkSpeed < 16 then hum.WalkSpeed = 16 end end end end)

-- ============================================================
-- MAIN
-- ============================================================
local Purple = Color3.fromRGB(160, 80, 255); local PurpleDark = Color3.fromRGB(65, 25, 120); local Green = Color3.fromRGB(70, 255, 130); local Orange = Color3.fromRGB(255, 190, 100); local Muted = Color3.fromRGB(155, 150, 175)
local DEVELOPER_NAME = "HANX HUB"; local SCRIPT_VERSION = "V2"
local function MainLabel(parent, text, height, color, bold, textSize) return mk("TextLabel", { Size = UDim2.new(1, 0, 0, height or 22), BackgroundTransparency = 1, Text = text, TextColor3 = color or Theme.Text, Font = bold and Theme.FontBold or Theme.Font, TextSize = textSize or 12, TextXAlignment = Enum.TextXAlignment.Left, TextYAlignment = Enum.TextYAlignment.Center, TextWrapped = true, Parent = parent, ZIndex = 15 }) end
local function MainSection(parent, text) return MainLabel(parent, string.upper(text), 19, Muted, true, 10) end
local function MainButton(parent, title, url, accent)
local button = mk("TextButton", { Name = title:gsub("%s+", "") .. "Button", Size = UDim2.new(1, -12, 0, 38), BackgroundColor3 = Color3.fromRGB(28, 24, 38), BorderSizePixel = 0, Text = title .. " ›", TextColor3 = Theme.Text, TextSize = 11, Font = Theme.FontBold, AutoButtonColor = false, Parent = parent, ZIndex = 15 }); corner(button, 8); stroke(button, accent or Purple, 1)
button.MouseEnter:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(48, 34, 65) }):Play() end); button.MouseLeave:Connect(function() TweenService:Create(button, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(28, 24, 38) }):Play() end)
button.MouseButton1Click:Connect(function() local copied = false; if typeof(setclipboard) == "function" then copied = pcall(setclipboard, url) end; pcall(function() StarterGui:SetCore("SendNotification", { Title = "HANX HUB", Text = copied and (title .. " link copied!") or "Clipboard unavailable.", Duration = 3 }) end) end); return button
end

local heroCard = Window:AddCard(TabMain.Page, "✦", "WELCOME")
MainLabel(heroCard, "HANX HUB", 38, Theme.Text, true, 27)
MainLabel(heroCard, "VIOLENCE DISTRICT SCRIPT", 23, Purple, true, 12)
MainLabel(heroCard, "More Power. More Control.", 24, Muted, false, 12)
local statusFrame = mk("Frame", { Size = UDim2.new(1, -12, 0, 42), BackgroundColor3 = Color3.fromRGB(25, 38, 30), BorderSizePixel = 0, Parent = heroCard, ZIndex = 15 }); corner(statusFrame, 8)
local statusDot = mk("Frame", { Size = UDim2.fromOffset(9, 9), Position = UDim2.new(0, 13, 0.5, -4), BackgroundColor3 = Green, BorderSizePixel = 0, Parent = statusFrame, ZIndex = 16 }); corner(statusDot, 9)
mk("TextLabel", { Size = UDim2.new(1, -40, 1, 0), Position = UDim2.fromOffset(30, 0), BackgroundTransparency = 1, Text = "HANX HUB | INTERFACE LOADED", TextColor3 = Green, TextSize = 11, Font = Theme.FontBold, TextXAlignment = Enum.TextXAlignment.Left, Parent = statusFrame, ZIndex = 16 })
MainSection(heroCard, "Script Version"); MainLabel(heroCard, SCRIPT_VERSION, 24, Purple, true, 15)
MainLabel(heroCard, "Welcome to the official HANX HUB interface.", 34, Muted, false, 11)

local playerCard = Window:AddCard(TabMain.Page, "◎", "SESSION")
MainSection(playerCard, "Player"); MainLabel(playerCard, LP.DisplayName, 27, Theme.Text, true, 18); MainLabel(playerCard, "@" .. LP.Name, 19, Muted, false, 11)
MainSection(playerCard, "Current Game"); MainLabel(playerCard, "Violence District", 25, Theme.Text, true, 14)
MainSection(playerCard, "Session Status"); MainLabel(playerCard, "● Connected", 23, Green, true, 12)
MainSection(playerCard, "Community"); MainLabel(playerCard, "HANX HUB Official Community", 28, Muted, false, 11)

local devCard = Window:AddCard(TabMain.Page, "♙", "DEVELOPER")
MainLabel(devCard, DEVELOPER_NAME, 34, Theme.Text, true, 22); MainLabel(devCard, "CREATOR & DEVELOPER", 22, Purple, true, 11)
MainLabel(devCard, "Developing scripts and features for Violence District.", 48, Muted, false, 12)
MainSection(devCard, "Our Mission"); MainLabel(devCard, "Building a better experience for the HANX HUB community.", 48, Theme.Text, false, 12)
MainLabel(devCard, "THANK YOU FOR YOUR SUPPORT!", 27, Green, true, 11)

local socialCard = Window:AddCard(TabMain.Page, "◇", "SOCIAL LINKS")
MainLabel(socialCard, "Follow and join our official community.", 35, Muted, false, 12)
MainButton(socialCard, "DISCORD - JOIN COMMUNITY", "https://discord.gg/Gz5pRBTUx", Color3.fromRGB(88, 101, 242))
MainButton(socialCard, "TIKTOK - FOLLOW DEVELOPER", "https://www.tiktok.com/@whoohnbro_", Color3.fromRGB(70, 70, 80))
MainButton(socialCard, "WHATSAPP - JOIN CHANNEL", "https://whatsapp.com/channel/0029Vb94hQl3LdQTdlkiCf0P", Color3.fromRGB(30, 150, 85))
MainLabel(socialCard, "STAY CONNECTED WITH HANX HUB", 25, Purple, true, 10)

local donateCard = Window:AddCard(TabMain.Page, "♡", "SUPPORT & DONATION")
MainLabel(donateCard, "Enjoying HANX HUB?", 30, Theme.Text, true, 17)
MainLabel(donateCard, "Your support helps us continue developing and improving the project.", 55, Muted, false, 12)
MainButton(donateCard, "DONATE VIA SAWERIA", "https://saweria.co/HANXHUB", PurpleDark)
MainLabel(donateCard, "THANK YOU FOR YOUR SUPPORT!", 28, Orange, true, 11); MainLabel(donateCard, "Every contribution means a lot.", 25, Muted, false, 11)

local infoCard = Window:AddCard(TabMain.Page, "ⓘ", "SCRIPT DETAILS")
MainSection(infoCard, "Project"); MainLabel(infoCard, "HANX HUB", 25, Theme.Text, true, 15)
MainSection(infoCard, "Supported Game"); MainLabel(infoCard, "Violence District", 25, Theme.Text, true, 14)
MainSection(infoCard, "Developer"); MainLabel(infoCard, DEVELOPER_NAME, 25, Theme.Text, true, 14)
MainSection(infoCard, "Version"); MainLabel(infoCard, SCRIPT_VERSION, 25, Purple, true, 15)
MainSection(infoCard, "Community"); MainLabel(infoCard, "HANX HUB OFFICIAL", 25, Muted, true, 11)

-- SURVIVOR FEATURES
local survCard = Window:AddCard(TabSurvivor.Page, "⚡", "Survivor Features")
local function AddSectionDivider(card, title) mk("TextLabel", { Size = UDim2.new(1, 0, 0, 24), BackgroundTransparency = 1, Text = "─── " .. title .. " ───", TextColor3 = Theme.Accent, Font = Theme.FontBold, TextSize = 10, Parent = card, ZIndex = 15 }) end

AddSectionDivider(survCard, "MOVEMENT")
Window:AddToggle(survCard, "Fast Vault", false, function(v) FastVaultEnabled = v end)
Window:AddToggle(survCard, "Auto Vault", false, function(v) AutoVaultEnabled = v end)
Window:AddToggle(survCard, "Auto Pallet Slide", false, function(v) AutoPalletSlideEnabled = v end)

AddSectionDivider(survCard, "PISTOL SETTINGS")
Window:AddToggle(survCard, "Enable Silent Aim Pistol", false, function(v) PistolConfig.Enabled = v end)
Window:AddToggle(survCard, "Laser Garis Pistol", true, function(v) PistolConfig.Laser = v end)
Window:AddToggle(survCard, "Cek Tembok (Wall Check)", false, function(v) PistolConfig.WallCheck = v end)
Window:AddDropdown(survCard, "Target Pistol", {"Killer", "Survivors"}, "Killer", function(v) PistolConfig.TargetMode = v end)

AddSectionDivider(survCard, "SKILL CHECK")
Window:AddToggle(survCard, "Auto Skill Check", false, function(v)
SkillCheckState.Enabled = v
if v then SK_Watch() else
if SkillCheckState.HeartbeatConn then SkillCheckState.HeartbeatConn:Disconnect(); SkillCheckState.HeartbeatConn = nil end
end
end)


local parryCard = Window:AddCard(TabSurvivor.Page, "🛡", "Mimiw Auto Parry")
Window:AddToggle(parryCard, "Enable Auto Parry", false, function(v) AutoParryConfig.Enabled = v end)
Window:AddSlider(parryCard, "Parry Range", 12, 42, 18, function(v) AutoParryConfig.Range = v end)
Window:AddSlider(parryCard, "Parry Delay (ms)", 0, 300, 80, function(v) AutoParryConfig.Delay = v / 1000 end)
Window:AddDropdown(parryCard, "Parry Key", {"F", "Q", "E", "R"}, "F", function(v)
    for i, key in ipairs(AutoParryKeys) do if key[1] == v then AutoParryConfig.KeyIndex = i break end end
end)
Window:AddToggle(parryCard, "Hanya Killer", true, function(v) AutoParryConfig.KillerOnly = v end)
Window:AddToggle(parryCard, "Cek Arah Hadap", true, function(v) AutoParryConfig.Facing = v end)
AddSectionDivider(parryCard, "PALLET SETTINGS")

Window:AddToggle(parryCard, "Auto Drop Pallet", false, function(v)
    AutoPalletEnabled = v
    UsedPallets = setmetatable({}, { __mode = "k" })
    if v and GUI and GUI.Debug then
        GUI.Debug("pallet", "Auto Pallet Enabled.")
    end
end)

Window:AddSlider(parryCard, "Radius Pallet", 5, 30, 15, function(v)
    AutoPalletRadius = v
end)

Window:AddSlider(parryCard, "Cooldown (s)", 0.5, 5, 1.5, function(v)
    AutoPalletCooldown = v
end)

-- KILLER
local killerCard = Window:AddCard(TabKiller.Page, "✂", "Killer Features")
Window:AddToggle(killerCard, "Enable Veil Silent Aim", false, function(v) VeilConfig.Enabled = v end)
Window:AddToggle(killerCard, "Auto Predict", false, function(v) VeilConfig.AutoPredict = v end)
Window:AddToggle(killerCard, "Show Laser Line", true, function(v) VeilConfig.ShowLaser = v end)
Window:AddSlider(killerCard, "Max Distance", 50, 500, 300, function(v) VeilConfig.MaxDist = v end)
Window:AddSlider(killerCard, "FOV (Radius)", 50, 500, 150, function(v) VeilConfig.FOV = v end)
Window:AddDropdown(killerCard, "Target Part", {"Torso", "Head", "Root"}, "Torso", function(v) VeilConfig.TargetPart = v end)

-- Killer Extras
local killerExtraCard = Window:AddCard(TabKiller.Page, "⚙", "Killer Extras")
Window:AddToggle(killerExtraCard, "Auto Stalk", false, function(v)
KillerExtras.AutoStalk.Enabled = v
if v then
if KE_GetRole() ~= "Killer" then KillerExtras.AutoStalk.Enabled = false; return end
KE_StartStalk()
else
KE_StopStalk()
end
end)
Window:AddSlider(killerExtraCard, "Stalk Range", 50, 400, 150, function(v) KillerExtras.AutoStalk.Range = v end)
Window:AddToggle(killerExtraCard, "Counter Auto Parry", false, function(v)
KillerExtras.CounterParry.Enabled = v
if v then
if KE_GetRole() ~= "Killer" then KillerExtras.CounterParry.Enabled = false; return end
KE_StartCounterParry()
else
KE_StopCounterParry()
end
end)
Window:AddSlider(killerExtraCard, "Parry Distance", 5, 30, 15, function(v) KillerExtras.CounterParry.Distance = v end)
Window:AddToggle(killerExtraCard, "No Slowdown Killer", false, function(v) KillerExtras.NoSlowdown.Enabled = v end)

-- VISUAL (ESP)
local espCard = Window:AddCard(TabVisual.Page, "👁", "ESP Settings")
Window:AddToggle(espCard, "Enable ESP", false, function(v)
ESP.Master = v
if v then ScanMap(true); startESPLoop() else ClearAllESP(); if espConn then espConn:Disconnect(); espConn = nil end end
end)
Window:AddSlider(espCard, "ESP Max Distance", 100, 5000, 1000, function(v) ESP.MaxDistance = v end)
Window:AddCheckbox(espCard, "Player ESP", false, Color3.fromRGB(50, 200, 100), function(v) ESP.Player = v end, function(c) ESPColors.Player = c end)
Window:AddCheckbox(espCard, "Killer ESP", false, Color3.fromRGB(255, 50, 50), function(v) ESP.Killer = v end, function(c) ESPColors.Killer = c end)
Window:AddCheckbox(espCard, "ESP Name", false, Color3.fromRGB(255, 255, 255), function(v) ESP.Name = v end)
Window:AddCheckbox(espCard, "ESP Distance", false, Color3.fromRGB(255, 255, 255), function(v) ESP.Distance = v end)

local worldCard = Window:AddCard(TabVisual.Page, "🏆", "World Effects")
Window:AddToggle(worldCard, "Full Bright", false, function(v) game:GetService("Lighting").Brightness = v and 2.8 or 1 end)
Window:AddSlider(worldCard, "Time Of Day", 0, 24, 14, function(v) game:GetService("Lighting").ClockTime = v end)
Window:AddToggle(worldCard, "No Fog", false, function(v) game:GetService("Lighting").FogEnd = v and 100000 or 1000 end)
Window:AddToggle(worldCard, "No Shadow", false, function(v) game:GetService("Lighting").GlobalShadows = not v end)


-- ============================================================
-- ============================================================
-- AUTO PALLET (CHASE + AVAILABILITY STATE)
-- ============================================================
local CollectionService = game:GetService("CollectionService")

AutoPalletEnabled = false
AutoPalletRadius = 15
AutoPalletCooldown = 1.5

local LastDropTime = 0
local PalletCandidates = {}
local PalletScanAt = 0
local PalletScanInterval = 0.75

local function GetKiller()
    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LP and player.Team and player.Team.Name == "Killer" and player.Character then
            local character = player.Character
            local root = character:FindFirstChild("HumanoidRootPart")
            local hum = character:FindFirstChildOfClass("Humanoid")
            if root and hum and hum.Health > 0 then
                return player, character, root
            end
        end
    end
    return nil, nil, nil
end

local function ResolvePallet(candidate)
    if not candidate or not candidate:IsDescendantOf(workspace) then return nil end
    local model = candidate:IsA("Model") and candidate or candidate:FindFirstAncestorOfClass("Model")
    if not model then return nil end

    local hitbox = model:FindFirstChild("hitbox", true)
        or model:FindFirstChild("Hitbox", true)
        or model:FindFirstChild("PrimaryPartPallet", true)
        or model.PrimaryPart

    if hitbox and not hitbox:IsA("BasePart") then
        hitbox = hitbox:FindFirstChildWhichIsA("BasePart", true)
    end
    if not hitbox then hitbox = model:FindFirstChildWhichIsA("BasePart", true) end
    if not hitbox then return nil end

    return { model = model, hitbox = hitbox }
end

local function PalletStateAvailable(data)
    if not data or not data.model or not data.hitbox then return false, false end

    local explicitState = false
    local nodes = { data.model, data.hitbox }

    for _, node in ipairs(nodes) do
        for attribute, value in pairs(node:GetAttributes()) do
            local key = string.lower(tostring(attribute))
            if key == "available" or key == "isavailable" or key == "ready" then
                explicitState = true
                if value == false then return false, true end
            elseif key == "dropped" or key == "isdropped" or key == "used"
                or key == "isused" or key == "palletdown" or key == "isdown" then
                explicitState = true
                if value == true then return false, true end
            elseif key == "palletstate" or key == "state" then
                if type(value) == "string" then
                    local state = string.lower(value)
                    if state:find("drop") or state:find("down") or state:find("used") then
                        return false, true
                    elseif state:find("ready") or state:find("up") or state:find("available") then
                        explicitState = true
                    end
                end
            end
        end
    end

    for _, node in ipairs(data.model:GetDescendants()) do
        if node:IsA("BoolValue") then
            local key = string.lower(node.Name)
            if key == "available" or key == "isavailable" or key == "ready" then
                explicitState = true
                if node.Value == false then return false, true end
            elseif key == "dropped" or key == "isdropped" or key == "used"
                or key == "isused" or key == "palletdown" or key == "isdown" then
                explicitState = true
                if node.Value == true then return false, true end
            end
        end
    end

    return true, explicitState
end

local function RefreshPalletCandidates(force)
    local now = os.clock()
    if not force and now - PalletScanAt < PalletScanInterval then return end
    PalletScanAt = now

    local candidates, seen = {}, {}
    local function addCandidate(instance)
        local data = ResolvePallet(instance)
        if data and not seen[data.model] then
            seen[data.model] = true
            table.insert(candidates, data.model)
        end
    end

    for _, tagged in ipairs(CollectionService:GetTagged("pallet")) do
        addCandidate(tagged)
    end

    local map = workspace:FindFirstChild("Map") or workspace
    for _, obj in ipairs(map:GetDescendants()) do
        local name = string.lower(obj.Name)
        if name == "pallet" or name == "hitbox" or name == "primarypartpallet" then
            addCandidate(obj)
        end
    end

    PalletCandidates = candidates
end

local function FindClosestPallet(myRoot)
    if not myRoot then return nil, math.huge end
    RefreshPalletCandidates(false)

    local closest, closestDist = nil, math.huge
    for _, model in ipairs(PalletCandidates) do
        if model and model.Parent then
            local data = ResolvePallet(model)
            if data then
                local available, hasState = PalletStateAvailable(data)
                if available and UsedPallets[data.model] and hasState then
                    UsedPallets[data.model] = nil
                end

                if available and not UsedPallets[data.model] then
                    local distance = (myRoot.Position - data.hitbox.Position).Magnitude
                    if distance < closestDist then
                        closest, closestDist = data, distance
                    end
                end
            end
        end
    end
    return closest, closestDist
end

local function IsKillerChasing(killerRoot, myRoot, distance)
    if not killerRoot or not myRoot then return false end
    local toPlayer = myRoot.Position - killerRoot.Position
    if toPlayer.Magnitude < 0.1 then return false end

    local direction = toPlayer.Unit
    local velocity = killerRoot.AssemblyLinearVelocity
    local horizontalVelocity = Vector3.new(velocity.X, 0, velocity.Z)
    local horizontalDirection = Vector3.new(direction.X, 0, direction.Z)
    local closingSpeed = horizontalDirection.Magnitude > 0.1
        and horizontalVelocity:Dot(horizontalDirection.Unit) or 0

    local look = killerRoot.CFrame.LookVector
    local horizontalLook = Vector3.new(look.X, 0, look.Z)
    local facingDot = horizontalLook.Magnitude > 0.1 and horizontalDirection.Magnitude > 0.1
        and horizontalLook.Unit:Dot(horizontalDirection.Unit) or -1

    local chaseRange = math.max(12, AutoPalletRadius + 5)
    if distance > chaseRange then return false end
    return closingSpeed >= 1.5 or (horizontalVelocity.Magnitude >= 2.5 and facingDot >= 0.65)
end

local function ExecuteDrop(palletData)
    if not palletData or not palletData.model or not palletData.model.Parent
        or not palletData.hitbox or not palletData.hitbox.Parent then
        return false
    end

    local available = PalletStateAvailable(palletData)
    if not available or UsedPallets[palletData.model] then return false end

    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local palletFolder = remotes and remotes:FindFirstChild("Pallet")
    local dropEvent = palletFolder and palletFolder:FindFirstChild("PalletDropEvent")
    if not dropEvent or not dropEvent:IsA("RemoteEvent") then return false end

    UsedPallets[palletData.model] = true
    local ok = pcall(function()
        dropEvent:FireServer(palletData.hitbox)
    end)
    if not ok then
        UsedPallets[palletData.model] = nil
        return false
    end
    return true
end

task.spawn(function()
    while task.wait(0.1) do
        if not AutoPalletEnabled then continue end

        local _, _, killerRoot = GetKiller()
        local myChar = LP.Character
        local myHum = myChar and myChar:FindFirstChildOfClass("Humanoid")
        local myRoot = myChar and myChar:FindFirstChild("HumanoidRootPart")
        if not killerRoot or not myRoot or not myHum or myHum.Health <= 0 then continue end

        local killerDistance = (killerRoot.Position - myRoot.Position).Magnitude
        if not IsKillerChasing(killerRoot, myRoot, killerDistance) then continue end

        local palletData, playerPalletDistance = FindClosestPallet(myRoot)
        if not palletData or playerPalletDistance > math.max(5, AutoPalletRadius) then continue end

        local killerPalletDistance = (killerRoot.Position - palletData.hitbox.Position).Magnitude
        local palletThreatRange = math.max(8, AutoPalletRadius * 0.8)
        if killerPalletDistance > palletThreatRange then continue end
        if os.clock() - LastDropTime < AutoPalletCooldown then continue end

        if ExecuteDrop(palletData) then
            LastDropTime = os.clock()
        end
    end
end)


pcall(function()
StarterGui:SetCore("SendNotification", { Title = "HANX HUB", Text = "Script Loaded Successfully!", Duration = 5 })
end)
