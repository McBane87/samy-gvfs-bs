.PHONY: glib	
glib: zlib libffi gmp glib_make_install

glib_prepare:
	$(eval PACKAGE := glib-2)
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
	
glib_download: glib_prepare
	if [[ ! -f $(OPT_DONE)/$@ || ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
		if [[ ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
			wget --no-check-certificate -P $(OPT_DOWNLOADS)/ $(PACK_URL) && \
			touch $(OPT_DONE)/$@ \
		;else \
			touch $(OPT_DONE)/$@ \
		;fi \
	;fi

glib_extract: glib_download
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_BUILD)/$(PACK_DIR) ]]; then \
		tar \
			-x \
			-$(PACK_AR) \
			-f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) \
			-C $(OPT_BUILD)/ && \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
		patch -p0 < $(OPT_PATCHES)/00-glib-cloexec_mkostemp.patch && \
		touch $(OPT_DONE)/$@ \
	;fi


OPT_GLIB_CFLAGS := $(OPT_CFLAGS)
OPT_GLIB_CXXFLAGS := $(OPT_CXXFLAGS)
OPT_GLIB_LDFLAGS := $(OPT_LDFLAGS)

ifneq (,$(findstring Yes,$(OPT_RPATH)))
OPT_GLIB_CFLAGS += -Wl,-R,$(OPT_PREFIX)/lib/gio/modules
OPT_GLIB_CXXFLAGS += -Wl,-R,$(OPT_PREFIX)/lib/gio/modules
OPT_GLIB_LDFLAGS += -Wl,-R,$(OPT_PREFIX)/lib/gio/modules
endif
	
glib_configure: glib_extract
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			if [[ -f configure ]]; then \
				sed -i 's/hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=""/g' configure \
			;fi && \
			./configure \
				$(OPT_CFG_PARAMS) \
				--with-threads=posix \
				--enable-included-printf \
				--disable-Bsymbolic \
				--disable-libelf \
				--disable-libmount \
				--disable-dtrace \
				--disable-compile-warnings \
				--disable-maintainer-mode \
				--with-pcre=internal \
				--with-xml-catalog=$(OPT_PREFIX)/etc/xml/catalog  \
				CFLAGS="$(OPT_GLIB_CFLAGS)" \
				CXXFLAGS="$(OPT_GLIB_CXXFLAGS)" \
				LDFLAGS="$(OPT_GLIB_LDFLAGS)" \
				glib_cv_uscore=no \
				glib_cv_stack_grows=no \
				ac_cv_func_posix_getpwuid_r=yes \
				ac_cv_func_posix_getgrgid_r=yes && \
		touch $(OPT_DONE)/$@ \
	;fi
	
glib_make: glib_configure
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			$(PROG_MAKE_T) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
glib_make_install: glib_make
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
			if [[ $$(find $(OPT_SYSROOT_BUILD)/lib/pkgconfig -name "*.pc") != "" ]]; then \
				find $(OPT_SYSROOT_BUILD)/lib/pkgconfig -name "*.pc" | xargs -n1 sed -i "s#^giomoduledir=.*#giomoduledir=$(OPT_PREFIX)/lib/gio/modules#g" \
			;fi && \
		touch $(OPT_DONE)/$@ \
	;fi

glib_clean: glib_prepare
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) DESTDIR=$(OPT_INSTALL) uninstall || echo "Nothing to do" && \
		$(PROG_MAKE) clean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make_install && \
		rm -f $(OPT_DONE)/$(PACKAGE)_all

glib_distclean: glib_prepare glib_clean
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) distclean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_configure