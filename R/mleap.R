library(sparklyr)
library(dplyr)
library(mleap)

conf <- spark_config()
conf$`sparklyr.shell.driver-memory` <- "8G"
sc <- spark_connect(master = "local", version = "2.2.0",
                    config = conf)

# copy some data to our "cluster"
diamonds_tbl <- copy_to(sc, ggplot2::diamonds)
diamonds_tbls <- diamonds_tbl %>%
  mutate(price = as.numeric(price)) %>%
  sdf_partition(train = 0.8, validation = 0.2)

# define and fit a pipeline
pipeline <- ml_pipeline(sc) %>%
  ft_string_indexer("cut", "cut_cat") %>%
  ft_string_indexer("color", "color_cat") %>%
  ft_string_indexer("clarity", "clarity_cat") %>%
  ft_vector_assembler(
    c("carat", "cut_cat", "color_cat", "clarity_cat",
      "depth", "table", "x", "y", "z"),
    "features"
  ) %>%
  ml_random_forest_regressor(
    label_col = "price",
    num_trees = 10, max_depth = 20)

pipeline_model <- pipeline %>%
  ml_fit(diamonds_tbls$train)

pipeline_model %>%
  ml_transform(diamonds_tbls$validation) %>%
  select(prediction, price)

# save the ml pipeline
ml_save(pipeline_model, "saved_models/spark-pipeline", 
        overwrite = TRUE)

# save the mleap bundle
ml_write_bundle(pipeline_model, 
                ml_transform(pipeline_model, diamonds_tbls$train),
                "saved_models/mleap-bundle.zip",
                overwrite = TRUE)

# make up some data to be scored
newdata <- list(
  carat = 0.65, cut = "Good", color = "E",
  clarity = "VS1", depth = 60, table = 60,
  x = 4.5, y = 4.6, z = 2.7
) %>%
  jsonlite::toJSON()
newdata

# start spark scoring service
p <- plumber::plumb("plumber/spark-plumber.R")
p$run()

# start mleap scoring service
p <- plumber::plumb("plumber/mleap-plumber.R")
p$run()

spark_disconnect(sc)

