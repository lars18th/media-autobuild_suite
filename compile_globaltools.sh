# set CPU count global. This can be overwrite from the compiler script (media-autobuild_suite.bat)
cpuCount=1
while true; do
  case $1 in
--cpuCount=* ) cpuCount="${1#*=}"; shift ;;
--build32=* ) build32="${1#*=}"; shift ;;
--build64=* ) build64="${1#*=}"; shift ;;
--deleteSource=* ) deleteSource="${1#*=}"; shift ;;
    -- ) shift; break ;;
    -* ) echo "Error, unknown option: '$1'."; exit 1 ;;
    * ) break ;;
  esac
done

cd $pwd
if [ ! -f ".gitconfig" ]; then
echo -------------------------------------------------
echo "build git config..."
echo -------------------------------------------------
cat > .gitconfig << "EOF"
[core]
	autocrlf = false
EOF
fi

# check if compiled file exist
do_checkIfExist() {
	local packetName="$1"
	local fileName="$2"
	local fileExtension=${fileName##*.}
	if [[ "$fileExtension" = "exe" ]]; then
		if [ -f "$GLOBALDESTDIR/bin/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						cd $LOCALBUILDDIR
						rm -rf $LOCALBUILDDIR/$packetName
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	elif [[ "$fileExtension" = "a" ]]; then
		if [ -f "$GLOBALDESTDIR/lib/$fileName" ]; then
			echo -
			echo -------------------------------------------------
			echo "build $packetName done..."
			echo -------------------------------------------------
			echo -
			if [[ $deleteSource = "y" ]]; then
				if [[ ! "${packetName: -4}" = "-git" ]]; then
					if [[ ! "${packetName: -3}" = "-hg" ]]; then
						cd $LOCALBUILDDIR
						rm -rf $LOCALBUILDDIR/$packetName
					fi
				fi
			fi
			else
				echo -------------------------------------------------
				echo "build $packetName failed..."
				echo "delete the source folder under '$LOCALBUILDDIR' and start again"
				read -p "first close the batch window, then the shell window"
				sleep 15
		fi	
	fi
}

buildProcess() {
cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libopenjpeg.a" ]; then
	echo -------------------------------------------------
	echo "openjpeg-1.5.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile openjpeg $bits\007"
		if [ -d "openjpeg-1.5.1" ]; then rm -rf openjpeg-1.5.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c "http://openjpeg.googlecode.com/files/openjpeg-1.5.1.tar.gz"
		tar xf openjpeg-1.5.1.tar.gz
		rm openjpeg-1.5.1.tar.gz
		cd openjpeg-1.5.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no LIBS="$LIBS -lpng -ljpeg -lz" CFLAGS="$CFLAGS -DOPJ_STATIC"
				
		make
		make install
		
		do_checkIfExist openjpeg-1.5.1 libopenjpeg.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfreetype.a" ]; then
	echo -------------------------------------------------
	echo "freetype-2.5.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile freetype $bits\007"
		if [ -d "freetype-2.5.3" ]; then rm -rf freetype-2.5.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://download.savannah.gnu.org/releases/freetype/freetype-2.5.3.tar.gz
		tar xf freetype-2.5.3.tar.gz
		rm freetype-2.5.3.tar.gz
		cd freetype-2.5.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist freetype-2.5.3 libfreetype.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfontconfig.a" ]; then
	echo -------------------------------------------------
	echo "fontconfig-2.11.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile fontconfig $bits\007"
		if [ -d "fontconfig-2.11.1" ]; then rm -rf fontconfig-2.11.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.freedesktop.org/software/fontconfig/release/fontconfig-2.11.1.tar.gz
		tar xf fontconfig-2.11.1.tar.gz
		rm fontconfig-2.11.1.tar.gz
		cd fontconfig-2.11.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		sed -i 's/-L${libdir} -lfontconfig[^l]*$/-L${libdir} -lfontconfig -lfreetype -lexpat/' "$GLOBALDESTDIR/lib/pkgconfig/fontconfig.pc"
		
		do_checkIfExist fontconfig-2.11.1 libfontconfig.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libfribidi.a" ]; then
	echo -------------------------------------------------
	echo "fribidi-0.19.6 is already compiled"
	echo -------------------------------------------------
	else
		echo -ne "\033]0;compile fribidi $bits\007"
		if [ -d "fribidi-0.19.6" ]; then rm -rf fribidi-0.19.6; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://fribidi.org/download/fribidi-0.19.6.tar.bz2
		tar xf fribidi-0.19.6.tar.bz2
		rm fribidi-0.19.6.tar.bz2
		cd fribidi-0.19.6
		
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install

if [ ! -f ${GLOBALDESTDIR}/bin/fribidi-config ]; then
cat > ${GLOBALDESTDIR}/bin/fribidi-config << "EOF"
#!/bin/sh
case $1 in
  --version)
    pkg-config --modversion fribidi
    ;;
  --cflags)
    pkg-config --cflags fribidi
    ;;
  --libs)
    pkg-config --libs fribidi
    ;;
  *)
    false
    ;;
