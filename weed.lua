local hs = game:GetService("HttpService")
local tp = game:GetService("TeleportService")
local plrs = game:GetService("Players")
local lp = plrs.LocalPlayer
local ws = game:GetService("Workspace")

local url = "https://discord.com/api/webhooks/1402083315334385704/U33lLch0wDtDfjR3M7NZgm_ZRXhj-yRS8R2zMF_YibQiDevjjhc5g9Fl4V5gtTwGs2G_"
local pid = game.PlaceId
local jid = game.JobId
local uname = lp.Name

local an = {
    ["Pot Hotspot"] = true, 
    ["Torrtuginni Dragonfrutini"] = true, 
    ["Garama and Madundung"] = true, 
    ["La Grande Combinasion"] = true, 
    ["Graipuss Medussi"] = true,
    ["Las Tralaleritas"] = true, 
    ["Los Tralaleritos"] = true, 
    ["Sammyni Spiderini"] = true,
    ["La Vacca Saturno Saturnita"] = true,
    ["Secret Lucky Block"] = true,
    ["Chimpanzini Spiderini"] = true,
    ["Los Combinasionas"] = true,
    ["Nuclearo Dinossauro"] = true,
    ["Dragon Cannelloni"] = true,
    ["Chicleteira Bicicleteira"] = true,
    ["Las Vaquitas Saturnitas"] = true,
    ["Agarrini la Palini"] = true
}

local function SendMessageEMBED(url, embed)
    local data = {
        ["embeds"] = {
            {
                ["title"] = embed.title,
                ["description"] = embed.description,
                ["color"] = embed.color,
                ["fields"] = embed.fields,
                ["footer"] = {
                    ["text"] = embed.footer.text
                },
                ["image"] = embed.image and { url = embed.image } or nil
            }
        }
    }
    local body = hs:JSONEncode(data)
    local response = (request or http_request or syn.request)({
        Url = url,
        Method = "POST",
        Headers = { ["Content-Type"] = "application/json" },
        Body = body
    })
end

local fa = {}

for _, p in pairs(ws.Plots:GetChildren()) do
    local ap = p:FindFirstChild("AnimalPodiums")
    if ap then
        for _, pd in pairs(ap:GetChildren()) do
            local oh = pd:FindFirstChild("Base")
                and pd.Base:FindFirstChild("Spawn")
                and pd.Base.Spawn:FindFirstChild("Attachment")
                and pd.Base.Spawn.Attachment:FindFirstChild("AnimalOverhead")

            if oh and oh:IsA("BillboardGui") then
                local dn = oh:FindFirstChild("DisplayName")
                local gen = oh:FindFirstChild("Generation")
                local mut = oh:FindFirstChild("Mutation")
                local rar = oh:FindFirstChild("Rarity")

                if dn and an[dn.Text] then
                    table.insert(fa, {
                        dn = dn.Text,
                        gen = gen and gen.Text or "Unknown",
                        mut = "?",
                        rar = rar and rar.Text or "Unknown"
                    })
                end
            end
        end
    end
end

if #fa > 0 then
    local dsc = {}
    for _, a in ipairs(fa) do
        local line = string.format("💫 %s - %s - %s%s", a.dn, a.gen, a.rar, a.mut and (" - " .. a.mut) or "")
        table.insert(dsc, line)
    end

    local pn = {}
    for _, p in ipairs(plrs:GetPlayers()) do
        table.insert(pn, p.Name)
    end

    local embed = {
        title = "artifact detected a secret brainrot!",
        description = table.concat(dsc, "\n"),
        color = 16753920,
        fields = {
            {
                name = "Teleport Script",
                value = string.format("```lua\ngame:GetService(\"TeleportService\"):TeleportToPlaceInstance(%d, \"%s\", game.Players.LocalPlayer)\n```", pid, jid)
            },
            {
                name = "Server ID",
                value = string.format("```%s```", jid)
            },
            {
                name = "Players",
                value = string.format("%d / %d\n%s", #plrs:GetPlayers(), plrs.MaxPlayers, table.concat(pn, ", "))
            },
            {
                name = "Account Name",
                value = uname
            },
            {
                name = "Script Version",
                value = "v1.0 beta"
            }
        },
        footer = { text = "artifact notifier, discord.gg/robloxskeet" },
    }

    SendMessageEMBED(url, embed)
end


local function hop()
    local srvs, c, jidNow = {}, "", game.JobId

    while c ~= nil and task.wait(0.3) do
        local r = (request or http_request or syn.request)({
            Url = ("https://games.roblox.com/v1/games/%d/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true&cursor=%s"):format(pid, c),
            Method = "GET"
        })

        if r and r.Success then
            local d = hs:JSONDecode(r.Body)
            for _, s in ipairs(d.data) do
                if tonumber(s.playing) < 7 and s.id ~= jidNow then
                    table.insert(srvs, s.id)
                end
            end
            c = d.nextPageCursor
            if #srvs > 0 then break end
        else
            break
        end
    end

    if #srvs > 0 then
        local t = srvs[math.random(1, #srvs)]
        queue_on_teleport([[
            loadstring(game:HttpGet("https://raw.githubusercontent.com/nfnato/web/refs/heads/main/weed.lua"))()
        ]])
        tp:TeleportToPlaceInstance(pid, t, lp)
    end
end

task.spawn(function()
    while task.wait(1) do
        hop()
    end
end)
