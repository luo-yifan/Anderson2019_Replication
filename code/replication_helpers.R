# Shared helpers for the Andersson (2019) replication project.

find_project_root <- function() {
  candidates <- c(".", "..")

  for (candidate in candidates) {
    if (
      file.exists(file.path(candidate, "README.md")) &&
      file.exists(file.path(candidate, "code", "replication_helpers.R")) &&
      dir.exists(file.path(candidate, "inputs", "data"))
    ) {
      return(normalizePath(candidate, winslash = "/", mustWork = TRUE))
    }
  }

  stop("Could not locate the project root.")
}

PROJECT_ROOT <- find_project_root()

project_path <- function(...) {
  normalizePath(file.path(PROJECT_ROOT, ...), winslash = "/", mustWork = FALSE)
}

ensure_directory <- function(path) {
  if (!dir.exists(path)) {
    dir.create(path, recursive = TRUE, showWarnings = FALSE)
  }
}

standalone_output_path <- function(filename) {
  output_dir <- project_path("outputs", "standalone")
  ensure_directory(output_dir)
  project_path("outputs", "standalone", filename)
}

TREATMENT_YEAR <- 1990
REFERENCE_YEAR <- TREATMENT_YEAR - 1
PRE_TREATMENT_YEARS <- 1960:REFERENCE_YEAR
POST_TREATMENT_YEARS <- (TREATMENT_YEAR + 1):2005
PLOT_YEARS <- 1960:2005
YEAR_BREAKS <- c(1960, 1970, 1980, 1990, 2000)

SWEDEN_NO <- 13
DONOR_NOS <- c(1:12, 14, 15)
PAPER_SYNTH_PREDICTORS <- c(
  "GDP_per_capita",
  "gas_cons_capita",
  "vehicles_capita",
  "urban_pop"
)
PAPER_PREDICTOR_YEARS <- 1980:1989
PAPER_SPECIAL_YEARS <- c(1989, 1980, 1970)
PAPER_BALANCE_TABLE_ORDER <- c(
  "GDP_per_capita",
  "vehicles_capita",
  "gas_cons_capita",
  "urban_pop",
  paste0("special.CO2_transport_capita.", PAPER_SPECIAL_YEARS)
)

FIGURE_WIDTH <- 7
FIGURE_HEIGHT <- 4.5
FIGURE1_HEIGHT <- 6.5
TABLE_FONT_SIZE <- 9
CO2_LABEL <- "CO2"

load_replication_data <- function() {
  list(
    desc = read_csv(
      project_path("inputs", "data", "descriptive_data.csv"),
      show_col_types = FALSE
    ),
    analysis = read_csv(
      project_path("inputs", "data", "analysis_data.csv"),
      show_col_types = FALSE
    ),
    population = read_csv(
      project_path("inputs", "data", "oecd_donor_population.csv"),
      show_col_types = FALSE
    )
  )
}

style_paper_table <- function(kable_object,
                              note = NULL,
                              note_title = "Notes:",
                              font_size = TABLE_FONT_SIZE,
                              full_width = FALSE) {
  styled_table <- kable_object |>
    kable_styling(
      latex_options = c("hold_position"),
      full_width = full_width,
      font_size = font_size
    )

  if (!is.null(note)) {
    styled_table <- styled_table |>
      footnote(
        general = note,
        general_title = note_title,
        escape = FALSE,
        threeparttable = knitr::is_latex_output()
      )
  }

  styled_table
}

paper_theme <- function(legend_position = "bottom") {
  theme_classic(base_size = 12) +
    theme(
      legend.position = legend_position,
      legend.title = element_blank(),
      legend.key = element_blank(),
      axis.line = element_line(color = "black")
    )
}

