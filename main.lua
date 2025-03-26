local function formatTimePlayed(seconds)
    local timeUnits = {
        { name = "week", value = 604800 },  
        { name = "day", value = 86400 },  
        { name = "hour", value = 3600 }, 
        { name = "minute", value = 60 },  
        { name = "second", value = 1 } 
    }

    local result = {}
    for _, unit in ipairs(timeUnits) do
        if seconds >= unit.value then
            local count = math.floor(seconds / unit.value)
            table.insert(result, string.format("%d %s%s", count, unit.name, count > 1 and "s" or ""))
            seconds = seconds % unit.value
        end
    end

    return table.concat(result, ", ")
end

local function discordabbreavite(number)
    if not number then return "0" end
    number = tonumber(number) or 0
    
    if number < 1000 then
        return tostring(number)
    end

    local suffixes = {"", "K", "M", "B", "T", "Qd", "Qn", "Sx"}
    local suffixIndex = 1

    while number >= 1000 and suffixIndex < #suffixes do
        number = number / 1000
        suffixIndex = suffixIndex + 1
    end

    return string.format("%.2f%s", number, suffixes[suffixIndex])
end

local function SendMessageEMBED(url, embed1, embed2)
    local http = game:GetService("HttpService")
    local headers = {
        ["Content-Type"] = "application/json"
    }
    
    local function createEmbed(embed, defaultTitle, defaultDescription)
        local cleanEmbed = {
            title = embed.title or defaultTitle,
            description = embed.description or defaultDescription,
            color = embed.color or 3447003,
            thumbnail = {
                url = embed.thumbnail and embed.thumbnail.url or "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png"
            },
            fields = {},
            footer = {
                text = embed.footer and embed.footer.text or defaultTitle,
                icon_url = "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png"
            },
            timestamp = embed.timestamp or os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }
        
        for _, field in ipairs(embed.fields or {}) do
            table.insert(cleanEmbed.fields, {
                name = tostring(field.name or ""),
                value = tostring(field.value or ""),
                inline = field.inline ~= false
            })
        end
        
        return cleanEmbed
    end

    local processedEmbed1 = createEmbed(embed1, "Player Statistics", "**Player Statistics:**")
    local processedEmbed2 = createEmbed(embed2, "Hatching Analytics", "**Hatching Analytics:**")

    local data = {
        content = nil,
        embeds = {processedEmbed1, processedEmbed2},
        username = "Player Statistics",
        avatar_url = "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png",
        attachments = {}
    }

    local jsonSuccess, jsonData = pcall(function()
        local function sanitize(obj)
            if type(obj) == "table" then
                local sanitized = {}
                for k, v in pairs(obj) do
                    if type(k) == "string" or type(k) == "number" then
                        sanitized[k] = sanitize(v)
                    end
                end
                return sanitized
            elseif type(obj) == "string" or type(obj) == "number" or type(obj) == "boolean" or obj == nil then
                return obj
            else
                return tostring(obj)
            end
        end
        
        return http:JSONEncode(sanitize(data))
    end)

    if not jsonSuccess then
        warn("JSON Encoding Failed:", jsonData)
        return false
    end

    local success, response = pcall(function()
        return request({
            Url = url,
            Method = "POST",
            Headers = headers,
            Body = jsonData
        })
    end)

    if not success then
        warn("Request Failed:", response)
        return false
    end

    return true
end


local function fpdata(playerData)
    playerData = playerData or {}
    local stats = playerData.stats or {}
    local rarities = stats.rarities or {}

    local embed1 = {
        title = "Player Statistics",
        color = 3447003,
        fields = {
            {
                name = "🖱️ Clicks",
                value = discordabbreavite(playerData.clicks),
                inline = true
            },
            {
                name = "💎 Gems",
                value = discordabbreavite(playerData.gems),
                inline = true
            },
            {
                name = "🔄 Rebirths",
                value = discordabbreavite(playerData.rebirths),
                inline = true
            },
            {
                name = "🖱️ Total Clicks",
                value = discordabbreavite(stats.totalClicks),
                inline = true
            },
            {
                name = "💎 Total Gems",
                value = discordabbreavite(stats.totalGems),
                inline = true
            },
            {
                name = "⏰ Time Played",
                value = formatTimePlayed(tonumber(stats.timePlayed) or 0),
                inline = true
            }
        },
        footer = {
            text = "Player Statistics"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }

    local embed2 = {
        title = "Hatching Statistics",
        color = 3447003,
        fields = {
            {
                name = "🥚 Eggs Opened",
                value = discordabbreavite(stats.eggsOpened),
                inline = true
            },
            {
                name = "🌟 Eternals Hatched",
                value = tostring(rarities.eternal or "0"),
                inline = true
            },
            {
                name = "✨ Mythicals Hatched",
                value = tostring(rarities.mythical or "0"),
                inline = true
            },
            {
                name = "Legendarys Hatched",
                value = tostring(rarities.legendary or "0"),
                inline = true
            }
        },
        footer = {
            text = "Hatching Statistics"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }

    return embed1, embed2
end


_G.WebhookFunctions = {
    formatTimePlayed = formatTimePlayed,
    discordabbreavite = discordabbreavite,
    SendMessageEMBED = SendMessageEMBED,
    fpdata = fpdata
}
