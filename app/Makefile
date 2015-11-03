.PHONY: clean

app: main.lisp main.c
	buildapp --output main-lisp --entry main --load main.lisp
	gcc main.c -o main-c -lfcgi

clean:
	rm -f main-lisp main-c