plot_figure1_components <- function(desc) {
  old_par <- par(no.readonly = TRUE)
  on.exit(par(old_par), add = TRUE)

  par(mfrow = c(2, 1), mar = c(4, 4, 2.5, 1))

  plot(desc$year, desc$Real_Gasoline_Price, type = "l", lwd = 2, col = "black",
       ylim = c(0, 13), xlab = "", ylab = "Real price (SEK/liter)",
       xaxs = "i", yaxs = "i")
  abline(v = TREATMENT_YEAR, lty = "dotted", lwd = 2)
  legend("topleft",
         legend = c("Gasoline price", "Energy tax", "VAT", "Carbon tax"),
         lty = c(1, 1, 4, 2),
         col = c("black", "gray50", "black", "black"),
         lwd = rep(2, 4), cex = 0.8)
  lines(desc$year, desc$Real_Carbontax, lty = "dashed", lwd = 2, col = "black")
  lines(desc$year, desc$Real_VAT, lty = "dotdash", lwd = 2, col = "black")
  lines(desc$year, desc$Real_Energytax, lty = "solid", lwd = 2, col = "gray50")
  title("Panel A. Tax components", line = 0.5)

  plot(desc$year, desc$Real_Gasoline_Price, type = "l", lwd = 2, col = "black",
       ylim = c(0, 13), xlab = "Year", ylab = "Real price (SEK/liter)",
       xaxs = "i", yaxs = "i")
  abline(v = TREATMENT_YEAR, lty = "dotted", lwd = 2)
  legend("topleft",
         legend = c("Gasoline price", "Total tax"),
         lty = c(1, 2), col = c("black", "black"),
         lwd = c(2, 2), cex = 0.8)
  lines(desc$year, desc$Real_total_tax, lty = "dashed", lwd = 2, col = "black")
  title("Panel B. Total tax", line = 0.5)
}

plot_figure2_fuel <- function(desc) {
  plot(desc$year, desc$gas_cons, type = "l", lwd = 2, col = "black",
       ylim = c(0, 600), xlab = "Year",
       ylab = "Road sector fuel consumption per capita (kg of oil equivalent)",
       xaxs = "i", yaxs = "i")
  abline(v = TREATMENT_YEAR, lty = "dotted", lwd = 2)
  legend("bottomright", legend = c("Gasoline", "Diesel"),
         lty = c(1, 2), col = c("black", "black"), lwd = c(2, 2), cex = 0.8)
  lines(desc$year, desc$diesel_cons, lty = "dashed", lwd = 2, col = "black")
  arrows(1987, 100, 1989, 100, col = "black", length = 0.1)
  text(1981, 100, "VAT + Carbon tax", cex = 1)
}

plot_figure3_transport_co2 <- function(desc) {
  plot(desc$year, desc$CO2_Sweden, type = "l", lwd = 2, col = "black",
       ylim = c(0, 3), xlab = "Year",
       ylab = "Metric tons per capita (CO2 from transport)",
       xaxs = "i", yaxs = "i")
  abline(v = TREATMENT_YEAR, lty = "dotted", lwd = 2)
  legend("bottomright", legend = c("Sweden", "OECD sample"),
         lty = c(1, 2), col = c("black", "black"), lwd = c(2, 2), cex = 0.8)
  lines(desc$year, desc$CO2_OECD, lty = "dashed", lwd = 2, col = "black")
  arrows(1987, 1.0, 1989, 1.0, col = "black", length = 0.1)
  text(1981, 1.0, "VAT + Carbon tax", cex = 1)
}

run_synth_setup <- function(analysis) {
  dataprep_out <- dataprep(
    foo = as.data.frame(analysis),
    predictors = PAPER_SYNTH_PREDICTORS,
    predictors.op = "mean",
    time.predictors.prior = PAPER_PREDICTOR_YEARS,
    special.predictors = list(
      list("CO2_transport_capita", 1989, "mean"),
      list("CO2_transport_capita", 1980, "mean"),
      list("CO2_transport_capita", 1970, "mean")
    ),
    dependent = "CO2_transport_capita",
    unit.variable = "Countryno",
    unit.names.variable = "country",
    time.variable = "year",
    treatment.identifier = SWEDEN_NO,
    controls.identifier = DONOR_NOS,
    time.optimize.ssr = PRE_TREATMENT_YEARS,
    time.plot = PLOT_YEARS
  )

  synth_out <- synth(data.prep.obj = dataprep_out, method = "All")
  synth_tables <- synth.tab(dataprep.res = dataprep_out, synth.res = synth_out)

  list(
    dataprep_out = dataprep_out,
    synth_out = synth_out,
    synth_tables = synth_tables
  )
}

