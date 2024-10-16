all: testing enter 

testing:
	@mix run -e 'FerroInterpreter.file("main")'

enter:
	- @echo ""
