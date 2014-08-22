PREFIX=/usr/local

.PHONY: all
all: vfnmake.1.gz
	@ echo "Use \`make etc' to generate the empty config file"
	@ echo "Use \`make install' to install vfnmake in your system"

vfnmake.1.gz: README.pod
	@ cp README.pod vfnmake.pod
	@ pod2man -u vfnmake.pod --utf8 --name=vfnmake --section=1 --center " " vfnmake.1
	@ gzip -f vfnmake.1
	@ echo "[1mDocumentation generated[0m"
	@ rm vfnmake.pod

.PHONY: etc
etc: vfnmake.conf

vfnmake.conf:
	@ echo -e "libs:\n\
pkgs:\n\
O:\n\
cflags:\n\
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
	@ rm -f vfnmake.1 vfnmake.1.gz vfnmake.pod vfnmake.conf vfnmake_with_pod

vfnmake_with_pod: vfnmake README.pod
	@ cp vfnmake vfnmake_with_pod
	@ echo -e "\n__END__\n" >> vfnmake_with_pod
	@ cat README.pod >> vfnmake_with_pod

.PHONY: install
install: vfnmake.1.gz vfnmake.conf vfnmake_with_pod
	@ install -D -m 755 vfnmake_with_pod $(PREFIX)/bin/vfnmake
	@ echo "[1;32m*[0m vfnmake installed"
	@ install -D -m 644 vfnmake.1.gz $(PREFIX)/share/man/man1/vfnmake.1.gz
	@ echo "[1;32m*[0m manpage installed"
	@ install -D -m 644 vfnmake.conf /etc/vfnmake.conf
	@ echo "[1;32m*[0m empty config file installed in /etc/vfnmake.conf"
	@ echo "[1mUse \`make uninstall' to remove vfnmake[0m"

.PHONY: uninstall
uninstall:
	@ rm $(PREFIX)/bin/vfnmake
	@ rm $(PREFIX)/share/man/man1/vfnmake.1.gz
	@ rm /etc/vfnmake.conf
	@ echo "[1;32m*[0m vfnmake removed"

.PHONY: AUR_prepare
AUR_prepare: vfnmake.1.gz vfnmake.conf vfnmake_with_pod