build_synth_path_data <- function(synth_results) {
  tibble(
    year = PLOT_YEARS,
    Sweden = as.numeric(synth_results$dataprep_out$Y1plot),
    `Synthetic Sweden` =
      as.numeric(synth_results$dataprep_out$Y0plot %*% synth_results$synth_out$solution.w)
  ) |>
    pivot_longer(-year, names_to = "Series", values_to = "CO2")
}

build_synth_gap_data <- function(synth_results) {
  tibble(
    year = PLOT_YEARS,
    gap = as.numeric(
      synth_results$dataprep_out$Y1plot -
        synth_results$dataprep_out$Y0plot %*% synth_results$synth_out$solution.w
    )
  )
}

compute_population_weighted_oecd_means <- function(analysis, population) {
  donor_countries <- analysis |>
    filter(Countryno %in% DONOR_NOS) |>
    distinct(country)

  required_years <- sort(unique(c(PAPER_PREDICTOR_YEARS, PAPER_SPECIAL_YEARS)))
  population_subset <- population |>
    filter(country %in% donor_countries$country, year %in% required_years)

  missing_population <- expand.grid(
    country = donor_countries$country,
    year = required_years
  ) |>
    as_tibble() |>
    anti_join(population_subset, by = c("country", "year"))

  if (nrow(missing_population) > 0) {
    stop("Population data are missing for one or more donor-country years.")
  }

  donor_period_means <- analysis |>
    filter(country %in% donor_countries$country, year %in% PAPER_PREDICTOR_YEARS) |>
    group_by(country) |>
    summarise(
      GDP_per_capita = mean(GDP_per_capita),
      vehicles_capita = mean(vehicles_capita),
      gas_cons_capita = mean(gas_cons_capita),
      urban_pop = mean(urban_pop),
      .groups = "drop"
    ) |>
    left_join(
      population_subset |>
        filter(year %in% PAPER_PREDICTOR_YEARS) |>
        group_by(country) |>
        summarise(population = mean(population), .groups = "drop"),
      by = "country"
    )

  oecd_means <- c(
    GDP_per_capita = weighted.mean(
      donor_period_means$GDP_per_capita,
      donor_period_means$population
    ),
    vehicles_capita = weighted.mean(
      donor_period_means$vehicles_capita,
      donor_period_means$population
    ),
    gas_cons_capita = weighted.mean(
      donor_period_means$gas_cons_capita,
      donor_period_means$population
    ),
    urban_pop = weighted.mean(
      donor_period_means$urban_pop,
      donor_period_means$population
    )
  )

  lag_means <- PAPER_SPECIAL_YEARS |>
    set_names(paste0("special.CO2_transport_capita.", PAPER_SPECIAL_YEARS)) |>
    purrr::map_dbl(
      \(lag_year) {
        lagged_data <- analysis |>
          filter(country %in% donor_countries$country, year == lag_year) |>
          left_join(
            population_subset |>
              filter(year == lag_year) |>
              select(country, population),
            by = "country"
          )

        weighted.mean(lagged_data$CO2_transport_capita, lagged_data$population)
      }
    )

  c(oecd_means, lag_means)
}

