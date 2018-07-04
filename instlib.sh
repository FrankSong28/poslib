#!/bin/bash

LIB_ROOT=`basename $0`
LIB_ROOT=`echo $0|sed -e "s/^-//g;s/\/$LIB_ROOT$//g"`
cd $LIB_ROOT
LIB_ROOT=`pwd`
LIB_PKG_ROOT=${LIB_ROOT}/pkg
LIB_SRC_ROOT=${LIB_ROOT}/src

# pkg define
gcc_pkg=gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz
zlib_pkg=zlib-1.2.11.tar.gz
libpng_pkg=libpng-1.6.32.tar.xz
ft2_src_pkg=freetype-2.8.1.tar.gz
ft2_demo_pkg=ft2demos-2.8.1.tar.gz
ft2_doc_pkg=freetype-doc-2.8.1.tar.gz
alsa_pkg=alsa-lib-1.1.5.tar.bz2
wpa_supplicant_pkg=wpa_supplicant-2.6.tar.gz

# git define
qrencode_git=`echo 'https://github.com/fukuchi/libqrencode.git'`
libdaemon_git=`echo 'git://git.0pointer.de/libdaemon'`
ifplugd_git=`echo "https://github.com/FrankSong28/ifplugd.git"`
openssl_git=`echo "git://git.openssl.org/openssl.git"`

# download url define
gcc_x64_url=`echo 'https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabihf/gcc-linaro-7.3.1-2018.05-x86_64_arm-linux-gnueabihf.tar.xz'`
gcc_x32_url=`echo 'https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabihf/gcc-linaro-7.3.1-2018.05-i686_arm-linux-gnueabihf.tar.xz'`
gdb_url=`echo 'http://ftp.gnu.org/gnu/gdb/gdb-8.0.1.tar.xz'`
zlib_url=`echo 'https://www.zlib.net/zlib-1.2.11.tar.gz'`
libpng_url=`echo 'ftp://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.xz'`
ft2_src_url=`echo 'https://download.savannah.gnu.org/releases/freetype/freetype-2.8.1.tar.bz2'`
ft2_doc_url=`echo 'https://download.savannah.gnu.org/releases/freetype/freetype-doc-2.8.tar.bz2'`
ft2_demo_url=`echo 'https://download.savannah.gnu.org/releases/freetype/ft2demos-2.8.1.tar.gz'`
alsa_url=`echo 'ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.5.tar.bz2'`
libnl_url=`echo 'https://www.infradead.org/~tgr/libnl/files/libnl-3.2.25.tar.gz'`
wpa_supplicant_url=`echo 'http://w1.fi/releases/wpa_supplicant-2.6.tar.gz'`

function xtar_pkg {
	[ -n "$2" ] && destdir=`echo "-C $2"`
	pkg_dir=`$3 tar -xvf $1 $destdir|sed -e '2,$ d;s/^\///g;s/\/[^\/]*$//g;s/\/$//g'`
	echo "$pkg_dir"
}

function get_git_src {
	cd $LIB_SRC_ROOT
	g_src_dir=`echo "$1"|sed -e 's/^.*\///g;s/\.git$//g'`

	[ -d $g_src_dir ] && rm -rf "$g_src_dir"
	git clone $1 1>&2
	[ $? -ne 0 ] && return || echo "$LIB_SRC_ROOT/$g_src_dir"
}

function dl_pkg {
	[ -z "$1" ] && return
	pkg_name=`echo "$1"|sed 's/.*\///g'`

	[ -n "$2" ] && dl_pkg_dir=$2 || dl_pkg_dir=${LIB_PKG_ROOT}
	cd $dl_pkg_dir
	curl -L -O $1 1>&2
	[ $? -ne 0 ] && return
	echo "pkg_name=$pkg_name" >&2
	echo "$pkg_name"
}

