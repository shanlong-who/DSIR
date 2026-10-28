---
title: "Premiers pas avec DSIR"
output: rmarkdown::html_document
---

<!-- chunk:1 -->

DSIR est un petit package R pour les travaux sur les données de santé mondiale. Il fournit les métadonnées des États Membres de l'OMS, des clients légers pour les API GHO et ODD des Nations Unies, ainsi que des thèmes `ggplot2` et une mise en forme `flextable` réutilisables, dans le style de l'OMS. Il s'adresse aux professionnels de santé, au personnel de l'OMS et aux chercheurs qui répètent régulièrement les mêmes tâches.

Ce tutoriel présente le parcours habituel : rechercher des pays, obtenir les données du GHO et des ODD, nettoyer les réponses et produire des graphiques et des tableaux pour les rapports. Un [tutoriel distinct](ghe-xmart.html) décrit WHO xMart et les GHE.

## Installation et préparation

Dans R, installez le package depuis CRAN :

```r
install.packages("DSIR")
```

Ce tutoriel utilise aussi `dplyr` et `ggplot2`. Si nécessaire, installez-les avec `install.packages(c("dplyr", "ggplot2"))`.

<!-- chunk:2 -->

Le code, les noms de fonctions et de colonnes, ainsi que les libellés des graphiques sont communs à la version anglaise. La langue du site ne modifie pas les libellés renvoyés par les sources. Les objectifs de développement durable sont abrégés en **ODD** dans le texte et en **SDG** dans le code.

## Métadonnées des États Membres de l'OMS

La table `who_countries` contient les 194 États Membres de l'OMS, avec leurs codes ISO3, ISO2 et M49, leurs noms officiels et courts et leur région OMS. La colonne `is_pic` identifie les 14 pays insulaires du Pacifique au sein de la Région du Pacifique occidental.

<!-- chunk:3 -->

DSIR fournit aussi des vecteurs prédéfinis de codes ISO3 pour chaque région OMS.

<!-- chunk:4 -->

L'indicateur `is_pic` facilite l'analyse collective des pays insulaires du Pacifique, dont les caractéristiques démographiques et géographiques sont particulières.

<!-- chunk:5 -->

`iso3_to_region()` associe un vecteur de codes ISO3 aux régions OMS. La fonction est vectorisée et renvoie `NA` pour les codes qui ne correspondent pas à un État Membre.

<!-- chunk:6 -->

Cette fonction facilite la jointure entre des données externes identifiées par ISO3 et la structure régionale de l'OMS.

`iso3_to_m49()` convertit les codes ISO3 en codes numériques M49 des Nations Unies. Par exemple, le GHO utilise `"PHL"`, tandis que l'API ODD utilise `"608"`. Les résultats sont des chaînes de trois caractères, complétées par des zéros à gauche, comme dans `who_countries$m49_code`.

<!-- chunk:7 -->

En pratique, la conversion explicite est souvent inutile : `sdg_data()` et `sdg_coverage()` acceptent des codes ISO3 dans `area` et effectuent la conversion en interne.

Lors de la construction du site et du package, les exemples nécessitant le réseau et les graphiques associés sont affichés sans exécution. Pour les exécuter pendant le rendu, définissez `DSIR_BUILD_LIVE_VIGNETTE=true` dans la session de rendu.

## Vérifier la disponibilité avant le téléchargement

Le répertoire public du GHO contient de nombreux indicateurs, mais un indicateur donné ne couvre pas forcément les pays ou les années souhaités. Avant un téléchargement complet avec `gho_data()`, trois fonctions permettent d'interroger la disponibilité sans télécharger toutes les observations.

`gho_has_data()` vérifie si des données existent pour un indicateur et des filtres donnés. Elle est utile pour examiner une liste d'indicateurs candidats.

<!-- chunk:8 -->

Elle renvoie `TRUE`, `FALSE` ou `NA`. Les échecs de requête, y compris un code absent du répertoire public actuel, produisent `NA`.

`gho_count()` renvoie le nombre de lignes correspondant aux mêmes filtres, ce qui aide à estimer la taille du téléchargement.

<!-- chunk:9 -->

`gho_coverage()` résume les années couvertes et le nombre d'observations par pays. Elle ne demande que `SpatialDim` et `TimeDim`, ce qui réduit le volume transféré.

<!-- chunk:10 -->

## Consulter les dates de mise à jour des sources

