local Translations = {
    error = {
        process_canceled = "Prozess Abgebrochen",
        plant_has_died = "Die Pflanze ist abgestorben. Drücke ~r~ E ~w~ um Sie zu entfernen.",
        cant_place_here = "Kann hier nicht platziert werden.",
        not_safe_here = "Dieser Ort ist nicht sicher, versuche es zuhause.",
        not_need_nutrition = "Diese Pflanze benötigt keinen Dünger.",
        this_plant_no_longer_exists = "Diese Pflanze existiert nicht mehr.",
        house_not_found = "Haus nicht gefunden",
        you_dont_have_enough_resealable_bags = "Du hast nicht genügend Plastiktütchen",
    },
    text = {
        sort = 'Sortieren:',
        harvest_plant = 'Drücke ~g~ E ~w~ um die Pflanze zu ernten.',
        nutrition = "Dünger:",
        health = "Gesundheit:",
        progress = "Fortschritt:",
        harvesting_plant = "Ernte Pflanze",
        planting = "Pflanze",
        feeding_plant = "Pflege Pflanze",
        the_plant_has_been_harvested = "Die Pflanze wurde geerntet",
        removing_the_plant = "Entferne Pflanze",
        stage = "Aktueller Status:",
        highestStage = "Erntestatus:",
    },
}

if GetConvar('qb_locale', 'en') == 'de' then
Lang = Lang or Locale:new({
    phrases = Translations,
    warnOnMissing = true
})
