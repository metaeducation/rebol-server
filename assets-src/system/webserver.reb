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

delete-recur: adapt :lib/delete [
  if file? port [
    if not exists? port [return null]
    if 'dir = exists? port [
      for-each x read dirize port [
          delete-recur join port [/ x]
      ]
    ]
  ]
]

import 'httpd
attempt [
  rem: import 'rem
  html: import 'html
]
rem-to-html: attempt[chain [:rem/load-rem :html/to-html]]

change-dir system/options/path

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
  "svg" svg
  "txt" text
  "wasm" wasm
]

mime: make map! [
  css "text/css"
  gif "image/gif"
  html "text/html"
  jpeg "image/jpeg"
  js "application/javascript"
  json "application/json"
  png "image/png"
  r "text/plain"
  svg "image/svg+xml"
  text "text/plain"
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
      ] else [{V}]
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
  xchar: charset "=&"
  r: make block! 0
  k: v: _
  query: to-text query
  i: 0
  parse query [any [
    copy k [to xchar | to end]
    [ "=" copy v [to "&" | to end]
    | (v: k k: i: i + 1)
    ]
    (
      append r (attempt [dehex k]) or [k]
      append r (attempt [dehex v]) or [v]
    )
    opt skip
  ]]
  r
]

request: _

handle-request: function [
    req [object!]
  ][
  set 'request req  ; global 
  req/target: my dehex
  path-elements: next split req/target #"/"
  ; 'extern' url /http://ser.ver/...
  if parse req/request-uri ["//"] [
    lib/print req/request-uri
    return reduce [200 mime/html "req/request-uri"]
  ] else [
    path: join root-dir req/target
    path-type: try exists? path
  ]
  append req reduce ['real-path clean-path path]
  if path-type = 'dir [
    if not access-dir [return 403]
    if req/query-string [
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
    return redirect-response join req/target dir-index
  ]
  if path-type = 'file [
    pos: try find-last last path-elements
      "."
    file-ext: (if pos [copy next pos] else [_])
    mimetype: try attempt [ext-map/:file-ext]
    if trap [data: read path] [return 403]
    if all [
      any [
        mimetype = 'rem
        all [
          mimetype = 'html
          "REBOL" = uppercase to-text copy/part data 5
        ]
      ]
      action? :rem-to-html
      any [
        not req/query-string
        not empty? req/query-string 
      ]
    ][
      rem/rem/request: req
      if error: try trap [
        data: rem-to-html data
      ] [ data: form error mimetype: 'text ]
      else [ mimetype: 'html ]
    ]
    if mimetype = 'rebol [
      if req/query-string [
        mimetype: 'html
        e: try trap [
          data: do data
        ]
        if all [not error? e | action? :data] [
          e: try trap [
            data: data req
          ]
        ]
        if error? e [data: e]
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
      ] else [mimetype: 'text]
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

    ; !!! This is a hook inserted for purposes of being
    ; able to know if a screenless emulator is running
    ; the console correctly.  /data/local/tmp is a special
    ; writable folder in Android.
    ;
    ; https://github.com/metaeducation/rebol-server/issues/9
    ; 
    if request/target = "/testwrite" [
       lib/print "writing /data/local/tmp/testwrite.txt"
       write %/data/local/tmp/testwrite.txt "TESTWRITE!"
    ] else [
       res: handle-request request
    ]

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

;; vim: set et sw=2:
