-- WebhookHandler.lua (Pastebin/GitHub content)
local WebhookHandler = {}
WebhookHandler.__index = WebhookHandler

function WebhookHandler.new()
    local self = setmetatable({}, WebhookHandler)
    self.remoteEvent = ReplicatedStorage.Shared.Framework.Network.Remote.Event
    self._enabled = false  
    self._connection = nil
    return self 
end

function WebhookHandler:initialize()
    self.remoteEvent.OnClientEvent:Connect(function(...)
        self:handleEvent(...)
    end)
end

function WebhookHandler:handleEvent(...)
    local args = {...}
    if args[1] == "HatchEgg" and typeof(args[2]) == "table" then
        self:processHatchEggEvent(args[2])
    end
end

function WebhookHandler:processHatchEggEvent(data)
    for _, petData in ipairs(data.Pets or {}) do
        self:checkLegendary(petData.Pet)
    end
end

function WebhookHandler:checkLegendary(pet)
    if pet and pet.Name and table.find(LegendaryPets, pet.Name) then
        self:sendWebhook(pet)
    end
end

function WebhookHandler:turnOn()
    if not self._connection then
        self:initialize()
    end
    self._enabled = true
    return true
end

function WebhookHandler:turnOff()
    self._enabled = false
    if self._connection then
        self._connection:Disconnect()
        self._connection = nil
    end
    return true
end

function WebhookHandler:isEnabled()
    return self._enabled
end

function WebhookHandler:sendWebhook(petData)
    local petInfo = Pets[petData.Name]
    if not petInfo then return end

    local url = _G.WebhookURL or ""
    if not string.find(url, "http") then
        warn("[Pet Tracker] Invalid Webhook URL!")
        return
    end

    local image = settings.show_pet_picture and getImageThumbnail(petInfo.Images.Normal) or nil
    local player = Players.LocalPlayer
    local stats, data = getStats()
    local chanceText = FormatChance(petData)
    local discoveryCount = getPetDiscoveryCount(petData.Name)
    local timesHatchedText = discoveryCount > 0
            and string.format(" %d %s", discoveryCount, discoveryCount == 1 and "time" or "times")
        or " (First time!)"

    local content = ""
    if settings.enable_ping and settings.ping_type ~= "None" then
        content = settings.ping_type
    end

    local embed = {
        title = "✨・New Pet Hatched!・✨",
        description = string.format("%s just hatched a **%s** **%s**!", 
            player.Name, petInfo.Rarity, petData.Name),
        color = 0x9B59B6, 
        fields = {{
            name = "Pet Details: ",
            value = string.format("**📝 Name:** %s\n**🎨  Chance:** %s\n🐣 ** Hatched:** %s", 
                petData.Name, tostring(chanceText), timesHatchedText),
            inline = false
        }},
        footer = { 
            text = "hatsune.lua • discord.gg/CaDymGbhQj  - " .. os.date("%m/%d/%Y %I:%M %p")
        }
    }

    if settings.show_user_data then
        table.insert(embed.fields, {
            name = "📊 Player Stats:",
            value = string.format("💎 ・ **Gems:** %s\n📦 ・ **Pets:** %s\n⌛ ・ **Playtime:** %s\n🥚 ・ **Hatches:** %s\n🫧 ・ **Bubbles:** %s",
                convertToShorter(data.Gems or 0, "bubbles"),
                convertToShorter(#data.Pets or 0, "hatches"),
                stats.playTime, stats.hatches, stats.bubbles),
            inline = false
        })
    end

    if image then
        embed.thumbnail = { url = image }  
    end

    local payload = {
        content = content,  
        username = "hatsune.lua",
        avatar_url = "",
        embeds = { embed }
    }

    local json = HttpService:JSONEncode(payload)
    local req = http_request or request or HttpPost or syn.request
    req({
        Url = url,
        Method = "POST",
        Headers = {["Content-Type"] = "application/json"},
        Body = json
    })
end

return WebhookHandler
