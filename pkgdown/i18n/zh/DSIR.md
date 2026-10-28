---
title: "DSIR 入门"
output: rmarkdown::html_document
---

<!-- chunk:1 -->

DSIR 是面向全球卫生数据工作的轻量级 R 包，提供 WHO 会员国元数据、GHO 和联合国 SDG API 客户端，以及可复用的 WHO 风格 `ggplot2` 主题和 `flextable` 表格格式。它面向卫生专业人员、WHO 工作人员和全球卫生研究人员，帮助完成日常重复任务。

本教程介绍典型流程：查询国家信息，从 GHO 和 SDG 获取数据，清洗原始响应，并制作报告图表。WHO xMart 与 GHE 的详细用法见[专门教程](ghe-xmart.html)。

## 安装与准备

在 R 中运行以下命令，从 CRAN 安装：

```r
install.packages("DSIR")
```

本教程还使用 `dplyr` 和 `ggplot2`；如未安装，请先运行 `install.packages(c("dplyr", "ggplot2"))`。

<!-- chunk:2 -->

示例代码、函数名、字段名及图中的文字与英文版共用，便于直接运行和对照。数据源返回的标签不会因网站语言而改变。

## WHO 会员国元数据

`who_countries` 数据表列出 WHO 的 194 个会员国，包括 ISO3、ISO2、联合国 M49 代码、正式名称、简称和 WHO 区域。西太平洋区域国家还可通过 `is_pic` 字段识别 14 个太平洋岛国。

<!-- chunk:3 -->

DSIR 还为每个 WHO 区域提供预定义的 ISO3 代码向量。

<!-- chunk:4 -->

太平洋岛国在人口和地理方面具有鲜明特点，常作为一组进行分析。`is_pic` 标记便于筛选这组国家。

<!-- chunk:5 -->

`iso3_to_region()` 可查询一组 ISO3 代码对应的 WHO 区域。它支持向量输入；不匹配 WHO 会员国的代码返回 `NA`。

<!-- chunk:6 -->

将外部数据按 ISO3 代码关联到 WHO 区域时，这个函数很方便。

`iso3_to_m49()` 将 ISO3 代码转换为联合国 M49 数字代码。例如 WHO GHO 使用 `"PHL"`，联合国 SDG 使用 `"608"`。结果是补齐前导零的三字符字符串，与 `who_countries$m49_code` 一致。

<!-- chunk:7 -->

通常可以省略显式转换：`sdg_data()` 和 `sdg_coverage()` 的 `area` 参数接受 ISO3 代码，并在内部完成查询。

构建网站和 R 包时，联网示例及使用其结果的图表只展示代码，不执行。若希望在渲染本教程时执行，请在渲染会话中设置 `DSIR_BUILD_LIVE_VIGNETTE=true`。

## 下载前检查数据可用性

GHO 公共目录有许多指标，但单个指标未必覆盖需要的国家或年份。在调用 `gho_data()` 完整下载前，可使用三个辅助函数查询可用性，而不下载完整观测数据。

`gho_has_data()` 检查某个指标及筛选条件是否有数据，适合初步筛选候选指标。

<!-- chunk:8 -->

结果为 `TRUE`、`FALSE` 或 `NA`。请求失败时返回 `NA`，包括代码不在当前公共目录中的情况。

`gho_count()` 返回相同筛选条件下的行数，便于估计下载规模。

<!-- chunk:9 -->

`gho_coverage()` 按国家汇总年份范围和观测数，只请求 `SpatialDim` 和 `TimeDim` 字段，因此传输量较小。

<!-- chunk:10 -->

## 查询数据源的更新时间

实验性的 `gho_last_updated()` 查询一个指标在所有地区、年份和维度的现有观测记录中，最新的非缺失时间戳。显式 `backend` 参数优先于 `DSIR.who_backend`；两者都未设置时使用 legacy。

<!-- chunk:11 -->

legacy 使用 `Date` 字段，xMart 使用 `Sys_CommitDateUtc`。DSIR 尚未确认 legacy 的 `Date` 是官方修改或发布日期；xMart 的系统提交时间可能反映数据处理。两者都不是最新观测年份。每次日期查询最多返回一行；xMart 还使用已缓存的指标目录和表字段信息。请求失败时不会自动切换 backend。顺序查询全部指标可能需要较长时间。

默认仍为原来的八列。`diagnostics = TRUE` 额外返回 `reason`、`stage`、`http_status`、`timestamp_kind`、`provider_route` 和 `provider_indicator`，不增加请求。`directory_not_listed` 表示成功读取的目录未列出该代码，不等于 GHO 代码无效。`http_error` 和 `request_failed` 区分 HTTP 错误与连接失败；`timestamp_field_missing` 和 `timestamp_missing` 区分没有时间字段与没有非缺失时间戳。目录请求成功不表示观测请求可用。`checked_at` 是检查开始时间，不是数据获取或源数据修改时间。多个指标共用系统时间戳不能证明数值同时改变；实际数值差异应通过快照比较。

