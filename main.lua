local function clock(secs)
    local timeParts = {
        { word = "week", amount = 604800 },  
        { word = "day", amount = 86400 },  
        { word = "hour", amount = 3600 }, 
        { word = "minute", amount = 60 },  
        { word = "second", amount = 1 } 
    }

    local builtString = {}
    for _, part in ipairs(timeParts) do
        if secs >= part.amount then
            local num = math.floor(secs / part.amount)
            table.insert(builtString, string.format("%d %s%s", num, part.word, num > 1 and "s" or ""))
            secs = secs % part.amount
        end
    end

    return table.concat(builtString, ", ")
end

local function shortNum(input)
    if not input then return "0" end
    input = tonumber(input) or 0
    
    if input < 1000 then
        return tostring(input)
    end

    local endings = {"", "K", "M", "B", "T", "Qd", "Qn", "Sx"}
    local currentEnd = 1

    while input >= 1000 and currentEnd < #endings do
        input = input / 1000
        currentEnd = currentEnd + 1
    end

    return string.format("%.2f%s", input, endings[currentEnd])
end

local function postHook(link, firstCard, secondCard)
    local web = game:GetService("HttpService")
    local config = {
        ["Content-Type"] = "application/json"
    }
    
    local function buildCard(card, fallbackTitle, fallbackDesc)
        local finalCard = {
            title = card.title or fallbackTitle,
            description = card.description or fallbackDesc,
            color = card.color or 3447003,
            thumbnail = {
                url = card.thumbnail and card.thumbnail.url or "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png"
            },
            fields = {},
            footer = {
                text = card.footer and card.footer.text or fallbackTitle,
                icon_url = "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png"
            },
            timestamp = card.timestamp or os.date("!%Y-%m-%dT%H:%M:%S.000Z")
        }
        
        for _, item in ipairs(card.fields or {}) do
            table.insert(finalCard.fields, {
                name = tostring(item.name or ""),
                value = tostring(item.value or ""),
                inline = item.inline ~= false
            })
        end
        
        return finalCard
    end

    local processedFirst = buildCard(firstCard, "Player Stats", "**Player Stats:**")
    local processedSecond = buildCard(secondCard, "Hatch Stats", "**Hatch Stats:**")

    local payload = {
        content = nil,
        embeds = {processedFirst, processedSecond},
        username = "Player Stats",
        avatar_url = "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png",
        attachments = {}
    }

    local encodeOK, jsonPayload = pcall(function()
        local function clean(data)
            if type(data) == "table" then
                local cleaned = {}
                for k, v in pairs(data) do
                    if type(k) == "string" or type(k) == "number" then
                        cleaned[k] = clean(v)
                    end
                end
                return cleaned
            elseif type(data) == "string" or type(data) == "number" or type(data) == "boolean" or data == nil then
                return data
            else
                return tostring(data)
            end
        end
        
        return web:JSONEncode(clean(payload))
    end)

    if not encodeOK then
        warn("JSON Problem:", jsonPayload)
        return false
    end

    local worked, result = pcall(function()
        return request({
            Url = link,
            Method = "POST",
            Headers = config,
            Body = jsonPayload
        })
    end)

    if not worked then
        warn("Request Issue:", result)
        return false
    end

    return true
end


local function playerStats(userData)
    userData = userData or {}
    local numbers = userData.stats or {}
    local hatches = numbers.rarities or {}

    local firstCard = {
        title = "Player Stats",
        color = 3447003,
        fields = {
            {
                name = "🖱️ Clicks",
                value = shortNum(userData.clicks),
                inline = true
            },
            {
                name = "💎 Gems",
                value = shortNum(userData.gems),
                inline = true
            },
            {
                name = "🔄 Rebirths",
                value = shortNum(userData.rebirths),
                inline = true
            },
            {
                name = "🖱️ Total Clicks",
                value = shortNum(numbers.totalClicks),
                inline = true
            },
            {
                name = "💎 Total Gems",
                value = shortNum(numbers.totalGems),
                inline = true
            },
            {
                name = "⏰ Play Time",
                value = clock(tonumber(numbers.timePlayed) or 0),
                inline = true
            }
        },
        footer = {
            text = "Player Stats"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }

    local secondCard = {
        title = "Hatch Stats",
        color = 3447003,
        fields = {
            {
                name = "🥚 Eggs Opened",
                value = shortNum(numbers.eggsOpened),
                inline = true
            },
            {
                name = "🌟 Eternals Hatched",
                value = tostring(hatches.eternal or "0"),
                inline = true
            },
            {
                name = "✨ Mythicals Hatched",
                value = tostring(hatches.mythical or "0"),
                inline = true
            },
            {
                name = "Legendarys Hatched",
                value = tostring(hatches.legendary or "0"),
                inline = true
            }
        },
        footer = {
            text = "Hatch Stats"
        },
        timestamp = os.date("!%Y-%m-%dT%H:%M:%S.000Z")
    }

    return firstCard, secondCard
end


_G.WebhookFunctions = {
    clock = clock,
    shortNum = shortNum,
    postHook = postHook,
    playerStats = playerStats
}
