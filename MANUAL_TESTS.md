# Ruční testovací scénář

Scénář ověřuje hlavní herní smyčku v Godot Engine 4.7. Každý krok proveďte v nové hře. Výsledek označte až po skutečném spuštění.

## Předpoklady

- Projekt se otevře přes `project.godot` a spustí hlavní scénu.
- Jsou dostupné všechny soubory v `assets/`.
- Hra začíná s objednávkou a časovým limitem.

## Kroky
| 1 | Spusťte hru klávesou F5. Pokud první objednávka není rybí polévka, restartujte R, dokud nebude rybí polévka první. | Zobrazí se kuchyně, bobří kuchař, HUD a objednávka; hudba začne hrát.
| 2 | Pohybujte se pomocí WASD a šipek. | Kuchař se pohybuje po prostoru a animace reaguje na pohyb.
| 3 | Přistupte k bedně a stiskněte E, potom zopakujte E u bedny. | Kuchař vezme surovinu a následně ji odloží; HUD zobrazuje změnu drženého předmětu.
| 4 | Vezměte rybu, položte ji na prkénko, stiskněte E u prkénka a po dokončení ji vyzvedněte. | Spustí se krájení, ukazatel postupu se naplní a hráč získá nakrájenou rybu.
| 5 | Vložte nakrájenou rybu do hrnce a počkejte na dokončení. | Hrnec ukazuje postup a poté stav „READY!“.
| 6 | Vezměte talíř, vyzvedněte hotovou rybí polévku z hrnce a odneste ji k okénku. | Pokrm je na talíři; při shodě s první objednávkou se objednávka odebere a skóre se zvýší.
| 7 | Připravte těsto a cukr v troubě a počkejte na dokončení. | Trouba ukazuje postup a dokončí pečení.
| 8 | Vezměte bramboru, uvařte ji v hrnci a vyzvedněte vařenou bramboru prázdnou rukou. Vezměte majonézu a postupně vložte obě suroviny do mixéru. Vezměte talíř a vyzvedněte salát. | Mixér dokončí salát okamžitě a hráč jej získá na talíři.
| 9 | Stiskněte N během přehrávání skladby. | Přehrávání přejde na jinou skladbu.
| 10 | Stiskněte Esc dvakrát. | Hra se pozastaví a následně pokračuje.
| 11 | Stiskněte R. | Hra se restartuje, čas a skóre se vrátí na počáteční hodnoty a objeví se nová objednávka.

## Záznam běhu

- Tester: Miiadinov Rustem
- Datum: 26/11/2026
- Verze Godotu: 4.7.2
- Výsledek: úspěšný
- Chyby / poznámky: žádne