#-----------------------------------------------------------------
# install linaro arm gcc
# Offical site: https://www.linaro.org/
# Downlaod URL:
#   https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabihf/gcc-linaro-7.2.1-2017.11-i686_arm-linux-gnueabihf.tar.xz
#   https://releases.linaro.org/components/toolchain/binaries/latest/arm-linux-gnueabihf/gcc-linaro-7.2.1-2017.11-x86_64_arm-linux-gnueabihf.tar.xz
function inst_gcc {
	echo "install linaro gcc ..."

	[ ! -d "${LIB_ROOT}/gcc" ] && mkdir -p "${LIB_ROOT}/gcc"
	cd "${LIB_ROOT}/gcc"

	profile=/etc/profile
	gcc_root=/opt/linaro

	[ ! -d $gcc_root ] && sudo mkdir -p $gcc_root

#	gcc_file=`dl_pkg ${gcc_x64_url} .`
	gcc_file=`echo "./${gcc_pkg}"`
	[ -z "$gcc_file" ] && return

	gcc_dir=`xtar_pkg ${gcc_pkg} ${gcc_root} sudo`
	[ -z "$gcc_dir" ] && return

	gcc_dir=`echo "${gcc_dir}" | sed 's/^\///g' | sed 's/\/$//g'`
	gcc_dir=${gcc_root}/${gcc_dir}
	gcc_prefix=`ls ${gcc_dir} | sed -n '1p'`
	gcc_path=${gcc_dir}/${gcc_prefix}

	gcc_bin=${gcc_dir}/bin
	gcc_usr=${gcc_path}/libc/usr

	grep "export LINARO_ARM_ROOT=" $profile > /dev/null
	if [ $? -eq 0 ]; then
		sudo sed -i "/export LINARO_ARM_ROOT=/c export LINARO_ARM_ROOT=${gcc_dir}" $profile
	else
		sudo sed -i "2i \\" $profile
		sudo sed -i "2i \\" $profile
		sudo sed -i "3i #linaro gcc env" $profile
		sudo sed -i "4i export LINARO_ARM_ROOT=${gcc_dir}" $profile
	fi

	grep "export LINARO_ARM_PREFIX=" $profile > /dev/null
	[ $? -eq 0 ] \
		&& sudo sed -i "/export LINARO_ARM_PREFIX=/c export LINARO_ARM_PREFIX=${gcc_prefix}" $profile \
		|| sudo sed -i "/LINARO_ARM_ROOT/a export LINARO_ARM_PREFIX=${gcc_prefix}" $profile

	grep "export LINARO_ARM_PATH=" $profile > /dev/null
	[ $? -eq 0 ] \
		&& sudo sed -i "/export LINARO_ARM_PATH=/c export LINARO_ARM_PATH=${gcc_bin}" $profile \
		|| sudo sed -i "/LINARO_ARM_PREFIX/a export LINARO_ARM_PATH=${gcc_bin}" $profile


	grep "export LINARO_ARM_USR=" $profile > /dev/null
	[ $? -eq 0 ] \
		&& sudo sed -i "/export LINARO_ARM_USR=/c export LINARO_ARM_USR=${gcc_usr}" $profile \
		|| sudo sed -i "/LINARO_ARM_PATH/a export LINARO_ARM_USR=${gcc_usr}" $profile

	grep "appendpath" $profile > /dev/null
	[ $? -eq 0 ] \
		&& sudo sed -i "/appendpath '\/usr\/bin'/a appendpath '${gcc-bin}'" $profile \
		|| sudo sed -i "/^PATH=/c PATH=${PATH}:${gcc_bin}" $profile

	source $profile
}

#-----------------------------------------------
# install gdb
# Offcial site: http://www.gnu.org/software/gdb
# Download URL: http://ftp.gnu.org/gnu/gdb/gdb-8.0.1.tar.xz
function inst_gdb {
	echo "Install gdb"

	[ ! -d "${LIB_ROOT}/gdb" ] && mkdir -p "${LIB_ROOT}/gdb"
	cd "${LIB_ROOT}/gdb"
	[ $? -ne 0 ] && return

	gdb_name=`dl_pkg "$gdb_url" .`
	[ -z "$gdb_name" ] && return

	gdb_dir=`xtar_pkg "${gdb_name}" .`
	[ -z "$gdb_dir" ] && return

	cd "$gdb_dir"
	make distclean

	echo "Install gdb to HOST"
	./configure --target=${gcc_prefix} --program-prefix=${gcc_prefix}- --prefix=${gcc_dir} --without-guile
	[ $? -ne 0 ] && return

	make
	[ $? -ne 0 ] && return
	sudo make install

	echo "Install gdb to TARGET"
	make distclean

	CC=${gcc_prefix}-gcc ./configure --target=${gcc_prefix} --program-prefix=${gcc_prefix}- --prefix=${gcc_usr} --host=${gcc_prefix} --disable-libstdcxx --enable-static
	[ $? -ne 0 ] && return

	make
	[ $? -ne 0 ] && return
	sudo make install
}

