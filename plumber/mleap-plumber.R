library(mleap)
mleap_model <- mleap_load_bundle("saved_models/mleap-bundle.zip")

#* @post /predict
score_mleap <- function(
  carat, cut, color, clarity, depth, table,
  x, y, z
) {
  pred_data <- data.frame(
    carat = carat, cut = cut, color = color, clarity = clarity,
    depth = depth, table = table, x = x, y = y, z = z,
    stringsAsFactors = FALSE
  )
  
  mleap_transform(mleap_model, pred_data)$prediction
}
