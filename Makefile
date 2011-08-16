.PHONY: all
all: vfnmake.1.gz

vfnmake.1.gz: README.pod
	@ cp README.pod vfnmake.pod
	@ pod2man vfnmake.pod > vfnmake.1
	@ gzip -f vfnmake.1
	@ echo "[1mDocumentation generated[0m"
	@ rm vfnmake.pod

.PHONY: etc
etc: vfnmake.conf

vfnmake.conf:
	@ echo -e "cc:\n\
cxx:\n\
debug_cc:\n\
debug_cxx:\n\
libs:\n\
pkgs:\n\
O:\n\
cflags:\n\
cxxflags:\n\
lflags:\n\
name:\n\
src_directory:\n\
bin_directory:\n\
objs_directory:\n\
echo:\n\
asm:\n\
qt:" > vfnmake.conf
	@ echo "[1mEmpty config file created[0m"


.PHONY: clean
clean:
	@ rm -f vfnmake.1 vfnmake.1.gz vfnmake.pod vfnmake.conf
