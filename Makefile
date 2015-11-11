PREFIX=/usr/local

.PHONY: all
all: vfnmkmc.1.gz
	@ echo "Use \`make etc' to generate the empty config file"
	@ echo "Use \`make install' to install vfnmkmc in your system"

vfnmkmc.1.gz: README.pod
	@ cp README.pod vfnmkmc.pod
	@ pod2man -u vfnmkmc.pod --utf8 --name=vfnmkmc --section=1 --center " " vfnmkmc.1
	@ gzip -f vfnmkmc.1
	@ echo "[1mDocumentation generated[0m"
	@ rm vfnmkmc.pod

.PHONY: etc
etc: vfnmkmc.conf

vfnmkmc.conf:
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
qt:" > vfnmkmc.conf
	@ echo "[1mEmpty config file created[0m"

.PHONY: clean
clean:
	@ rm -f vfnmkmc.1 vfnmkmc.1.gz vfnmkmc.pod vfnmkmc.conf vfnmkmc_with_pod

vfnmkmc_with_pod: vfnmkmc README.pod
	@ cp vfnmkmc vfnmkmc_with_pod
	@ echo -e "\n__END__\n" >> vfnmkmc_with_pod
	@ cat README.pod >> vfnmkmc_with_pod

.PHONY: install
install: vfnmkmc.1.gz vfnmkmc.conf vfnmkmc_with_pod
	@ install -D -m 755 vfnmkmc_with_pod $(PREFIX)/bin/vfnmkmc
	@ echo "[1;32m*[0m vfnmkmc installed"
	@ install -D -m 644 vfnmkmc.1.gz $(PREFIX)/share/man/man1/vfnmkmc.1.gz
	@ echo "[1;32m*[0m manpage installed"
	@ install -D -m 644 vfnmkmc.conf /etc/vfnmkmc.conf
	@ echo "[1;32m*[0m empty config file installed in /etc/vfnmkmc.conf"
	@ echo "[1mUse \`make uninstall' to remove vfnmkmc[0m"

.PHONY: uninstall
uninstall:
	@ rm $(PREFIX)/bin/vfnmkmc
	@ rm $(PREFIX)/share/man/man1/vfnmkmc.1.gz
	@ rm /etc/vfnmkmc.conf
	@ echo "[1;32m*[0m vfnmkmc removed"

.PHONY: AUR_prepare
AUR_prepare: vfnmkmc.1.gz vfnmkmc.conf vfnmkmc_with_pod
