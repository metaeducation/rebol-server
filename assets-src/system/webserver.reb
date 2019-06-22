#!/usr/bin/r3
REBOL [Name: "webserver"]
-help: does [lib/print {
USAGE: r3 webserver.reb [OPTIONS]
OPTIONS:
  -h, -help, --help : this help
  -q      : verbose: 0 (quiet)
  -v      : verbose: 2 (debug)
  INTEGER : port number [8000]
  OTHER   : web root [system/options/path]
  -a name : access-dir via name.*
EXAMPLE: 8080 /my/web/root -q -a index
}]

;; INIT
port: 8888
root-dir: %"./"
access-dir: false
verbose: 1

a: system/options/args
iterate a [case [
    "-a" = a/1 [
      a: next a
      access-dir: case [
        tail? a [true]
        a/1 = "true" [true]
        a/1 = "false" [false]
      ] else [to-file a/1]
    ]
    find ["-h" "-help" "--help"] a/1 [-help quit]
    "-q" = a/1 [verbose: 0]
    "-v" = a/1 [verbose: 2]
    integer? load a/1 [port: load a/1]
    true [root-dir: to-file a/1]
]]

;; LIBS
import 'httpd
attempt [
  rem: import 'rem
  html: import 'html
]
rem-to-html: attempt[chain [:rem/load-rem :html/to-html]]

cd (:system/options/path)

ext-map: [
  "css" css
  "gif" gif
  "htm" html
  "html" html
  "jpg" jpeg
  "jpeg" jpeg
  "js" js
  "json" json
  "png" png
  "r" rebol
  "r3" rebol
  "reb" rebol
  "rem" rem
  "txt" text
  "wasm" wasm
]

mime: make map! [
  html "text/html"
  jpeg "image/jpeg"
  r "text/plain"
  text "text/plain"
  js "application/javascript"
  json "application/json"
  css "text/css"
  wasm "application/wasm"
]

status-codes: [
  200 "OK" 201 "Created" 204 "No Content"
  301 "Moved Permanently" 302 "Moved temporarily" 303 "See Other" 307 "Temporary Redirect"
  400 "Bad Request" 401 "No Authorization" 403 "Forbidden" 404 "Not Found" 411 "Length Required"
  500 "Internal Server Error" 503 "Service Unavailable"
]

html-list-dir: function [
  "Output dir contents in HTML."
  dir [file!]
  ][
  if trap [list: read dir] [return _]
  ;;for-next list [if 'dir = exists? join dir list/1 [append list/1 %/]]
  ;; ^-- workaround for #838
  sort/compare list func [x y] [
    case [
      all [dir? x not dir? y] [true]
      all [not dir? x dir? y] [false]
      y > x [true]
      true [false]
    ]
  ]
  if dir != %/ [insert list %../]
  data: copy {<head>
    <meta name="viewport" content="initial-scale=1.0" />
    <style> a {text-decoration: none}
    body {font-family: monospace}
    .b {font-weight: bold}
    </style>
  </head>
  [>]: Navigate [V]: View [E]: Exec <hr/>
  }
  for-each i list [
    is-rebol-file: did all [
      not dir? i
      parse i [thru ".reb" end]
    ]
    append data unspaced [
      {<a }
      if dir? i [{class="b" }]
      {href="} i
      {?">[}
      case [
        is-rebol-file [{E}]
        dir? i [{>}]
        default [{V}]
      ]
      {]</a> }
      {<a }
      if dir? i [{class="b" }]
      {href="} i
      {">}
      i
      </a> <br/>
    ]
  ]
  data
]

parse-query: function [query] [
  query: to-text query
  r: split query "&"
]

handle-request: function [
    request [object!]
  ][
  path-elements: next split request/target #"/"
  ; 'extern' url /http://ser.ver/...
  if parse request/request-uri ["/http" opt "s" "://" to end] [
    if all [
      3 = length path-elements
      #"/" != last path-elements/3
    ] [; /http://ser.ver w/out final slash
      path: unspaced [
        request/target "/"
        if request/query-string unspaced [
          "?" to-text request/query-string
        ]
      ]
      return redirect-response path
    ]
    path: to-url next request/request-uri
    path-type: 'file
  ] else [
    path: join root-dir request/target
    path-type: try exists? path
  ]
  append request reduce ['real-path clean-path path]
  if path-type = 'dir [
    if not access-dir [return 403]
    if request/query-string [
      if data: html-list-dir path [
        return reduce [200 mime/html data]
      ] 
      return 500
    ]
    if file? access-dir [
      for-each ext [%.reb %.rem %.html %.htm] [
        dir-index: join access-dir ext
        if 'file = try exists? join path dir-index [
          if ext = %.reb [append dir-index "?"]
          break
        ]
      ] then [dir-index: "?"]
    ] else [dir-index: "?"]
    return redirect-response join request/target dir-index
  ]
  if path-type = 'file [
    pos: try find-last last path-elements
      "."
    file-ext: (if pos [copy next pos] else [_])
    mimetype: try attempt [ext-map/:file-ext]
    if trap [data: read path] [return 403]
    if all [
      request/query-string
      action? :rem-to-html
      any [
        mimetype = 'rem
        all [
          mimetype = 'html
          "REBOL" = uppercase to-text copy/part data 5
        ]
      ]
    ][
      rem/rem/request: request
      if error: trap [
        data: rem-to-html data
      ] [ data: form error mimetype: 'text ]
      else [ mimetype: 'html ]
    ]
    if request/query-string [
      if mimetype = 'rebol [
        mimetype: 'html
        trap [
          data: do data
        ]
        if action? :data [
          if error? e: trap [data: data request]
          [ data: e mimetype: "text/html" ]
        ]
        case [
          block? :data [
            mimetype: first data
            data: next data
          ]
          quoted? :data [
            data: form eval data
            mimetype: 'text
          ]
          error? :data [mimetype: 'text]
        ]
        data: form :data
      ] else [
        mimetype: 'text
      ]
    ]
    return reduce [200 try select mime :mimetype data]
  ]
  404
]

redirect-response: function [target] [
  reduce [200 mime/html unspaced [
    {<html><head><meta http-equiv="Refresh" content="0; url=}
    target {" /></head></html>}
  ]]
]

;; MAIN
server: open compose [
  scheme: 'httpd (port) [
    if verbose >= 2 [lib/print mold request]
    if verbose >= 1 [
      lib/print spaced [
        request/method
        request/request-uri
      ]
    ]
    res: handle-request request
    if integer? res [
      response/status: res
      response/type: "text/html"
      response/content: unspaced [
        <h2> res space select status-codes res </h2>
        <b> request/method space request/request-uri </b>
        <br> <pre> mold request </pre>
      ]
    ] else [
      response/status: res/1
      response/type: res/2
      response/content: to-binary res/3
    ]
    if verbose >= 1 [
      lib/print spaced ["=>" response/status]
    ]
  ]
]
if verbose >= 1 [
  lib/print spaced ["Serving on port" port]
  lib/print spaced ["root-dir:" clean-path root-dir]
  lib/print spaced ["access-dir:" mold access-dir]
]

wait server

;; vim: set syn=rebol sw=2 ts=2 sts=2 expandtab:
