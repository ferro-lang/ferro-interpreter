all: testing py-testing

testing:
	@mix run -e 'FerroInterpreter.file("main")' | gnomon

py-testing:
	@python3 main.py | gnomon