联合国 SDG API 提供整个数据库的更新时间，没有对应的指标级数据更新时间字段：

<!-- chunk:12 -->

两个函数都返回一行，包含 `source`、`backend`、`scope`、`indicator`、`updated`、`timestamp_field`、`checked_at` 和 `status`。`updated` 保留原始字符串和时区信息；未注明的时区不会被假定为 UTC。`checked_at` 是 UTC 格式的查询开始时间。

`status` 区分 `"ok"`、`"not_available"`（未提供时间戳）和 `"failed"`（查询映射、请求或响应验证失败）。缺少时间戳不代表没有观测数据。SDG 的 `scope` 为 `"database"`，`backend` 和 `indicator` 为缺失值。整库时间不表示所有序列都在该时刻改变；序列发布批次代码和元数据文档更新日期不能替代数据更新时间。

## 从 GHO 获取指标数据

通常分三步：搜索指标代码、获取数据、清洗响应。`area` 可接受较长的 ISO3 向量，因此一次调用即可获取整个区域的数据。

### 第一步：搜索指标

<!-- chunk:13 -->

从结果中选择 `IndicatorCode`，将它传给下一步的 `gho_data()`。

### 第二步：获取数据

<!-- chunk:14 -->

这里一次获取西太平洋区域全部 28 个会员国的数据。

### 第三步：清洗原始响应

`gho_clean()` 生成 **DSIR 统一的 15 列指标数据结构**，与 `sdg_clean()` 的默认结果一致。字段为 `source`（`"gho"`）、`id`、`indicator`、`location`、`iso3`、`location_name`、`year`、`value`、`value_num`、`low`、`high`、`series` 以及三个 GHO 维度字段 `dim1`–`dim3`。已知地理位置会补充相应名称；原始响应中缺少的字段用相应类型的 `NA` 填充。

<!-- chunk:15 -->

## 使用 geomean() 汇总指标

部分卫生指标使用分项值的几何平均数，而非算术平均数。例如，全民健康覆盖（UHC）服务覆盖指数通过嵌套几何平均汇总 14 个示踪指标。DSIR 提供 `geomean()`：

<!-- chunk:16 -->

`geomean()` 对缺失值、零值和负值有明确处理规则，详见 `?geomean`。这个辅助函数可减少自行编写指标汇总代码时的常见错误。

## 使用 theme_dsi() 和 theme_dsi_facet() 绘图

DSIR 提供两个相配的 `ggplot2` 主题，用于 WHO 风格图形：简洁的绘图区、适度的网格和一致的强调色。在面向 WHO 的图表中，可分别用它们替代 `theme_minimal()` 和 `theme_bw()`。

一般而言，**单图使用 `theme_dsi()`，分面图使用 `theme_dsi_facet()`**。两者的字体、标题和图例处理一致；分面版本增加边框、浅色分面标题背景和面板间距，帮助区分小图。

### 单图：`theme_dsi()`

`theme_dsi()` 使用半框坐标轴、浅色网格和 WHO 蓝色的轴线。默认显示两个方向的网格；`grid = "y"` 可只保留水平网格。

<!-- chunk:17 -->

柱形图可搭配 `scale_y_dsi_col()`；若数值映射到 `x`，则使用 `scale_x_dsi_col()`。它们封装 `scale_*_continuous()`，去掉数值轴下端的扩展，使柱形贴合坐标轴。

<!-- chunk:18 -->

### 分面图：`theme_dsi_facet()`

多个面板重复使用强调色轴线时，画面容易显得繁杂。`theme_dsi_facet()` 改用完整面板边框、浅灰分面标题背景和面板间距，使各组数据更清晰。

<!-- chunk:19 -->

`strip_fill` 可调整分面标题背景色，例如用基于 WHO 强调色的浅蓝色突出分组。

<!-- chunk:20 -->

## 使用 dsi_flextable_defaults() 制作表格

`dsi_flextable_defaults()` 全局设置 WHO 风格的 `flextable` 默认格式，包括 booktabs 风格、粗体表头和适度的内边距。在报告开头调用一次，后续 `flextable()` 就会沿用这些设置。

<!-- chunk:21 -->

## 使用 SDG 指标

`sdg_data()` 和 `sdg_clean()` 同样采用“获取后清洗”的流程。主要区别是指标代码使用带点的 SDG 格式（例如 `"3.4.1"`），并且保留字符型的原始 `value`：API 中有些行包含 `"<0.1"` 或汇总说明等非数值内容。清洗后的 `value_num`、`low` 和 `high` 为数值型，无法转换时为 `NA`。

`sdg_indicators()` 的可选 `search` 参数与 `gho_indicators()` 类似：多个关键词按“且”组合，在指标说明中进行不区分大小写的匹配。SDG 指标列表较短（约 250 行），且接口不是 OData，因此筛选在客户端执行。

<!-- chunk:22 -->

`sdg_data()` 和 `sdg_coverage()` 的 `area` 可接受 ISO3 代码（内部通过 `iso3_to_m49()` 转换）或联合国 M49 数字代码。因此 `wpro_cty`、`afro_cty` 等区域向量可直接使用。一次调用中不要混用两种格式。

