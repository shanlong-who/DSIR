# Review of GHO data fetching design in gho.R

## User

请帮我看看R文件夹下的gho.R，你认为这个fetch GHO
data的流程，我设计的是否合适

## Assistant

Let me read the gho.R file to understand the current implementation.

The user wants me to review the GHO data fetching flow in gho.R and give
my assessment. Let me analyze the design carefully.

Key components to review: 1. `.gho_get()` - The core HTTP fetch with
OData paging 2.
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
and `.gho_build_url()` - The public API and URL building 3.
[`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
and `.gho_indicators_build_url()` - The catalog endpoint 4.
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md),
[`gho_has_data()`](https://shanlong-who.github.io/DSIR/reference/gho_has_data.md),
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md),
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md) -
Utility functions

5.  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md) -
    The cleaning and tidying function

Looking at what works well here: the fail-soft pattern handles network
issues gracefully by returning NULL with warnings rather than throwing
errors, OData paging is correctly implemented through the
`@odata.nextLink` mechanism, and the retry logic with timeout and
backoff is consistently applied across `.gho_get()` and
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md).
The fix for the
[`cli::cli_warn()`](https://cli.r-lib.org/reference/cli_abort.html) glue
injection vulnerability using `conditionMessage(e)` is solid, and
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
appears to have proper timeout handling.

The indicator catalog is efficiently memoized at the session level, and
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
uses helper functions to gracefully handle missing columns. The
`spatial_type` inference from the `area` column is a nice usability
feature with appropriate messaging.

A few things worth examining:
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
fetches the entire dataset just to extract unique dimension values,
which could be inefficient for large indicators—using `$select` to fetch
only the relevant column would be much faster. Also,
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
appears to be printing the URL somewhere, which creates some redundancy
since `.gho_get()` already does this, though this is intentional since
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
bypasses that function. There’s also a potential surprise where
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
might trigger a network call through its indicator name resolution, even
when called offline. Finally, when
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
encounters a NULL result, it returns an empty tibble without the
expected GHO column structure, which could cause issues downstream.

Looking at other functions,
[`gho_coverage()`](https://shanlong-who.github.io/DSIR/reference/gho_coverage.md)
uses base R’s [`split()`](https://rdrr.io/r/base/split.html) and
[`vapply()`](https://rdrr.io/r/base/lapply.html) for grouping operations
rather than dplyr, which is a reasonable choice to avoid extra
dependencies. The paging logic accumulates results by repeatedly
combining lists and then binding them together, which could
theoretically be memory-inefficient for very large datasets, though GHO
responses are typically bounded so this isn’t a practical concern. I
should verify that the OData syntax for filtering multiple areas using
the `in` operator is actually valid.

OData v4 does support the `in` operator, so that’s correct. However,
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
downloads the entire response when it only needs one column—it could be
more efficient by using the `select` parameter to fetch just that
specific dimension. The type check in
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
using [`is.data.frame()`](https://rdrr.io/r/base/as.data.frame.html) is
appropriate because `simplifyVector = TRUE` converts JSON object arrays
to data frames, while empty arrays become empty lists. There’s also a
potential inefficiency where
[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
calls `.gho_resolve_indicator_name()`, which in turn calls
`.gho_indicator_catalog()` on every invocation—

though this is mitigated by caching after the first network request. The
difference between `.gho_get()` returning an empty tibble with no
columns versus `.dsi_empty_clean()` returning a typed 15-column empty
tibble is intentional, since `.gho_get()` is a generic OData fetcher
rather than something specific to the unified schema. The more
significant issue is that
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
fetches all data without using `$select`, essentially downloading every
row of the indicator when it should be more selective.

There’s also a maintenance concern with
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
duplicating the httr2 request pattern from `.gho_get()` just to access
the `@odata.count` field. This creates a burden if the request logic
needs to change in one place but not the other. A better approach might
be to have a lower-level function that returns the full response body,
letting both functions use it without duplication.

The core design is solid for a lightweight OData client with good
fail-soft behavior, retry logic, and paging support. The real issue is
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
fetching all columns when it only needs one—using `$select` would be a
meaningful performance win, especially with large datasets. I can
confirm the URL builder properly handles multiple select columns by
comma-joining them, which is valid OData syntax.

整体设计很扎实——fail-soft 模式、retry/timeout 配对、OData
paging、session-level 缓存都做得干净。有几个值得讨论的点，一个算是真正的
bug，其余是设计权衡。

------------------------------------------------------------------------

**[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
没有用 `$select`（最值得改的地方）**

``` r

# 现在：下载 indicator 的全部列
res <- .gho_get(paste0("https://ghoapi.azureedge.net/api/", indicator))
```

但 `.gho_build_url()` 已经支持 `select` 参数了。对于 `NCDMORT3070`
这类大 indicator，这会拉取数十万行的全部字段，只是为了取某一列的
distinct 值。应该改成：

``` r

url <- .gho_build_url(indicator, select = dimension)
res <- .gho_get(url)
```

这个改动是低风险的，但在实际使用时性能差异会很明显。

------------------------------------------------------------------------

**[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
的 HTTP 调用是必要的重复**

它不走 `.gho_get()` 是因为需要读 `@odata.count` 而不是 `value`，这在
AGENTS.md 里有记录。可以接受，但这意味着日后调整 timeout 或 retry
逻辑时需要同步两处。一个更干净的做法是抽出底层 `.gho_perform(url)` 返回
parsed body，让 `.gho_get()` 和
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
都调它——但对当前规模来说可能是 over-engineering。

------------------------------------------------------------------------

**[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
失败时返回无列的空 tibble**

``` r

if (is.null(res)) tibble::tibble() else res
```

[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
失败时走 `.dsi_empty_clean()` 返回有类型的 15 列空 tibble，而
[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
失败时返回 0×0 的空
tibble。这是有意为之（[`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
的 schema 由 GHO 原始字段决定，不是统一 schema），但如果用户做
`gho_data(...) |> gho_clean()`
遇到网络故障，[`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
能正确处理 0
行输入，所以实际上不会出问题。这点是设计上的不对称，算是可接受的
trade-off。

------------------------------------------------------------------------

**其他几个小设计确认是合理的：**

- `area` 给了但 `spatial_type` 没给时自动推断并发 `cli_inform` 提示 —
  这个 UX 很好
- `val <- body$value` 用 `is.data.frame(val)` 检查（而不是
  `length > 0`）是正确的，因为 `simplifyVector = TRUE` 时空数组返回
  [`list()`](https://rdrr.io/r/base/list.html) 不是 `data.frame`
- `contains(tolower(...))` 的 OData 搜索用单引号转义处理是正确的

------------------------------------------------------------------------

**总结**

最值得提交一个修复的是
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
缺少 `$select`。其余的设计权衡都有合理依据，维持现状没问题。

修复
[`gho_dimensions()`](https://shanlong-who.github.io/DSIR/reference/gho_dimensions.md)
加上 `select = dimension` 参数。

考虑把 HTTP 调用逻辑抽到低层 `.gho_perform()` 以消除
[`gho_count()`](https://shanlong-who.github.io/DSIR/reference/gho_count.md)
的重复。
