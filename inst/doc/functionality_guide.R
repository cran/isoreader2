## ----include=FALSE------------------------------------------------------------
# default chunk options
knitr::opts_chunk$set(collapse = FALSE, message = TRUE, comment = "")

## ----message=FALSE------------------------------------------------------------
# libraries
library(isoreader2) # load isoreader2 R package
library(dplyr) # for select syntax and mutating data frames

## ----include=FALSE------------------------------------------------------------
# copy the bundled example files (and any extraction cache) to a local
# folder so reading does not write into the installed package directory
if (!dir.exists("tmp_examples")) {
  dir.create("tmp_examples")
}
ir_examples_folder() |>
  list.files(full.names = TRUE) |>
  file.copy(to = "tmp_examples", overwrite = TRUE)

## -----------------------------------------------------------------------------
# supported file types
ir_get_supported_file_types()

## -----------------------------------------------------------------------------
# path to your data folder (here a local copy of the example files)
data_folder <- file.path("tmp_examples")

# find continuous flow files (.dxf/.cf) in the folder
file_paths <- data_folder |> ir_find_continuous_flow()

# show what was found
file_paths

## -----------------------------------------------------------------------------
# read the files
isofiles <- file_paths |> ir_read_isofiles()

# show what was read
isofiles

## -----------------------------------------------------------------------------
# combine two collections (here just the same files twice for illustration)
c(isofiles, isofiles)

## -----------------------------------------------------------------------------
# save and reload the read isofiles
isofiles |> ir_save_isofiles(file.path("tmp_examples", "my_isofiles"))
reloaded <- ir_load_isofiles(file.path("tmp_examples", "my_isofiles"))

## -----------------------------------------------------------------------------
# aggregate the data
dataset <- isofiles |> ir_aggregate_isofiles()

# show all that was recovered
# (as well as what was ignored / not aggregated)
dataset

## -----------------------------------------------------------------------------
# report intensities in nanoamperes instead of the default millivolts
isofiles |>
  ir_aggregate_isofiles(intensity_units = "nA") |>
  ir_get_data(traces = c("species", "mass", "time.s", "intensity.nA"))

## -----------------------------------------------------------------------------
# minimal vs. extended aggregator
ir_get_aggregator("minimal")
ir_get_aggregator("extended")

# using the extended aggregator instead of the default (standard)
isofiles |> ir_aggregate_isofiles(aggregator = "extended")

## -----------------------------------------------------------------------------
my_agg <-
  ir_get_aggregator("minimal") |>
  # pull the "Identifier 1" metadata field out under a friendlier name
  ir_add_to_aggregator("metadata", "sample_id", source = "Identifier 1") |>
  ir_register_aggregator(name = "my_aggregator")

# show my aggregator summary
my_agg

# use it
isofiles |> ir_aggregate_isofiles(aggregator = "my_aggregator")

## -----------------------------------------------------------------------------
isofiles |> ir_get_problems()
dataset |> ir_get_problems()

## -----------------------------------------------------------------------------
isofiles |> ir_show_problems()
dataset |> ir_show_problems()

## -----------------------------------------------------------------------------
# direct access to the individual datasets
dataset$metadata
dataset$traces

# retrieve + combine data with dplyr select syntax
dataset |>
  ir_get_data(
    metadata = c("file_name", "analysis", sample = "Identifier 1"),
    traces = c("species", "mass", "time.s", "intensity.mV")
  )

## -----------------------------------------------------------------------------
# all metadata columns
dataset |> ir_get_metadata()

# all traces (joined with the file metadata)
dataset |> ir_get_traces()

## -----------------------------------------------------------------------------
# aggregate with the extended aggregator so the vendor data table is included
dataset_ext <- isofiles |> ir_aggregate_isofiles(aggregator = "extended")

# retrieve the vendor data table (joined with the file metadata)
dataset_ext |> ir_get_vendor_data_table()

## -----------------------------------------------------------------------------
# keep only continuous flow files and add a derived label column
dataset |>
  ir_filter_metadata(type == "cf") |>
  ir_mutate_metadata(label = paste(file_name, analysis, sep = " / ")) |>
  ir_get_metadata(metadata = c("file_name", "analysis", "label"))

## -----------------------------------------------------------------------------
# keep only the continuous flow files
dataset |>
  ir_filter_for_continuous_flow() |>
  ir_get_metadata(metadata = c("file_name", "type"))

## ----eval=FALSE---------------------------------------------------------------
# # save and reload the aggregated data
# dataset |> ir_save_aggregated_data(file.path("tmp_examples", "my_dataset"))
# reloaded <- ir_load_aggregated_data(file.path("tmp_examples", "my_dataset"))

## -----------------------------------------------------------------------------
dataset_ratios <- dataset |> ir_calculate_ratios()

dataset_ratios |>
  ir_get_data(
    metadata = "file_name",
    traces = c("species", "mass", "time.s", "ratio_name", "ratio")
  )

## -----------------------------------------------------------------------------
dataset |>
  ir_calculate_ratios(N2 = 28, normalize_ratios = median) |>
  ir_get_data(
    metadata = "file_name",
    traces = c("species", "mass", "ratio_name", "ratio")
  )

## -----------------------------------------------------------------------------
dataset |> ir_plot_continuous_flow(facet = file_name)

## -----------------------------------------------------------------------------
dataset |>
  ir_plot_continuous_flow(
    species = "CO2",
    facet = file_name,
    time_window.min = c(4.5, 8.5)
  )

## -----------------------------------------------------------------------------
dataset |>
  ir_calculate_ratios(normalize_ratios = median) |>
  ir_plot_continuous_flow(
    species = "CO2",
    ratio = "45/44",
    facet = file_name,
    time_window.min = c(4.5, 8.5)
  )

## -----------------------------------------------------------------------------
library(ggplot2)
dataset |>
  ir_plot_continuous_flow(
    species = "N2",
    facet = file_name,
    scientific = TRUE
  ) +
  labs(title = "N2 traces") +
  theme(legend.position = "bottom")

## -----------------------------------------------------------------------------
dataset |> ir_generate_traces_tibble(species = "CO2")

## -----------------------------------------------------------------------------
di_dataset <-
  data_folder |>
  ir_find_dual_inlet() |>
  ir_read_isofiles() |>
  ir_aggregate_isofiles("V") |>
  ir_calculate_ratios()

di_dataset |> ir_plot_dual_inlet(facet = file_name)

## -----------------------------------------------------------------------------
di_dataset |> ir_plot_dual_inlet(mass = c(44, 45, 46), facet = file_name)

## -----------------------------------------------------------------------------
data_folder |>
  ir_find_scans() |>
  ir_read_isofiles() |>
  ir_aggregate_isofiles("V") |>
  ir_plot_scans(scan_type = "high voltage")

## -----------------------------------------------------------------------------
ir_export_to_excel(
  metadata = dataset |> ir_get_metadata(),
  traces = dataset |> ir_get_traces(),
  file = "tmp_examples/my_dataset.xlsx"
)

## -----------------------------------------------------------------------------
# list available options and read one
names(ir_get_options())
ir_get_option("debug")

# set an option (here enable debug mode), then restore the default
invisible(ir_options(debug = TRUE))
ir_get_option("debug")

## ----include=FALSE------------------------------------------------------------
# reset options
invisible(ir_options(debug = FALSE))
# clean up the local data folder created for this vignette
unlink("tmp_examples", recursive = TRUE)