esac
EOF
fi

	do_checkIfExist fribidi-0.19.6 libfribidi.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libSDL.a" ]; then
	echo -------------------------------------------------
	echo "SDL-1.2.15 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile SDL $bits\007"
		if [ -d "SDL-1.2.15" ]; then rm -rf SDL-1.2.15; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c http://www.libsdl.org/release/SDL-1.2.15.tar.gz
		tar xf SDL-1.2.15.tar.gz
		rm SDL-1.2.15.tar.gz
		cd SDL-1.2.15
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-shared=no
		make -j $cpuCount
		make install
		
		sed -i "s/-mwindows//" "$GLOBALDESTDIR/bin/sdl-config"
		sed -i "s/-mwindows//" "$GLOBALDESTDIR/lib/pkgconfig/sdl.pc"
		
		do_checkIfExist SDL-1.2.15 libSDL.a
fi

#----------------------
# crypto engine
#----------------------

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgcrypt.a" ]; then
	echo -------------------------------------------------
	echo "libgcrypt-1.5.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libgcrypt $bits\007"
		if [ -d "libgcrypt-1.5.3" ]; then rm -rf libgcrypt-1.5.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 ftp://ftp.gnupg.org/gcrypt/libgcrypt/libgcrypt-1.5.3.tar.bz2
		tar xf libgcrypt-1.5.3.tar.bz2
		rm libgcrypt-1.5.3.tar.bz2
		cd libgcrypt-1.5.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --with-gnu-ld
		make -j $cpuCount
		make install
		
		do_checkIfExist libgcrypt-1.5.3 libgcrypt.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libgnutls.a" ]; then
	echo -------------------------------------------------
	echo "gnutls-3.2.3 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile gnutls $bits\007"
		if [ -d "gnutls-3.2.3" ]; then rm -rf gnutls-3.2.3; fi
		wget --tries=20 --retry-connrefused --waitretry=2 ftp://ftp.gnutls.org/gcrypt/gnutls/v3.2/gnutls-3.2.3.tar.xz
		tar xf gnutls-3.2.3.tar.xz
		rm gnutls-3.2.3.tar.xz
		cd gnutls-3.2.3
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --enable-threads=win32 --disable-guile --disable-doc --disable-tests --disable-shared --with-gnu-ld --without-p11-kit
		make -j $cpuCount
		make install
		sed -i 's/-lgnutls *$/-lgnutls -lnettle -lhogweed -liconv -lcrypt32 -lws2_32 -lz -lgmp -lintl/' $GLOBALDESTDIR/lib/pkgconfig/gnutls.pc
		
		if [[ $bits = "32bit" ]]; then
			sed -i 's/-L\/global32\/lib .*/-L\/global32\/lib/' $GLOBALDESTDIR/lib/pkgconfig/gnutls.pc
		else
			sed -i 's/-L\/global64\/lib .*/-L\/global64\/lib/' $GLOBALDESTDIR/lib/pkgconfig/gnutls.pc
		fi
		
		do_checkIfExist gnutls-3.2.3 libgnutls.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/bin/rtmpdump.exe" ]; then
	echo -------------------------------------------------
	echo "rtmpdump is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile rtmpdump $bits\007"
		if [ -d "rtmpdump" ]; then rm -rf rtmpdump; fi
		git clone --depth 1 git://git.ffmpeg.org/rtmpdump rtmpdump
		cd rtmpdump
		sed -i 's/LIB_GNUTLS=.*/LIB_GNUTLS=-lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1 $(LIBZ)/' Makefile
		sed -i 's/LIBS_mingw=.*/LIBS_mingw=-lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl/' Makefile
		make LDFLAGS="$LDFLAGS" prefix=$GLOBALDESTDIR CRYPTO=GNUTLS SHARED= SYS=mingw install LIBS="$LIBS -liconv -lrtmp -lgnutls -lhogweed -lnettle -lgmp -liconv -ltasn1 -lws2_32 -lwinmm -lgdi32 -lcrypt32 -lintl -lz -liconv"
		sed -i 's/Libs:.*/Libs: -L${libdir} -lrtmp -lwinmm -lz -lgmp -lintl/' $GLOBALDESTDIR/lib/pkgconfig/librtmp.pc
		
		do_checkIfExist rtmpdump rtmpdump.exe
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libdca.a" ]; then
	echo -------------------------------------------------
	echo "libdca is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libdca $bits\007"
		if [ -d "libdca" ]; then rm -rf libdca; fi
		svn co svn://svn.videolan.org/libdca/trunk libdca
		cd libdca
		./bootstrap
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libdca libdca.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libxml2.a" ]; then
	echo -------------------------------------------------
	echo "libxml2-2.9.1 is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libxml2 $bits\007"
		if [ -d "libxml2-2.9.1" ]; then rm -rf libxml2-2.9.1; fi
		wget --tries=20 --retry-connrefused --waitretry=2 -c ftp://xmlsoft.org/libxml2/libxml2-2.9.1.tar.gz
		tar xf libxml2-2.9.1.tar.gz
		rm libxml2-2.9.1.tar.gz
		cd libxml2-2.9.1
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared --enable-static
		make -j $cpuCount
		make install
		cp $GLOBALDESTDIR/lib/xml2.a $GLOBALDESTDIR/lib/libxml2.a
		cp $GLOBALDESTDIR/lib/xml2.la $GLOBALDESTDIR/lib/libxml2.la
		
		do_checkIfExist libxml2-2.9.1 libxml2.a