#-----------------------------------------------
# install zlib, ver 1.2.11, depended by libpng, openssl, freetype
# Offical site: https://www.zlib.net/
# Download URL: https://www.zlib.net/zlib-1.2.11.tar.gz
function inst_zlib {
	echo "Install Zlib..."

	pkg_file=`dl_pkg "${zlib_url}"`
	[ -z "$pkg_file" ] && return

	lib_dir=`xtar_pkg ${LIB_PKG_ROOT}/${zlib_pkg} ${LIB_SRC_ROOT}`
	[ -z "$lib_dir" ] && return

	cd ${LIB_SRC_ROOT}/${lib_dir}/
	make distclean
	CHOST=${gcc_prefix} ./configure --prefix=${gcc_usr}
	[ $? -ne 0 ] && return
	make
	sudo make install
}

#----------------------------------------------------
# install libpng, depend zlib
# Offical site: http://libpng.org/pub/png/libpng.html
# Download URL: ftp://ftp-osl.osuosl.org/pub/libpng/src/libpng16/libpng-1.6.34.tar.xz
function inst_libpng {
	echo "Install libpng"

	pkg_file=`dl_pkg "${libpng_url}"`
	[ -z "$pkg_file" ] && return

	lib_dir=`xtar_pkg ${LIB_PKG_ROOT}/${libpng_pkg} ${LIB_SRC_ROOT}`
	[ -z "$lib_dir" ] && return

	cd ${LIB_SRC_ROOT}/${lib_dir}/
	make distclean
	./configure --prefix=${gcc_usr} --host=${gcc_prefix}
	[ $? -ne 0 ] && return
	make
	sudo make install
}

#----------------------------------------------------------------
# install freetype, depend zlib
# Offical site: https://www.freetype.org/index.html
# Download URL:
#	src:  https://download.savannah.gnu.org/releases/freetype/freetype-2.8.1.tar.bz2
#	doc:  https://download.savannah.gnu.org/releases/freetype/freetype-doc-2.8.tar.bz2
#   demo: https://download.savannah.gnu.org/releases/freetype/ft2demos-2.8.1.tar.gz
function inst_freetype {
	echo "Install FreeType"

	dl_pkg "${ft2_doc_url}"
	dl_pkg "${ft2_demo_pkg}"
	pkg_file=`dl_pkg "${ft2_src_pkg}"`
	[ -z "$pkg_file" ] && return

	lib_dir=`xtar_pkg ${LIB_PKG_ROOT}/${ft2_src_pkg} ${LIB_SRC_ROOT}`
	[ -z "$lib_dir" ] && return

	cd ${LIB_SRC_ROOT}/${lib_dir}
	make distclean
	./configure --host=${gcc_prefix} --prefix=${gcc_usr} --with-zlib=yes --with-bzip2=no --with-harfbuzz=no
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install
}

#-------------------------------------------------------------------
# install alsa-sound
# Offical site: http://www.alsa-project.org/main/index.php/Main_Page
# Download URL: ftp://ftp.alsa-project.org/pub/lib/alsa-lib-1.1.5.tar.bz2
function inst_alsa {
	echo "Install alsa-sound"

	pkg_file=`dl_pkg "${alsa_url}"`
	[ -z "$pkg_file" ] && return

	lib_dir=`xtar_pkg ${LIB_PKG_ROOT}/${alsa_pkg} ${LIB_SRC_ROOT}`
	[ -z "$lib_dir" ] && return

	cd ${LIB_SRC_ROOT}/${lib_dir}
	make distclean
	CC=${gcc_prefix}-gcc ./configure --host=${gcc_prefix} --prefix=${gcc_usr} --disable-python
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install
}

#------------------------------------------------------------------
# install libqrencode
# Github: https://github.com/fukuchi/libqrencode.git
function inst_qrencode {
	echo "Install libqrencode"

	src_dir=`git_src "$qrencode_git"`
	[ -z "$src_dir" ] && return
	cd $src_dir

	make distclean
	autogen.sh
	./configure --prefix=${gcc_usr} --host=${gcc_prefix}
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install
}

dis_setpgrp=`echo "ac_cv_func_getpgrp_void=no ac_cv_func_setpgrp_void=yes ac_cv_func_memcmp_working=yes rb_cv_binary_elf=no rb_cv_negative_time=no"`

#----------------------------------------------------------------
# install libdaemon, depended by ifplugd
# Github: git://git.0pointer.de/libdaemon
function inst_libdaemon {
	echo "Install libdaemon"

	src_dir=`get_git_src "$libdaemon_git"`
	[ -z "$src_dir" ] && return

	cd $src_dir
	NOCONFIGURE=yes ./bootstrap.sh
	[ $? -ne 0 ] && return
	eval "${dis_setpgrp} ./configure --prefix=${gcc_usr} --host=${gcc_prefix} --disable-lynx --enable-static"
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install
 }

