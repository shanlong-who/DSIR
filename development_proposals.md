# DSIR 软件包后续版本改进与功能扩展设想

本文件整理了针对 `DSIR` 包（当前
v0.7.1）后续版本升级的改进设想与功能扩展方案，供作者评估决策。

------------------------------------------------------------------------

## 1. GHO 系列函数性能与过滤改进

### 1.1 `gho_dimensions()` 性能优化（使用 OData `$select`）

- **当前痛点**：目前
  [gho_dimensions()](file:///c:/Users/User/OneDrive%20-%20World%20Health%20Organization/Documents/CAT/Claude/DSIR/R/gho.R#L416-L424)
  通过下载指定指标的**全量数据**，再在本地提取维度的唯一值。若指标数据量庞大（如数十万行的死亡率数据），会导致严重的网络延迟与内存占用。

- **改进方案**：在 API 请求中添加 OData 的 `$select`
  参数，仅下载目标维度列的数据。

- **概念代码实现**：

  ``` r

  gho_dimensions <- function(indicator, dimension = "SpatialDimType") {
    stopifnot(is.character(indicator), length(indicator) == 1L, nzchar(indicator))
    stopifnot(is.character(dimension), length(dimension) == 1L)

    # 构建仅选择目标维度的 URL，大幅减少数据传输量
    url <- .gho_build_url(indicator, select = dimension)
    res <- .gho_get(url)

    if (is.null(res) || !dimension %in% names(res)) return(character())
    vals <- unique(res[[dimension]])
    sort(vals[!is.na(vals)])
  }
  ```

### 1.2 `gho_data()` 增加服务端多维度过滤支持

- **当前痛点**：目前的
  [gho_data()](file:///c:/Users/User/OneDrive%20-%20World%20Health%20Organization/Documents/CAT/Claude/DSIR/R/gho.R#L113-L120)
  仅支持按空间范围和年份过滤。GHO
  包含大量的性别（`Sex`）、年龄段（`AgeGroup`）等核心拆分维度（存在于
  `Dim1`/`Dim2`/`Dim3`
  字段）。若用户需要特定子集，必须下载全量数据后再进行本地过滤。

- **改进方案**：在
  [`gho_data()`](https://shanlong-who.github.io/DSIR/reference/gho_data.md)
  中增加 `filter_extra`（或支持 `...`），允许用户直接传递额外的 OData
  `$filter` 语句。

- **概念设计**：

  ``` r

  gho_data <- function(indicator, spatial_type = NULL, area = NULL,
                       year_from = NULL, year_to = NULL, filter_extra = NULL) {
    # 在内部 .gho_build_url 中拼接额外的自定义过滤条件
    # 例如：filter_extra = "Dim1 eq 'FMLE' and Dim2 eq 'YEARS15-49'"
  }
  ```

### 1.3 `gho_indicators()` 增加缓存刷新控制

- **当前痛点**：目前
  [`gho_clean()`](https://shanlong-who.github.io/DSIR/reference/gho_clean.md)
  依赖的指标目录缓存在包内部的 `.dsi_cache`
  环境中。如果用户在长时间运行的 R
  会话中需要强制刷新目录，无法通过公开接口操作。

- **改进方案**：为
  [`gho_indicators()`](https://shanlong-who.github.io/DSIR/reference/gho_indicators.md)
  增加 `force_refresh` 参数。

- **概念设计**：

  ``` r

  gho_indicators <- function(search = NULL, force_refresh = FALSE) {
    if (force_refresh) {
      .dsi_cache$gho_indicator_catalog <- NULL
    }
    # 正常执行获取流程...
  }
  ```

------------------------------------------------------------------------

## 2. 可视化工具链优化策略

遵循您之前拒绝 `ggbar()`/`ggcol()`
以避免引入过于琐碎包装器的设计哲学，对于可视化的扩展建议采取“**文档赋能为主，高门槛图表封装为辅**”的策略。

### 2.1 方案 A：新增“指标可视化” Vignette（推荐）

无需增加包体积和新函数，编写一篇专门的 Vignette（如
[`vignette("visualizing-indicators")`](https://shanlong-who.github.io/DSIR/articles/visualizing-indicators.md)），指导用户如何结合
`DSIR` 规范的 15 列
Schema、[theme_dsi()](file:///c:/Users/User/OneDrive%20-%20World%20Health%20Organization/Documents/CAT/Claude/DSIR/R/theme_dsi.R#L50-L92)
以及 ggplot2 绘制高频图表： \* **置信区间带状图**：使用
`geom_ribbon(aes(ymin = low, ymax = high))` 配合趋势折线图。 \*
**多维度分面图**：利用 `dim1` / `dim2` 配合 `facet_wrap()`。

### 2.2 方案 B：仅引入难以用原生 ggplot2 编写的全球卫生专业图表

若确需在包中增加制图函数，建议只引入以下两类具有较高编写成本的专业图表：

#### ① 森林对比图（置信区间对比图）

- **用途**：用于横向对比多个国家在某年份的指标点估计值及其置信区间（`low`
  至 `high`）。

- **接口设计**：

  ``` r

  ggforest <- function(df, title = NULL) {
    # 自动过滤多余年份，保留最新/指定年份，绘制 errorbar
    # 使用 theme_dsi() 进行美化
  }
  ```

#### ② 进展哑铃图 (Dumbbell Progress Plot)

- **用途**：对比各国家在两个特定时间点（例如 SDG 基线 2015 年 vs 2023
  最新年份）的指标进展变化。

- **接口设计**：

  ``` r

  ggdumbbell <- function(df, year_start, year_end) {
    # 内部将数据转换为宽表，绘制 geom_segment() 和 geom_point()
    # 自动根据进展是正向还是负向标记哑铃骨架的颜色
  }
  ```

------------------------------------------------------------------------

## 3. 全球卫生分析新函数扩展

针对日常分析工作流中的高频痛点，建议在后续版本中考虑引入以下高阶处理函数：

### 3.1 进度追踪与未来投影函数 (SDG Target Progress)

- **`calc_aarr(year, value)` (Average Annual Rate of Reduction)**
  - **用途**：计算平均年降低率（广泛应用于评估孕产妇死亡率、儿童死亡率等下降指标的年均进展速度）。
  - **公式**：
    ``` math
    \text{AARR} = 1 - \left(\frac{V_t}{V_0}\right)^{\frac{1}{t - t_0}}
    ```
- **`project_indicator(df, target_year = 2030)`**
  - **用途**：基于历史数据进行简单线性或对数线性趋势外推，预测目标年份（如
    2030 年）的指标值，帮助评估能否达成 SDG Target。

### 3.2 地区人口加权聚合函数 (Regional Aggregator)

- **`aggregate_regions(df, method = "weighted", weight_col = "population")`**
  - **用途**：[geomean()](file:///c:/Users/User/OneDrive%20-%20World%20Health%20Organization/Documents/CAT/Claude/DSIR/R/geomean.R#L40-L106)
    目前提供了解构指标的聚合，但在计算 WHO 区域（如 WPR,
    SEAR）或全球层面的指标估计值时，必须根据国家人口进行加权汇总。
  - **功能**：接收含有 ISO3 的清洗后数据，自动关联包内自带的
    [who_countries](file:///c:/Users/User/OneDrive%20-%20World%20Health%20Organization/Documents/CAT/Claude/DSIR/R/data.R#L9-L81)
    获取所属 WHO 区域，并结合内置的年度国家人口权重进行加权汇总。

### 3.3 WHO 国家名称标准化工具

- **`who_name_overrides` (命名映射向量) 或
  `standardize_country_names()`**
  - **用途**：由于外部数据源（如 World Bank, IHME）的国名各异（例如
    “Iran (Islamic Republic of)” vs “Iran” vs “Iran, Islamic
    Rep.”），分析师在合并外部数据到 `DSIR`
    工作流时，国名关联往往非常痛苦。
  - **功能**：内置一个包含全球卫生数据常见缩写别名的映射表，方便用户将任意拼写的国名一键标准化为
    `DSIR` 支持的 ISO3 编码。

------------------------------------------------------------------------

## 4. 潜在风险与维护建议

1.  **保持依赖项轻量**：在引入加权聚合、国名标准化等新功能时，尽量使用
    Base R 语法或 `rlang`/`tibble` 依赖，避免将 `dplyr` 或 `tidyr` 从
    `Suggests` 提升到 `Imports`。
2.  **网络稳定性**：任何新引入的 API
    级预处理（例如获取人口权重、目标定义）均需严格遵守现有的 fail-soft
    规范，即在无网络时发出警告并返回空值/NA，而不能引起程序崩溃。
