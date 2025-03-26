local function clock(secs)
    local timeParts = {
        { word = "week", amount = 604800 },  
        { word = "day", amount = 86400 },  
        { word = "hour", amount = 3600 }, 
        { word = "minute", amount = 60 },  
        { word = "second", amount = 1 } 
    }

    local bs = {}
    for _, part in ipairs(timeParts) do
        if secs >= part.amount then
            local num = math.floor(secs / part.amount)
            table.insert(bs, string.format("%d %s%s", num, part.word, num > 1 and "s" or ""))
            secs = secs % part.amount
        end
    end

    return table.concat(bs, ", ")
end

local function sn(input)
    if not input then return "0" end
    input = tonumber(input) or 0
    
    if input < 1000 then
        return tostring(input)
    end

    local ends = {"", "K", "M", "B", "T", "Qd", "Qn", "Sx"}
    local ce = 1

    while input >= 1000 and ce < ends do
        input = input / 1000
        ce = ce + 1
    end

    return string.format("%.2f%s", input, ends[ce])
end

local function ph(link, fc, sc)
    local web = game:GetService("HttpService")
    local config = {
        ["Content-Type"] = "application/json"
    }
    
    local function bc(card, fbt, fbd)
        local finalCard = {
            title = card.title or fbt,
            description = card.description or fbd,
            color = card.color or 3447003,
            thumbnail = {
                url = card.thumbnail and card.thumbnail.url or "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png"
            },
            fields = {},
            footer = {
                text = card.footer and card.footer.text or fbt,
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

    local pf = bc(fc, "Player Stats", "**Player Stats:**")
    local ps = bc(sc, "Hatch Stats", "**Hatch Stats:**")

    local payload = {
        content = nil,
        embeds = {pf, ps},
        username = "Player Stats",
        avatar_url = "https://cdn.discordapp.com/attachments/1342961019193921638/1353058260877447178/ggh.png",
        attachments = {}
    }

    local eo, jp = pcall(function()
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

    if not eo then
        warn("JSON Problem:", jp)
        return false
    end

    local worked, result = pcall(function()
        return request({
            Url = link,
            Method = "POST",
            Headers = config,
            Body = jp
        })
    end)

    if not worked then
        warn("Request Issue:", result)
        return false
    end

    return true
end


local function ps(ua)
    ua = ua or {}
    local numbers = ua.stats or {}
    local hatches = numbers.rarities or {}

    local fc = {
        title = "Player Stats",
        color = 3447003,
        fields = {
            {
                name = "🖱️ Clicks",
                value = sn(ua.clicks),
                inline = true
            },
            {
                name = "💎 Gems",
                value = sn(ua.gems),
                inline = true
            },
            {
                name = "🔄 Rebirths",
                value = sn(ua.rebirths),
                inline = true
            },
            {
                name = "🖱️ Total Clicks",
                value = sn(numbers.totalClicks),
                inline = true
            },
            {
                name = "💎 Total Gems",
                value = sn(numbers.totalGems),
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

    local sc = {
        title = "Hatch Stats",
        color = 3447003,
        fields = {
            {
                name = "🥚 Eggs Opened",
                value = sn(numbers.eggsOpened),
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

    return fc, sc
end


_G.WebhookFunctions = {
    clock = clock,
    sn = sn,
    ph = ph,
    ps = ps
}
