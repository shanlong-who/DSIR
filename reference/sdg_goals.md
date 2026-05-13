# List SDG Goals

Fetches the list of Sustainable Development Goals from the UN SDG API.

## Usage

``` r
sdg_goals(include_children = FALSE)
```

## Arguments

- include_children:

  Logical. Include targets and indicators nested under each goal?
  Default `FALSE`.

## Value

A list (or [tibble](https://tibble.tidyverse.org/reference/tibble.html))
of SDG goals, or `NULL` when the service is unreachable.

## See also

[`sdg_targets()`](https://shanlong-who.github.io/DSIR/reference/sdg_targets.md),
[`sdg_indicators()`](https://shanlong-who.github.io/DSIR/reference/sdg_indicators.md),
[`sdg_data()`](https://shanlong-who.github.io/DSIR/reference/sdg_data.md).

## Examples

``` r
# \donttest{
sdg_goals()
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List?includechildren=false>
#> # A tibble: 17 × 4
#>    code  title                                                 description uri  
#>    <chr> <chr>                                                 <chr>       <chr>
#>  1 1     End poverty in all its forms everywhere               Goal 1 cal… /v1/…
#>  2 2     End hunger, achieve food security and improved nutri… Goal 2 see… /v1/…
#>  3 3     Ensure healthy lives and promote well-being for all … Goal 3 aim… /v1/…
#>  4 4     Ensure inclusive and equitable quality education and… Goal 4 foc… /v1/…
#>  5 5     Achieve gender equality and empower all women and gi… Goal 5 aim… /v1/…
#>  6 6     Ensure availability and sustainable management of wa… Goal 6 goe… /v1/…
#>  7 7     Ensure access to affordable, reliable, sustainable a… Goal 7 see… /v1/…
#>  8 8     Promote sustained, inclusive and sustainable economi… Goal 8 aim… /v1/…
#>  9 9     Build resilient infrastructure, promote inclusive an… Goal 9 foc… /v1/…
#> 10 10    Reduce inequality within and among countries          Goal 10 ca… /v1/…
#> 11 11    Make cities and human settlements inclusive, safe, r… Goal 11 ai… /v1/…
#> 12 12    Ensure sustainable consumption and production patter… Goal 12 ai… /v1/…
#> 13 13    Take urgent action to combat climate change and its … Climate ch… /v1/…
#> 14 14    Conserve and sustainably use the oceans, seas and ma… Goal 14 se… /v1/…
#> 15 15    Protect, restore and promote sustainable use of terr… Goal 15 fo… /v1/…
#> 16 16    Promote peaceful and inclusive societies for sustain… Goal 16 en… /v1/…
#> 17 17    Strengthen the means of implementation and revitaliz… The 2030 A… /v1/…
sdg_goals(include_children = TRUE)
#> Fetching:
#> <https://unstats.un.org/sdgs/UNSDGAPIV5/v1/sdg/Goal/List?includechildren=true>
#> # A tibble: 17 × 5
#>    code  title                                         description uri   targets
#>    <chr> <chr>                                         <chr>       <chr> <list> 
#>  1 1     End poverty in all its forms everywhere       Goal 1 cal… /v1/… <df>   
#>  2 2     End hunger, achieve food security and improv… Goal 2 see… /v1/… <df>   
#>  3 3     Ensure healthy lives and promote well-being … Goal 3 aim… /v1/… <df>   
#>  4 4     Ensure inclusive and equitable quality educa… Goal 4 foc… /v1/… <df>   
#>  5 5     Achieve gender equality and empower all wome… Goal 5 aim… /v1/… <df>   
#>  6 6     Ensure availability and sustainable manageme… Goal 6 goe… /v1/… <df>   
#>  7 7     Ensure access to affordable, reliable, susta… Goal 7 see… /v1/… <df>   
#>  8 8     Promote sustained, inclusive and sustainable… Goal 8 aim… /v1/… <df>   
#>  9 9     Build resilient infrastructure, promote incl… Goal 9 foc… /v1/… <df>   
#> 10 10    Reduce inequality within and among countries  Goal 10 ca… /v1/… <df>   
#> 11 11    Make cities and human settlements inclusive,… Goal 11 ai… /v1/… <df>   
#> 12 12    Ensure sustainable consumption and productio… Goal 12 ai… /v1/… <df>   
#> 13 13    Take urgent action to combat climate change … Climate ch… /v1/… <df>   
#> 14 14    Conserve and sustainably use the oceans, sea… Goal 14 se… /v1/… <df>   
#> 15 15    Protect, restore and promote sustainable use… Goal 15 fo… /v1/… <df>   
#> 16 16    Promote peaceful and inclusive societies for… Goal 16 en… /v1/… <df>   
#> 17 17    Strengthen the means of implementation and r… The 2030 A… /v1/… <df>   
# }
```