build_synth_balance_table <- function(synth_tables, analysis, population) {
  row_labels <- c(
    "GDP_per_capita" = "GDP per capita",
    "vehicles_capita" = "Motor vehicles (per 1,000 people)",
    "gas_cons_capita" = "Gasoline consumption per capita",
    "urban_pop" = "Urban population",
    "special.CO2_transport_capita.1989" =
      paste(CO2_LABEL, "from transport per capita 1989"),
    "special.CO2_transport_capita.1980" =
      paste(CO2_LABEL, "from transport per capita 1980"),
    "special.CO2_transport_capita.1970" =
      paste(CO2_LABEL, "from transport per capita 1970")
  )
  oecd_means <- compute_population_weighted_oecd_means(analysis, population)

  synth_tables$tab.pred |>
    as.data.frame() |>
    tibble::rownames_to_column("var") |>
    mutate(
      Variable = row_labels[var],
      `Sample Mean` = unname(oecd_means[var])
    ) |>
    arrange(match(var, PAPER_BALANCE_TABLE_ORDER)) |>
    mutate(
      across(
        c(Treated, `Synthetic`, `Sample Mean`),
        ~ ifelse(
          var %in% "GDP_per_capita",
          formatC(.x, format = "f", digits = 1, big.mark = ","),
          formatC(.x, format = "f", digits = 1)
        )
      )
    ) |>
    select(Variable, Treated, `Synthetic`, `Sample Mean`)
}

build_synth_weights_table <- function(synth_tables) {
  all_weights <- synth_tables$tab.w |>
    arrange(unit.names) |>
    mutate(Weight = round(w.weights, 3), Country = unit.names) |>
    select(Country, Weight)

  left_half <- all_weights[1:7, ]
  right_half <- all_weights[8:14, ]

  bind_cols(
    left_half,
    right_half |> rename(`Country ` = Country, `Weight ` = Weight)
  )
}

plot_synth_path <- function(path_data) {
  ggplot(path_data, aes(x = year, y = CO2, color = Series, linetype = Series)) +
    geom_line(linewidth = 1) +
    geom_vline(xintercept = TREATMENT_YEAR, linetype = "dotted", color = "black") +
    scale_color_manual(values = c("Sweden" = "black", "Synthetic Sweden" = "gray50")) +
    scale_linetype_manual(values = c("Sweden" = "solid", "Synthetic Sweden" = "dashed")) +
    scale_x_continuous(breaks = YEAR_BREAKS) +
    labs(
      x = "Year",
      y = "CO2 emissions per capita (metric tons)",
      color = NULL,
      linetype = NULL
    ) +
    paper_theme()
}

plot_synth_gap <- function(gap_data) {
  ggplot(gap_data, aes(x = year, y = gap)) +
    geom_line(linewidth = 1, color = "black") +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_vline(xintercept = TREATMENT_YEAR, linetype = "dotted", color = "black") +
    scale_x_continuous(breaks = YEAR_BREAKS) +
    labs(x = "Year", y = "Gap in CO2 emissions per capita (metric tons)") +
    paper_theme("none")
}

add_panel_indicators <- function(analysis) {
  analysis |>
    mutate(
      treated = as.integer(country == "Sweden" & year >= TREATMENT_YEAR),
      sweden = as.integer(country == "Sweden")
    )
}

build_did_results <- function(panel_data) {
  twfe <- feols(
    CO2_transport_capita ~ treated | Countryno + year,
    data = panel_data,
    vcov = "iid"
  )

  se_conv <- summary(twfe, vcov = "iid")
  se_hc <- summary(twfe, vcov = "hetero")
  se_year <- summary(twfe, vcov = ~year)
  se_twoway <- summary(twfe, vcov = ~Countryno + year)

  did_table <- tibble(
    `SE Type` = c(
      "Conventional (i.i.d.)",
      "Heteroskedasticity-Consistent (HC)",
      "Clustered by Year",
      "Two-Way Clustered (Country and Year)"
    ),
    Estimate = coef(twfe)["treated"],
    `Std. Error` = c(
      se_conv$se["treated"],
      se_hc$se["treated"],
      se_year$se["treated"],
      se_twoway$se["treated"]
    )
  ) |>
    mutate(
      `t-stat` = round(Estimate / `Std. Error`, 2),
      `p-value` = round(2 * pt(-abs(`t-stat`), df = twfe$nobs - 1), 4),
      Estimate = round(Estimate, 4),
      `Std. Error` = round(`Std. Error`, 4)
    )

  list(model = twfe, table = did_table)
}

