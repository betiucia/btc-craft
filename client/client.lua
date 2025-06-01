local BtcCore = exports['btc-core']:GetCore()
local locale = Locale[Config.Locale]
local inCrafting = false
local managedProps = {} -- Tabela para gerenciar props: key = tableId, value = prop handle ou 'loading'
local currentOpenedCraftTable = nil

-- [[ Funções Auxiliares para Props por Proximidade ]]

local function CreatePropForTable(tableId, tableData)
    if not tableData.prop_model or managedProps[tableId] then return end -- Só cria se tiver modelo e não estiver já gerenciado

    local modelHash = GetHashKey(tableData.prop_model)
    managedProps[tableId] = 'loading' -- Marca como carregando
    if Config.Debug then print(('[btc-craft] Requisitando modelo %s para mesa %s'):format(tableData.prop_model, tableId)) end

    Citizen.CreateThread(function()
        -- Bloco para requisitar modelo (como você ajustou e funcionou)
        RequestModel(modelHash) -- Requisita o modelo
        while not HasModelLoaded(modelHash) do
            Wait(10)            -- Espera carregar (Wait(0) ou Wait(10) são comuns aqui)
        end
        -- Fim do bloco para requisitar modelo

        -- Verifica se ainda devemos criar (jogador pode ter se afastado ou modelo falhou - redundância)
        -- Adicionamos uma verificação extra de HasModelLoaded aqui por segurança
        if not HasModelLoaded(modelHash) or managedProps[tableId] ~= 'loading' then
            if managedProps[tableId] == 'loading' then managedProps[tableId] = nil end
            -- Não precisamos mais do SetModelAsNoLongerNeeded aqui se falhou, pois não foi criado
            if Config.Debug and HasModelLoaded(modelHash) then
                print(('[btc-craft] Criação cancelada para mesa %s (jogador afastou-se)')
                    :format(tableId))
            end
            if Config.Debug and not HasModelLoaded(modelHash) then
                print(('[btc-craft] Criação cancelada para mesa %s (modelo não carregou)')
                    :format(tableId))
            end
            -- Libera o modelo se ele carregou mas a criação foi cancelada por outro motivo
            if HasModelLoaded(modelHash) then SetModelAsNoLongerNeeded(modelHash) end
            return
        end

        local coords = tableData.pos
        local heading = tableData.prop_heading or 0.0
        local prop = CreateObject(modelHash, coords.x, coords.y, coords.z, true, true, false) -- Cria o objeto

        -- Verifica se o prop foi criado com sucesso
        if prop and prop ~= 0 then
            SetEntityHeading(prop, heading) -- Define a rotação

            -- [[ Adiciona esta linha para colocar o objeto no chão ]]
            PlaceObjectOnGroundProperly(prop)

            FreezeEntityPosition(prop, true) -- Congela no lugar (após ajustar ao chão)

            managedProps[tableId] = prop     -- Armazena o handle do prop
            if Config.Debug then
                print(('[btc-craft] Prop %s criado e posicionado para mesa %s (Handle: %s)'):format(
                    tableData.prop_model, tableId, prop))
            end
        else
            if Config.Debug then
                print(('[btc-craft] Falha ao criar o objeto %s para mesa %s após carregar modelo.')
                    :format(tableData.prop_model, tableId))
            end
            managedProps[tableId] = nil -- Limpa o status se a criação falhou
        end

        -- Libera o modelo da memória APÓS o objeto ser criado (ou falhar)
        SetModelAsNoLongerNeeded(modelHash)
    end)
end

