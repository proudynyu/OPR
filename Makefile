FILE=pdf_reader

build: main.odin
	odin build . -out:${FILE}.exe

run: main.odin
	odin run .
