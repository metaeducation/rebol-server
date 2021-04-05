function [request] [
  ;; 
  fix-load-r3: function [file] [
    if 'file != exists? file [return]
    text: read/string file
    replace/all text
      "https://metaeducation.s3.amazonaws.com/travis-builds/load-r3.js"
      "/system/load-r3.js"
    write file text
  ]
  tmp: %install.tmp/
  query: parse-query request/query-string
  src: select query "src"
  target: dirize join %apps/ select query "name"
  case [
    parse src [thru ".zip" end] []
    parse src [
      remove opt ["http" opt "s" "://"]
      "github.com/"
      thru "/"
      [ thru "/" end
      | not to "/" to end insert "/"
      ]
    ] [append insert src "https://codeload." "zip/master"]
    default [return spaced ["Invalid src:" src]]
  ]
  zip: read to-url src
  delete-recur tmp
  mkdir/deep tmp
  unzip/quiet tmp zip
  src: read tmp
  src: either (1 = length-of src) and (dir? src/1)
  [ join tmp src/1 ] [tmp]
  fix-load-r3 join src %index.html
  delete-recur target
  rename src target
  delete-recur tmp
  {<meta http-equiv="Refresh" content="0; url=/apps/" />}
]
