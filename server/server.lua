local BtcCore = exports['btc-core']:GetCore()
local locale = Locale[Config.Locale]

RegisterNetEvent('btc-craft:removeItems')
AddEventHandler('btc-craft:removeItems', function(recipe, quantity)
    local src = source
    local duration = 1000

    for k, v in pairs(BTC_CRAFT_RECIPES) do
        if recipe == v.id then
            duration = v.duration * quantity
            for type, _ in pairs(v) do
                if type == 'required_items' then
                    for index, item in pairs(_) do
                        local useItem = item.item
                        local itemType = item.type or 'item'
                        local amount = item.amount * quantity
                        local itemRemove = BtcCore.framework.removeItem(src, useItem, amount, itemType)
                        local itemLabel = BtcCore.framework.getItemLabel(useItem, itemType)
                        if not itemRemove then
                            Notify(locale[2] .. ' x' .. amount .. ' ' .. itemLabel, 5000, "error", src)
                            TriggerClientEvent('btc-craft:setCrafting', src)
                            return
                        end
                    end
                end
            end
            break
        end
    end

    Citizen.Wait(duration)

    for k, v in pairs(BTC_CRAFT_RECIPES) do
        if recipe == v.id then
            for type, item in pairs(v) do
                if type == 'output' then
                    local useItem = item.item
                    local amount = item.amount * quantity
                    local itemType = item.type or 'item'
                    local itemAdd = BtcCore.framework.addItem(src, useItem, amount, itemType)
                    local itemLabel = BtcCore.framework.getItemLabel(useItem, itemType)
                    Webhook(src, locale[6], 'x'..amount..' '..itemLabel)
                    if not itemAdd then
                        Notify(locale[2] .. ' ' .. itemLabel, 5000, "error", src)
                        TriggerClientEvent('btc-craft:setCrafting', src)
                        return
                    elseif itemAdd then
                        Notify(locale[3] .. ' x' .. amount .. ' ' .. itemLabel, 5000, "success", src)
                        TriggerClientEvent('btc-craft:setCrafting', src)
                        return
                    end
                end
            end
            break
        end
    end
end)

------------------------ callbacks
BtcCore.callback.register('btc-craft:getJob', function(source, cb)
    local src = source
    local job = BtcCore.framework.getJob(src)
    return cb(job)
end)

BtcCore.callback.register('btc-craft:canAdd', function(source, cb, item, amount, type)
    local src = source
    local can = BtcCore.framework.canAddItem(src, item, amount, type)
    return cb(can)
end)