<!-- chunk:23 -->

<!-- chunk:24 -->

默认情况下，`sdg_clean()` 与 `gho_clean()` 都生成 15 列结构，可通过 `bind_indicators()` 合并。SDG 数据填入 `series`；会员国的 `iso3` 通过 `m49_to_iso3()` 解析。GHO 专用的 `dim1`–`dim3` 保持为 `NA`。

### 保留有名称的 SDG 维度

SDG 维度位于 `sdg$dimensions` 的命名字段中，并非 GHO 的位置维度。默认 15 列结果省略这些字段；分析分层数据时应显式保留：

<!-- chunk:25 -->

结果会增加字符列，如 `dim_age`、`dim_location`、`dim_sex`、`dim_reporting_type`、`dim_quantile` 和 `dim_type_of_household`。实际列名取决于 API 返回的维度。代码保持原样，不会给缺失类别擅自赋予总人群代码。`keep_metadata = TRUE` 还可保留单位和其他属性。

使用数据源中的准确名称和代码选择序列与人群分层：

<!-- chunk:26 -->

这些筛选在完成分页下载后于本地执行。同一维度内的多个值按“或”组合，不同维度之间按“且”组合。若请求的维度不存在，会发出警告并返回零行，避免静默忽略人群限制。

2026 年 9 月 30 日核对的联合国 3.8.2 目录列出按 2025 年修订定义发布的序列 `SH_OOP_XPD_EARNNET40`。GHO 的 `FINANCIALHARDSHIP_PROPORTIONOFPOP` 还在 `Dim1` 中包含大额卫生支出和致贫性卫生支出分项；它们不是该联合国目录中的独立序列，也不能通过保留 SDG 维度来重建。参见 [WHO 定义与分项说明](https://www.who.int/data/gho/indicator-metadata-registry/imr-details/376)。

### 了解维度含义并保留来源信息

`sdg_dimensions()` 可查询各序列的官方类别和标签，无需下载观测数据。列出的类别不一定在每个国家都有观测值。

<!-- chunk:27 -->

`code` 列是筛选所用的 JSON API 代码，`sdmx` 是另一种表示方式。`kind` 区分维度与属性，例如单位和数据性质。

同时保留来源信息与人群维度：

<!-- chunk:28 -->

`keep_metadata` 将返回的属性保存为 `attr_*` 列，还保留来源、时间细节或覆盖范围、基期、值类型和地理信息网址。脚注及相关指标、目标和具体目标代码以列表列保存，可保留多个条目。建议使用 RDS 保存这种结构。

GHO 可以直接显示各位置维度的类型。以下经济困难指标代码截至 2026 年 10 月 6 日不在公共 xMart 目录中，因此示例显式选择 `legacy` 数据服务。

<!-- chunk:29 -->

类型来自每条观测的 `Dim1Type`–`Dim3Type`，不会根据代码前缀推断，也不假设整个指标的类型恒定。GHO 元数据包括获取数据的 `provider`、原始来源代码、观测标识、`footnotes` 中的说明、地理与时间类型、上级地理位置、更新时间和时间区间。两个可选参数都不改变默认的 15 列结果。

`sdg_data()` 在本地筛选前验证 API 声明的分页信息和总行数。下载不完整时，发出警告并返回零行。`sdg_coverage()` 保留这些警告，也接受 `series` 和 `dimensions` 筛选；不筛选时，其观测数包含每个地区和序列下的所有分层。

### 使用 bind_indicators() 合并 GHO 和 SDG

`bind_indicators()` 可将任意数量的已清洗数据表按行合并。`source`（`"gho"` 或 `"sdg"`）便于按来源筛选或分面。

额外字段（包括命名的 SDG 维度）会保留；缺少相应字段的输入补入对应类型的缺失值。合并数据行不会统一不同来源的代码或指标定义。

<!-- chunk:30 -->

### 使用 sdg_coverage() 查看序列覆盖情况

单个 SDG 指标可能包含多个**序列**，例如不同疫苗、性别分层或死因，各自具有不同的国家和年份覆盖范围。指标 `"3.b.1"` 的示例包括 DTP3、MCV2、PCV3 和 HPV 四个序列，较新疫苗的时间覆盖范围比 DTP3 短。

`sdg_coverage()` 按 `(location, series)` 汇总年份范围和观测数，便于在分析前确认有哪些序列以及各自的覆盖情况。

<!-- chunk:31 -->

DSIR 未为 SDG 提供与 `gho_has_data()` 和 `gho_count()` 对应的函数。现有设计优先通过 `sdg_coverage()` 回答“有哪些序列及其覆盖范围”，而非增加下载前的简单可用性检查。

## 下一步

- 阅读[WHO xMart 与全球卫生估计](ghe-xmart.html)。
- 学习[卫生指标可视化](visualizing-indicators.html)。
- 在 [GitHub 仓库](https://github.com/shanlong-who/DSIR)查看源码，提交问题、功能建议或拉取请求。
