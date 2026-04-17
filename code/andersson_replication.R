# ============================================================
# Andersson (2019) Replication
# AEM 7510 – Environmental Economics – Spring 2026
# Name: Yifan Luo (yl3699)
# Date: 2026-03-31
# ============================================================
# Required packages (install once if needed):
# install.packages(c("tidyverse", "Synth", "fixest", "sandwich"))

library(tidyverse)
library(Synth)
library(fixest)
library(sandwich)

helper_candidates <- c(
  "code/replication_helpers.R",
  "replication_helpers.R",
  "../code/replication_helpers.R"
)
helper_path <- helper_candidates[file.exists(helper_candidates)][1]

if (is.na(helper_path)) {
  stop("Could not find code/replication_helpers.R.")
}

source(helper_path)

# ============================================================
# 1. DESCRIPTIVE STATISTICS
# ============================================================

message("Writing standalone outputs to: ", project_path("outputs", "standalone"))

data_objects <- load_replication_data()
desc <- data_objects$desc
analysis <- data_objects$analysis
population <- data_objects$population

# ---------- Figure 1: Gasoline Price Components ----------
pdf(standalone_output_path("figure1.pdf"), width = FIGURE_WIDTH, height = FIGURE1_HEIGHT)
plot_figure1_components(desc)
dev.off()

# ---------- Figure 2: Road Sector Fuel Consumption ----------
pdf(standalone_output_path("figure2.pdf"), width = FIGURE_WIDTH, height = FIGURE_HEIGHT)
plot_figure2_fuel(desc)
dev.off()

# ---------- Figure 3: CO2 Emissions from Transport ----------
pdf(standalone_output_path("figure3.pdf"), width = FIGURE_WIDTH, height = FIGURE_HEIGHT)
plot_figure3_transport_co2(desc)
dev.off()

# ============================================================
# 2. SYNTHETIC CONTROL METHOD
# ============================================================

synth_results <- run_synth_setup(analysis)
dataprep_out <- synth_results$dataprep_out
synth_out <- synth_results$synth_out
synth_tables <- synth_results$synth_tables

cat("\n--- Synthetic Control Weights ---\n")
print(synth_tables$tab.w)

cat("\n--- Predictor Balance ---\n")
print(build_synth_balance_table(synth_tables, analysis, population), row.names = FALSE)

# ---------- Figure 4: Sweden vs. Synthetic Sweden ----------
path_data <- build_synth_path_data(synth_results)
fig4 <- plot_synth_path(path_data)

ggsave(standalone_output_path("figure4.pdf"), fig4,
       width = FIGURE_WIDTH, height = FIGURE_HEIGHT)
if (interactive()) {
  print(fig4)
}

# ---------- Figure 5: Gap (treatment effect) ----------
gap_data <- build_synth_gap_data(synth_results)
fig5 <- plot_synth_gap(gap_data)

ggsave(standalone_output_path("figure5.pdf"), fig5,
       width = FIGURE_WIDTH, height = FIGURE_HEIGHT)
if (interactive()) {
  print(fig5)
}

# ---------- 2(b): Average treatment effect post-treatment ----------
ate_synth <- gap_data %>%
  filter(year %in% POST_TREATMENT_YEARS) %>%
  summarise(ATE = mean(gap))

cat("\n--- Synthetic Control Average Treatment Effect (1990–2005) ---\n")
cat(sprintf("ATE = %.4f metric tons CO2 per capita\n", ate_synth$ATE))

# ============================================================
# 3. DIFFERENCE-IN-DIFFERENCES (Two-Way Fixed Effects)
# ============================================================

analysis_panel <- add_panel_indicators(analysis)

# ---------- 3(a): TWFE with four SE types ----------
did_results <- build_did_results(analysis_panel)
did_table <- did_results$table

cat("\n--- DiD: TWFE Estimates with Alternative Standard Errors ---\n")
print(did_table, digits = 4)

# ============================================================
# 4. EVENT STUDY
# ============================================================

event_study <- build_event_study_model(analysis_panel)
es_df <- build_event_study_df(event_study)
fig_es <- plot_event_study(es_df)

ggsave(standalone_output_path("event_study.pdf"), fig_es,
       width = FIGURE_WIDTH, height = FIGURE_HEIGHT)
if (interactive()) {
  print(fig_es)
}

# ============================================================
# 5. REGRESSION DISCONTINUITY IN TIME (RDiT)
# ============================================================

sweden_ts <- build_sweden_time_series(analysis_panel)

# ---------- 5(a): Polynomial degrees 1–9 ----------
rdit_results <- build_rdit_results(sweden_ts)

cat("\n--- RDiT: Treatment Effect by Polynomial Degree ---\n")
print(rdit_results, digits = 4)

# ---------- 5(b): Graphical RD for n = 7 and n = 9 ----------
sweden_ts <- add_rdit_fits(sweden_ts)
fig_rdit <- plot_rdit(sweden_ts)

ggsave(standalone_output_path("figure_rdit.pdf"), fig_rdit,
       width = FIGURE_WIDTH, height = FIGURE_HEIGHT)
if (interactive()) {
  print(fig_rdit)
}

# ---------- Summary: treatment effects at the discontinuity ----------
rdit_ate7 <- filter(rdit_results, n == 7)
rdit_ate9 <- filter(rdit_results, n == 9)
cat(sprintf("\nRDiT α̂ (n=7): %.4f  (SE = %.4f)\n",
            rdit_ate7$estimate, rdit_ate7$`Robust SE`))
cat(sprintf("RDiT α̂ (n=9): %.4f  (SE = %.4f)\n",
            rdit_ate9$estimate, rdit_ate9$`Robust SE`))

# ============================================================
# SUMMARY: All treatment effect estimates
# ============================================================
cat("\n============================================================")
cat("\n SUMMARY OF TREATMENT EFFECT ESTIMATES")
cat("\n============================================================\n")
cat(sprintf("Synthetic Control ATE (1990–2005):   %.4f\n", ate_synth$ATE))
cat(sprintf("DiD TWFE α̂ (conventional SE):        %.4f\n",
            did_table$Estimate[1]))
cat(sprintf("RDiT α̂ (n=7):                        %.4f\n", rdit_ate7$estimate))
cat(sprintf("RDiT α̂ (n=9):                        %.4f\n", rdit_ate9$estimate))
cat("============================================================\n")
