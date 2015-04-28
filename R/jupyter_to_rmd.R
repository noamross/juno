#' Convert a Jupyter Notebook file to an Rmd file
#'
#' @param infile the jupyter file to convert
#' @param outfile the target file
#' @import stringi
#' @import jsonlite
#' @import yaml
#' @export
jupyter_to_rmd = function(infile, outfile) {

  jupyter_list = jsonlite::fromJSON(infile, simplifyDataFrame = FALSE)

  jupyter_info = jupyter_list[names(jupyter_list) != "cells"]
  knitr_metadata = jupyter_info$metadata$knitr_metadata
  jupyter_info$metadata$knitr_metadata = NULL
  header_yaml = as.yaml(c(knitr_metadata, list(jupyter_info = jupyter_info)))
  cat("---\n", header_yaml, "---\n", file=outfile, sep="")

  for(cell in jupyter_list$cells) {
    jupyter_meta = cell$metadata[names(cell$metadata) != "knitr_meta"]

    if(length(jupyter_meta) > 0) {
      jupyter_meta = paste(", jupyter_meta =", as.character(list(jupyter_meta)))
    } else {
      jupyter_meta = NULL
    }

    if (cell$cell_type == "code") {

      if(!is.null(cell$metadata$knitr_meta)) {
        label = cell$metadata$knitr_meta$label
        if(!is.null(label)) label = paste0(" ", label)
        options = cell$metadata$knitr_meta[names(cell$metadata$knitr_meta) != "label"]
        options = paste(",", (paste(names(options), "=", options, collapse=", ")))
      } else {
        label = options = NULL
      }

      cat("\n```{", tolower(jupyter_list$metadata$language_info$name), label,
          options, jupyter_meta, "}\n", cell$source, "\n```\n",
          file=outfile, sep="", append=TRUE)
    } else {
      cat("\n<!-- jupyter_", cell$cell_type, jupyter_meta, " -->\n",
          cell$source, "\n", file=outfile, sep="", append=TRUE)
    }
  }
}
