.PHONY: samba3	
samba3: zlib samba3_make_install

samba3_prepare:
	$(eval PACKAGE := samba-3)
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
	
samba3_download: samba3_prepare
	if [[ ! -f $(OPT_DONE)/$@ || ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
		if [[ ! -f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) ]]; then \
			wget --no-check-certificate -P $(OPT_DOWNLOADS)/ $(PACK_URL) && \
			touch $(OPT_DONE)/$@ \
		;else \
			touch $(OPT_DONE)/$@ \
		;fi \
	;fi

samba3_extract: samba3_download
	if [[ ! -f $(OPT_DONE)/$@ || ! -d $(OPT_BUILD)/$(PACK_DIR) ]]; then \
		tar \
			-x \
			-$(PACK_AR) \
			-f $(OPT_DOWNLOADS)/$(PACK_AR_FILE) \
			-C $(OPT_BUILD)/ && \
		touch $(OPT_DONE)/$@ \
	;fi
	
samba3_configure: samba3_extract
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR)/source3 && \
			if [[ -f configure ]]; then \
				sed -i 's/hardcode_libdir_flag_spec=.*/hardcode_libdir_flag_spec=""/g' configure \
			;fi && \
			./configure \
				$(OPT_CFG_PARAMS) \
				--without-krb5 --without-ldap --without-ads \
				--disable-cups --enable-swat=no --with-winbind=no \
				--without-libtalloc --without-libtevent --without-libtdb --without-libnetapi --without-libsmbsharemodes --without-libaddns \
				--with-static-modules=gpext,perfcount,vfs,auth,charset,nss_info,idmap,pdb \
				--without-sys-quotas \
				--with-cachedir=$(OPT_TMPDIR)/.gvfs.samba/locks \
				--with-configdir=$(OPT_PREFIX)/etc/samba \
				--with-lockdir=$(OPT_TMPDIR)/.gvfs.samba/locks \
				--with-logfilebase=$(OPT_TMPDIR)/.gvfs.samba/log \
				--with-ncalrpcdir=$(OPT_TMPDIR)/.gvfs.samba/ncalrpc \
				--with-nmbdsocketdir=$(OPT_TMPDIR)/.gvfs.samba/locks/.nmbd \
				--with-ntp-signd-socket-dir=$(OPT_TMPDIR)/.gvfs.samba \
				--with-piddir=$(OPT_TMPDIR)/.gvfs.samba/locks \
				--with-privatedir=$(OPT_PREFIX)/etc/samba/private \
				--with-statedir=$(OPT_TMPDIR)/.gvfs.samba/locks \
				--with-swatdir=$(OPT_PREFIX)/etc/samba/swat \
				--with-winbindd-privileged-socket-dir=$(OPT_TMPDIR)/.gvfs.samba/winbindd_privileged \
				--with-winbindd-socket-dir=$(OPT_TMPDIR)/.gvfs.samba/winbindd \
				samba_cv_CC_NEGATIVE_ENUM_VALUES=yes \
				libreplace_cv_HAVE_GETADDRINFO=no \
				ac_cv_file__proc_sys_kernel_core_pattern=yes && \
		touch $(OPT_DONE)/$@ \
	;fi
	
samba3_make: samba3_configure
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR)/source3 && \
			$(PROG_MAKE_T) && \
		touch $(OPT_DONE)/$@ \
	;fi
	
samba3_make_install: samba3_make
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		cd $(OPT_BUILD)/$(PACK_DIR)/source3 && \
			$(PROG_MAKE) \
			DESTDIR=$(OPT_INSTALL) \
			install && \
			cp -av $(OPT_BUILD)/$(PACK_DIR)/source3/pkgconfig/*.pc $(OPT_SYSROOT_BUILD)/lib/pkgconfig/ && \
			if [[ $$(find $(OPT_SYSROOT_BUILD)/lib -name "*.la") != "" ]]; then \
				find $(OPT_SYSROOT_BUILD)/lib -name "*.la" | xargs -n1 sed -i "s# $(OPT_PREFIX)# $(OPT_SYSROOT_BUILD)#g" \
			;fi && \
			if [[ $$(find $(OPT_SYSROOT_BUILD)/lib/pkgconfig -name "*.pc") != "" ]]; then \
				find $(OPT_SYSROOT_BUILD)/lib/pkgconfig -name "*.pc" | xargs -n1 sed -i "s#^prefix=.*#prefix=$(OPT_SYSROOT_BUILD)#g" \
			;fi && \
		touch $(OPT_DONE)/$@ \
	;fi

samba3_clean: samba3_prepare
	cd $(OPT_BUILD)/$(PACK_DIR)/source3 && \
		$(PROG_MAKE) DESTDIR=$(OPT_INSTALL) uninstall || echo "Nothing to do" && \
		$(PROG_MAKE) clean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make && \
		rm -f $(OPT_DONE)/$(PACKAGE)_make_install && \
		rm -f $(OPT_DONE)/$(PACKAGE)_all

samba3_distclean: samba3_prepare samba3_clean
	cd $(OPT_BUILD)/$(PACK_DIR)/source3 && \
		$(PROG_MAKE) distclean || echo "Nothing to do" && \
		rm -f $(OPT_DONE)/$(PACKAGE)_configure