# ============================================================
# DSIR Theme Demo
# ============================================================

library(DSIR)
library(ggplot2)
library(flextable)

has_patchwork <- requireNamespace("patchwork", quietly = TRUE)
has_officer   <- requireNamespace("officer",   quietly = TRUE)

# ------------------------------------------------------------
# 1. theme_dsi() \u2014 ggplot2 theme showcase
# ------------------------------------------------------------

# Scatter plot
p1 <- ggplot(msleep, aes(bodywt, brainwt, color = vore)) +
  geom_point(size = 2, alpha = 0.7, na.rm = TRUE) +
  scale_x_log10() +
  scale_y_log10() +
  labs(
    title    = "Brain vs Body Weight",
    subtitle = "Mammalian species from msleep dataset",
    x = "Body weight (kg, log scale)",
    y = "Brain weight (kg, log scale)",
    color = "Diet",
    caption = "Source: ggplot2::msleep"
  ) +
  theme_dsi()

# Bar chart
df_vore <- na.omit(msleep[, "vore", drop = FALSE])
df_vore <- as.data.frame(table(vore = df_vore$vore))

p2 <- ggplot(df_vore, aes(reorder(vore, -Freq), Freq, fill = vore)) +
  geom_col(show.legend = FALSE, width = 0.6) +
  geom_text(aes(label = Freq), vjust = -0.5, color = "steelblue", fontface = "bold") +
  scale_y_continuous(expand = expansion(mult = c(0, 0.15))) +
  labs(
    title    = "Number of Species by Diet Type",
    subtitle = "Counts from msleep dataset",
    x = NULL, y = "Count"
  ) +
  theme_dsi()

# Line chart
p3 <- ggplot(economics, aes(date, unemploy / 1000)) +
  geom_line(color = "steelblue", linewidth = 0.6) +
  geom_area(fill = "steelblue", alpha = 0.1) +
  labs(
    title    = "US Unemployment Over Time",
    subtitle = "In thousands",
    x = NULL, y = "Unemployed (thousands)",
    caption  = "Source: ggplot2::economics"
  ) +
  theme_dsi()

# Box plot
p4 <- ggplot(mpg, aes(reorder(class, hwy, FUN = median), hwy, fill = class)) +
  geom_boxplot(show.legend = FALSE, alpha = 0.7, outlier.color = "steelblue") +
  coord_flip() +
  labs(
    title    = "Highway MPG by Vehicle Class",
    subtitle = "Ordered by median",
    x = NULL, y = "Highway MPG"
  ) +
  theme_dsi()

if (has_patchwork) {
  combined <- (p1 + p2) / (p3 + p4) +
    patchwork::plot_annotation(
      title    = "theme_dsi() Gallery",
      subtitle = "Publication-ready charts with a consistent look",
      theme    = theme_dsi(base_size = 14)
    )
  print(combined)
} else {
  print(p1); print(p2); print(p3); print(p4)
  message("Install 'patchwork' to see the combined gallery.")
}


# ------------------------------------------------------------
# 2. dsi_flextable_defaults() \u2014 flextable theme showcase
# ------------------------------------------------------------

dsi_flextable_defaults()

ft1 <- data.frame(
  Region   = c("AFRO", "AMRO", "EMRO", "EURO", "SEARO", "WPRO"),
  Members  = c(47, 35, 22, 53, 10, 28),
  Example  = c("Nigeria", "Brazil", "Egypt", "Germany", "India", "China")
) |>
  flextable() |>
  set_caption("WHO Regional Offices Overview") |>
  autofit()

print(ft1)

ft2 <- head(mtcars[, c("mpg", "cyl", "hp", "wt", "qsec")], 8) |>
  flextable() |>
  set_caption("Motor Trend Car Data (Top 8)") |>
  colformat_double(digits = 1) |>
  autofit()

print(ft2)

if (has_officer) {
  doc <- officer::read_docx()
  doc <- flextable::body_add_flextable(doc, ft1)
  doc <- officer::body_add_par(doc, "")
  doc <- flextable::body_add_flextable(doc, ft2)
  out <- tempfile(fileext = ".docx")
  print(doc, target = out)
  message("Demo complete. Word file written to: ", out)
} else {
  message("Install 'officer' to export tables to Word.")
}
