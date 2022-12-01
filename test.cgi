#!/usr/bin/env tclsh
#set fp [open "test.text" r]
#set file_data [read $fp]
#close $fp
#puts $file_data
set x 1010
set x [clock seconds]
puts "Content-Type: text/html
Status: 200 Success

<!DOCTYPE html>
<html>

<head>
  <meta charset=\"UTF-8\">
  <meta name=\"viewport\" content=\"width=device-width, initial-scale=1\">
  <title>app</title>
  <link href=\"/entireframework.min.css\" rel=\"stylesheet\" type=\"text/css\">
  <style>
    .hero {
      background: #eee;
      padding: 20px;
      border-radius: 10px;
      margin-top: 1em;
    }
  </style>
</head>

<body>
  <nav class=\"nav\" tabindex=\"-1\" onclick=\"this.focus()\">
    <div class=\"container\">
      <a class=\"pagename current\" href=\"#\">octetta</a>
    </div>
  </nav>
  <div class='hero'>
    my echo works $x
  </div>
</body>

</html>"
