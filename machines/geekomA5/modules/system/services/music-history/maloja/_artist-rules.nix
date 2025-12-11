{ pkgs, lib, ... }:
let
  toTSV = parts: builtins.concatStringsSep "\t" parts;

  #NOTE - https://github.com/krateng/maloja/blob/c6cf28896ca836407a1943cae5542d2b83d009cf/maloja/data_files/config/rules/rules.info
  rules = {
    belongTogether =
      artist:
      toTSV [
        "belongtogether"
        artist
      ];

    replaceArtist =
      source: target:
      toTSV [
        "replaceartist"
        source
        target
      ];
  };

  artists = {
    # Artists with separators in their names
    belongTogether = [
      "M|O|O|N"
      "Морэ & Рэльсы"
      "AC/DC"
      "4.А.Й.К.А"
      "A.K.A.C.O.D."
      "Echo & the Bunnymen"
      "Joey Valence & Brae"
      "Crosby, Stills, Nash & Young"
      "Coco & Clair Clair"
      "Trummor & Orgel"
      "SelloRekt / LA Dreams"
      "Harold Melvin & the Blue Notes"
      "Daryl Hall & John Oates"
      "Amadou & Mariam"
      "TR/ST"
      "Terror/Cactus"
    ];

    # Aliases / translations / transliteration
    # Source = target
    replaceArtist = {
      "Samoe Bolshoe Prostoe Chislo" = "Самое Большое Простое Число";
      "Zemfira" = "Земфира";
      "Zемфира" = "Земфира";
      "Kino" = "Кино";
      "Viacheslav Butusov" = "Вячеслав Бутусов";
      "Vyacheslav Butusov" = "Вячеслав Бутусов";
      "Naik Borzov" = "Найк Борзов";
      "Bi-2" = "Би-2";
      "Splean" = "Сплин";
      "Mumiy Troll" = "Мумий Тролль";
      "7b" = "7Б";
      "Krovostok" = "Кровосток";
      "Naadia" = "Наадя";
      "PCP" = "Perforated Cerebral Party";
      "МОРЭ&РЭЛЬСЫ" = "Морэ & Рэльсы";

      "И Друг Мой Грузовик..." = "...И Друг Мой Грузовик";
      "Я И Друг Мой Грузовик" = "...И Друг Мой Грузовик";
      "Vagonovozhatye" = "Вагоновожатые";
      "Okean Elzy" = "Океан Ельзи";
      "Skryabin" = "Скрябін";
      "DakhaBrakha" = "ДахаБраха";

      "Kate Tempest" = "Kae Tempest";
      "Lyapis Trubetskoy" = "Ляпис Трубецкой";
      "Алина Орлова" = "Alina Orlova";
    };
  };

  allRulesTSV = builtins.concatLists [
    (builtins.map rules.belongTogether artists.belongTogether)
    (lib.mapAttrsToList rules.replaceArtist artists.replaceArtist)
  ];
in
pkgs.writeText "maloja-custom-rules.tsv" (lib.concatLines allRulesTSV)
