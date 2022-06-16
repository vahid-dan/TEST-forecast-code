# LAKE-forecast-code

Suppose we want to use this template to run forecasts for a new site named "lake".

0- Make sure you already have the drivers ready for the new site "lake".
- If `forecast_met_model` is `noaa/NOAAGEFS_1hr`, the NOAA forecasts should be already downloaded and accessible at `drivers/noaa/NOAAGEFS_6hr/lake`.

1- Create a new repository from LAKE-forecast-code by hitting "Use this template" button.

2- Change the `site_id` from `fcre` to `lake` in the following files:
- `configuration/default/configure_flare.yml`
- `configuration/default/observation_processing.yml`

3- Change the `forecast_site` from `fcre` to `lake` in the following file:
- `main_workflow.R`
