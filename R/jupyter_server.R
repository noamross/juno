.jupyter_server = new.env()
.jupyter_server$url = 'xxx'

#get_jupyter_server = function()

# juno <- function(notebook = NULL, ...) {
#   url = jupyter_server(...)
#   if(is.null(notebook)) {
#     file.copy(
#   } else {
#     file_url = paste0(url, "/", notebook)
#   }
#   view_url(file_url)
# }

#' @importFrom rstudioapi viewer
#' @importFrom utils browseURL
view_url = function(url) {
  viewer <- getOption("viewer")
  if (!is.null(viewer)) {
    rstudioapi::viewer(url)
  }
  else {
    utils::browseURL(url)
  }
}


#' Launch a jupyter server or connect with one already running
#' @param dir the server working directory
#' @param port the port on which to launch the server
#' @param ip the ip to launch the server on
#' @param view open a viewer window or browser with the server?
#' @export
jupyter_server = function(dir=getwd(), port=8888, ip='localhost', view=TRUE) {

  server_options = list(dir=dir, port=port, ip=ip)
  if(!is.null(file)) file = URLencode(file)
  running = check_local_url(.jupyter_server$url)
  if(running & (identical(server_options, .jupyter_server$server_options))) {
    return(.jupyter_server$url)
  }
  if(running) {
    kill_jupyter_server()
  }

  tmp = tempfile()
  system(paste0("ipython notebook --no-browser --log-level=0 --port=",
                port, " --ip=", ip, " --notebook-dir=", dir, " & echo $! > ",
                tmp))
  .jupyter_server$pid = readLines(tmp)
  .jupyter_server$server_options = server_options
  .jupyter_server$url = paste0('http://', ip, ':', port)
  if(view) view_url(.jupyter_server$url)

  return(.jupyter_server$url)

}

kill_jupyter_server = function() {
  if(!is.null(.jupyter_server$pid)) {
    system(paste('kill', .jupyter_server$pid))
    .jupyter_server$pid = NULL
    return(TRUE)
  } else {
    return(FALSE)
  }
}

check_local_url = function(url) {
  response = try(GET(url), silent = TRUE)
  if("try-error" %in% class(response)) return(FALSE)
  return(http_status(response)$category == "success")
}

# system(paste('kill', pid), ignore.stdout = TRUE, ignore.stderr = TRUE, wait=FALSE)
# First, look for server/kernel running, figure out port, directory
# Make URL based on
