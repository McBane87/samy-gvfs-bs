#!/bin/bash

PS3='Input: '

echo
echo 'Please choose your Toolchain: '
options=("arm_v7_vfp_le" "mips24ke_nfp_be" "Abort")
select opt in "${options[@]}"
do
	case $opt in
		"arm_v7_vfp_le")
			OPT_TOOLCHAIN=$opt
			OPT_CROSS='armv7fl-montavista-linux-gnueabi'
			OPT_SYSROOT=$PWD/toolchains/$opt/target
			OPT_INSTALL=$PWD/target/$opt
			OPT_PATH=$PWD/toolchains/$opt/bin
			break
			;;
		"mips24ke_nfp_be")
			OPT_TOOLCHAIN=$opt
			OPT_CROSS='mips-montavista-linux-gnu'
			OPT_SYSROOT=$PWD/toolchains/$opt/target
			OPT_INSTALL=$PWD/target/$opt
			OPT_PATH=$PWD/toolchains/$opt/bin
			break
			;;
		"Abort")
			exit
			;;
		*) 
			"echo invalid option"
			;;
	esac
done

echo
echo 'Choose a Prefix: '
options=("/mnt/opt/privateer" "/mnt/opt/privateer/usr/local" "/mnt/opt/privateer/usr/local/GVFS" "I want to use a Custom Prefix" "Abort")
select opt in "${options[@]}"
do
	case $opt in
		"/mnt/opt/privateer")
			OPT_PREFIX=$opt
			break
			;;
		"/mnt/opt/privateer/usr/local")
			OPT_PREFIX=$opt
			break
			;;
		"/mnt/opt/privateer/usr/local/GVFS")
			OPT_PREFIX=$opt
			break
			;;
		"I want to use a Custom Prefix")
			break
			;;
		"Abort")
			exit
			;;
		*) 
			echo "invalid option"
			;;
	esac
done

if [[ -z $OPT_PREFIX ]]; then

	echo
	echo "Please type your custom Prefix"
	read -p "$PS3" OPT_PREFIX
	
fi

echo
echo 'Where should the compiled libraries and binaries put their temporary files?: '
options=("/tmp" "/dtv" "I want to use a Custom Prefix" "Abort")
select opt in "${options[@]}"
do
	case $opt in
		"/tmp")
			OPT_TMPDIR=$opt
			break
			;;
		"/dtv")
			OPT_TMPDIR=$opt
			break
			;;
		"I want to use a Custom Prefix")
			break
			;;
		"Abort")
			exit
			;;
		*) 
			echo "invalid option"
			;;
	esac
done

if [[ -z $OPT_TMPDIR ]]; then

	echo
	echo "Please type your custom Temp-Dir."
	read -p "$PS3" OPT_TMPDIR
	
fi

echo
echo "Do you want to hardcode (rpath) $OPT_PREFIX/lib into the compiled Libs/Binaries?: "
options=("Yes" "No" "Abort")
select opt in "${options[@]}"
do
	case $opt in
		"Yes")
			OPT_RPATH=$opt
			break
			;;
		"No")
			OPT_RPATH=$opt
			break
			;;
		"Abort")
			exit
			;;
		*) 
			"echo invalid option"
			;;
	esac
done

CPUs=$(nproc 2>/dev/null)
echo
echo "On some cases I can use more than one CPU-Core for compiling."

if [[ "$CPUs" != "" ]]; then
	Threads=$(echo "$CPUs * 0.75" | bc 2>/dev/null | sed 's/\..*$//g' 2>/dev/null)
	if [[ "$Threads" != "" ]]; then
		if [[ "$Threads" == "$CPUs" ]]; then
			Threads=$(echo "$CPUs - 1" | bc 2>/dev/null | sed 's/\..*$//g' 2>/dev/null)
		fi
	fi
fi

if [[ "$Threads" != "" ]]; then
	echo "I would suggest $Threads Threads. Is that OK?"
	options=("Yes" "No" "Abort")
	select opt in "${options[@]}"
	do
		case $opt in
			"Yes")
				OPT_THREADS=$Threads
				break
				;;
			"No")
				break
				;;
			"Abort")
				exit
				;;
			*) 
				"echo invalid option"
				;;
		esac
	done
fi

if [[ -z $OPT_THREADS ]]; then

	echo
	echo "Please type your custom number of Threads. (To disable it type 1):"
	read -p "$PS3" OPT_THREADS
	
fi
if [[ $( echo $OPT_THREADS | egrep '^[0-9]+$' 2>/dev/null >/dev/null)$? -ne 0 ]]; then
	OPT_THREADS=1
fi

echo
echo
echo "Your choosen Config is:"
echo
echo "Toolchain:                $OPT_TOOLCHAIN"
echo "Cross-Compiler:           $OPT_CROSS"
echo "Prefix:                   $OPT_PREFIX"
echo "Temp-Dir:                 $OPT_TMPDIR"
echo "Sysroot:                  $OPT_SYSROOT"
echo "Install Directory:        $OPT_INSTALL"
echo "Use RPATH:                $OPT_RPATH"
echo "Threads:                  $OPT_THREADS"
echo

OPT_INST_SYSROOT="$OPT_INSTALL/$(echo $OPT_PREFIX | sed 's#^/##g')"

echo "" > $PWD/config.mk
echo "OPT_PATH = $OPT_PATH" >> $PWD/config.mk
echo "OPT_WORKDIR = $PWD" >> $PWD/config.mk
echo "OPT_TOOLCHAIN = $OPT_TOOLCHAIN" >> $PWD/config.mk
echo "OPT_CROSS = $OPT_CROSS" >> $PWD/config.mk
echo "OPT_PREFIX = $OPT_PREFIX" >> $PWD/config.mk
echo "OPT_TMPDIR = $OPT_TMPDIR" >> $PWD/config.mk
echo "OPT_SYSROOT_TCHAIN = $OPT_SYSROOT" >> $PWD/config.mk
echo "OPT_SYSROOT_BUILD = $OPT_INST_SYSROOT" >> $PWD/config.mk
echo "OPT_INSTALL = $OPT_INSTALL" >> $PWD/config.mk
echo "OPT_RPATH = $OPT_RPATH" >> $PWD/config.mk
echo "OPT_THREADS = $OPT_THREADS" >> $PWD/config.mk
