local Translations = {
    error = {
        process_canceled = "Proces Annulleret",
        plant_has_died = "Planten er død. Tryk på ~r~ E ~w~ for at fjerne planten.",
        cant_place_here = "Kan ikke placere her",
        not_safe_here = "Det er ikke sikkert her, prøv dit hus",
        not_need_nutrition = "Planten har ikke brug for ernæring",
        this_plant_no_longer_exists = "Findes denne plante ikke længere?",
        house_not_found = "Hus ikke fundet",
        you_dont_have_enough_resealable_bags = "Du har ikke nok genlukkelige poser",
    },
    text = {
        sort = 'Sorter:',
        harvest_plant = 'Tryk på ~g~ E ~w~ for at høste planten.',
        nutrition = "Ernæring:",
        health = "Sundhed:",
        progress = "Fremskridt:",
        harvesting_plant = "Høster planten",
        planting = "Planter",
        feeding_plant = "Giver planten næring",
        the_plant_has_been_harvested = "Planten er blevet høstet",
        removing_the_plant = "Fjerner planten",
        stage = "Nuværende stadie:",
        highestStage = "Høststadie:",
    },
}


if GetConvar('qb_locale', 'en') == 'da' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end

