.PHONY: gmp	
gmp: gmp_make_install

gmp_prepare:
	$(eval PACKAGE := gmp)
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
	
gmp_download: gmp_prepare
	if [[ ! -f $(OPT_DONE)/$@ || ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
		if [[ ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
			wget --no-check-certificate -P $(OPT_DOWNLOADS)/ $(PACK_URL) && \
			touch $(OPT_DONE)/$@ \
		;else \
			touch $(OPT_DONE)/$@ \
		;fi \
	;fi

gmp_extract: gmp_download
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_BUILD)/$(PACK_DIR) ]]; then \
		tar \
			-x \
			-$(PACK_AR) \
			-f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) \
			-C $(OPT_BUILD)/ && \
		touch $(OPT_DONE)/$@ \
	;fi
	
gmp_configure: gmp_extract
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			if [[ -f configure ]]; then \
				sed -i 's/hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=""/g' configure \
			;fi && \
			./configure \
				$(OPT_CFG_PARAMS) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
gmp_make: gmp_configure
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR) && \
			$(PROG_MAKE_T) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
gmp_make_install: gmp_make
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

gmp_clean: gmp_prepare
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) DESTDIR=$(OPT_INSTALL) uninstall || echo "Nothing to do" && \
		$(PROG_MAKE) clean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make_install && \
		rm -f $(OPT_DONE)/$(PACKAGE)_all

gmp_distclean: gmp_prepare gmp_clean
	cd $(OPT_BUILD)/$(PACK_DIR) && \
		$(PROG_MAKE) distclean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_configure