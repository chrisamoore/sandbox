<!DOCTYPEhtml>
<htmllang="en">
	<head>
		<meta charset="utf-8" />
	</head>
	<body>
		<h1>Password Reset</h1>
			To reset your password, complete this form:
			{{ URL::route("user/reset") . "?token=" . $token }}
	</body>
</html>
