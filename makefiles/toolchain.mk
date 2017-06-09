arm_v7_vfp_le:
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		tar -xJf $(OPT_DOWNLOADS)/arm_v7_vfp_le.tar.xz -C $(OPT_WORKDIR)/toolchains/ && \
		touch $(OPT_DONE)/$@ \
	;fi
	

mips24ke_nfp_be:
	if [[ ! -f $(OPT_DONE)/$@ ]]; then \
		tar -xJf $(OPT_DOWNLOADS)/mips24ke_nfp_be.tar.xz -C $(OPT_WORKDIR)/toolchains/ && \
		touch $(OPT_DONE)/$@ \
	;fi