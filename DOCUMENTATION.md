Bash Graph Animator - Programmer's documentation

Struktura projektu

Skript je možné spustit s parametrem "-v", tedy verbose, kdy místo klasického "unixového" chování, kdy skript až na chyby mlčí, vypisuje, ve které fázi se zrovna nachází.

Nejdříve skript projde parametry, se kterými byl spuštěn. Pokud mezi nimi nalezne parametr s konfiguračním souborem, soubor zkontroluje a ze souboru načte v něm obsažené direktivy. O toto se stará funkce "load_config".

Následovně jsou načteny zbylé parametry, k tomu je využito parsovací utility getopts.
Po načtení parametrů proběhne kontrola, zda všechny poteřebné parametry jsou zadány.

V dalším kroku se načítají data ze souborů, či z http odkazů. K pomoci při stahování souborů přes http bylo využito programu wget.
Pokud je souborů skriptu předáno více, jsou podle data v prvním sloupci seřazeny za sebe.

Tato data jsou následovně zkontrolována - první sloupec obsahující datum je regulárním výrazem porovnán s časovým formátem, skriptu předaným v parametru -t, či v konfiguračním souboru. Druhý soupec je zkontrolován, zda obsahuje číselnou hodnotu (celočíselnou, či desetinnou).

Poté skript nastavuje rozsahy na jednotlivých osách - díky tomu, že data jsou již v této dobře správně seřazena, při nastavení na ose X hodnot "min" či "max" stačí vzít první, resp. poslední řádek. Pokud je nastavena hodnota auto, je třeba rozsah osy X nastavovat vždy znovu před vykreslováním snímku. Třetí možností je již určená float/int hodnota, která se jen do rozsahu dosadí.

Při nastavování rozsahů na ose Y na hodnotu Max, resp. Min je třeba všechna data projít a dle nejvyšší, resp. nejnižší hodnoty rozsah nastavit. Při nastavování na hodnotu auto je možné proměnné nechat prázdné a gnuplot vše sám vyřeší.

Následovně je počítána rychlost a snímky za sekundu z předem zadaných hodnot FPS, speed a time. Pokud v předchozích krocích byly určitým způsobem zadány všechny direktivy, na obrazovku je vypsáno varování, říkající, že bude počítáno pouze s časem a rychlostí.

Rychlost je později využívána při počtu cyklů při generování jednotlivých snímků. Ze vstupních dat jsou vybrána data od středu souboru, s narůstajícím počtem cyklů tyto vybraná data narůstají, vždy o 2*speed řádků.

Tato data jsou následovně předána programu gnuplot, který z nich jednotlivé obrazy vygeneruje. O průběhu informuje jednoduchá funkce.

Pro animaci je vytvořen adresář, podle direktivy Name. Pokud již takový adresář existuje, je vytvořen s příponou _i, kde i=max(i,0)+1. Pokud tedy nějaké adresáře smažeme, vytvoří se mezera a skript vytvoří adresář největšího čísla + 1.

Do tohoto adresáře je následovně pomocí programu ffmpeg vytvořena animace, ze snímků z předchozích kroků. Pro animaci je vybrán formát mp4.