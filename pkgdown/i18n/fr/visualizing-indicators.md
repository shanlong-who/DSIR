---
title: "Visualiser les indicateurs"
output: rmarkdown::html_document
---

<!-- chunk:1 -->

<!-- chunk:2 -->

`gho_clean()` et `sdg_clean()` renvoient la même structure à 15 colonnes. Quelques exemples `ggplot2` couvrent ainsi les graphiques courants : tendances avec bandes d'incertitude, ventilations par sexe ou âge, comparaisons entre pays avec intervalles, graphiques en haltères et suivi des progrès avec `aarr()`.

Ces exemples restent du code `ggplot2` directement adaptable à votre projet, sans ajouter de fonctions graphiques spécialisées au package. Le code et les libellés des graphiques sont communs à la version anglaise ; les explications sont traduites ici. Pour l'installation et l'accès aux données, consultez les [premiers pas avec DSIR](DSIR.html).

## Données d'exemple

Les graphiques utilisent la structure nettoyée. Dans une analyse réelle, les données pourraient provenir des API :

<!-- chunk:3 -->

Pour permettre la construction hors ligne et garantir la reproductibilité, nous simulons un petit jeu de données de même structure : un indicateur illustratif de mortalité prématurée due aux maladies non transmissibles (MNT), pour six pays du Pacifique occidental entre 2000 et 2023. `dim1` indique le sexe ; `low` et `high` contiennent les bornes illustratives.

**Toutes les valeurs et tous les graphiques de cette page reposent sur des données simulées, et non sur des estimations publiées par l'OMS.**

<!-- chunk:4 -->

## Tendances avec une bande d'incertitude

`low` et `high` correspondent directement à `geom_ribbon()`. Filtrez d'abord une seule strate : ici, les deux sexes réunis (`dim1 == "SEX_BTSX"`). `theme_dsi_facet()` est la variante du thème adaptée aux facettes.

<!-- chunk:5 -->

Les intervalles simulés servent à illustrer le graphique. Pour une analyse réelle, vérifiez la définition des intervalles d'incertitude dans la source.

## Ventilations à partir de dim1 / dim2 / dim3

Dans l'ancien GHO, les ventilations par sexe, âge ou autre catégorie figurent dans `dim1`, `dim2` et `dim3`. Associez la strate à `colour` et utilisez une palette accessible aux personnes daltoniennes, comme `scale_color_viridis_d()` de `ggplot2`. Les données simulées reprennent ces dimensions positionnelles ; adaptez les colonnes aux dimensions nommées lorsque vous utilisez xMart.

<!-- chunk:6 -->

## Comparaison entre pays avec intervalles

Pour comparer les pays à un moment donné avec leurs intervalles d'incertitude, sélectionnez la dernière année par pays et utilisez `geom_pointrange()`. Trier l'axe selon la valeur facilite la lecture. Ici, la dernière année est identique pour tous les pays ; vérifiez ce point avec des données réelles.

<!-- chunk:7 -->

## Graphique en haltères pour comparer les progrès

Un graphique en haltères compare deux dates par pays. Construisez une table large à partir de deux sélections filtrées et d'une jointure, sans package supplémentaire de restructuration. Les couleurs proviennent de la palette Okabe–Ito, adaptée aux personnes daltoniennes.

<!-- chunk:8 -->

## Suivre les progrès avec aarr()

`aarr()` calcule le taux annuel moyen de réduction (AARR), une mesure courante du suivi des progrès à l'OMS et à l'UNICEF. Elle s'utilise directement dans `summarise()` avec `.by` sur les données nettoyées. Attention au signe : **une valeur positive indique une baisse de l'indicateur**.

<!-- chunk:9 -->

Une projection simple prolonge la dernière valeur selon l'AARR observé. C'est un outil d'examen rapide, qui ne remplace pas les modèles et hypothèses propres à chaque indicateur utilisés pour les projections officielles à l'horizon 2030.

<!-- chunk:10 -->

Pour poursuivre : [WHO xMart et estimations sanitaires mondiales](ghe-xmart.html).
