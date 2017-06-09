include config.mk

ifeq ($(or $(OPT_PATH),$(OPT_WORKDIR),$(OPT_TOOLCHAIN),$(OPT_CROSS),$(OPT_PREFIX),$(OPT_TMPDIR),$(OPT_SYSROOT_TCHAIN),$(OPT_SYSROOT_BUILD),$(OPT_INSTALL),$(OPT_RPATH),$(OPT_THREADS)),)
$(error CORE-Variables not set. Use config.sh before make.)
endif

export SHELL := /bin/bash
export PATH := $(OPT_PATH):$(PATH)
export PKG_CONFIG_PATH := $(OPT_SYSROOT_BUILD)/lib/pkgconfig

OPT_CFLAGS := $(CFLAGS) -D_GNU_SOURCE -I$(OPT_SYSROOT_BUILD)/include -L$(OPT_SYSROOT_BUILD)/lib
OPT_CXXFLAGS := $(CXXFLAGS) -D_GNU_SOURCE -I$(OPT_SYSROOT_BUILD)/include -L$(OPT_SYSROOT_BUILD)/lib
OPT_LDFLAGS := $(LDFLAGS) -L$(OPT_SYSROOT_BUILD)/lib -Wl,-rpath-link,$(OPT_SYSROOT_BUILD)/lib

ifneq (,$(findstring Yes,$(OPT_RPATH)))
OPT_CFLAGS += -Wl,-R,$(OPT_PREFIX)/lib
OPT_CXXFLAGS += -Wl,-R,$(OPT_PREFIX)/lib
OPT_LDFLAGS += -Wl,-R,$(OPT_PREFIX)/lib
endif

OPT_CFG_PARAMS := --prefix=$(OPT_PREFIX) 
OPT_CFG_PARAMS += --host=$(OPT_CROSS)
OPT_CFG_PARAMS += --disable-nls 
OPT_CFG_PARAMS += --disable-rpath 
OPT_CFG_PARAMS += --without-libiconv-prefix 
OPT_CFG_PARAMS += --without-libintl-prefix  
OPT_CFG_PARAMS += --enable-shared  
OPT_CFG_PARAMS += --enable-static 
OPT_CFG_PARAMS += CFLAGS="$(OPT_CFLAGS)"
OPT_CFG_PARAMS += CXXFLAGS="$(OPT_CXXFLAGS)" 
OPT_CFG_PARAMS += LDFLAGS="$(OPT_LDFLAGS)"

OPT_DONE := $(OPT_WORKDIR)/.done
OPT_DOWNLOADS := $(OPT_WORKDIR)/downloads
OPT_BUILD := $(OPT_WORKDIR)/builds
OPT_URLS := $(OPT_WORKDIR)/urls.download
OPT_SCRIPTS := $(OPT_WORKDIR)/scripts
OPT_PATCHES := $(OPT_WORKDIR)/patches
OPT_PACKAGE := $(OPT_WORKDIR)/packages/$(OPT_TOOLCHAIN)
OPT_PACKAGE_ROOT := $(OPT_WORKDIR)/packages/$(OPT_TOOLCHAIN)/root

PROG_MAKE := make V=1
PROG_MAKE_T := make -j$(OPT_THREADS) V=1

PROG_INST := install -m 644 -D
PROG_INST_EXEC := install -m 755 -D
PROG_INST_STRIP := install -m 755 -D --strip-program=$(OPT_CROSS)-strip -s
PROG_INST_LINK := rsync -l

include makefiles/toolchain.mk
include makefiles/zlib.mk
include makefiles/expat.mk
include makefiles/libxml2.mk
include makefiles/openssl.mk
include makefiles/libffi.mk
include makefiles/fuse.mk
include makefiles/libnfs.mk
include makefiles/sqlite3.mk
include makefiles/gmp.mk
include makefiles/nettle.mk
include makefiles/gnutls.mk
include makefiles/samba3.mk
include makefiles/glib.mk
include makefiles/libproxy.mk
include makefiles/glib-networking.mk
include makefiles/libsoup.mk
include makefiles/dbus.mk
include makefiles/gvfs.mk

.PHONY: default
default: all ;
.DEFAULT_GOAL := all

all: prepare toolchain zlib libxml2 expat openssl libffi fuse libnfs sqlite3 gmp nettle gnutls samba3 glib libproxy glib-networking libsoup dbus gvfs image