local function DeletePropForTable(tableId)
    local prop = managedProps[tableId]
    if prop and prop ~= 'loading' then
        managedProps[tableId] = nil -- Remove da tabela de gerenciamento ANTES de deletar

        -- Precisamos garantir que a entidade ainda existe e temos controle sobre ela
        if DoesEntityExist(prop) then
            if NetworkHasControlOfEntity(prop) then
                DeleteEntity(prop)
                if Config.Debug then print(('[btc-craft] Prop deletado para mesa %s (Handle: %s)'):format(tableId, prop)) end
            else
                -- Tenta obter controle antes de deletar
                NetworkRequestControlOfEntity(prop)
                local attempts = 0
                Citizen.CreateThread(function()
                    while not NetworkHasControlOfEntity(prop) and attempts < 10 do -- Tenta por 1 segundo
                        Wait(100)
                        attempts = attempts + 1
                    end
                    if DoesEntityExist(prop) and NetworkHasControlOfEntity(prop) then
                        DeleteEntity(prop)
                        if Config.Debug then
                            print(('[btc-craft] Prop deletado para mesa %s após obter controle (Handle: %s)')
                                :format(tableId, prop))
                        end
                    elseif DoesEntityExist(prop) then
                        SetEntityAsNoLongerNeeded(prop) -- Alternativa se não conseguir controle
                        if Config.Debug then
                            print(('[btc-craft] Falha ao obter controle, marcando prop como não necessário para mesa %s (Handle: %s)')
                                :format(tableId, prop))
                        end
                    end
                end)
            end
        else
            if Config.Debug then
                print(('[btc-craft] Tentativa de deletar prop para mesa %s falhou (Handle: %s, Entidade não existe mais)')
                    :format(tableId, prop))
            end
        end
    elseif prop == 'loading' then
        managedProps[tableId] = nil -- Se estava carregando, apenas cancela
        if Config.Debug then print(('[btc-craft] Cancelado carregamento de prop para mesa %s'):format(tableId)) end
    end
end

-- [[ Loop Principal de Proximidade ]]
Citizen.CreateThread(function()
    if not Config.EnableProximityProps then return end -- Sai se a funcionalidade estiver desativada

    while true do
        Wait(Config.ProximityCheckInterval or 1500) -- Espera o intervalo definido

        local playerPed = PlayerPedId()
        if not playerPed or playerPed == -1 then goto continue end -- Pula se o jogador não estiver válido

        local playerCoords = GetEntityCoords(playerPed)

        -- Itera sobre todas as mesas definidas
        for tableId, tableData in pairs(BTC_CRAFT_TABLES) do
            if tableData.pos and tableData.prop_model then       -- Processa apenas se tiver posição e modelo de prop
                local distance = #(playerCoords - tableData.pos) -- Calcula a distância

                -- Lógica de Spawn
                if distance < Config.PropSpawnDistance then
                    if not managedProps[tableId] then -- Se não está gerenciado (nem carregando, nem criado)
                        CreatePropForTable(tableId, tableData)
                    end
                    -- Lógica de Despawn
                elseif distance > Config.PropDespawnDistance then
                    if managedProps[tableId] then -- Se está gerenciado (criado ou carregando)
                        DeletePropForTable(tableId)
                    end
                end
            end
        end
        ::continue:: -- Label para o goto
    end
end)


--------------------- Prompt (Criado separadamente agora)
Citizen.CreateThread(function()
    for k, v in pairs(BTC_CRAFT_TABLES) do
        local key = GetHashKey(Config.KeysOpenCraft)
        local coords = v.pos
        local label = v.label
        -- Cria apenas o prompt aqui
        BtcCore.prompts.createPrompt(GetCurrentResourceName() .. k, coords, key, label,
            { type = 'client', event = 'btc_craft:openCrafting', args = { k, v } })
    end
end)

----- Mesas

local function HasRequiredJob(playerJob, required)
    -- ... (código existente sem alterações) ...
    if not required or required == false then return true end

    if type(required) == "string" then
        return playerJob == required
    elseif type(required) == "table" then
        for _, job in pairs(required) do
            if playerJob == job then return true end
        end
    end

    return false
end

---------------------- UI e Callbacks (sem alterações significativas na lógica principal aqui)