build_event_study_model <- function(panel_data) {
  feols(
    CO2_transport_capita ~ i(year, sweden, ref = REFERENCE_YEAR) | Countryno + year,
    data = panel_data,
    vcov = "hetero"
  )
}

build_event_study_df <- function(event_study_model) {
  as.data.frame(coeftable(event_study_model)) |>
    rownames_to_column("term") |>
    mutate(year = as.integer(str_extract(term, "\\d{4}"))) |>
    select(year, estimate = Estimate, se = `Std. Error`) |>
    bind_rows(tibble(year = REFERENCE_YEAR, estimate = 0, se = 0)) |>
    arrange(year) |>
    mutate(
      ci_lo = estimate - 1.96 * se,
      ci_hi = estimate + 1.96 * se
    )
}

plot_event_study <- function(es_df) {
  ggplot(es_df, aes(x = year, y = estimate)) +
    geom_ribbon(aes(ymin = ci_lo, ymax = ci_hi), alpha = 0.2, fill = "gray75") +
    geom_line(linewidth = 0.8, color = "black") +
    geom_point(size = 1.5, color = "black") +
    geom_hline(yintercept = 0, linetype = "dashed") +
    geom_vline(xintercept = REFERENCE_YEAR + 0.5, linetype = "dotted", color = "black") +
    scale_x_continuous(breaks = YEAR_BREAKS) +
    labs(
      x = "Year",
      y = "Estimated treatment effect (metric tons CO2 per capita)"
    ) +
    paper_theme("none")
}

build_sweden_time_series <- function(panel_data) {
  panel_data |>
    filter(country == "Sweden") |>
    arrange(year) |>
    mutate(
      D = as.integer(year >= TREATMENT_YEAR),
      t_pre = ifelse(year < TREATMENT_YEAR, TREATMENT_YEAR - year, 0),
      t_post = ifelse(year >= TREATMENT_YEAR, year - TREATMENT_YEAR, 0)
    )
}

build_rdit_formula <- function(n) {
  pre_terms <- paste0("I(t_pre^", 1:n, ")", collapse = " + ")
  post_terms <- paste0("I(t_post^", 1:n, ")", collapse = " + ")
  as.formula(paste("CO2_transport_capita ~ D +", pre_terms, "+", post_terms))
}

build_rdit_results <- function(sweden_ts) {
  map_dfr(1:9, function(n) {
    model <- lm(build_rdit_formula(n), data = sweden_ts)
    se_robust <- sqrt(diag(vcovHC(model, type = "HC1")))

    tibble(
      n = n,
      estimate = round(coef(model)["D"], 4),
      `Robust SE` = round(se_robust["D"], 4),
      `t-stat` = round(coef(model)["D"] / se_robust["D"], 2),
      `p-value` = round(
        2 * pt(-abs(coef(model)["D"] / se_robust["D"]), df = df.residual(model)),
        4
      )
    )
  })
}

add_rdit_fits <- function(sweden_ts, degrees = c(7, 9)) {
  fitted_data <- sweden_ts

  for (degree in degrees) {
    model <- lm(build_rdit_formula(degree), data = fitted_data)
    fitted_data[[paste0("fitted_n", degree)]] <- predict(model, newdata = fitted_data)
  }

  fitted_data
}

plot_rdit <- function(sweden_ts) {
  ggplot(sweden_ts, aes(x = year)) +
    geom_point(aes(y = CO2_transport_capita), color = "black", size = 2, alpha = 0.7) +
    geom_line(aes(y = fitted_n7, linetype = "n = 7"), color = "black", linewidth = 1) +
    geom_line(aes(y = fitted_n9, linetype = "n = 9"), color = "gray50", linewidth = 1) +
    geom_vline(xintercept = TREATMENT_YEAR, linetype = "dotted", color = "black") +
    scale_x_continuous(breaks = YEAR_BREAKS) +
    scale_linetype_manual(values = c("n = 7" = "solid", "n = 9" = "dashed")) +
    labs(
      x = "Year",
      y = "CO2 emissions per capita (metric tons)",
      linetype = "Polynomial degree"
    ) +
    paper_theme()
}
