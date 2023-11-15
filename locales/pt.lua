local Translations = {
    error = {
        process_canceled = "Processo cancelado",
        plant_has_died = "A planta morreu. Carrega no ~r~ E ~w~ para remover a planta",
        cant_place_here = "Não podes colocar a planta aqui",
        not_safe_here = "Não podes colocar a planta aqui, tenta na tua casa",
        not_need_nutrition = "A planta não precisa de nutrição",
        this_plant_no_longer_exists = "Esta planta já não existe",
        house_not_found = "Casa não encontrada",
        you_dont_have_enough_resealable_bags = "Tu não tens sacos lacráveis suficientes",
    },
    text = {
        sort = 'Organizar:',
        harvest_plant = 'Carrega no ~g~ E ~w~ para colher a planta',
        nutrition = "Nutrição:",
        health = "Saúde:",
        harvesting_plant = "A colher planta",
        planting = "A plantar",
        feeding_plant = "A alimentar planta",
        the_plant_has_been_harvested = "A planta foi colhida",
        removing_the_plant = "A remover a planta",
    },
}

if GetConvar('qb_locale', 'en') == 'pt' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end