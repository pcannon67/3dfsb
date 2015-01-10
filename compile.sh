#!/bin/sh
# Compile 3dfsb using sdl-config and pkg-config to find the necessary CFLAGS paths and linker flags

execfind ()
{
    for cmd in $*; 
    do
        if "$cmd" --version > /dev/null; then
            echo "$cmd";
            break;
        fi;
    done;
}
                                            
SDL_CONFIG=$(execfind sdl-config sdl11-config sdl10-config sdl12-config \/boot\/develop\/tools/gnupro\/bin\/sdl-config);

if ! "$SDL_CONFIG" --version > /dev/null; then
    echo "Cannot find the sdl-config script.";
    echo "Please check your SDL installation.";
    exit 1;
fi

echo "Using $SDL_CONFIG.";
SDL_CFLAGS=$($SDL_CONFIG --cflags);	# Example: -I/usr/include/SDL -D_GNU_SOURCE=1 -D_REENTRANT
SDL_LIBS=$($SDL_CONFIG --libs);		# Example: -L/usr/lib/x86_64-linux-gnu -lSDL

GSTREAMER_CFLAGS=$(pkg-config --cflags gstreamer-1.0)	# Example: -pthread -I/usr/local/include/gstreamer-1.0 -I/usr/local/lib/gstreamer-1.0/include -I/usr/include/glib-2.0 -I/usr/lib/x86_64-linux-gnu/glib-2.0/include
GSTREAMER_LIBS=$(pkg-config --libs gstreamer-1.0)	# Example: -L/usr/local/lib -lgstreamer-1.0 -lgobject-2.0 -lglib-2.0

# GTK is for debugging purposes (dumping an image to a file)
GTK_CFLAGS=$(pkg-config --cflags gtk+-2.0)
GTK_LIBS=$(pkg-config --libs gtk+-2.0)

OTHER_LIBS=$(pkg-config --libs glu SDL_stretch)

NOPKGCONFIG_LIBS="-lglut -lmagic -lm"

if uname -s | grep -i -c "LINUX" > /dev/null; then 
    echo "GNU/Linux detected.";
    echo "compiling...";
    # On Linux, pkg-config is easier to use than sdl-config...
    SDL_CFLAGS=$(pkg-config --cflags SDL_image);	# Example: -D_GNU_SOURCE=1 -D_REENTRANT -I/usr/include/SDL 
    SDL_LIBS=$(pkg-config --libs SDL_image);		# Example: -lSDL_image -lSDL 

    #warnings="-Wall"

    # This works fine in the first steps, but then fails in a way very similar to how it fails on pluto
    #gccopt="-static -static-libgcc"

    gccopt="-g"		# debugging info by default

    if ! uname -m | grep 64; then
	    objcopy --input binary --output elf32-i386 --binary-architecture i386 images/icon_pdf.png icon_pdf.o
    else
            # The --binary-architecture i386 is correct here
	    objcopy --input binary --output elf64-x86-64 --binary-architecture i386 images/icon_pdf.png icon_pdf.o
    fi
    gcc $gccopt $warnings $SDL_CFLAGS $GSTREAMER_CFLAGS $GTK_CFLAGS 3dfsb.c icon_pdf.o -o 3dfsb $GSTREAMER_LIBS $SDL_LIBS $OTHER_LIBS $GTK_LIBS $NOPKGCONFIG_LIBS
elif uname -s | grep -i -c "BEOS" > /dev/null; then 
    echo "BeOS detected.";
    echo "compiling...";
    gcc $SDL_LIBS $SDL_CFLAGS -I/boot/develop/tools/gnupro/include/ -I/boot/develop/headers/be/opengl/ -L/boot/home/config/lib -L/boot/develop/tools/gnupro/lib/ -lSDL_image -lGL -lglut -lmagic -D_THREAD_SAFE -O2 -x c -o 3dfsb 3dfsb.c;
elif uname -s | grep -i -c "BSD" > /dev/null; then 
    echo "BSD detected.";
    echo "compiling...";
    gcc $SDL_LIBS $SDL_CFLAGS -I/usr/local/include -I/usr/include/ -I/usr/X11R6/include -L/usr/lib/ -L/usr/local/lib/ -L/usr/X11R6/lib -lSDL_image -lGL -lGLU -lglut -lXmu -lXi -lXext -lX11 -lm -lmagic -D_THREAD_SAFE -O2 -x c -o 3dfsb 3dfsb.c;
else
    echo "Unknown OS. If you are running Linux, BeOS or";
    echo "FreeBSD please send me the output of 'uname -s'." 
    exit 1;
fi;

exit 0;
