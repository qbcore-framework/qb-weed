local Translations = {
    error = {
        process_canceled = "Proces gestopt",
        plant_has_died = "De plant is gestorven. Druk ~r~ E ~w~ om de plant te verwijderen.",
        cant_place_here = "Kan hier niet geplaatst worden",
        not_safe_here = "Het is hier niet veilig, probeer het in huis",
        not_need_nutrition = "Deze plant heeft geen voeding nodig",
        this_plant_no_longer_exists = "Deze plant bestaat niet meer",
        house_not_found = "Huis werd niet gevonden",
        you_dont_have_enough_resealable_bags = "Je hebt niet genoeg verkoopbare zakken",
    },
    text = {
        sort = 'Soort:',
        harvest_plant = 'Druk ~g~ E ~w~ om te oogsten.',
        nutrition = "Voeding:",
        health = "Gezondheid:",
        progress = "Voortgang:",
        harvesting_plant = "Plant aan het oogsten",
        planting = "Aan het planten",
        feeding_plant = "Plant aan het voeden",
        the_plant_has_been_harvested = "De plant is geoogst",
        removing_the_plant = "Plant aan het verwijderen",
        stage = "Huidig stadium:",
        highestStage = "Oogst stadium:",
    },
}

if GetConvar('qb_locale', 'en') == 'nl' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
