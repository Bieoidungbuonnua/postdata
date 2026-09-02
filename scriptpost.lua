getgenv().ToolNote = "trietnam"

local req = (syn and syn.request) or (http and http.request) or http_request or request
local url = 'http://160.191.243.153:51234/post'

local function findMob(mobName)
    return workspace.Enemies:FindFirstChild(mobName) or game:GetService('ReplicatedStorage'):FindFirstChild(mobName)
end

function GetPirateRaidMob()
    for i, v in ipairs(workspace.Enemies:GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and v:IsA('Model')
        and (v.HumanoidRootPart.Position - Vector3.new(-5545.9873046875, 314.0802307128906, -2964.34912109375)).magnitude <= 1000
        and not v:GetAttribute('IsBoss') then
            return v
        end
    end
    for i, v in ipairs(game:GetService('ReplicatedStorage'):GetChildren()) do
        if v:FindFirstChild("HumanoidRootPart") and v:IsA('Model')
        and (v.HumanoidRootPart.Position - Vector3.new(-5545.9873046875, 314.0802307128906, -2964.34912109375)).magnitude <= 1000
        and not v:GetAttribute('IsBoss') then
            return v
        end
    end
    return nil
end

function checkSea(v)
    local mapAttr = workspace:GetAttribute("MAP")
    if not mapAttr then return false end  -- FIX: nil-check trước khi match
    return v == tonumber(mapAttr:match("%d+"))
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

-- Hàm gửi API thuần túy, không có Webhook
local function sendPayload(payload)
    if not req then
        warn("❌ Exploit của bạn không hỗ trợ HTTP Request!")
        return
    end

    local success, err = pcall(function()
        local response = req({
            Url = url,
            Method = "POST",
            Headers = {
                ["Content-Type"] = "application/json"
            },
            Body = game:GetService("HttpService"):JSONEncode(payload)
        })
        
        if response and (response.StatusCode == 200 or response.StatusCode == 204) then
            local detail = payload[payload.Type] and (" (" .. payload[payload.Type] .. ")") or ""
        else
            warn("❌ POST thất bại - " .. payload.Type .. " | HTTP Code: " .. tostring(response and response.StatusCode or "Unknown"))
        end
    end)
    
    if not success then
        warn("❌ Lỗi mạng khi thực hiện gửi dữ liệu: " .. tostring(err))
    end
end

local postDataIntoServer = function()
    local maxPlayers = game:GetService('Players').MaxPlayers
    local currentPlayers = #game:GetService('Players'):GetPlayers()
    local playerStr = `{currentPlayers}/{maxPlayers}`
    local clockTime = math.floor(game.Lighting.ClockTime)
    local isNightVal = isNight(game.Lighting.ClockTime)

    local Elite = {'Diablo', 'Urban', 'Deandre'}
    local RareBoss = {'rip_indra True Form', 'Dough King', 'Cake Prince', 'Soul Reaper', 'Cursed Captain'}
    local myNote = getgenv().ToolNote

    -- 1. Check Elite
    for i, v in ipairs(Elite) do
        if findMob(v) then
            local payload = {
                ["JobId"] = tostring(game.JobId),
                ["PlaceId"] = game.PlaceId,
                ["Players"] = playerStr,
                ["ClockTime"] = clockTime,
                ["IsNight"] = isNightVal,
                ["Type"] = "Elite",
                ["Elite"] = v,
                ["Note"] = myNote
            }
            sendPayload(payload)
        end
    end

    -- 2. Check Rare Boss
    for i, v in ipairs(RareBoss) do
        if findMob(v) then
            local payload = {
                ["JobId"] = tostring(game.JobId),
                ["PlaceId"] = game.PlaceId,
                ["Players"] = playerStr,
                ["ClockTime"] = clockTime,
                ["IsNight"] = isNightVal,
                ["Type"] = "Rare Boss",
                ["Rare Boss"] = v,
                ["Note"] = myNote
            }
            sendPayload(payload)
        end
    end

    -- 3. Check Castle (Pirate Raid)
    if GetPirateRaidMob() then
        local payload = {
            ["JobId"] = tostring(game.JobId),
            ["PlaceId"] = game.PlaceId,
            ["Players"] = playerStr,
            ["ClockTime"] = clockTime,
            ["IsNight"] = isNightVal,
            ["Type"] = "Castle",
            ["Note"] = myNote
        }
        sendPayload(payload)
    end

    -- 4. Check Mirage
    if workspace.Map:FindFirstChild('MysticIsland') then
        local payload = {
            ["JobId"] = tostring(game.JobId),
            ["PlaceId"] = game.PlaceId,
            ["Players"] = playerStr,
            ["ClockTime"] = clockTime,
            ["IsNight"] = isNightVal,
            ["Type"] = "Mirage",
            ["Note"] = myNote,
            ["timetonight"] = getSecondsToNightStart()
        }
        sendPayload(payload)
    end

    -- 5. Check Moon
    local moonStatus = getMoon()
    local phaseStatus = getMoonPhase()
    
    if moonStatus == "8/8" and phaseStatus == "Full Moon" then
        local payload = {
            ["JobId"] = tostring(game.JobId),
            ["PlaceId"] = game.PlaceId,
            ["Players"] = playerStr,
            ["ClockTime"] = clockTime,
            ["IsNight"] = isNightVal,
            ["Type"] = "Moon",
            ["MoonPhase"] = phaseStatus,
            ["Note"] = myNote,
            ["timetonight"] = getSecondsToNightStart()
        }
        sendPayload(payload)
    end
end
    while wait(1) do
        postDataIntoServer()
    end
