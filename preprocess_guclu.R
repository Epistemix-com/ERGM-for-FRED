## Import Packages

library(tidyverse)
library(igraph)
library(intergraph)
library(network)

## Import Data and Preprocess

raw_path <- "data_guclu"
fred_path <- "data_guclu_for_FRED"
schools <- c("C-EM1", "C-EM2", "C-ES", "C-HS", "P-ES", "P-HS", "P-MS1", "P-MS2")
grade_to_num <- c("Kindergarten" = 0, "1st grade" = 1, "2nd grade" = 2, "3rd grade" = 3,
                  "4th grade" = 4, "5th grade" = 5, "6th grade" = 6, "7th grade" = 7,
                  "8th grade" = 8, "9th grade" = 9, "10th grade" = 10, "11th grade" = 11, "12th grade" = 12)

## create a list of the empirical networks for each school

graphs <- lapply(schools, function(school) {
  g <- read.graph(here::here(raw_path, paste0("net_", school, "_onlystudents-wholeday.gml")), format = "gml")
  vertex_attr(g, "school") <- school
  vertex_attr(g, "grade") <- case_when(
    vertex_attr(g, "shape") == "ellipse" & vertex_attr(g, "xfact") == 0 ~ "Kindergarten",
    vertex_attr(g, "shape") == "box" & vertex_attr(g, "xfact") == 0 ~ "1st grade",
    vertex_attr(g, "shape") == "diamond" & vertex_attr(g, "xfact") == 0 ~ "2nd grade",
    vertex_attr(g, "shape") == "triangle" & vertex_attr(g, "xfact") == 0 ~ "3rd grade",
    vertex_attr(g, "shape") == "ellipse" & vertex_attr(g, "xfact") == 1 & vertex_attr(g, "yfact") == 3 ~ "4th grade",
    vertex_attr(g, "shape") == "box" & vertex_attr(g, "xfact") == 1 & vertex_attr(g, "yfact") == 3 ~ "5th grade",
    vertex_attr(g, "shape") == "diamond" & vertex_attr(g, "xfact") == 1 & vertex_attr(g, "yfact") == 3 ~ "6th grade",
    vertex_attr(g, "shape") == "triangle" & vertex_attr(g, "xfact") == 1 & vertex_attr(g, "yfact") == 3 ~ "7th grade",
    vertex_attr(g, "shape") == "ellipse" & vertex_attr(g, "xfact") == 3 & vertex_attr(g, "yfact") == 1 ~ "8th grade",
    vertex_attr(g, "shape") == "box" & vertex_attr(g, "xfact") == 3 & vertex_attr(g, "yfact") == 1 ~ "9th grade",
    vertex_attr(g, "shape") == "diamond" & vertex_attr(g, "xfact") == 3 & vertex_attr(g, "yfact") == 1 ~ "10th grade",
    vertex_attr(g, "shape") == "triangle" & vertex_attr(g, "xfact") == 3 & vertex_attr(g, "yfact") == 1 ~ "11th grade",
    vertex_attr(g, "shape") == "ellipse" & vertex_attr(g, "xfact") == 5 & vertex_attr(g, "yfact") == 1 ~ "12th grade"
  )
  vertex_attr(g, "grade_numeric") <- grade_to_num[vertex_attr(g, "grade")]
  vertex_attr(g, "id") <- seq_len(gorder(g))
  
  return(asNetwork(g))
}
)

names(graphs) <- schools
