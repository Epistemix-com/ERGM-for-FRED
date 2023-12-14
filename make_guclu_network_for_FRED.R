library(tidyverse)
library(igraph)
library(tidygraph)


# Add Empirical Network to Random Agent IDs in FRED -----------------------

raw_path <- "data_guclu"
fred_path <- "data_guclu_for_FRED"
schools <- c("C-EM1", "C-EM2", "C-ES", "C-HS", "P-ES", "P-HS", "P-MS1", "P-MS2")

# Read in the graphs and assign the 'school' attribute
graphs <- lapply(schools, function(school) {
  g <- read.graph(paste0(raw_path, "/net_", school, "_onlystudents-wholeday.gml"), format = "gml")
  vertex_attr(g, "school") <- school
  g
})

# Merge the graphs
merged_graph <- do.call(disjoint_union, graphs)

# Change the 'id' attribute to match the node index
vertex_attr(merged_graph, "id") <- seq_len(gorder(merged_graph))

# Assign the 'grade' attribute based on the 'shape', 'xfact', and 'yfact' attributes
vertex_attr(merged_graph, "grade") <- case_when(
  vertex_attr(merged_graph, "shape") == "ellipse" & vertex_attr(merged_graph, "xfact") == 0 ~ "Kindergarten",
  vertex_attr(merged_graph, "shape") == "box" & vertex_attr(merged_graph, "xfact") == 0 ~ "1st grade",
  vertex_attr(merged_graph, "shape") == "diamond" & vertex_attr(merged_graph, "xfact") == 0 ~ "2nd grade",
  vertex_attr(merged_graph, "shape") == "triangle" & vertex_attr(merged_graph, "xfact") == 0 ~ "3rd grade",
  vertex_attr(merged_graph, "shape") == "ellipse" & vertex_attr(merged_graph, "xfact") == 1 & vertex_attr(merged_graph, "yfact") == 3 ~ "4th grade",
  vertex_attr(merged_graph, "shape") == "box" & vertex_attr(merged_graph, "xfact") == 1 & vertex_attr(merged_graph, "yfact") == 3 ~ "5th grade",
  vertex_attr(merged_graph, "shape") == "diamond" & vertex_attr(merged_graph, "xfact") == 1 & vertex_attr(merged_graph, "yfact") == 3 ~ "6th grade",
  vertex_attr(merged_graph, "shape") == "triangle" & vertex_attr(merged_graph, "xfact") == 1 & vertex_attr(merged_graph, "yfact") == 3 ~ "7th grade",
  vertex_attr(merged_graph, "shape") == "ellipse" & vertex_attr(merged_graph, "xfact") == 3 & vertex_attr(merged_graph, "yfact") == 1 ~ "8th grade",
  vertex_attr(merged_graph, "shape") == "box" & vertex_attr(merged_graph, "xfact") == 3 & vertex_attr(merged_graph, "yfact") == 1 ~ "9th grade",
  vertex_attr(merged_graph, "shape") == "diamond" & vertex_attr(merged_graph, "xfact") == 3 & vertex_attr(merged_graph, "yfact") == 1 ~ "10th grade",
  vertex_attr(merged_graph, "shape") == "triangle" & vertex_attr(merged_graph, "xfact") == 3 & vertex_attr(merged_graph, "yfact") == 1 ~ "11th grade",
  vertex_attr(merged_graph, "shape") == "ellipse" & vertex_attr(merged_graph, "xfact") == 5 & vertex_attr(merged_graph, "yfact") == 1 ~ "12th grade"
)

# Create a vector to map grade names to numeric values
grade_mapping <- c("Kindergarten" = 0, "1st grade" = 1, "2nd grade" = 2, "3rd grade" = 3,
                   "4th grade" = 4, "5th grade" = 5, "6th grade" = 6, "7th grade" = 7,
                   "8th grade" = 8, "9th grade" = 9, "10th grade" = 10, "11th grade" = 11, "12th grade" = 12)

# Add the "grade_numeric" attribute to the merged_graph
vertex_attr(merged_graph, "grade_numeric") <- grade_mapping[vertex_attr(merged_graph, "grade")]


# Convert the merged graph to a tbl_graph object
merged_tbl <- as_tbl_graph(merged_graph)

# Filter the edges for each school and write to a CSV file
lapply(schools, function(school_name) {
  filtered_edges <- merged_tbl %>%
    filter(school == school_name) %>%
    activate(edges) %>%
    as_tibble()
  
  write_csv(filtered_edges, here::here(fred_path, paste0(school_name, "-edgelist.csv")), col_names=FALSE)
})

#### Assign network nodes to random Jefferson County Nodes ----

# read person file from Jefferson County
jeff <- read_csv(here::here("jefferson_person.txt")) %>% 
  rename(age = AGE, id = ID)

jeff_g <- merged_graph

# Extract a sample of 'id' values from the tibble
sample_ids <- jeff %>%
  select(id) %>%
  slice_sample(n = gorder(jeff_g)) %>%
  pull()

# Replace the node names and 'id' attributes with the sample 'id' values
V(jeff_g)$name <- sample_ids
vertex_attr(jeff_g, "id") <- sample_ids

# Create a named vector that maps node indices to new vertex id values
index_to_id <- setNames(sample_ids, seq_along(sample_ids))

# Update the edge list to use the new vertex id values
jeff_tbl <- jeff_g %>%
  as_tbl_graph() %>% 
  activate(edges) %>% 
  as_tibble() %>% 
  mutate(from = index_to_id[from],
         to = index_to_id[to])

# Write
jeff_tbl %>% write_csv(here::here(fred_path, "guclu_jefferson.csv"), col_names=FALSE)

