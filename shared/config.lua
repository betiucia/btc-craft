Config = {}
Config.Locale = 'pt-br'                -- Idioma que está utilizando, no caso o português
Config.Debug = true                    -- Ativar debug para ver os logs no console do servidor
Config.Target = false                   -- Para usar eye Target -- ox_target necessário
Config.KeysOpenCraft = "INPUT_CREATOR_ACCEPT"


-- [[ Novas Configurações para Props por Proximidade ]]
Config.EnableProximityProps = true     -- Define se a criação por proximidade está ativa
Config.PropSpawnDistance = 50.0       -- Distância para criar o prop (metros/unidades do jogo)
Config.PropDespawnDistance = 80.0     -- Distância para remover o prop (ligeiramente maior para evitar piscar)
Config.ProximityCheckInterval = 1500   -- Tempo em milissegundos entre cada verificação de proximidade



-------- Progressbar

function ProgressBar(duration)

lib.progressCircle({
        duration = duration,
        position = 'bottom',
        useWhileDead = false,
        canCancel = false,
    })

end

---- Notificações

local isServerSide = IsDuplicityVersion()
function Notify(message, timer, type, source) -- translateNumber é o número da tradução conforme o Config.Translate
    if timer then
        timer = timer
    else
        timer = 5000
    end

    if isServerSide then
        TriggerClientEvent('ox_lib:notify', source, { title = message, type = type, duration = timer })
    else
        lib.notify({ title = message, type = type, duration = timer })
    end
end