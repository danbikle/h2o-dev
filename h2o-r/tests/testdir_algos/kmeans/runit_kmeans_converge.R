setwd(normalizePath(dirname(R.utils::commandArgs(asValues=TRUE)$"f")))
source('../../h2o-runit.R')

test.km.iter_max <- function(conn) {
  Log.info("Importing ozone.csv data...\n")
  ozone.hex <- h2o.uploadFile(conn, locate("smalldata/glm_test/ozone.csv"))
  print(summary(ozone.hex))
  miters <- 5
  ncent <- 10
  
  Log.info(paste("Run k-means in a loop of", miters, "iterations with max_iter = 1"))
  start <- ozone.hex[1:ncent,]
  expect_error(h2o.kmeans(ozone.hex, max_iterations = 0))
  for(i in 1:miters) {
    fitrep <- h2o.kmeans(ozone.hex, init = start, max_iterations = 1)
    start <- fitrep@model$centers
  }
  Log.info(paste("Run k-means with max_iter =", miters))
  fitall <- h2o.kmeans(ozone.hex, init = ozone.hex[1:ncent,], max_iterations = miters)
  expect_equivalent(fitrep@model$centers, fitall@model$centers)
  
  Log.info("Check cluster centers have converged")
  fitall2 <- h2o.kmeans(ozone.hex, init = fitall@model$centers, max_iter = 1)
  avg_change <- sum((fitall@model$centers - fitall2@model$centers)^2)/ncent
  expect_true(avg_change < 1e-6 || fitall@model$iterations > miters)
  testEnd()
}

doTest("KMeans Test: Test convergence at max iterations", test.km.iter_max)