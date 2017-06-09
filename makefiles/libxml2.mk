.PHONY: libxml2	
libxml2: zlib libxml2_make_install

libxml2_prepare:
	$(eval PACKAGE := libxml2)
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
	
libxml2_download: libxml2_prepare
	if [[ ! -f $(OPT_DONE)/$@ || ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
		if [[ ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
			wget --no-check-certificate -P $(OPT_DOWNLOADS)/ $(PACK_URL) && \
			touch $(OPT_DONE)/$@ \
		;else \
			touch $(OPT_DONE)/$@ \
		;fi \
	;fi

libxml2_extract: libxml2_download
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_BUILD)/$(PACK_DIR) ]]; then \
		tar \
			-x \
			-$(PACK_AR) \
			-f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) \
			-C $(OPT_BUILD)/ && \
		touch $(OPT_DONE)/$@ \
	;fi
	
libxml2_configure: libxml2_extract
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			if [[ -f configure ]]; then \
				sed -i 's/hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=""/g' configure \
			;fi && \
			./configure \
				$(OPT_CFG_PARAMS) \
				--without-python && \
		touch $(OPT_DONE)/$@ \
	;fi
	
libxml2_make: libxml2_configure
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			$(PROG_MAKE_T) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
libxml2_make_install: libxml2_make
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

libxml2_clean: libxml2_prepare
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) DESTDIR=$(OPT_INSTALL) uninstall || echo "Nothing to do" && \
		$(PROG_MAKE) clean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make_install && \
		rm -f $(OPT_DONE)/$(PACKAGE)_all

libxml2_distclean: libxml2_prepare libxml2_clean
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) distclean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_configure