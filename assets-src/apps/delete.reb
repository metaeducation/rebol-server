function [request] [
  query: parse-query request/query-string
  ?? name: clean-path join %apps/ select query "name"
  delete-recur name
  {<meta http-equiv="Refresh" content="0; url=/apps/" />}
]

