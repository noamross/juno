#' @import knitr rmarkdown stringi jsonlite
rmd_to_jupyter <- function(infile, outfile) {
  input_lines = rmarkdown:::read_lines_utf8(infile, getOption("encoding"))
  partitioned = rmarkdown:::partition_yaml_front_matter(input_lines)
  rmd_metadata = rmarkdown:::parse_yaml_front_matter(input_lines)

  knitr:::knit_code$restore()
  knitr::opts_knit$set(out.format = 'markdown')
  assign("labels", NULL, knitr:::.knitEnv)
  knitr:::chunk_counter(reset=TRUE)

  chunks = knitr:::split_file(partitioned$body, patterns = knitr::all_patterns$md)

  block_code = lapply(knitr:::knit_code$get(), function(x) {
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
      chunks[[i]]$source[1:(length(chunks[[i]]$source) - 1)] = paste0(chunks[[i]]$source[1:(length(chunks[[i]]$source) - 1)], "\n")
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

  jupyter = list()
  jupyter$cells = cells
  jupyter$metadata = rmd_metadata$jupyter_info$metadata
  jupyter$metadata$knitr_metadata = rmd_metadata[names(rmd_metadata) != "jupyter_info"]
  jupyter$nbformat = rmd_metadata$jupyter_info$nbformat
  jupyter$nbformat_minor = rmd_metadata$jupyter_info$nbformat_minor

  for(i in seq_along(jupyter$cells)) {
    if(length(jupyter$cells[[i]]$metadata) == 0) jupyter$cells[[i]]['metadata'] = list(NULL)
  }
  cat(jsonlite::toJSON(jupyter, pretty=TRUE, auto_unbox=TRUE), file = outfile)

}
