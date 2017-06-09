.PHONY: libproxy	
libproxy: zlib libffi gmp nettle gnutls libproxy glib libproxy_make_install

libproxy_prepare:
	$(eval PACKAGE := libproxy)
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
	
libproxy_download: libproxy_prepare
	if [[ ! -f $(OPT_DONE)/$@ || ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
		if [[ ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
			wget --no-check-certificate -P $(OPT_DOWNLOADS)/ $(PACK_URL) && \
			touch $(OPT_DONE)/$@ \
		;else \
			touch $(OPT_DONE)/$@ \
		;fi \
	;fi

libproxy_extract: libproxy_download
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_BUILD)/$(PACK_DIR) ]]; then \
		tar \
			-x \
			-$(PACK_AR) \
			-f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) \
			-C $(OPT_BUILD)/ && \
		touch $(OPT_DONE)/$@ \
	;fi
	
libproxy_configure: libproxy_extract
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		mkdir $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ || echo "Maybe already existing" && \
		cd $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ && \
			cmake -G "Unix Makefiles" \
				-DCMAKE_SYSTEM_NAME=Linux \
				-DCMAKE_SYSTEM_VERSION=1 \
				-DCMAKE_C_COMPILER=$(OPT_CROSS)-gcc \
				-DCMAKE_CXX_COMPILER=$(OPT_CROSS)-g++ \
				-DCMAKE_INSTALL_PREFIX=$(OPT_PREFIX) \
				-DCMAKE_C_FLAGS="$(OPT_CFLAGS)" \
				-DCMAKE_CXX_FLAGS="$(OPT_CXXFLAGS)" \
				-DCMAKE_EXE_LINKER_FLAGS="$(OPT_LDFLAGS)" \
				-DWITH_GNOME3:BOOL=OFF \
				-DWITH_KDE:BOOL=OFF \
				../ \
				&& \
		touch $(OPT_DONE)/$@ \
	;fi
	
libproxy_make: libproxy_configure
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ && \
			$(PROG_MAKE_T) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
libproxy_make_install: libproxy_make
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ && \
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

libproxy_clean: libproxy_prepare
	cd $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ && \
		$(PROG_MAKE) DESTDIR=$(OPT_INSTALL) uninstall || echo "Nothing to do" && \
		$(PROG_MAKE) clean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make_install && \
		rm -f $(OPT_DONE)/$(PACKAGE)_all

libproxy_distclean: libproxy_prepare libproxy_clean
	cd $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ && \
		$(PROG_MAKE) distclean || echo "Nothing to do" && \
		cd $(OPT_BUILD) && rm -rf $(OPT_BUILD)/$(PACK_DIR)/_BUILD_ && \
		rm -f $(OPT_DONE)/$(PACKAGE)_configure