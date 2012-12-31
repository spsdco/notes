$ ->
	# Parse Initial Text
	window.noted.parseText()

	# Event Handlers
	$("#content header .edit").click ->
		$("#contentbody .preview").toggle()
		$("#contentbody .edit").toggle()
		window.noted.parseText()

		# There should be a better way to do this
		if $(this).text() is "save"
			$(this).text "edit"
		else
			$(this).text "save"


window.noted =
	parseText: ->
		converter = new Showdown.converter()
		html = htmlToText $("#contentbody .edit").html()
		$("#contentbody .preview").html converter.makeHtml html
