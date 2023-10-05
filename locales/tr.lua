local Translations = {
    error = {
        process_canceled = "İşlem İptal Edildi",
        plant_has_died = "Bitki ölmüş. Bitkiyi kaldırmak için ~r~ E ~w~ tuşuna basın.",
        cant_place_here = "Buraya Koyamazsınız",
        not_safe_here = "Burası Güvenli Değil, evinizi deneyin",
        not_need_nutrition = "Bitki Besin İhtiyacı İstemiyor",
        this_plant_no_longer_exists = "Bu bitki artık mevcut değil?",
        house_not_found = "Ev Bulunamadı",
        you_dont_have_enough_resealable_bags = "Yeterince Kapatılabilir Poşetiniz Yok",
    },
    text = {
        sort = 'Sırala:',
        harvest_plant = 'Bitkiyi hasat etmek için ~g~ E ~w~ tuşuna basın.',
        nutrition = "Besin:",
        health = "Sağlık:",
        progress = "İlerleme:",
        harvesting_plant = "Bitkiyi Hasat Ediyor",
        planting = "Dikme",
        feeding_plant = "Bitkiye Besleme",
        the_plant_has_been_harvested = "Bitki hasat edildi",
        removing_the_plant = "Bitkiyi Kaldırma",
        stage = "Mevcut Aşama:",
        highestStage = "Hasat Aşaması:",
    },
}

if GetConvar('qb_locale', 'en') == 'tr' then
    Lang = Locale:new({
        phrases = Translations,
        warnOnMissing = true,
        fallbackLang = Lang,
    })
end
