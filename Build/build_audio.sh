#!/bin/sh

# Written by @piyatat, based on @kevin's build_dependencies.sh script for Tesseract-OCR-iOS.


GLOBAL_OUTDIR="`pwd`/build"
LOCAL_OUTDIR="./outdir"
OGG_LIB="`pwd`/libogg-1.3.2"
FLAC_LIB="`pwd`/flac-1.3.1"
OPUS_LIB="`pwd`/opus-1.1"

IOS_BASE_SDK="8.1"
IOS_DEPLOY_TGT="8.0"

export CXX=`xcrun -find c++`
export CC=`xcrun -find cc`

export LD=`xcrun -find ld`
export AR=`xcrun -find ar`
export AS=`xcrun -find as`
export NM=`xcrun -find nm`
export RANLIB=`xcrun -find ranlib`

XCODE_DEVELOPER_PATH=/Applications/Xcode.app/Contents/Developer
XCODETOOLCHAIN_PATH=$XCODE_DEVELOPER_PATH/Toolchains/XcodeDefault.xctoolchain
SDK_IPHONEOS_PATH=$(xcrun --sdk iphoneos --show-sdk-path)
SDK_IPHONESIMULATOR_PATH=$(xcrun --sdk iphonesimulator --show-sdk-path)

export PATH="$XCODETOOLCHAIN_PATH/usr/bin:$PATH"

declare -a archs
archs=(arm7 arm7s arm64 i386 x86_64)

declare -a arch_name
arch_names=(arm-apple-darwin7 arm-apple-darwin7s arm-apple-darwin64 i386-apple-darwin x86_64-apple-darwin)

setenv_all() {
	# Add internal libs
	export CFLAGS="$CFLAGS -I$GLOBAL_OUTDIR/include -L$GLOBAL_OUTDIR/lib -Qunused-arguments"

	export LDFLAGS="-L$SDKROOT/usr/lib/"

	export CPPFLAGS=$CFLAGS
	export CXXFLAGS=$CFLAGS
}

setenv_arm7() {
	unset DEVROOT SDKROOT CFLAGS CPP CXXCPP LDFLAGS CPPFLAGS CXXFLAGS

	export SDKROOT=$SDK_IPHONEOS_PATH

	export CFLAGS="-arch armv7 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

	setenv_all
}

setenv_arm7s() {
	unset DEVROOT SDKROOT CFLAGS CPP CXXCPP LDFLAGS CPPFLAGS CXXFLAGS

	export SDKROOT=$SDK_IPHONEOS_PATH

	export CFLAGS="-arch armv7s -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

	setenv_all
}

setenv_arm64() {
	unset DEVROOT SDKROOT CFLAGS CPP CXXCPP LDFLAGS CPPFLAGS CXXFLAGS

	export SDKROOT=$SDK_IPHONEOS_PATH

	export CFLAGS="-arch arm64 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT -I$SDKROOT/usr/include/"

	setenv_all
}

setenv_i386() {
	unset DEVROOT SDKROOT CFLAGS CPP CXXCPP LDFLAGS CPPFLAGS CXXFLAGS

	export SDKROOT=$SDK_IPHONESIMULATOR_PATH

	export CFLAGS="-arch i386 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"

	setenv_all
}

setenv_x86_64() {
	unset DEVROOT SDKROOT CFLAGS CPP CXXCPP LDFLAGS CPPFLAGS CXXFLAGS

	export SDKROOT=$SDK_IPHONESIMULATOR_PATH

	export CFLAGS="-arch x86_64 -pipe -no-cpp-precomp -isysroot $SDKROOT -miphoneos-version-min=$IOS_DEPLOY_TGT"

	setenv_all
}

