require 'formula'

class Abuse < Formula
  homepage 'http://abuse.zoy.org/'
  url 'http://abuse.zoy.org/raw-attachment/wiki/download/abuse-0.8.tar.gz'
  head 'svn://svn.zoy.org/abuse/abuse/trunk'
  sha1 '12fea968a1494338ad71c6ec24954f3eef56826a'

  depends_on 'autoconf' => :build
  depends_on 'automake' => :build
  depends_on 'libtool' => :build
  depends_on 'pkg-config' => :build
  depends_on 'sdl'
  depends_on 'sdl_mixer'
  depends_on 'libvorbis'

  def startup_script; <<-EOS.undent
    #!/bin/bash
    #{libexec}/abuse-bin -datadir "#{share}/abuse" "$@"
    EOS
  end

  def install
    # Hack to work with newer versions of automake
    inreplace "bootstrap", '11 10 9 8 7 6 5', '$(seq -s " " 5 99)'

    # Add SDL.m4 to aclocal includes
    inreplace "bootstrap",
      "aclocal${amvers} ${aclocalflags}",
      "aclocal${amvers} ${aclocalflags} -I#{HOMEBREW_PREFIX}/share/aclocal"

    # undefined
    inreplace 'src/net/fileman.cpp', 'ushort', 'unsigned short'
    inreplace 'src/sdlport/setup.cpp', 'UInt8', 'uint8_t'

    # Fix autotools obsoletion notice
    inreplace 'configure.ac', 'AM_CONFIG_HEADER', 'AC_CONFIG_HEADERS'

    # Re-enable OpenGL detection
    inreplace 'configure.ac',
      "#error\t/* Error so the compile fails on OSX */",
      '#include <OpenGL/gl.h>'

    system "./bootstrap"
    system "./configure", "--disable-dependency-tracking",
                          "--disable-debug",
                          "--prefix=#{prefix}",
                          "--disable-sdltest",
                          "--with-assetdir=#{share}/abuse",
                          "--with-sdl-prefix=#{Formula['sdl'].opt_prefix}"

    # Use Framework OpenGL, not libGl
    %w[ . src src/imlib src/lisp src/net src/sdlport ].each do |p|
      inreplace "#{p}/Makefile", '-lGL', '-framework OpenGL'
    end

    system "make"

    bin.install 'src/abuse-tool'
    libexec.install 'src/abuse' => 'abuse-bin'
    (share+'abuse').install Dir["data/*"] - %w(data/Makefile data/Makefile.am data/Makefile.in)
    # Use a startup script to find the game data
    (bin+'abuse').write startup_script
  end

  def caveats; <<-EOS.undent
    Game settings and saves will be written to the ~/.abuse folder.
    EOS
  end

  test do
    system("#{libexec}/abuse-bin", '--help')
  end
end
