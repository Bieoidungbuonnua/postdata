getgenv().ToolNote = "kaigod"

-- Ẩn toàn bộ output
local print = function() end
local warn  = function() end

local req = (syn and syn.request) or (http and http.request) or http_request or request
local url = 'http://160.191.243.153:51234/post'

local function findMob(mobName)
    return workspace.Enemies:FindFirstChild(mobName) or game:GetService('ReplicatedStorage'):FindFirstChild(mobName)
end

function GetPirateRaidMob(x)
    local Mob
    if x then
        for i, v in ipairs(workspace.Enemies:GetChildren()) do
            if v:FindFirstChild("HumanoidRootPart") and v:IsA('Model')
            and (v.HumanoidRootPart.Position - Vector3.new(-5545.9873046875, 314.0802307128906, -2964.34912109375)).magnitude <= 1000
            and not v:GetAttribute('IsBoss') then
                Mob = v
            end
        end
    else
        for i, v in ipairs(game:GetService('ReplicatedStorage'):GetChildren()) do
            if v:FindFirstChild("HumanoidRootPart") and v:IsA('Model')
            and (v.HumanoidRootPart.Position - Vector3.new(-5545.9873046875, 314.0802307128906, -2964.34912109375)).magnitude <= 1000
            and not v:GetAttribute('IsBoss') then
                Mob = v
            end
        end
    end
    return Mob
end

function checkSea(v)
    local map = workspace:GetAttribute("MAP")
    if not map then return false end
    return v == tonumber(tostring(map):match("%d+"))
end

local getMoon = newcclosure(function()
    local tex = checkSea(3)
        and ((game.Lighting:FindFirstChild("Sky") and game.Lighting.Sky.MoonTextureId)
        or (game.Lighting:FindFirstChild("Space_Skybox") and game.Lighting.Space_Skybox.MoonTextureId))
        or ""

    tex = tex:gsub("rbxassetid://", "http://www.roblox.com/asset/?id=")

    return ({
        ["http://www.roblox.com/asset/?id=15493317929"] = "Blue Moon";
        ["http://www.roblox.com/asset/?id=9709149431"] = "8/8";
        ["http://www.roblox.com/asset/?id=9709149052"] = "7/8";
        ["http://www.roblox.com/asset/?id=9709143733"] = "6/8";
        ["http://www.roblox.com/asset/?id=9709150401"] = "5/8";
        ["http://www.roblox.com/asset/?id=9709135895"] = "4/8";
        ["http://www.roblox.com/asset/?id=9709150086"] = "2/8";
        ["http://www.roblox.com/asset/?id=9709139597"] = "1/8";
        ["http://www.roblox.com/asset/?id=9709149680"] = "0/8";
    })[tex] or "nil"
end)

local getMoonPhase = newcclosure(function()
    local moonphase = game.Lighting:GetAttribute("MoonPhase")
    if not moonphase then return "Unknown" end
    if moonphase == 5 and not getgenv().isfmended then
        return "Full Moon"
    end
    return "Normal"
end)

local FULL_CYCLE_CLOCK = 24
local FULL_DAY_REAL = 1200
local NIGHT_START = 18
local NIGHT_END = 6

local function isNight(clock)
    return (clock >= NIGHT_START) or (clock < NIGHT_END)
end

local function getSecondsToNightStart()
    local now = game.Lighting.ClockTime
    if isNight(now) then return 0 end
    local delta = now < NIGHT_START and (NIGHT_START - now) or 0
    return math.floor((delta / FULL_CYCLE_CLOCK) * FULL_DAY_REAL)
end

-- Gửi toàn bộ payload trong 1 request duy nhất, có retry 1 lần
local HttpService = game:GetService("HttpService")
local function sendBatch(payloads)
    if not req then return end
    if #payloads == 0 then return end
    local body = HttpService:JSONEncode(payloads)
    local function doSend()
        local ok, res = pcall(req, {
            Url     = url,
            Method  = "POST",
            Headers = { ["Content-Type"] = "application/json" },
            Body    = body,
            Timeout = 5
        })
        return ok and res and (res.StatusCode == 200 or res.StatusCode == 204)
    end
    if not doSend() then
        task.wait(2)
        pcall(doSend)
    end
