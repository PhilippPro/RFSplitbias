#' @export multiclass.brier
#' @rdname measures
#' @format none
multiclass.brier = makeMeasure(id = "multiclass.brier", minimize = TRUE, best = 0, worst = Inf,
  properties = c("classif", "classif.multi", "req.pred", "req.truth", "req.prob"),
  name = "Multiclass Brier score",
  fun = function(task, model, pred, feats, extra.args) {
    if (!is.na(pred$task.desc$negative)) {
      measureBrier(getPredictionProbabilities(pred), pred$data$truth, pred$task.desc$negative, pred$task.desc$positive)
    } else {
      measureMulticlassBrier(getPredictionProbabilities(pred), pred$data$truth)
    }
  }
)

#' @export measureMulticlassBrier
#' @rdname measures
#' @format none
measureMulticlassBrier = function(probabilities, truth) {
  mean(rowSums((probabilities - model.matrix( ~ . -1, data = as.data.frame(truth)))^2))
}
