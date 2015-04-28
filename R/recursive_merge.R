# from https://stackoverflow.com/questions/13811501/r-merge-lists-with-overwrite-and-recursion
# Merges list1 with list2, replacing items in list1 with list2 if they exist
recursive_merge = function(list1, list2) {
  allNames <- unique(c(names(list1), names(list2)))
  merged <- list1 # we will copy over/replace values from list2 as necessary
  for (x in allNames) {
    # convenience
    a <- list1[[x]]
    b <- list2[[x]]
    if (is.null(a)) {
      # only exists in list2, copy over
      merged[[x]] <- b
    } else if (is.list(a) && is.list(b)) {
      # recurse
      merged[[x]] <- recursive_merge(a, b)
    } else if (!is.null(b)) {
      # replace the list1 value with the list2 value (if it exists)
      merged[[x]] <- b
    }
  }
  return(merged)
}