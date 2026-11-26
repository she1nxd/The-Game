# Home for Christmas

## Popis hry

Home for Christmas je 3D kuchařská hra na čas. Hráč ovládá bobřího kuchaře, připravuje vánoční jídla na jednotlivých stanicích a vydává hotové objednávky. Za správně vydaná jídla získává body; objednávky postupně ztrácejí trpělivost.

## Ovládání

| Klávesa | Akce |
| --- | --- |
| W, A, S, D nebo šipky | Pohyb kuchaře |
| E | Interakce s nejbližší stanicí |
| N | Přeskočení právě hrající skladby |
| Esc | Pozastavení / pokračování |
| R | Restart hry |

Postup přípravy se zobrazuje nad příslušnou stanicí. Suroviny se berou z beden, ryba se krájí na prkénku, další jídla se připravují v hrnci, mixéru nebo troubě. Hotové pokrmy se podle receptu vyzvedávají a vydávají v okénku.

## Spuštění projektu

### V Godot editoru

1. Nainstalujte Godot Engine **4.7**.
2. Stáhněte nebo naklonujte celý repozitář. Ve složce musí zůstat `project.godot` i adresář `assets/`.
3. V Godot Project Manageru zvolte **Import** a vyberte soubor `project.godot`.
4. Otevřete projekt a stiskněte **F5** (spustit projekt). Klávesu **F6** použijte, pokud máte otevřenou scénu `main.tscn`.

### Export samostatné hry

V Godot editoru otevřete **Project → Export**, přidejte exportní preset pro cílový operační systém a zvolte **Export Project**. Na jiném počítači pak spusťte vytvořený soubor. Exportní šablony pro daný systém musí být v Godotu nainstalované.

## Použité technologie

- Godot Engine 4.7
- GDScript
- 3D scéna sestavovaná skriptem a modely ve formátu glTF
- 2D textury pro ikony objednávek a obrazové pozadí
- MP3 hudební soubory přehrávané pomocí `AudioStreamPlayer`

## Ruční testovací scénář

Opakovatelný scénář je v [MANUAL_TESTS.md](MANUAL_TESTS.md). Před odevzdáním jej spusťte na cílové verzi Godotu a zaznamenejte výsledek.

## Použité modely

- Bobr: „Beaver Inc, Global Game Jam 2020“ od Edriviel, licence CC BY 4.0. Podrobnosti a požadovaná atribuce jsou v `assets/beaver/license.txt`.
- Vánoční strom: „Christmas Tree POLYCRAFT“ od LowlyPoly, licence CC BY 4.0. Podrobnosti a požadovaná atribuce jsou v `assets/christmas_tree/license.txt`.

## Odevzdávací poznámky

Design dokument je v [DESIGN.md](DESIGN.md). Deník selhání AI a retrospektiva jsou připravené jako osobní návrhy v [AI_FAILURE_DIARY.md](AI_FAILURE_DIARY.md) a [RETROSPECTIVE.md](RETROSPECTIVE.md); každý student je musí zkontrolovat a odevzdat samostatně. Historie Git obsahuje příspěvky autorů `she1nxd` a `nevim-nevim`; ověřte, že odpovídají všem členům týmu.
