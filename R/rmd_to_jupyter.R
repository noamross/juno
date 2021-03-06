#' @import knitr rmarkdown stringi jsonlite
#' @export
rmd_to_jupyter <- function(infile, outfile) {
  input_lines = rmarkdown:::read_lines_utf8(infile, getOption("encoding"))
  partitioned = rmarkdown:::partition_yaml_front_matter(input_lines)
  rmd_metadata = rmarkdown:::parse_yaml_front_matter(input_lines)

  knitr:::knit_code$restore()
  knitr::opts_knit$set(out.format = 'markdown')
  assign("labels", NULL, knitr:::.knitEnv)
  knitr:::chunk_counter(reset=TRUE)

  chunks = knitr:::split_file(partitioned$body, patterns = knitr::all_patterns$md)

  block_code = knitr:::knit_code$get()

  language = attr(block_code[[1]], "chunk_opts")$engine
  if(is.null(language)) language = "r"

  block_code = lapply(block_code, function(x) {
    attributes(x) <- NULL
    return(x)
  })


  for(i in seq_along(chunks)) {
    if(class(chunks[[i]]) == "block") {
      chunks[[i]]$source = block_code[[chunks[[i]]$params$label]]
    } else if(class(chunks[[i]]) == "inline") {
      chunks[[i]]$source = chunks[[i]]$input.src
    }
    if(length(chunks[[i]]$source) > 1) {
      chunks[[i]]$source = chunks[[i]]$source[chunks[[i]]$source != ""]
      chunks[[i]]$source[1:(length(chunks[[i]]$source) - 1)] =
         paste0(chunks[[i]]$source[1:(length(chunks[[i]]$source) - 1)], "\n")

    }
    if(identical(chunks[[i]]$source, "")) chunks[[i]]$source = character()
  }

  cells = lapply(chunks, function(chunk) {
    cell = list()
    if(class(chunk) == "block") {
      cell$cell_type = "code"
      cell$execution_count = NA
      cell$metadata= list()
      cell$metadata = eval(chunk$params$jupyter_meta)
      cell$metadata$knitr_meta = chunk$params[names(chunk$params) != "jupyter_meta"]
      if(stri_detect_regex(chunk$params$label, paste0(knitr::opts_knit$get("unnamed.chunk.label"),"-\\d+"))) {
        cell$metadata$knitr_meta$label = NULL
      }
      cell$outputs = character()
      cell$source = chunk$source
    } else if(class(chunk) == "inline") {
      cell$cell_type = "markdown"
      cell$metadata = list()
      cell$source = chunk$source
    }
    if(length(cell$metadata$knitr_meta) == 0) cell$metadata$knitr_meta = NULL
    return(cell)
  })

  cells = lapply(cells, function(cell) {
    if(cell$cell_type == "markdown" & length(cell$source) == 0) {
      return(NULL)
    } else {
      return(cell)
    }
  })

  cells = cells[!sapply(cells, is.null)]

  jupyter = list()
  jupyter$cells = cells
  jupyter_info = recursive_merge(rmd_metadata$jupyter_info, .default_jupyter_info[[language]])
  jupyter$metadata = jupyter_info$metadata
  jupyter$metadata$knitr_metadata = rmd_metadata[names(rmd_metadata) != "jupyter_info"]
  jupyter$nbformat = jupyter_info$nbformat
  jupyter$nbformat_minor = jupyter_info$nbformat_minor

  for(i in seq_along(jupyter$cells)) {
    if(length(jupyter$cells[[i]]$metadata) == 0) jupyter$cells[[i]]['metadata'] = list(NULL)
  }
  cat(jsonlite::toJSON(jupyter, pretty=TRUE, auto_unbox=TRUE, force=TRUE), file = outfile)

}

.default_jupyter_info = list(
  r = list(
    metadata = list(
      kernelspec = list(display_name = "R", language = "", name = "ir"),
      language_info = list(codemirror_mode = "r", file_extension = ".r",
                           mimetype = "text/x-r-source", name = "R",
                           pygments_lexer = "r",
                           version = paste0(R.version$major, ".", R.version$minor))),
    nbformat = 4, nbformat_minor = 0),

  python = list(
    metadata = list(
      kernelspec = list(display_name = "Python 2", language = "python",
                        name = "python2"),
      language_info = list(codemirror_mode = list(name = "ipython", version = 2),
                           file_extension = ".py", mimetype = "text/x-python",
                           name = "python", nbconvert_exporter = "python",
                           pygments_lexer = "ipython2", version = "2.7.9")),
    nbformat = 4, nbformat_minor = 0))

