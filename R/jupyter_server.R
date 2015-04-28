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
#' @param notebook to open. If file does not exist, it will be created, with a \code{.ipynb} extension. Default is none, just launch a server in the background.
#' @param dir the server working directory. Default is either the working directory or parent directory of the notebook.
#' @param port the port on which to launch the server.  Default is 8888.
#' @param ip the ip to launch the server on.  Default is 'localhost'
#' @param view open a viewer window or browser with the server? Default is to view only if a notebook is specified.
#' @export
#' @import stringi
jupyter_server = function(notebook = NULL, dir=NULL, port=8888, ip='localhost', view=NULL) {

  if(is.null(view)) view = !is.null(notebook)

  if(!is.null(notebook)) {
    if(!file.exists(notebook)) {
      if(tools::file_ext(notebook) == "") {
        notebook = paste0(notebook, ".ipynb")
      }
      file.copy(from = system.file('notebook_template.ipynb', package = "juno"),
                to = notebook)
      }
  } else {
    notebook_path=NULL
  }


  if(is.null(dir) & !is.null(notebook)) {
    if(normalizePath(notebook) %in% normalizePath(list.files(getwd(), recursive=TRUE))) {
      dir = getwd()
      notebook_path = paste0('/notebooks/',
                             stri_extract_first_regex(normalizePath(notebook), paste0("(?<=", normalizePath(dir), "/).*")))
    } else {
      dir = dirname(normalizePath(notebook))
      notebook_path = paste0('/notebooks/', notebook)
    }
  } else if(is.null(dir)) {
    dir = getwd()
  }



  server_options = list(dir=dir, port=port, ip=ip)
  running = check_local_url(.jupyter_server$url)
  if(running & (identical(server_options, .jupyter_server$server_options))) {
    notebook_path = URLencode(paste0(.jupyter_server$url, notebook_path))
    if(view) view_url(notebook_path)
    return(notebook_path)
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

  notebook_path = URLencode(paste0(.jupyter_server$url, notebook_path))
  if(view) view_url(notebook_path)

  return(notebook_path)

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
