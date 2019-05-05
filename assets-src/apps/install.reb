function [request] [
  set [app-name: src:] split-query request/query-string
  base-dir: join
    first split-path request/real-path
    app-name
  repo: _
  parse src [
    opt ["http" opt "s" "://github.com/"]
    copy repo [thru "/" [to "/" | to end]]
  ]
  append repo "/"
  api-base-url: join https://api.github.com/repos/ repo
  import 'json
  x: load-json read/string join api-base-url "git/refs/heads/master"
  sha: x/object/sha
  x: load-json read/string join api-base-url ["git/trees/" sha "?recursive=1"]
  x: x/tree
  raw-base-url: join https://raw.githubusercontent.com/ reduce [repo sha]
  mkdir base-dir
  for-each x x [
    if e: trap [
      target: x/path
      url: raw-base-url/:target
      type: x/type
      target: base-dir/:target
      if type = "tree" [mkdir/deep ?? target]
      else [write target read url]
    ] [return quote e]
  ]
  return unspaced [
    <p>{<a href="}app-name{/">}
    app-name </a>
    { installed!} <br/>
    <a href="./">{Apps}</a>
    </p>
  ]
]