AddEventHandler("btc_craft:openCrafting", function(k, craftTable)
    BtcCore.callback.triggerServer('btc-craft:getJob', function(playerjob)
        local playerPed = PlayerPedId()
        local PlayerJob = playerjob

        if not HasRequiredJob(PlayerJob, craftTable.required_jobs) then
            Notify(locale[1], 5000, "error")
            return
        end

        if inCrafting then
            Notify(locale[4], 5000, "error")
            return
        end

        inCrafting = true


        currentOpenedCraftTable = craftTable                               -- << GUARDA a informação da mesa atual

        SetCurrentPedWeapon(playerPed, GetHashKey('WEAPON_UNARMED'), true) -- unarm player
        Citizen.InvokeNative(0x524B54361229154F, PlayerPedId(), GetHashKey("world_human_write_notebook"), 9999999999,
            true,
            false, false, false)
        SetNuiFocus(true, true)

        local recipesToSend = {}
        -- ... (Lógica para buscar receitas e enviar para NUI permanece igual) ...
        for _, recipeId in ipairs(craftTable.recipes or {}) do
            for _, recipe in ipairs(BTC_CRAFT_RECIPES) do
                if recipe.id == recipeId then
                    local clonedRecipe = json.decode(json.encode(recipe))
                    clonedRecipe.label = BtcCore.framework.getItemLabel(clonedRecipe.output.item,
                        clonedRecipe.output.type)
                    clonedRecipe.image = BtcCore.framework.getItemImage(clonedRecipe.output.item)
                    if clonedRecipe.required_items then
                        for _, item in ipairs(clonedRecipe.required_items) do
                            item.label = BtcCore.framework.getItemLabel(item.item, item.type)
                            item.image = BtcCore.framework.getItemImage(item.item)
                        end
                    end
                    if clonedRecipe.required_tools then
                        for _, tool in ipairs(clonedRecipe.required_tools) do
                            if tool.item then
                                tool.label = BtcCore.framework.getItemLabel(tool.item, tool.type)
                                tool.image = BtcCore.framework.getItemImage(tool.item)
                            end
                        end
                    end
                    table.insert(recipesToSend, clonedRecipe)
                    break
                end
            end
        end

        SendNUIMessage({
            action = "openCraftingMenu",
            recipes = recipesToSend,
            tableLabel = craftTable.label,
            tablePos = craftTable.pos,
            tableId = k
        })
    end)
end)

RegisterNUICallback("closeMenu", function(data, cb)
    SetNuiFocus(false, false)
    inCrafting = false
    local playerPed = PlayerPedId()
    ClearPedTasks(playerPed)      -- Limpa a animação/cenário ao fechar
    currentOpenedCraftTable = nil -- << LIMPA a informação da mesa
    cb("ok")
end)


