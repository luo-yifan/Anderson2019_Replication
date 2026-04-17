knitr::opts_chunk$set(
  echo    = FALSE,
  message = FALSE,
  warning = FALSE,
  fig.align = "center",
  fig.width  = 7,
  fig.height = 4.5,
  fig.path = "figure/",
  cache.path = "cache/"
)

library(tidyverse)
library(Synth)
library(fixest)
library(sandwich)
library(knitr)
library(kableExtra)

helper_candidates <- c(
  "../code/replication_helpers.R",
  "code/replication_helpers.R"
)
helper_path <- helper_candidates[file.exists(helper_candidates)][1]

if (is.na(helper_path)) {
  stop("Could not find code/replication_helpers.R.")
}

source(helper_path)

data_objects <- load_replication_data()
desc <- data_objects$desc
analysis <- data_objects$analysis
population <- data_objects$population

plot_figure1_components(desc)

plot_figure2_fuel(desc)

plot_figure3_transport_co2(desc)

synth_results <- run_synth_setup(analysis)
dataprep_out <- synth_results$dataprep_out
synth_out <- synth_results$synth_out
synth_tables <- synth_results$synth_tables
path_data <- build_synth_path_data(synth_results)
gap_data <- build_synth_gap_data(synth_results)

tab1 <- build_synth_balance_table(synth_tables, analysis, population)

kable(tab1, booktabs = TRUE, escape = FALSE,
      longtable = FALSE,
      align  = "lccc",
      linesep = "",
      col.names = c("Variables", "Sweden", "Synth. Sweden", "OECD sample"),
      caption = "CO2 Emissions from Transport Predictor Means before Tax Reform") |>
  style_paper_table(
    note = paste(
      paste("All variables except lagged", CO2_LABEL, "are averaged for the period 1980--1989."),
      "GDP per capita is purchasing power parity (PPP)--adjusted and measured in 2005 US dollars.",
      "Gasoline consumption is measured in kilograms of oil equivalent.",
      "Urban population is measured as percentage of total population.",
      paste(CO2_LABEL, "emissions are measured in metric tons."),
      "The last column reports the population-weighted averages of the 14 OECD countries in the donor pool."
    ),
    note_title = "Notes:"
  ) |>
  column_spec(1, width = "2.45in") |>
  column_spec(2:4, width = "0.8in") |>
  identity()

tab2 <- build_synth_weights_table(synth_tables)

kable(tab2, booktabs = TRUE, align = "lclc",
      longtable = FALSE,
      linesep = "",
      caption = "Country Weights in Synthetic Sweden") |>
  style_paper_table(
    note = "With the synthetic control method, extrapolation is not allowed, so all weights are between 0 and 1 and sum to 1.",
    note_title = "Note:"
  ) |>
  column_spec(c(1, 3), width = "1.45in") |>
  column_spec(c(2, 4), width = "0.7in")

plot_synth_path(path_data)

plot_synth_gap(gap_data)

ate_synth <- gap_data |>
  filter(year %in% POST_TREATMENT_YEARS) |>
  summarise(ATE = mean(gap))

analysis_panel <- add_panel_indicators(analysis)
did_results <- build_did_results(analysis_panel)
twfe <- did_results$model
did_table <- did_results$table

kable(did_table, booktabs = TRUE, escape = FALSE, align = "lcccc",
      linesep = "",
      caption = "TWFE estimates with alternative standard errors.") |>
  style_paper_table()

es_model <- build_event_study_model(analysis_panel)
es_df <- build_event_study_df(es_model)

plot_event_study(es_df)

sweden_ts <- build_sweden_time_series(analysis_panel)
rdit_results <- build_rdit_results(sweden_ts)

rdit_col_names <- if (knitr::is_latex_output()) {
  c(
    "\\makecell[c]{Poly. Degree\\\\($n$)}",
    "$\\hat{\\alpha}$",
    "\\makecell[c]{Robust\\\\SE}",
    "$t$-stat",
    "$p$-value"
  )
} else {
  c(
    "Poly. Degree ($n$)",
    "$\\hat{\\alpha}$",
    "Robust SE",
    "$t$-stat",
    "$p$-value"
  )
}

rdit_table <- if (knitr::is_latex_output()) {
  kbl(
    rdit_results,
    format = "latex",
    booktabs = TRUE,
    align = "ccccc",
    col.names = rdit_col_names,
    escape = FALSE,
    linesep = "",
    caption = "RDiT estimates for polynomial degrees $n = 1, \\ldots, 9$. Robust (HC1) standard errors throughout."
  )
} else {
  kable(
    rdit_results,
    booktabs = TRUE,
    align = "ccccc",
    col.names = rdit_col_names,
    escape = FALSE,
    linesep = "",
    caption = "RDiT estimates for polynomial degrees $n = 1, \\ldots, 9$. Robust (HC1) standard errors throughout."
  )
}

rdit_table |>
  style_paper_table()

sweden_ts <- add_rdit_fits(sweden_ts)

plot_rdit(sweden_ts)