La fonction expérimentale `gho_last_updated()` recherche l'horodatage non manquant le plus récent parmi les observations actuelles d'un indicateur, pour tous les lieux, années et dimensions. Un argument `backend` explicite prime sur `DSIR.who_backend`. Si aucun des deux n'est défini, la fonction utilise legacy.

<!-- chunk:11 -->

Les champs sources sont `Date` pour legacy et `Sys_CommitDateUtc` pour xMart. DSIR n'a pas établi que `Date` désigne une modification ou publication officielle ; un commit système xMart peut refléter un traitement. Aucun des deux champs n'est la dernière année d'observation. Chaque requête de date renvoie au plus une ligne. xMart utilise aussi le répertoire et les informations de champs mis en cache. Il n'y a pas de basculement automatique entre les backends. Interroger tous les indicateurs à la suite peut prendre beaucoup de temps.

Les huit colonnes par défaut restent inchangées. `diagnostics = TRUE` ajoute `reason`, `stage`, `http_status`, `timestamp_kind`, `provider_route` et `provider_indicator`, sans requête supplémentaire. `directory_not_listed` indique un code absent du répertoire lu avec succès, sans prouver que le code GHO est invalide. `http_error` et `request_failed` distinguent une erreur HTTP d'un échec de connexion. `timestamp_field_missing` et `timestamp_missing` distinguent un champ absent d'une réponse sans horodatage non manquant. Un répertoire accessible ne prouve pas que les requêtes d'observations fonctionnent. `checked_at` est le début du contrôle, pas une date de récupération ou de modification des données. Des horodatages système identiques ne prouvent pas que les valeurs ont changé ensemble ; utilisez les instantanés pour comparer les valeurs récupérées.

L'API ODD des Nations Unies fournit un horodatage pour toute la base, sans champ équivalent pour les données de chaque indicateur :

<!-- chunk:12 -->

Les deux fonctions renvoient une ligne avec `source`, `backend`, `scope`, `indicator`, `updated`, `timestamp_field`, `checked_at` et `status`. `updated` conserve la chaîne et les informations de fuseau horaire d'origine. Un fuseau non précisé n'est pas supposé être UTC. `checked_at` est l'heure de début de la requête en UTC.

`status` distingue `"ok"`, `"not_available"` (aucun horodatage fourni) et `"failed"` (échec de recherche, de requête ou de validation de la réponse). Un horodatage manquant ne prouve pas l'absence d'observations. Pour les ODD, `scope` vaut `"database"`, tandis que `backend` et `indicator` sont manquants. Cet horodatage ne signifie pas que toutes les séries ont changé au même moment. Les codes de version des séries et les dates de mise à jour des documents de métadonnées ne remplacent pas les dates de mise à jour des données.

## Obtenir des indicateurs du GHO

Le parcours habituel comporte trois étapes : rechercher le code, obtenir les données, puis nettoyer la réponse. `area` accepte un long vecteur ISO3 ; une seule requête peut donc couvrir une région entière.

### Étape 1 : rechercher un indicateur

<!-- chunk:13 -->

Choisissez un `IndicatorCode` dans le résultat et transmettez-le à `gho_data()` à l'étape suivante.

### Étape 2 : obtenir les données

<!-- chunk:14 -->

Cet exemple demande les données des 28 États Membres de la Région du Pacifique occidental en une seule fois.

### Étape 3 : nettoyer la réponse brute

`gho_clean()` produit la **structure commune de DSIR à 15 colonnes**, également utilisée par défaut par `sdg_clean()`. Les colonnes sont `source` (`"gho"`), `id`, `indicator`, `location`, `iso3`, `location_name`, `year`, `value`, `value_num`, `low`, `high`, `series` et les trois dimensions GHO `dim1`–`dim3`. Les lieux connus reçoivent leur libellé ; les colonnes absentes de la réponse sont remplies avec des `NA` du type approprié.

<!-- chunk:15 -->

## Agréger des indicateurs avec geomean()

Certains indicateurs sont construits à partir de la moyenne géométrique de leurs composantes, plutôt que de leur moyenne arithmétique. Par exemple, l'indice de couverture des services de santé universelle (UHC) agrège 14 indicateurs traceurs par des moyennes géométriques imbriquées. DSIR fournit `geomean()` :

<!-- chunk:16 -->

`geomean()` applique des règles définies aux valeurs manquantes, nulles et négatives ; consultez `?geomean`. Cette fonction réduit les erreurs courantes lors du calcul d'un indice à partir de ses composantes.

## Tracer avec theme_dsi() et theme_dsi_facet()

