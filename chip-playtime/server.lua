-- Playtime tracking table
local playtimeData = {}

-- Ensure oxmysql is available
local oxmysql = exports.oxmysql

-- Create table if not exists
local function ensureTable()
    oxmysql:execute([[CREATE TABLE IF NOT EXISTS playtime (
        identifier VARCHAR(64) PRIMARY KEY,
        seconds INT NOT NULL
    )]], {}, function() end)
end

ensureTable()

-- Load playtime for a player
local function loadPlaytime(identifier, cb)
    oxmysql:execute('SELECT seconds FROM playtime WHERE identifier = ?', {identifier}, function(result)
        if result and result[1] then
            cb(result[1].seconds)
        else
            cb(0)
        end
    end)
end

-- Save playtime for a player
local function savePlaytime(identifier, seconds)
    oxmysql:execute('INSERT INTO playtime (identifier, seconds) VALUES (?, ?) ON DUPLICATE KEY UPDATE seconds = ?', {identifier, seconds, seconds})
end

-- Helper to get player identifier (license preferred)
local function getIdentifier(source)
    local identifiers = GetPlayerIdentifiers(source)
    for _, id in ipairs(identifiers) do
        if string.find(id, "license:") then
            return id
        end
    end
    return identifiers[1] or ("src:"..tostring(source))
end

-- On player connecting, start tracking
AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
    local src = source
    local identifier = getIdentifier(src)
    loadPlaytime(identifier, function(seconds)
        playtimeData[identifier] = { seconds = seconds, lastJoin = os.time() }
    end)
end)

-- On player dropped, update playtime
AddEventHandler('playerDropped', function(reason)
    local src = source
    local identifier = getIdentifier(src)
    if playtimeData[identifier] and playtimeData[identifier].lastJoin then
        local session = os.time() - playtimeData[identifier].lastJoin
        playtimeData[identifier].seconds = playtimeData[identifier].seconds + session
        playtimeData[identifier].lastJoin = nil
        savePlaytime(identifier, playtimeData[identifier].seconds)
    end
end)

-- Every minute, add 60 seconds to online players
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(60000)
        for _, playerId in ipairs(GetPlayers()) do
            local identifier = getIdentifier(playerId)
            if playtimeData[identifier] then
                playtimeData[identifier].seconds = playtimeData[identifier].seconds + 60
                savePlaytime(identifier, playtimeData[identifier].seconds)
            end
        end
    end
end)

-- Format seconds to H:M:S
local function formatPlaytime(seconds)
    local h = math.floor(seconds / 3600)
    local m = math.floor((seconds % 3600) / 60)
    local s = seconds % 60
    return string.format("%02dh %02dm %02ds", h, m, s)
end

-- /playtime command
RegisterCommand('playtime', function(source)
    local identifier = getIdentifier(source)
    local data = playtimeData[identifier]
    if not data then
        TriggerClientEvent("chat:addMessage", source, { args = {"Playtime", "No playtime data found."} })
        return
    end
    -- Update playtime for current session
    local totalSeconds = data.seconds
    if data.lastJoin then
        totalSeconds = totalSeconds + (os.time() - data.lastJoin)
    end
    local playerName = GetPlayerName(source) or "Player"
    local playtimeStr = formatPlaytime(totalSeconds)
    local msg = playerName.." has played for "..playtimeStr
    -- Send to Discord webhook with embed
    if Config.PlaytimeWebhook and Config.PlaytimeWebhook ~= "" then
        local embed = {
            {
                title = "Player Playtime",
                color = 5814783, -- blue-ish
                thumbnail = { url = "https://r2.fivemanage.com/kcxNcBMlF4V8Xn7vubTR3/96_x_96_pixels.png" },
                fields = {
                    { name = "Player", value = playerName, inline = true },
                    { name = "Playtime", value = playtimeStr, inline = true }
                },
                timestamp = os.date('!%Y-%m-%dT%H:%M:%SZ')
            }
        }
        PerformHttpRequest(Config.PlaytimeWebhook, function(err, text, headers) end, 'POST', json.encode({
            username = "Playtime Tracker",
            avatar_url = "https://r2.fivemanage.com/kcxNcBMlF4V8Xn7vubTR3/96_x_96_pixels.png",
            embeds = embed
        }), { ['Content-Type'] = 'application/json' })
    end
    -- Also show in chat
    TriggerClientEvent("chat:addMessage", source, { args = {"Playtime", msg} })
end, false)