clean: zlib_clean libffi_clean fuse_clean
	rm -f $(OPT_DONE)/*_make
	rm -f $(OPT_DONE)/*_make_install
	rm -f $(OPT_DONE)/*_all

distclean: clean zlib_distclean libffi_distclean fuse_distclean
	rm -f $(OPT_DONE)/*_configure
	
proper-clean:
	rm -f $(OPT_DONE)/*
	rm -rf $(OPT_BUILD)/*
	rm -rf $(OPT_INSTALL)/*
	rm -rf $(OPT_PACKAGE_ROOT)/*
	rm -f config.mk
	
	
prepare:
	if [[ ! -d $(OPT_DONE) ]]; then \
		mkdir $(OPT_DONE); \
	fi;
		
toolchain: prepare $(OPT_TOOLCHAIN)

define loop_inst_file
	if [[ "$$f" == "" ]]; then \
		continue; \
	fi; \
	T=$$(echo $$f | sed 's#$(OPT_SYSROOT_BUILD)/##g'); \
	D=$$(dirname $(OPT_PACKAGE_ROOT)/$$T); \
	if [[ "$$T" == "" || "$$D" == "" ]]; then \
		continue; \
	fi; \
	if [[ ! -d $$D ]]; then \
		echo "Creating Dir: $$D"; \
		mkdir -p $$D; \
	fi; \
	if [[ -d $$f ]]; then \
		if [[ ! -d $(OPT_PACKAGE_ROOT)/$$T ]]; then \
			echo "Creating Dir: $(OPT_PACKAGE_ROOT)/$$T"; \
			mkdir -p $(OPT_PACKAGE_ROOT)/$$T; \
		fi; \
	elif [[ -L $$f ]]; then \
		echo "Copy-Symlink: $$f -> $(OPT_PACKAGE_ROOT)/$$T"; \
		$(PROG_INST_LINK) $$f $(OPT_PACKAGE_ROOT)/$$T; \
	elif [[ $$(file $$f 2>/dev/null | grep 'stripped' 2>/dev/null >/dev/null)$$? -eq 0 ]]; then \
		echo "Copy-Strip: $$f -> $(OPT_PACKAGE_ROOT)/$$T"; \
		$(PROG_INST_STRIP) $$f $(OPT_PACKAGE_ROOT)/$$T; \
	elif [[ $$(file $$f 2>/dev/null | grep 'script' 2>/dev/null >/dev/null)$$? -eq 0 ]]; then \
		echo "Copy-Script: $$f -> $(OPT_PACKAGE_ROOT)/$$T"; \
		$(PROG_INST_EXEC) $$f $(OPT_PACKAGE_ROOT)/$$T; \
	else \
		echo "Copy: $$f -> $(OPT_PACKAGE_ROOT)/$$T"; \
		$(PROG_INST) $$f $(OPT_PACKAGE_ROOT)/$$T; \
	fi
endef

.PHONY: install
install: gvfs
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_PACKAGE_ROOT) ]]; then \
		mkdir -p $(OPT_PACKAGE_ROOT) && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gapplication $(OPT_PACKAGE_ROOT)/bin/gapplication && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gdbus $(OPT_PACKAGE_ROOT)/bin/gdbus && \
#		$(PROG_INST_EXEC) $(OPT_SYSROOT_BUILD)/bin/gdbus-codegen $(OPT_PACKAGE_ROOT)/bin/gdbus-codegen && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gio $(OPT_PACKAGE_ROOT)/bin/gio && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gio-querymodules $(OPT_PACKAGE_ROOT)/bin/gio-querymodules && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/glib-compile-resources $(OPT_PACKAGE_ROOT)/bin/glib-compile-resources && \
		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/glib-compile-schemas $(OPT_PACKAGE_ROOT)/bin/glib-compile-schemas && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/glib-genmarshal $(OPT_PACKAGE_ROOT)/bin/glib-genmarshal && \
#		$(PROG_INST_EXEC) $(OPT_SYSROOT_BUILD)/bin/glib-gettextize $(OPT_PACKAGE_ROOT)/bin/glib-gettextize && \
#		$(PROG_INST_EXEC) $(OPT_SYSROOT_BUILD)/bin/glib-mkenums $(OPT_PACKAGE_ROOT)/bin/glib-mkenums && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gobject-query $(OPT_PACKAGE_ROOT)/bin/gobject-query && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gresource $(OPT_PACKAGE_ROOT)/bin/gresource && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gsettings $(OPT_PACKAGE_ROOT)/bin/gsettings && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/gtester $(OPT_PACKAGE_ROOT)/bin/gtester && \
#		$(PROG_INST_EXEC) $(OPT_SYSROOT_BUILD)/bin/gtester-report $(OPT_PACKAGE_ROOT)/bin/gtester-report && \
		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/ntlm_auth $(OPT_PACKAGE_ROOT)/bin/ntlm_auth && \
		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/bin/openssl $(OPT_PACKAGE_ROOT)/bin/openssl && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/libexec/dbus-daemon-launch-helper $(OPT_PACKAGE_ROOT)/libexec/dbus-daemon-launch-helper && \
#		$(PROG_INST_STRIP) $(OPT_SYSROOT_BUILD)/libexec/glib-pacrunner $(OPT_PACKAGE_ROOT)/libexec/glib-pacrunner && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/bin/ -mindepth 1 -type f -name "gvfs-*" -o -name "dbus*"); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/sbin/ -mindepth 1 -type f -name "gvfsd*"); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/lib/ -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name "*.so*" -o -name "*.dat" ); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/lib/engines/ -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name "*.so*"); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/lib/gio/modules/ -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name "*.so*"); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/lib/gvfs/ -mindepth 1 -maxdepth 1 \( -type f -o -type l \) -name "*.so*"); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/etc/ -mindepth 1 | grep -v '$(OPT_SYSROOT_BUILD)/etc/ssl/man'); do \
			$(loop_inst_file) \
		;done && \
		touch $(OPT_SYSROOT_BUILD)/etc/ssl/certs/ca-certificates.crt && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/share/glib-2.0/ -mindepth 1); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/share/gvfs/ -mindepth 1); do \
			$(call loop_inst_file) \
		;done && \
		for f in $$(find $(OPT_SYSROOT_BUILD)/share/dbus-1/ -mindepth 1); do \
			$(call loop_inst_file) \
		;done && \
		touch $(OPT_DONE)/$@ \
	;fi
	

.PHONY: image
image: install
	if [[ ! -d $(OPT_BUILD)/tmpmnt ]]; then \
		mkdir $(OPT_BUILD)/tmpmnt; \
	fi && \
	if [[ ! -d $(OPT_PACKAGE)/GVFS ]]; then \
		mkdir $(OPT_PACKAGE)/GVFS; \
	fi && \
	cp -a $(OPT_WORKDIR)/misc/04_04_gvfs.init $(OPT_PACKAGE)/GVFS/04_04_gvfs.init.dis && \
	sed -i 's#{{{TMP}}}#$(OPT_TMPDIR)#g;s#{{{PREFIX}}}#$(OPT_PREFIX)#g' $(OPT_PACKAGE)/GVFS/04_04_gvfs.init.dis && \
	cp -a $(OPT_WORKDIR)/misc/gvfs_mounts.cfg $(OPT_PACKAGE)/GVFS/gvfs_mounts.cfg && \
	cp -a $(OPT_WORKDIR)/misc/gvfs_fuse.cfg $(OPT_PACKAGE)/GVFS/gvfs_fuse.cfg && \
	echo; echo "Creating Image, please wait..."; echo && \
	dd if=/dev/zero of=$(OPT_PACKAGE)/GVFS/gvfs_root.img bs=1M count=50 && \
	mkfs.ext3 -E root_owner=0:0 -d $(OPT_PACKAGE_ROOT) $(OPT_PACKAGE)/GVFS/gvfs_root.img && \
	tune2fs -c0 -i0 $(OPT_PACKAGE)/GVFS/gvfs_root.img && \
	echo "Creating Image ($(OPT_PACKAGE)/GVFS/gvfs_root.img) successful."; echo && \
	echo; \
	echo "If you are not building as root user, which is a good decision, "; \
	echo "then please consider changing the owner of the files inside the image,"; \
	echo "because at the moment all the files inside the Image are owned by your current user."; \
	echo "This isn't a big deal for the SamyGo-Environment and would still work, but"; \
	echo "it would be cleaner if they are owned by root. (Security and those things...)"; \
	echo; \
	echo "As root do:"; \
	echo "mount -t ext3 -o loop $(OPT_PACKAGE)/GVFS/gvfs_root.img $(OPT_BUILD)/tmpmnt && chown -R root:root $(OPT_BUILD)/tmpmnt/* && umount $(OPT_BUILD)/tmpmnt"; \
	echo; \
	echo "After this type \"make package\" to create a zip compressed file"; \
	echo
	
.PHONY: package
package:
	if [[ -d $(OPT_PACKAGE)/GVFS ]]; then \
		cd $(OPT_PACKAGE)/ && \
		zip $(OPT_TOOLCHAIN)-gvfs.zip GVFS/* && \
		echo; \
		echo "Zip File created sucessful."; \
		echo "$(OPT_PACKAGE)/$(OPT_TOOLCHAIN)-gvfs.zip"; \
		echo \
	;else \
		echo; \
		echo "$(OPT_PACKAGE)/GVFS not found!"; \
		echo "Please use \"make image\" once before"; \
		echo \
	;fi
	