fi

cd $LOCALBUILDDIR

if [ -f "$GLOBALDESTDIR/lib/libilbc.a" ]; then
	echo -------------------------------------------------
	echo "libilbc is already compiled"
	echo -------------------------------------------------
	else 
		echo -ne "\033]0;compile libilbc $bits\007"
		if [ -d "libilbc" ]; then rm -rf libilbc; fi
		git clone --depth 1 https://github.com/dekkers/libilbc.git libilbc
		cd libilbc
		if [[ ! -f "configure" ]]; then
			autoreconf -fiv
		fi
		./configure --build=$targetBuild --host=$targetHost --prefix=$GLOBALDESTDIR --disable-shared
		make -j $cpuCount
		make install
		
		do_checkIfExist libilbc libilbc.a
fi
}

if [[ $build32 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile global tools 32 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global32/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile global tools 32 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

if [[ $build64 = "yes" ]]; then
	echo "-------------------------------------------------------------------------------"
	echo
	echo "compile global tools 64 bit"
	echo
	echo "-------------------------------------------------------------------------------"
	source /global64/etc/profile.local
	buildProcess
	echo "-------------------------------------------------------------------------------"
	echo "compile global tools 64 bit done..."
	echo "-------------------------------------------------------------------------------"
	sleep 3
fi

sleep 3