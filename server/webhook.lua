local BtcCore = exports['btc-core']:GetCore()
local locale = Locale[Config.Locale]


function Webhook(source, action, info)
    local src = source
    local firstname, lastname = BtcCore.framework.getName(src)
    local citizenid = BtcCore.framework.getCitizenID(src)
    local license = BtcCore.framework.getLicense(src)
    local resource = GetCurrentResourceName()
    local title = action

    local embed = {

        {
            ["color"] = Config.WebhookColor,
            ["icon_url"] = Config.UrlIcon,
            ["title"] = title,

            author = {
                name = resource,
                icon_url = Config.UrlIcon,

            },

            thumbnail = {
                url = Config.UrlIconThumb,
            },

            fields = {
                { name = 'Name', value = firstname .. ' ' .. lastname, inline = true },
                { name = "Citizen ID / CID", value = citizenid,                    inline = true },
                { name = 'License/Steam ID', value = license,                        inline = false },
                { name = 'Action', value = info,                         inline = false },

            },

        }
    }

    PerformHttpRequest(Config.WebhookUrl, function(err, text, headers) end, 'POST',
        json.encode({ username = resource, embeds = embed }),
        { ['Content-Type'] = 'application/json' })
end
