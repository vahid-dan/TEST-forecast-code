in_situ_qaqc <- function(insitu_obs_fname,
                         data_location,
                         maintenance_file,
                         ctd_fname,
                         nutrients_fname,
                         secchi_fname,
                         ch4_fname = NULL,
                         cleaned_insitu_file,
                         lake_name_code,
                         config){

  print("QAQC Catwalk")

  d <- temp_oxy_chla_qaqc(realtime_file = insitu_obs_fname[1],
                          qaqc_file = insitu_obs_fname[2],
                          maintenance_file = maintenance_file,
                          input_file_tz = "EST",
                          focal_depths = config$focal_depths,
                          config = config)

  if(exists("ctd_fname")){
    if(!is.na(ctd_fname)){
      print("QAQC CTD")
      d_ctd <- extract_CTD(fname = ctd_fname,
                           input_file_tz = "EST",
                           focal_depths = config$focal_depths,
                           config = config)
      d <- rbind(d,d_ctd)
    }
  }


  if(exists("nutrients_fname")){
    if(!is.na(nutrients_fname)){
      print("QAQC Nutrients")
      d_nutrients <- extract_nutrients(fname = nutrients_fname,
                                       input_file_tz = "EST",
                                       focal_depths = config$focal_depths)
      d <- rbind(d,d_nutrients)
    }
  }


  if(!is.null("ch4_fname")){
    if(!is.na(ch4_fname)){
      print("QAQC CH4")
      d_ch4 <- extract_ch4(fname = ch4_fname,
                           input_file_tz = "EST",
                           focal_depths = config$focal_depths)
      d <- rbind(d,d_ch4)
    }
  }


  first_day <- lubridate::as_datetime(paste0(lubridate::as_date(min(d$timestamp)), " ", config$averaging_period_starting_hour))

  last_day <- lubridate::as_datetime(paste0(lubridate::as_date(max(d$timestamp)), " ", config$averaging_period_starting_hour))

  full_time_local <- seq(first_day, last_day, by = "1 day")

  d_clean <- NULL


  for(i in 1:length(config$target_variable)){
    print(paste0("Extracting ",config$target_variable[i]))
    #depth_breaks <- sort(c(bins1, bins2))
    time_breaks <- seq(first_day, last_day, by = config$averaging_period[i])

    d_curr <- d %>%
      dplyr::filter(variable == config$target_variable[i],
                    method %in% config$measurement_methods[[i]]) %>%
      dplyr::mutate(time_class = cut(timestamp, breaks = time_breaks, labels = FALSE)) %>%
      dplyr::group_by(time_class, depth) %>%
      dplyr::summarize(value = mean(value, na.rm = TRUE), .groups = "drop") %>%
      dplyr::mutate(datetime = time_breaks[time_class]) %>%
      dplyr::mutate(variable = config$target_variable[i]) %>%
      dplyr::select(datetime, depth, variable, value) %>%
      dplyr::mutate(date = lubridate::as_date(datetime))

    if(config$averaging_period[i] == "1 hour"){
      d_curr <- d_curr %>%
      dplyr::mutate(hour = lubridate::hour(datetime)) %>%
      dplyr::filter(hour == lubridate::hour(first_day))
    }else{
      d_curr <- d_curr %>%
        dplyr::mutate(hour = NA) %>%
        dplyr::mutate(hour = as.numeric(hour))
    }

    d_curr <- d_curr %>% dplyr::select(-datetime)

    d_clean <- rbind(d_clean,  d_curr)
  }

  d_clean <- d_clean %>% tidyr::drop_na(value)

  if(!is.na(secchi_fname)){

    d_secchi <- extract_secchi(fname = file.path(secchi_fname),
                               input_file_tz = "EST",
                               focal_depths = config$focal_depths)

    d_secchi <- d_secchi %>%
      dplyr::mutate(date = lubridate::as_date(timestamp)) %>%
      dplyr::mutate(hour = NA) %>%
      dplyr::select(-timestamp)

    d_clean <- rbind(d_clean,d_secchi)
  }

  d_clean <- d_clean %>% select(date, hour, depth, value, variable)

  d_clean$value <- round(d_clean$value, digits = 4)

  if(!dir.exists(dirname(cleaned_insitu_file))){
    dir.create(dirname(cleaned_insitu_file), recursive = TRUE)
  }


  readr::write_csv(d_clean, cleaned_insitu_file)

  return(cleaned_insitu_file)

}
