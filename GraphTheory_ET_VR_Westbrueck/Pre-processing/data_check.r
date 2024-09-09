library(jsonlite)
library(tidyverse)
# here library is not necessary as the data is big and in a different location

DATA_FOLDER <- "/mnt/f/big-data/vr_data/Data/preprocessing-pipeline/graphs"
DATA <- Sys.glob(file.path(DATA_FOLDER, "*_subgraphs_*.json"))

DATA

cur_data <- read_json(DATA[1])

pids <- c(2002, 2005, 2008, 2009, 2015, 2016, 2017, 2018, 2024, 2006, 2007, 2013, 2014, 2021, 2020, 2025)
groups <- c("Control","Control","Control","Control","Control","Control","Control","Control","Control", "Glaucoma","Glaucoma","Glaucoma","Glaucoma","Glaucoma","Glaucoma", "Glaucoma")

node_names <- map(cur_data$G$Nodes, function(x) x$Name) %>% unlist()
node_names <- c('PID', 'Group', node_names)

dummy_vals <- matrix(0, length(pids), length(node_names))
colnames(dummy_vals) <- node_names

i <- 1
for (data_file in DATA) {
    file_name <- basename(data_file)
    cur_p <- str_split(file_name, "_")[[1]][1] %>% as.integer()
    dummy_vals[i, "PID"] <- cur_p
    
    cur_g <- groups[which(pids == cur_p)]
    dummy_vals[i, "Group"] <- cur_g == "Control"

    # json data processing
    cur_data <- read_json(data_file)
    edges <- map(cur_data$G$Edges, function(x) x$EndNodes)
    for(edge in edges) {
        dummy_vals[i, edge[[1]]] <- dummy_vals[i, edge[[1]]] + 1
        dummy_vals[i, edge[[2]]] <- dummy_vals[i, edge[[2]]] + 1
    }
    i <- i + 1
}

g_table <- as_tibble(dummy_vals)
g_table <- g_table %>% mutate(across(c(PID, Group), factor))
g_table <- g_table %>% mutate(across(-c(PID, Group), as.integer))
g_table <- g_table %>% mutate(Group = fct_recode(Group, Control = "1", Glaucoma = "0"))

g_table

g_table_longer <- g_table %>% pivot_longer(!PID & !Group, names_to = "Building_Name", values_to = "Degree") %>% mutate(Building_Name = factor(Building_Name))

library(showtext)
font_add_google("Lato", "lato")
showtext_auto()

library(httpgd)
hgd()

g_table_longer %>% ggplot(aes(x = Building_Name, y = Degree, group = Group, color = Group)) + geom_point()

g_table_summary <- g_table_longer %>%
  group_by(Group, Building_Name) %>%
  summarise(
    n = n(),
    mean = mean(Degree),
    sd = sd(Degree)
  ) %>%
  mutate(se = sd / sqrt(n))  %>%
  mutate(ic = se * qt((1 - 0.05) / 2 + .5, n - 1))

# Standard Error
g_table_summary %>% ggplot(aes(x = Building_Name, y = mean, group = Group, color = Group)) +
  geom_bar(stat="identity", alpha=0.5, position = position_dodge()) +
  geom_errorbar(aes(ymin=mean-se, ymax=mean+se), linewidth=0.4, colour="black", alpha=0.9, size=1.5, position = position_dodge(.9)) +
  ggtitle("using standard error")


g_table_summary_filtered <- g_table_longer %>%
  filter(Degree > 2) %>%
  group_by(Group, Building_Name) %>%
  summarise(
    n = n(),
    mean = mean(Degree),
    sd = sd(Degree)
  ) %>%
  mutate(se = sd / sqrt(n))  %>%
  mutate(ic = se * qt((1 - 0.05) / 2 + .5, n - 1))



g_table_longer %>% filter(Degree > 2) %>% group_by(PID, Group) %>% summarise(node_mean = sum(Degree) / n()) %>% ungroup() %>% t_test(node_mean ~ Group)