#----------------------------------------------------------------
# install ifplugd, depend libdaemon
# Github: https://github.com/FrankSong28/ifplugd.git
function inst_ifplugd {
	echo "Install ifplugd"

	src_dir=`get_git_src "$ifplugd_git"`
	[ -z "$src_dir" ] && return
	cd "$src_dir"
	mkdir init
	sed -i 's/AC_FUNC_MALLOC/#AC_FUNC_MALLOC/g' configure.ac
	./configure --prefix=${gcc_usr} --host=${gcc_prefix} --disable-lynx --disable-xmltoman --disable-subversion --with-initdir=init
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install

	[ -n "$FS_BIN" ] && cp ${gcc_usr}/sbin/ifplugd ${FS_BIN}
}

#----------------------------------------------------------------
# install openssl, depended by wpa_supplicant
# Offical site: https://www.openssl.org/
# Git: git://git.openssl.org/openssl.git
function inst_openssl {
	echo "Install openssl"

	src_dir=`get_git_src "$openssl_git"`
	[ -z "$src_dir" ] && return
	cd "$src_dir"
	./Configure linux-armv4 --prefix=${gcc_usr} --cross-compile-prefix=${gcc_prefix}- zlib no-tests
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install
}

#----------------------------------------------------------------
# install libnl, depended by wpa_supplicant
# Offical site: https://www.infradead.org/~tgr/libnl/
# Download URL: https://www.infradead.org/~tgr/libnl/files/libnl-3.2.25.tar.gz
function inst_libnl {
	echo "Install libnl"

	pkg_file=`dl_pkg "$libnl_url"`
	[ -z "$pkg_dir" ] && return
	src_dir=`xtar_pkg "${LIB_PKG_ROOT}/${pkg_file}" ${LIB_SRC_ROOT}`
	[ -z "$src_dir" ] && return
	cd ${LIB_SRC_ROOT}/${src_dir}

	./configure --prefix=${gcc_usr} --host=${gcc_prefix}
	[ $? -ne 0 ] && return
	make
	[ $? -ne 0 ] && return
	sudo make install
}

#----------------------------------------------------------------
# install wpa_supplicant, depend openssl, libnl
# Offical site: http://w1.fi/wpa_supplicant/
# Download URL: http://w1.fi/releases/wpa_supplicant-2.6.tar.gz
function inst_wpa_supplicant {
	echo "Install wpa_supplicant"

	pkg_file=`dl_pkg "$wpa_supplicant_url"`
	[ -z "$pkg_file" ] && return

	app_dir=`xtar_pkg ${LIB_PKG_ROOT}/${pkg_file} ${LIB_SRC_ROOT}`
	[ -z "$app_dir" ] && return

	cd "${LIB_SRC_ROOT}/${app_dir}/wpa_supplicant"
	cp defconfig .config

	#using libnl 3.2
	sed -i 's/#CONFIG_LIBNL32=y/CONFIG_LIBNL32=y/g' .config

	CC=${gcc_prefix}-gcc make -j
}

#----------------------------------------------------------------
# main

[ $# -eq 0 ] && allflag=true || allflag=false

ins_all=`echo '--gcc --zlib --libpng --freetype --alsa --qrencode --libdaemon --ifplugd --openssl --libnl --wpa_supplicant'`
ins_prefix=inst_
ins_func=`echo 'gcc'`

[ ! -d "${LIB_SRC_ROOT}" ] && mkdir -p "${LIB_SRC_ROOT}"

[ ! -d "{LIB_PKG_ROOT}" ] && mkdir -p "${LIB_PKG_ROOT}"

while true
do
	if $allflag; then
		[ -z "$ins_all" ] && break

		ins_func=`echo "$ins_all"|sed -e "s/ .*//g;s/^-*//g"`
		ins_all=`echo "$ins_all"|sed "s/^[^ ]* *//g"`
	else
		[ $# -lt 1 ] && break
		ins_func=`echo "$1"|sed "s/[-*]//g"`
		shift
	fi

	if [ "$ins_func" != "gcc" -a -z "$LINARO_ARM_PREFIX" ]; then
		echo "Linaro gcc not installed!"
		exit 1
	fi

	[ -z "$gcc_dir" ] && gcc_dir=$LINARO_ARM_ROOT
	[ -z "$gcc_usr" ] && gcc_usr=$LINARO_ARM_USR
	[ -z "$gcc_prefix" ] && gcc_prefix=$LINARO_ARM_PREFIX

	eval "${ins_prefix}${ins_func}"
	cd ${LIB_ROOT}

done

exit 0