DSIR fournit deux thèmes `ggplot2` assortis pour des graphiques dans le style de l'OMS : panneaux simples, grilles discrètes et couleur d'accent cohérente. Ils peuvent remplacer respectivement `theme_minimal()` et `theme_bw()` dans les graphiques destinés aux travaux de l'OMS.

En règle générale, utilisez **`theme_dsi()` pour un seul panneau et `theme_dsi_facet()` pour les facettes**. La typographie, les titres et les légendes sont communs. Le thème à facettes ajoute des bordures, un fond clair aux bandeaux et davantage d'espace entre les panneaux.

### Un seul panneau : `theme_dsi()`

`theme_dsi()` utilise un cadre partiel, des grilles légères et des axes dans le bleu de l'OMS. Les grilles sont présentes dans les deux directions par défaut ; `grid = "y"` conserve uniquement les lignes horizontales.

<!-- chunk:17 -->

Pour les diagrammes en colonnes, ajoutez `scale_y_dsi_col()`, ou `scale_x_dsi_col()` lorsque les valeurs sont associées à `x`. Ces fonctions encapsulent `scale_*_continuous()` et retirent l'espace ajouté à la base de l'axe, afin que les colonnes touchent celui-ci.

<!-- chunk:18 -->

### Plusieurs facettes : `theme_dsi_facet()`

La répétition d'axes accentués peut surcharger un graphique à plusieurs panneaux. `theme_dsi_facet()` utilise des bordures complètes, des bandeaux gris clair et un espacement entre les panneaux pour mieux distinguer les groupes.

<!-- chunk:19 -->

`strip_fill` permet de modifier le fond des bandeaux, par exemple avec un bleu clair dérivé de la couleur d'accent de l'OMS.

<!-- chunk:20 -->

## Créer des tableaux avec dsi_flextable_defaults()

`dsi_flextable_defaults()` définit globalement les valeurs par défaut de `flextable` dans le style de l'OMS : thème booktabs, en-têtes en gras et marges intérieures modérées. Appelez-la une fois au début du rapport ; les tableaux suivants reprendront ces réglages.

<!-- chunk:21 -->

## Utiliser les indicateurs des ODD

`sdg_data()` et `sdg_clean()` suivent le même parcours : obtenir les données, puis les nettoyer. Les codes utilisent le format ODD avec des points, par exemple `"3.4.1"`. La colonne brute `value` reste une chaîne de caractères, car certaines lignes contiennent `"<0.1"` ou des notes d'agrégation. Les colonnes nettoyées `value_num`, `low` et `high` sont numériques, avec `NA` si la conversion est impossible.

Le paramètre facultatif `search` de `sdg_indicators()` fonctionne comme celui de `gho_indicators()` : les mots-clés sont combinés par ET et recherchés dans la description sans distinction de casse. Le filtrage s'effectue côté client, car la liste est courte, environ 250 lignes, et le service n'utilise pas OData.

<!-- chunk:22 -->

Le paramètre `area` de `sdg_data()` et `sdg_coverage()` accepte soit des codes ISO3, convertis en interne avec `iso3_to_m49()`, soit des codes M49. Les vecteurs régionaux tels que `wpro_cty` et `afro_cty` sont donc utilisables directement. Ne mélangez pas les deux formats dans un même appel.

<!-- chunk:23 -->

<!-- chunk:24 -->

Par défaut, `sdg_clean()` et `gho_clean()` produisent la même structure à 15 colonnes, combinable avec `bind_indicators()`. Les lignes ODD renseignent `series` et, pour les États Membres, `iso3` via `m49_to_iso3()`. Les colonnes GHO `dim1`–`dim3` restent à `NA`.

### Conserver les dimensions nommées des ODD

Les dimensions ODD sont des champs nommés dans `sdg$dimensions`, distincts des dimensions positionnelles du GHO. La sortie compacte à 15 colonnes les omet. Conservez-les explicitement pour une analyse désagrégée :

<!-- chunk:25 -->

Des colonnes de caractères sont ajoutées, par exemple `dim_age`, `dim_location`, `dim_sex`, `dim_reporting_type`, `dim_quantile` et `dim_type_of_household`. Les noms dépendent des dimensions réellement renvoyées. Les codes restent inchangés ; une catégorie absente n'est pas remplacée par un code de population totale. `keep_metadata = TRUE` conserve aussi les unités et les autres attributs.

Sélectionnez la série et les strates avec les noms et codes exacts de la source :

<!-- chunk:26 -->

Ces filtres sont appliqués localement après la pagination. Plusieurs valeurs d'une même dimension sont combinées par OU ; différentes dimensions, par ET. Si une dimension demandée est absente, la fonction avertit et renvoie zéro ligne, au lieu d'ignorer la restriction de population.

