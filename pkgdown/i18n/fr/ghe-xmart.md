---
title: "WHO xMart et estimations sanitaires mondiales"
output: rmarkdown::html_document
---

<!-- chunk:1 -->

DSIR 0.13.0 utilise `backend = 'auto'` par défaut et privilégie le service public xMart de l'OMS. Il essaie legacy uniquement si le code exact est absent d'un répertoire lu avec succès ou si le nombre d'observations de l'indicateur entier est confirmé comme nul. Une petite requête vérifie cette disponibilité avant les filtres de pays, d'année ou de dimension. Un résultat filtré vide ou une couverture partielle ne déclenche aucun basculement et ne combine pas les versions. Les valeurs explicites `backend = 'xmart'` et `backend = 'legacy'` fixent toujours le service. Les estimations sanitaires mondiales (GHE) utilisent toujours xMart. Un échec de téléchargement ne provoque jamais de changement de service. Les exemples nécessitant le réseau sont affichés sans exécution lors de la construction du tutoriel.

Le code est commun à la version anglaise. Les codes, les noms de champs et les libellés des sources restent inchangés. Pour commencer, consultez les [premiers pas avec DSIR](DSIR.html).

## Rechercher les codes GHO et conserver les dimensions nommées

<!-- chunk:2 -->

Le répertoire public fournit une route publiée et un identifiant d'indicateur. Les tables larges contiennent des dimensions nommées et des groupes de mesures numériques ; les tables longues contiennent des paires explicites de types et de membres de dimensions. DSIR convertit les deux formats vers ses colonnes brutes habituelles. `gho_clean()` conserve 15 colonnes par défaut. Les champs nommés facultatifs préservent le sens des catégories ; les métadonnées facultatives conservent les unités et une colonne `provider` pour chaque ligne.

Les observations GHO brutes contiennent `Provider` et l'attribut `who_provenance`. Les libellés manquants sont recherchés auprès du service enregistré, même si l'option de session a changé. Les origines inconnues de données importées restent à `NA`. Les positions peuvent différer des anciennes colonnes `Dim1`–`Dim3` ; préférez les filtres nommés.

Le répertoire xMart et l'ancien catalogue peuvent couvrir des codes et des versions de publication différents. Un code inconnu provoque un avertissement ; il n'est jamais remplacé par un code similaire. Les fonctions de requête GHO, y compris les horodatages, acceptent `backend`. Un argument explicite est prioritaire sur `DSIR.who_backend`, sans modifier cette option. Si l'option n'est pas définie, auto est utilisé. La recherche par mots-clés en mode auto consulte uniquement xMart. Utilisez `gho_indicators(backend = 'legacy')` pour explorer les codes propres à legacy et accéder au catalogue intégré daté si sa requête en ligne échoue. Employez le même backend pour rechercher les codes, les dimensions, les comptes, la couverture et les données.

Un basculement automatique émet un avertissement et enregistre `requested_backend`, le `backend` utilisé et `fallback_reason` dans l'attribut `who_provenance`, y compris pour les résultats scalaires de comptage et de disponibilité. Il conserve les codes ISO3 ou régionaux connus de l'OMS et les filtres d'année, mais ne traduit ni les dimensions nommées ou positionnelles, ni les codes de zone M49 ou natifs. Ces filtres empêchent le basculement ; ils ne sont jamais supprimés. Pour la recherche de dimensions, seuls `SpatialDim`, `SpatialDimType`, `TimeDim` et `TimeDimType` permettent un basculement. Fixez le service pour utiliser ses conventions propres. Un horodatage manquant ne provoque pas de changement. La sélection est vérifiée à chaque appel.

<!-- chunk:3 -->

Une requête réussie sans observation correspondante produit un message d'information. Dans ce cas, `gho_has_data()` renvoie `FALSE` et `gho_count()` renvoie `0L`. Les échecs de requête ou de lecture produisent un avertissement et une table vide ou `NA`. Un code inconnu du répertoire xMart produit un avertissement. Après une réponse HTTP 404 de l'ancien service, DSIR vérifie le catalogue avant de signaler l'absence d'un indicateur. L'échec de cette vérification ne prouve pas l'absence. Les échecs de requête et de lecture ne déclenchent jamais de basculement automatique.

## Explorer les choix disponibles dans les GHE

<!-- chunk:4 -->

Les références officielles des années et des sexes sont petites. La liste géographique utilise les observations toutes causes, tous âges et sexes réunis de l'année la plus récente. Les listes d'âges et de causes utilisent un petit extrait du premier État Membre disponible selon l'ordre ISO3, afin d'éviter des regroupements coûteux sur toute la base. Ces listes servent à l'exploration ; `ghe_coverage()` vérifie la couverture réelle de la sélection. Certains codes d'âge observés n'ont pas de libellé dans la référence publiée ; leurs libellés restent manquants.

Les champs de cause `level`, `cause_group`, `rankable` et `single_cause` proviennent du fournisseur. Celui-ci ne publie pas de code parent ; un code de groupe ne constitue pas un code parent. N'additionnez pas un total hiérarchique à ses sous-catégories.

## Télécharger les mesures choisies

<!-- chunk:5 -->

Les effectifs sont exprimés en décès ou en années, les taux pour 100 000 habitants et les proportions en pourcentage. Les effectifs conservent les bornes d'incertitude publiées. L'API ne fournit pas de bornes pour les taux ou les proportions ; DSIR ne les reconstitue pas par calcul.

Un taux pour l'âge `TOTAL` est un taux brut ; un groupe quinquennal sélectionné donne un taux spécifique à l'âge. Les groupes d'âge agrégés peuvent se chevaucher : n'additionnez pas tous les groupes renvoyés pour obtenir un total.

`measure = NULL` renvoie toutes les mesures prises en charge sur des lignes distinctes. Le nombre de lignes source diffère donc du nombre de lignes de la table longue finale. La couverture compte les observations source. Les requêtes dont tous les filtres sont `NULL` sont refusées. Au-delà d'un million de lignes source, réduisez les filtres ou définissez explicitement `DSIR.who_max_rows`. Les filtres volumineux utilisent en interne une requête POST avec un corps texte.

## Téléchargements reproductibles et révisions des estimations

<!-- chunk:6 -->

Les références sont mises en cache en mémoire pendant dix minutes. `snapshot()` écrit uniquement dans le chemin choisi. Les versions des GHE peuvent réviser les années antérieures : les estimations de 2023 publiées par l'OMS en 2026 ne sont pas automatiquement comparables à l'ancienne publication de 2021. DSIR utilise `DEX_CMS/GHE_FULL`, et non les anciennes vues `GHE_FULL_FOCUS` ou `GHE_FULL_DD`.

## Population standard OMS 2026

Depuis DSIR 0.11.0, `who_std_pop` utilise la population standard OMS 2026. Le tableau officiel comprend 18 groupes d'âge jusqu'à `85+`. Les pourcentages arrondis totalisent 100,02 ; DSIR les normalise à 100. `std_million` représente des effectifs proportionnels ramenés à un million, sans arrondi à l'entier.

<!-- chunk:7 -->

L'ancien objet est remplacé. Regroupez les âges observés selon les groupes publiés avant d'appliquer les poids. Aucun découpage plus fin de `0-4` ou de `85+` n'est fourni. Source : [WHO/HSA/DDA/GHE/2026.4, tableau 1, page 6](https://cdn.who.int/media/docs/default-source/gho-documents/global-health-estimates/ghe2023_who_standard_population.pdf).

Étape suivante : [visualiser les indicateurs](visualizing-indicators.html).
