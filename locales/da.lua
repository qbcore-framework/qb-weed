local Translations = {
    error = {
        process_canceled = "Handlingen afbrudt",
        plant_has_died = "Planten er sgu død. Tryk ~r~ E ~w~ for at fjerne den.",
        cant_place_here = "Kan ikke placeres her",
        not_safe_here = "Det er ikke sikkert her, prøv hjemme hos dig selv",
        not_need_nutrition = "Planten har ikke brug for næring",
        this_plant_no_longer_exists = "Planten eksistere ikke?",
        house_not_found = "Huset kunne ikke findes",
        you_dont_have_enough_resealable_bags = "Du har ikke nok salgsposer",
    },
    text = {
        sort = 'Art:',
        harvest_plant = 'Tryk ~g~ E ~w~ for at høste planten.',
        nutrition = "Næring:",
        health = "Status:",
        progress = "Process:",
        harvesting_plant = "Høster planten",
        planting = "Planter",
        feeding_plant = "Fodre planten",
        the_plant_has_been_harvested = "Planten er blevet høstet",
        removing_the_plant = "Fjerner planten",
        stage = "Nuværende stadie:",
        highestStage = "Høst stadie:",
    },
}

Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
