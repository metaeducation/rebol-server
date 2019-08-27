function [request] [
  emit: function [value] [append out value]
  cwd: first split-path request/real-path
  out: copy {<!DOCTYPE html><html>
    <head>
      <title>Apps</title>
      <meta charset="utf-8">
      <meta name="viewport" content="width=device-width, initial-scale=1">
      <style>
        a {text-decoration: none}
        h1 {margin-bottom: 2px}
        form {margin: 0}
      </style>
    </head></body>
    <h1>Installed Apps</h1>
    [&ndash;]: Delete <hr/>
  }
  for-each x read cwd [
    if dir? x [
      emit reword
        {<a href='delete.reb?name=$t'>[&ndash;]</a>
          <a href='$x'>$t</a> <br>
        }
        reduce ['x x 't copy/part x back tail x]
    ]
  ]
  emit {<h1>Available Apps</h1>
    [+]: (re)install
    <i>(see <a href=apps-list.reb>apps-list.reb</a>)</i>
    <hr/>
  }
  apps-list: load root-dir/apps/apps-list.reb
  for-each [name src desc] apps-list [
    emit reword {
        <p>
        <a href="install.reb?name=$name&src=$src">[+]</a>
        <a href="$src">$name</a>
        &mdash; $desc</p>
      }
      reduce ['name to-text name 'desc desc 'src src] 
  ]
  emit {<h1>Custom install</h1>
    <form action='install.reb'>
    name:
    <br><input name='name' type='text' style='width: 90%'>
    <br>
    source: (github.com/user/repo or *.zip)
    <br><input name='src' type='text' style='width: 90%'>
    <br>
    <input type='submit' value='Install'>
    </form>
  }
  emit "</body></html>"
]

;; vim: set et sw=2:
