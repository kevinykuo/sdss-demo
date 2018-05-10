library(sparklyr)
sc <- spark_connect(master = "local", version = "2.2.0")
spark_model <- ml_load(sc, "saved_models/spark-pipeline")

#* @post /predict
score_spark <- function(
  carat, cut, color, clarity, depth, table,
  x, y, z
) {
  pred_data <- data.frame(
    carat = carat, cut = cut, color = color, clarity = clarity,
    depth = depth, table = table, x = x, y = y, z = z,
    stringsAsFactors = FALSE
  )
  pred_data_tbl <- sdf_copy_to(sc, pred_data, overwrite = TRUE)
  
  ml_transform(spark_model, pred_data_tbl) %>%
    dplyr::pull(prediction)
}