RegisterNUICallback('produceItem', function(data, cb)
    local ped = PlayerPedId()
    local recipe = data.recipe
    local quantity = data.quantity
    local duration = 1000
    ClearPedTasks(ped)
    SetNuiFocus(false, false)
    local canadd = true

    cb('ok') -- Responde ao NUI imediatamente

    -- Verifica se ainda temos a informação da mesa de onde o craft foi iniciado
    if not currentOpenedCraftTable then
        Notify("Erro: Mesa de trabalho não identificada.", 5000, "error")
        return
    end

        for k, v in pairs(BTC_CRAFT_RECIPES) do
        if recipe == v.id then
            for type, item in pairs(v) do
                if type == 'output' then
                    local amount = item.amount * quantity
                    local item = item.item
                    local type = item.type or 'item'
                    canadd = BtcCore.callback.triggerServerSync('btc-craft:canAdd', item, amount, type)
                     break
                end
            end
            break
        end
    end


    if not canadd then
        Notify(locale[5], 5000, "error")
        return
    end


    Wait(4000)
    BtcCore.framework.setInvBusy()
    FreezeEntityPosition(ped, true) -- Congela o jogador

    ------------ Checar os itens e ferramentas primeiro ------------
    local hasAllItems = true -- Flag para controle
    for k, v in pairs(BTC_CRAFT_RECIPES) do
        if recipe == v.id then
            duration = v.duration * quantity
            -- Checar Itens Requeridos
            if v.required_items then
                for index, item in pairs(v.required_items) do
                    -- ... (lógica de checagem de item.amount * quantity) ...
                    local useItem = item.item
                    local amount = item.amount * quantity
                    local itemType = item.type or 'item'
                    local itemLabel = BtcCore.framework.getItemLabel(useItem, itemType)
                    local hasItem = BtcCore.framework.hasItem(useItem, amount, itemType)
                    if not hasItem then
                        Notify(locale[2] .. ' x' .. amount .. ' ' .. itemLabel, 5000, "error")
                        hasAllItems = false
                        break -- Sai do loop de itens
                    end
                end
            end
            if not hasAllItems then
                inCrafting = false
                BtcCore.framework.setInvNoBusy()
                FreezeEntityPosition(ped, false)
                ClearPedTasks(ped) -- Não precisa limpar tasks pois nenhuma foi iniciada
                return
            end

            -- Checar Ferramentas Requeridas
            if v.required_tools then
                for index, item in pairs(v.required_tools) do
                    -- ... (lógica de checagem de ferramenta) ...
                    local useItem = item.item
                    local amount = item.amount
                    local itemType = item.type or 'item'
                    local hasItem = BtcCore.framework.hasItem(useItem, amount, itemType)
                    local itemLabel = BtcCore.framework.getItemLabel(useItem, itemType)
                    if not hasItem then
                        Notify(locale[2] .. ' ' .. itemLabel, 5000, "error")
                        hasAllItems = false
                        break -- Sai do loop de ferramentas
                    end
                end
            end
            break -- Sai do loop de receitas após checar a correta
        end
    end

    -- Se não tiver todos os itens/ferramentas, para a execução aqui
    if not hasAllItems then
        inCrafting = false
        BtcCore.framework.setInvNoBusy()
        FreezeEntityPosition(ped, false)
        ClearPedTasks(ped) -- Não precisa limpar tasks pois nenhuma foi iniciada
        return
    end

    ------------ Se passou pelas checagens, INICIA A ANIMAÇÃO ------------
    local craftTable = currentOpenedCraftTable -- Pega a info da mesa guardada
    local animDict = craftTable.animDict
    local animName = craftTable.animName
    local scenarioName = craftTable.anim -- Assumindo que 'anim' guarda o nome do cenário

    ClearPedTasks(ped)                   -- Garante que não há outra tarefa antes de iniciar a nova

    TriggerEvent('btc-craft:ProgressBar', duration)

    if scenarioName and IsScenarioTypeEnabled(scenarioName) then
        TaskStartScenarioAtPosition(ped, GetHashKey(scenarioName), craftTable.pos.x, craftTable.pos.y,
            craftTable.pos.z, GetEntityHeading(ped), 0, true, false)
        if Config.Debug then print(('[btc-craft] Iniciando cenário %s'):format(scenarioName)) end
    elseif animDict and animName then
        RequestAnimDict(animDict)
        while not HasAnimDictLoaded(animDict) do Wait(100) end
        TaskPlayAnim(ped, animDict, animName, 8.0, -8.0, -1, 1, 0, false, false, false)
        if Config.Debug then print(('[btc-craft] Iniciando animação %s/%s'):format(animDict, animName)) end
    else
        if Config.Debug then print(('[btc-craft] Nenhuma animação/cenário válido definido para esta mesa.')) end
        -- Nenhuma animação para tocar
    end
    --------------------------------------------------------------------

    -- Envia para o servidor para remover itens e iniciar o timer
    TriggerServerEvent('btc-craft:removeItems', recipe, quantity)
end)

RegisterNetEvent('btc-craft:ProgressBar')
AddEventHandler('btc-craft:ProgressBar', function(duration)
    ProgressBar(duration)
end)

RegisterNetEvent('btc-craft:setCrafting')
AddEventHandler('btc-craft:setCrafting', function()
    local ped = PlayerPedId()
    inCrafting = false
    BtcCore.framework.setInvNoBusy()
    FreezeEntityPosition(ped, false)
    ClearPedTasks(ped)            -- Limpa a animação ao final/falha do craft
    currentOpenedCraftTable = nil -- << LIMPA a informação da mesa
end)

AddEventHandler("onResourceStop", function(resourceName)
    -- ... (lógica de deletar prompts e props permanece igual) ...
    if GetCurrentResourceName() ~= resourceName then return end
    for k, v in pairs(BTC_CRAFT_TABLES) do
        BtcCore.prompts.deletePrompt(GetCurrentResourceName() .. k)
    end
    if Config.EnableProximityProps then
        for tableId, prop in pairs(managedProps) do
            DeletePropForTable(tableId)
        end
        if Config.Debug then print(('[btc-craft] Props de crafting por proximidade removidos.')) end
        managedProps = {}
    end
    currentOpenedCraftTable = nil -- Limpa ao parar recurso também
end)
