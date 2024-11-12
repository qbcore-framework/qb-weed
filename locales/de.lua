local Translations = {
    error = {
        process_canceled = "Vorgang abgebrochen",
        plant_has_died = "Die Pflanze ist gestorben. Drücke ~r~ E ~w~ um die Pflanze zu entfernen.",
        cant_place_here = "Kann hier nicht platziert werden",
        not_safe_here = "Es ist hier nicht sicher, versuche es in deinem Haus",
        not_need_nutrition = "Die Pflanze benötigt keine Nährstoffe",
        this_plant_no_longer_exists = "Diese Pflanze existiert nicht mehr?",
        house_not_found = "Haus nicht gefunden",
        you_dont_have_enough_resealable_bags = "Du hast nicht genug wiederverschließbare Beutel",
    },
    text = {
        sort = 'Sortieren:',
        harvest_plant = 'Drücke ~g~ E ~w~ um die Pflanze zu ernten.',
        nutrition = "Nährstoffe:",
        health = "Gesundheit:",
        progress = "Fortschritt:",
        harvesting_plant = "Pflanze ernten",
        planting = "Pflanzen",
        feeding_plant = "Pflanze düngen",
        the_plant_has_been_harvested = "Die Pflanze wurde geerntet",
        removing_the_plant = "Pflanze entfernen",
        stage = "Aktuelle Phase:",
        highestStage = "Erntephase:",
    },
}

if GetConvar('qb_locale', 'en') == 'de' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