create_outdir_lipo() {
	for file in `find $LOCAL_OUTDIR/i386 -name "lib*.a"`; do
		lib_arm7=`echo $file | sed "s/i386/arm7/g"`
		lib_arm7s=`echo $file | sed "s/i386/arm7s/g"`
		lib_arm64=`echo $file | sed "s/i386/arm64/g"`
		lib_x86_64=`echo $file | sed "s/i386/x86_64/g"`
		lib_i386=`echo $file`
		lib=`echo $file | sed "s/i386//g"`
		xcrun -sdk iphoneos lipo -arch armv7s $lib_arm7s -arch armv7 $lib_arm7 -arch arm64 $lib_arm64 -arch i386 $lib_i386 -arch x86_64 $lib_x86_64 -create -output $lib
	done
}

merge_libfiles() {
	DIR=$1
	LIBNAME=$2

	cd $DIR
	for i in `find . -name "lib*.a"`; do
		$AR -x $i
	done
	$AR -r $LIBNAME *.o
	rm -rf *.o __*
	cd -
}

#######################
# Start clean
#######################

rm -rf GLOBAL_OUTDIR lib include

#######################
# Ogg
#######################
cd $OGG_LIB
rm -rf $LOCAL_OUTDIR

for n in "${!archs[@]}"
do
	mkdir -p "$LOCAL_OUTDIR/${archs[$n]}"
	make clean 2> /dev/null
	make distclean 2> /dev/null
	eval "setenv_${archs[$n]}"
	bash autogen.sh
	./configure --host="${arch_names[$n]}" --enable-shared=no
	make -j12
	for i in `find . -name "lib*.a" | grep -v $LOCAL_OUTDIR`; do
		cp -rvf $i "$LOCAL_OUTDIR/${archs[$n]}"
	done
done

create_outdir_lipo

mkdir -p $GLOBAL_OUTDIR/include/ogg && cp -rvf include/ogg/*.h $GLOBAL_OUTDIR/include/ogg/
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/libogg.a $GLOBAL_OUTDIR/lib
make clean 2> /dev/null
make distclean 2> /dev/null
cd ..

#######################
# FLAC
#######################
cd $FLAC_LIB
rm -rf $LOCAL_OUTDIR

for n in "${!archs[@]}"
do
	mkdir -p "$LOCAL_OUTDIR/${archs[$n]}"
	make clean 2> /dev/null
	make distclean 2> /dev/null
	eval "setenv_${archs[$n]}"
	bash autogen.sh
	./configure --host="${arch_names[$n]}" --enable-static=yes --enable-shared=no --disable-cpplibs
	make -j12
	for i in `find . -name "lib*.a" | grep -v $LOCAL_OUTDIR`; do
		cp -rvf $i "$LOCAL_OUTDIR/${archs[$n]}"
	done
done

create_outdir_lipo

mkdir -p $GLOBAL_OUTDIR/include/flac && cp -rvf include/FLAC/*.h $GLOBAL_OUTDIR/include/flac/
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/libFLAC-static.a $GLOBAL_OUTDIR/lib
make clean 2> /dev/null
make distclean 2> /dev/null
cd ..

#######################
# Opus
#######################
cd $OPUS_LIB
rm -rf $LOCAL_OUTDIR

for n in "${!archs[@]}"
do
	mkdir -p "$LOCAL_OUTDIR/${archs[$n]}"
	make clean 2> /dev/null
	make distclean 2> /dev/null
	eval "setenv_${archs[$n]}"
	bash autogen.sh
	./configure --host="${arch_names[$n]}" --enable-shared=no
	make -j12
	for i in `find . -name "lib*.a" | grep -v $LOCAL_OUTDIR`; do
		cp -rvf $i "$LOCAL_OUTDIR/${archs[$n]}"
	done
done

create_outdir_lipo

mkdir -p $GLOBAL_OUTDIR/include/opus && cp -rvf include/*.h $GLOBAL_OUTDIR/include/opus/
mkdir -p $GLOBAL_OUTDIR/lib && cp -rvf $LOCAL_OUTDIR/libopus.a $GLOBAL_OUTDIR/lib
make clean 2> /dev/null
make distclean 2> /dev/null
cd ..

echo "Finished!"
