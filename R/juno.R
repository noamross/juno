#' Display a jupyter notebook file
#'
#' NASA's Juno mission is currently on its way to Jupiter
#'
#' @param jupyter_file a jupyter notebook file
#' @param port the port to display the notebook on localhost
#' @export
juno <- function(nbname, port=8888) {
  system(paste0("ipython notebook --no-browser --port=", port), wait=FALSE, ignore.stdout=TRUE, ignore.stderr = TRUE)
  url =paste0("http://localhost:", port, "/notebooks/", URLencode(nbname))
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    viewer(url)
  }
  else {
    utils::browseURL(url)
  }
}