Le catalogue des Nations Unies pour l'indicateur 3.8.2, vérifié le 30 septembre 2026, contient la série `SH_OOP_XPD_EARNNET40`, conforme à la définition révisée en 2025. Le code GHO `FINANCIALHARDSHIP_PROPORTIONOFPOP` comporte aussi des composantes de dépenses de santé importantes et appauvrissantes dans `Dim1`. Elles ne sont pas des séries distinctes de ce catalogue ODD et ne peuvent pas être reconstituées en conservant les dimensions. Consultez la [définition et les composantes de l'OMS](https://www.who.int/data/gho/indicator-metadata-registry/imr-details/376).

### Comprendre les dimensions et conserver le contexte

`sdg_dimensions()` présente les catégories et libellés officiels de chaque série, sans télécharger les observations. Les catégories répertoriées ne sont pas forcément observées dans chaque pays.

<!-- chunk:27 -->

`code` contient les codes de l'API JSON utilisés pour filtrer ; `sdmx` est une autre représentation. `kind` distingue les dimensions des attributs, tels que les unités et la nature des données.

Pour conserver à la fois le contexte et les dimensions de population :

<!-- chunk:28 -->

`keep_metadata` conserve les attributs dans des colonnes `attr_*`, ainsi que la source, les détails ou la couverture temporelle, la période de base, le type de valeur et l'URL d'information géographique. Les notes et les codes associés d'indicateurs, d'objectifs et de cibles sont des colonnes de listes qui préservent plusieurs éléments. Utilisez RDS pour enregistrer cette structure.

Pour le GHO, affichez directement le type de chaque dimension positionnelle. Le code de difficultés financières ci-dessous était absent du répertoire public xMart au 6 octobre 2026 ; l'exemple choisit donc explicitement le service `legacy`.

<!-- chunk:29 -->

Les types proviennent de `Dim1Type`–`Dim3Type` pour chaque observation. Ils ne sont ni déduits d'un préfixe ni supposés constants pour l'ensemble d'un indicateur. Les métadonnées GHO comprennent `provider`, les codes de source, les identifiants d'observation, les commentaires dans `footnotes`, les types géographiques et temporels, les lieux parents, les dates de mise à jour et les intervalles temporels. Les deux options laissent la sortie par défaut à 15 colonnes inchangée.

`sdg_data()` vérifie la pagination déclarée et le nombre total de lignes avant le filtrage local. Un téléchargement incomplet produit un avertissement et zéro ligne. `sdg_coverage()` conserve ces avertissements et accepte les filtres `series` et `dimensions`. Sans filtre, les comptes regroupent toutes les strates d'un lieu et d'une série.

### Combiner le GHO et les ODD avec bind_indicators()

`bind_indicators()` empile autant de tables nettoyées que nécessaire. La colonne `source`, `"gho"` ou `"sdg"`, permet de filtrer ou de créer des facettes selon l'origine.

Les colonnes supplémentaires, y compris les dimensions ODD nommées, sont conservées. Les entrées qui ne les possèdent pas reçoivent des valeurs manquantes du type approprié. L'empilement n'harmonise pas les codes ni les définitions entre sources.

<!-- chunk:30 -->

### Examiner les séries avec sdg_coverage()

Un indicateur ODD peut contenir plusieurs **séries**, par exemple des vaccins, des strates par sexe ou des causes de décès, chacune avec sa propre couverture géographique et temporelle. L'exemple `"3.b.1"` comporte quatre séries de vaccination : DTP3, MCV2, PCV3 et HPV. Les vaccins plus récents ont une couverture temporelle plus courte que DTP3.

`sdg_coverage()` résume les années et le nombre d'observations par `(location, series)`, afin d'examiner les séries disponibles avant de choisir l'analyse.

<!-- chunk:31 -->

DSIR ne fournit pas d'équivalents ODD de `gho_has_data()` et `gho_count()`. Sa conception privilégie l'examen des séries et de leur couverture avec `sdg_coverage()`, plutôt que des vérifications simples avant le téléchargement.

## Pour aller plus loin

- Consultez [WHO xMart et les estimations sanitaires mondiales](ghe-xmart.html).
- Découvrez comment [visualiser les indicateurs](visualizing-indicators.html).
- Retrouvez le code dans le [dépôt GitHub](https://github.com/shanlong-who/DSIR) et proposez des corrections, des fonctions ou des demandes de fusion.
