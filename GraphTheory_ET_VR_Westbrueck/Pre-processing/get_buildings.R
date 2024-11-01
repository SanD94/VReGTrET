library(tidyverse)

get_buildings <- function(file_path = "../additional_Files/building_collider_list.csv") {
    building_csv_file <- file_path
    buildings <- read_csv(building_csv_file)
    buildings <- buildings %>% 
                    select(`...1`, target_collider_name, 
                            transformed_collidercenter_x, 
                            transformed_collidercenter_y) %>%
                    rename(
                        ID = `...1` ,
                        Name = target_collider_name,
                        x = transformed_collidercenter_x,
                        y = transformed_collidercenter_y
                    ) %>%
                    distinct(Name, .keep_all = TRUE)
    buildings
}

get_building_counter <- function(def_val = 0) {
    buildings <- get_buildings()
    building_counter <- buildings %>% pull(Name) %>% reduce(function (acc, cur) {
            acc[[cur]] <- def_val
            acc
        }, .init = list())
    # noData and newSession should be interpreted as buildings for the analysis before generating the graph
    building_counter[["noData"]] <- def_val
    building_counter[["newSession"]] <- def_val
    building_counter
}

get_adj_list <- function(building_data, include_noisy = FALSE) {
    initial_edges <- get_building_counter <- 
    if (!include_noisy)
        building_data <- building_data %>% filter(noisy == FALSE)
    order_buildings <- building_data %>% pull(building) %>% as.character()
    len <- length(order_buildings)
    edges <- map2(order_buildings[1:len-1], order_buildings[2:len], function(x, y) list(x,y))
    adj_list <- edges %>% reduce(
        function(acc, cur_edge) {
            a <- cur_edge[[1]]
            b <- cur_edge[[2]]
            if(is.null(acc[[a]][[b]]))
                acc[[a]][[b]] <- 0
            acc[[a]][[b]] <- acc[[a]][[b]] + 1
            acc
        },
        .init = list()
    )
    adj_list
}