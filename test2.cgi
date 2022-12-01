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

		<title>working</title>

		<link href=\"/entireframework.min.css\" rel=\"stylesheet\" type=\"text/css\">
	</head>
	<body>
		<nav class=\"nav\" tabindex=\"-1\" onclick=\"this.focus()\">
			<div class=\"container\">
				<a class=\"pagename current\" href=\"#\">Your Site Name</a>
				<a href=\"#\">One</a>
				<a href=\"#\">Two</a> 
				<a href=\"#\">Three</a>
			</div>
		</nav>
		<button class=\"btn-close btn btn-sm\">×</button>
		<div class=\"container\">
			<h1>Example</h1>
			<p>You can view the source of this page and copy it to get a quick start on a project with Min!</p>
		</div>
	</body>
</html>"
