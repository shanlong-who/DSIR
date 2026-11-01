---
title: "Visualiser les indicateurs"
output: rmarkdown::html_document
---

<!-- chunk:1 -->

<!-- chunk:2 -->

`gho_clean()`, `sdg_clean()` et `ghe_clean()` renvoient par défaut des tibbles `dsir_data` avec la même structure de base à 15 colonnes. Utilisez `output = "tibble"` pour obtenir un tibble ordinaire. Quelques exemples `ggplot2` couvrent ainsi les graphiques courants : tendances avec bandes d'incertitude, ventilations par sexe ou âge, comparaisons entre pays avec intervalles, graphiques en haltères et suivi des progrès avec `aarr()`.

La méthode expérimentale `plot()` permet de tracer des tendances annuelles et des comparaisons entre pays pour une même année, après vérification des données. Les exemples `ggplot2` ci-dessous permettent d'autres analyses et personnalisations. Le code et les libellés des graphiques sont communs à la version anglaise ; les explications sont traduites ici. Pour l'installation et l'accès aux données, consultez les [premiers pas avec DSIR](DSIR.html).

## Données d'exemple

Les graphiques utilisent la structure nettoyée. Dans une analyse réelle, les données pourraient provenir des API :

<!-- chunk:3 -->

Pour permettre la construction hors ligne et garantir la reproductibilité, nous simulons un petit jeu de données de même structure : un indicateur illustratif de mortalité prématurée due aux maladies non transmissibles (MNT), pour six pays du Pacifique occidental entre 2000 et 2023. `dim1` indique le sexe ; `low` et `high` contiennent les bornes illustratives.

**Toutes les valeurs et tous les graphiques de cette page reposent sur des données simulées, et non sur des estimations publiées par l'OMS.**

<!-- chunk:4 -->

## Graphiques S3 expérimentaux

Les résultats des fonctions de nettoyage conservent les métadonnées d'acquisition et de nettoyage dans les attributs de l'objet. La table simulée ci-dessus ne possède pas d'historique d'acquisition ; la conversion explicite n'en crée pas. Les unités sont définies ici dans le cadre de la simulation.

<!-- chunk:5 -->

<!-- chunk:6 -->

Les résultats sont des objets ggplot ordinaires. Les bornes fournies sont représentées par des intervalles, sans supposer de niveau de confiance. Une comparaison utilise une année commune. Les lignes de tendance sont interrompues en cas de valeur manquante ou d'écart supérieur à un an. Aucune méthode n'agrège les données ni ne convertit les unités. Sélectionnez un seul indicateur, une seule série ou mesure et une seule unité, puis filtrez les autres strates ou indiquez les colonnes avec `group` et `facet`. Par exemple, les tendances par sexe peuvent utiliser `group = "dim1"` et `facet = "iso3"`. Si des dimensions variables ont été omises lors du nettoyage, recommencez avec les options de conservation. Après modification de champs nécessaires au graphique marqués `needs_review`, vérifiez les données puis utilisez des correspondances ggplot explicites.

## Tendances avec une bande d'incertitude

`low` et `high` correspondent directement à `geom_ribbon()`. Filtrez d'abord une seule strate : ici, les deux sexes réunis (`dim1 == "SEX_BTSX"`). `theme_dsi_facet()` est la variante du thème adaptée aux facettes.

<!-- chunk:7 -->

Les intervalles simulés servent à illustrer le graphique. Pour une analyse réelle, vérifiez la définition des intervalles d'incertitude dans la source.

## Ventilations à partir de dim1 / dim2 / dim3

Dans l'ancien GHO, les ventilations par sexe, âge ou autre catégorie figurent dans `dim1`, `dim2` et `dim3`. Associez la strate à `colour` et utilisez une palette accessible aux personnes daltoniennes, comme `scale_color_viridis_d()` de `ggplot2`. Les données simulées reprennent ces dimensions positionnelles ; adaptez les colonnes aux dimensions nommées lorsque vous utilisez xMart.

<!-- chunk:8 -->

## Comparaison entre pays avec intervalles

Pour comparer les pays à un moment donné avec leurs intervalles d'incertitude, sélectionnez la dernière année par pays et utilisez `geom_pointrange()`. Trier l'axe selon la valeur facilite la lecture. Ici, la dernière année est identique pour tous les pays ; vérifiez ce point avec des données réelles.

<!-- chunk:9 -->

## Graphique en haltères pour comparer les progrès

Un graphique en haltères compare deux dates par pays. Construisez une table large à partir de deux sélections filtrées et d'une jointure, sans package supplémentaire de restructuration. Les couleurs proviennent de la palette Okabe–Ito, adaptée aux personnes daltoniennes.

<!-- chunk:10 -->

## Suivre les progrès avec aarr()

`aarr()` calcule le taux annuel moyen de réduction (AARR), une mesure courante du suivi des progrès à l'OMS et à l'UNICEF. Elle s'utilise directement dans `summarise()` avec `.by` sur les données nettoyées. Attention au signe : **une valeur positive indique une baisse de l'indicateur**.

<!-- chunk:11 -->

Une projection simple prolonge la dernière valeur selon l'AARR observé. C'est un outil d'examen rapide, qui ne remplace pas les modèles et hypothèses propres à chaque indicateur utilisés pour les projections officielles à l'horizon 2030.

<!-- chunk:12 -->

Pour poursuivre : [WHO xMart et estimations sanitaires mondiales](ghe-xmart.html).
