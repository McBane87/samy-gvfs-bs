.PHONY: gvfs	
gvfs: samba3 libnfs fuse libsoup gvfs_make_install

gvfs_prepare:
	$(eval PACKAGE := gvfs)
	$(eval PACK_DIR := $(shell grep '^$(PACKAGE)' $(OPT_URLS) | head -1 | cut -d';' -f1))
	$(eval PACK_AR := $(shell grep '^$(PACKAGE)' $(OPT_URLS) | head -1 | cut -d';' -f2))
	$(eval PACK_AR_FILE := $(shell grep '^$(PACKAGE)' $(OPT_URLS) | head -1 | cut -d';' -f3))
	$(eval PACK_URL := $(shell grep '^$(PACKAGE)' $(OPT_URLS) | head -1 | cut -d';' -f4))
	[[ "$(PACKAGE)" != "" ]] && \
	[[ "$(PACK_DIR)" != "" ]] && \
	[[ "$(PACK_AR)" != "" ]] && \
	[[ "$(PACK_AR_FILE)" != "" ]] && \
	[[ "$(PACK_URL)" != "" ]] && \
	echo
	
gvfs_download: gvfs_prepare
	if [[ ! -f $(OPT_DONE)/$@ || ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
		if [[ ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
			wget --no-check-certificate -P $(OPT_DOWNLOADS)/ $(PACK_URL) && \
			touch $(OPT_DONE)/$@ \
		;else \
			touch $(OPT_DONE)/$@ \
		;fi \
	;fi

gvfs_extract: gvfs_download
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_BUILD)/$(PACK_DIR) ]]; then \
		tar \
			-x \
			-$(PACK_AR) \
			-f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) \
			-C $(OPT_BUILD)/ && \
#		find $(OPT_BUILD)/$(PACK_DIR)/ -name Makefile.in -exec sed -i -- 's#-rpath $$(\([a-z]\|[0-9]\)\+)#-rpath /_NONE_#gi' {} \; || echo "Nothing" && \
		touch $(OPT_DONE)/$@ \
	;fi

	
OPT_GVFS_CFLAGS := $(OPT_CFLAGS) -L$(OPT_SYSROOT_BUILD)/lib/gvfs
OPT_GVFS_CXXFLAGS := $(OPT_CXXFLAGS) -L$(OPT_SYSROOT_BUILD)/lib/gvfs
OPT_GVFS_LDFLAGS := $(OPT_LDFLAGS) -L$(OPT_SYSROOT_BUILD)/lib/gvfs

ifneq (,$(findstring Yes,$(OPT_RPATH)))
OPT_GVFS_CFLAGS += -Wl,-R,$(OPT_PREFIX)/lib/gio/modules:$(OPT_PREFIX)/lib/gvfs
OPT_GVFS_CXXFLAGS += -Wl,-R,$(OPT_PREFIX)/lib/gio/modules:$(OPT_PREFIX)/lib/gvfs
OPT_GVFS_LDFLAGS += -Wl,-R,$(OPT_PREFIX)/lib/gio/modules:$(OPT_PREFIX)/lib/gvfs
endif
	
gvfs_configure: gvfs_extract
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			if [[ -f configure ]]; then \
				sed -i 's/hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=""/g' configure \
			;fi && \
			./configure \
				$(OPT_CFG_PARAMS) \
				--bindir=$(OPT_PREFIX)/bin \
				--sbindir=$(OPT_PREFIX)/sbin \
				--libexecdir=$(OPT_PREFIX)/sbin \
				--disable-documentation \
				--disable-gcr \
				--disable-admin \
				--disable-avahi \
				--disable-udev \
				--disable-gudev \
				--disable-gdu \
				--disable-udisks2 \
				--disable-libsystemd-login \
				--disable-cdda \
				--disable-afc \
				--disable-goa \
				--disable-google \
				--disable-gphoto2 \
				--disable-keyring \
				--disable-bluray \
				--disable-libusb \
				--disable-libmtp \
				--disable-archive \
				--disable-afp \
				--disable-bash-completion \
				--with-systemduserunitdir=no \
				--enable-http \
				--enable-samba \
				--enable-nfs \
				--enable-fuse \
				CFLAGS="$(OPT_GVFS_CFLAGS)" \
				CXXFLAGS="$(OPT_GVFS_CXXFLAGS)" \
				LDFLAGS="$(OPT_GVFS_LDFLAGS)" && \
		touch $(OPT_DONE)/$@ \
	;fi
	
gvfs_make: gvfs_configure
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			$(PROG_MAKE_T) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
gvfs_make_install: gvfs_make
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			$(PROG_MAKE) \
			DESTDIR=$(OPT_INSTALL) \
			install && \
			if [[ $$(find $(OPT_SYSROOT_BUILD)/lib -name "*.la") != "" ]]; then \
				find $(OPT_SYSROOT_BUILD)/lib -name "*.la" | xargs -n1 sed -i "s# $(OPT_PREFIX)# $(OPT_SYSROOT_BUILD)#g" \
			;fi && \
			if [[ $$(find $(OPT_SYSROOT_BUILD)/lib/pkgconfig -name "*.pc") != "" ]]; then \
				find $(OPT_SYSROOT_BUILD)/lib/pkgconfig -name "*.pc" | xargs -n1 sed -i "s#^prefix=.*#prefix=$(OPT_SYSROOT_BUILD)#g" \
			;fi && \
		touch $(OPT_DONE)/$@ \
	;fi

gvfs_clean: gvfs_prepare
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) DESTDIR=$(OPT_INSTALL) uninstall || echo "Nothing to do" && \
		$(PROG_MAKE) clean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make_install && \
		rm -f $(OPT_DONE)/$(PACKAGE)_all

gvfs_distclean: gvfs_prepare gvfs_clean
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) distclean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_configure