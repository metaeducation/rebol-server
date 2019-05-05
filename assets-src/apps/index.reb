function [request] [
  emit: function [value] [append out value]
  cwd: first split-path request/real-path
  out: copy {<!DOCTYPE html><html>
      <head>
        <title>Apps</title>
        <meta charset="utf-8">
        <meta name="viewport" content="width=device-width, initial-scale=1">
        <style> a {text-decoration: none} </style>
      </head></body>
      <h1>Installed Apps</h1>
  }
  for-each x read cwd [
    if dir? x [
      emit reword
        {<a href='$x'>[$t]</a> <br>}
        reduce ['x x 't copy/part x back tail x]
    ]
  ]
  emit {<h1>Available Apps</h1>}
  apps-list: load root-dir/apps/apps-list.reb
  for-each [name src desc] apps-list [
    emit reword {
        <p><a href="$src"><b>[$name]</b></a>
        <a href="install.reb?$name&$src">[(re)install]</a>
        &mdash; $desc</p>
      }
      reduce ['name to-text name 'desc desc 'src src] 
  ]
  emit "</dl></body></html>"
]
