BTC_CRAFT_TABLES = {}

BTC_CRAFT_TABLES = {
    {
        id = "mesa_cozinha_01",
        label = "Mesa de Cozinha",
        pos = vec3(-818.18, -1323.0799560546875, 42.66075134277344),
        radius = 2.0,
        -- anim = "PROP_PLAYER_SEAT_CHAIR_STOOLCOOKGRILL1__TRANS",
        recipes = { "pao_caseiro", "sopa_legumes" },
        required_jobs = {'unemployed'},
        prop_model = 'p_stoveiron02x', -- <--- Adicione o modelo do prop aqui (use backticks `` ou aspas)
        prop_heading = 90.52, -- <--- (Opcional) Rotação do prop
        animDict = 'amb_work@world_human_bartender@cleaning@glass@female_a@idle_b', -- << Dicionário da animação
        animName = "idle_e", -- << Nome da animação dentro do dicionário
        animFlag = 49 -- << (Opcional) Flag para looping e outras propriedades (49 = Looping + Enable Player Control)
        
    },
    -- {
    --     id = "mesa_forja_01",
    --     label = "Forja de Armas",
    --     pos = vector3(-1330.25, 2455.92, 140.01),
    --     radius = 2.5,
    --     anim = "WORLD_HUMAN_BLACKSMITH",
    --     recipes = { "machado_rude", "flecha_simples" },
    --     required_jobs = { "ferreiro", "aprendiz_ferreiro" },

    -- },
    -- {
    --     id = "mesa_alquimia_01",
    --     label = "Mesa de Alquimia",
    --     pos = vector3(-1300.15, 2400.33, 145.00),
    --     radius = 2.0,
    --     anim = "WORLD_HUMAN_MEDICINE",
    --     recipes = { "pocao_cura" },
    --     required_jobs = "ferreiro"
    -- }
}