#' @export multiclass.brier
#' @rdname measures
#' @format none
multiclass.brier = makeMeasure(id = "multiclass.brier", minimize = TRUE, best = 0, worst = 1,
  properties = c("classif", "classif.multi", "req.pred", "req.truth", "req.prob"),
  name = "Multiclass Brier score",
  fun = function(task, model, pred, feats, extra.args) {
  measureMulticlassBrier(getPredictionProbabilities(pred), pred$data$truth)
  }
)

#' @export measureMulticlassBrier
#' @rdname measures
#' @format none
measureMulticlassBrier = function(probabilities, truth) {
  mean(rowSums((probabilities - model.matrix( ~ . -1, data = as.data.frame(truth)))^2))
}