end

local postDataIntoServer = function()
    local maxPlayers   = game:GetService('Players').MaxPlayers
    local currentPlayers = #game:GetService('Players'):GetPlayers()
    local playerStr    = `{currentPlayers}/{maxPlayers}`
    local clockTime    = math.floor(game.Lighting.ClockTime)
    local isNightVal   = isNight(game.Lighting.ClockTime)
    local myNote       = getgenv().ToolNote
    local jobId        = tostring(game.JobId)
    local placeId      = game.PlaceId

    local Elite    = {'Diablo', 'Urban', 'Deandre'}
    local RareBoss = {'rip_indra True Form', 'Dough King', 'Cake Prince', 'Soul Reaper', 'Cursed Captain'}

    local batch = {}

    -- 1. Check Elite
    for _, v in ipairs(Elite) do
        if findMob(v) then
            table.insert(batch, {
                ["JobId"] = jobId, ["PlaceId"] = placeId,
                ["Players"] = playerStr, ["ClockTime"] = clockTime,
                ["IsNight"] = isNightVal, ["Type"] = "Elite",
                ["Elite"] = v, ["Note"] = myNote
            })
        end
    end

    -- 2. Check Rare Boss
    for _, v in ipairs(RareBoss) do
        if findMob(v) then
            table.insert(batch, {
                ["JobId"] = jobId, ["PlaceId"] = placeId,
                ["Players"] = playerStr, ["ClockTime"] = clockTime,
                ["IsNight"] = isNightVal, ["Type"] = "Rare Boss",
                ["Rare Boss"] = v, ["Note"] = myNote
            })
        end
    end

    -- 3. Check Castle (Pirate Raid)
    local raidRS  = GetPirateRaidMob()
    local raidWS  = GetPirateRaidMob(true)
    if raidRS and raidWS then
        table.insert(batch, {
            ["JobId"] = jobId, ["PlaceId"] = placeId,
            ["Players"] = playerStr, ["ClockTime"] = clockTime,
            ["IsNight"] = isNightVal, ["Type"] = "Castle",
            ["Note"] = myNote
        })
    end

    -- 4. Check Mirage
    if workspace.Map:FindFirstChild('MysticIsland') then
        table.insert(batch, {
            ["JobId"] = jobId, ["PlaceId"] = placeId,
            ["Players"] = playerStr, ["ClockTime"] = clockTime,
            ["IsNight"] = isNightVal, ["Type"] = "Mirage",
            ["Note"] = myNote, ["timetonight"] = getSecondsToNightStart()
        })
    end

    -- 5. Check Moon
    local moonStatus  = getMoon()
    local phaseStatus = getMoonPhase()
    if moonStatus == "8/8" and phaseStatus == "Full Moon" then
        table.insert(batch, {
            ["JobId"] = jobId, ["PlaceId"] = placeId,
            ["Players"] = playerStr, ["ClockTime"] = clockTime,
            ["IsNight"] = isNightVal, ["Type"] = "Moon",
            ["MoonPhase"] = phaseStatus, ["Note"] = myNote,
            ["timetonight"] = getSecondsToNightStart()
        })
    end

    -- Gửi 1 request duy nhất chứa tất cả data
    sendBatch(batch)
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    local plr = game.Players.LocalPlayer
    -- Chờ GUI tối đa 90 giây, tránh treo mãi mãi
    local waited = 0
    repeat
        task.wait(1)
        waited += 1
    until plr.PlayerGui:FindFirstChild("Main (minimal)") or waited >= 90

    while true do
        pcall(postDataIntoServer)
        task.wait(1)
    end
end)
