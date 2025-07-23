# Maintainer: Fabio 'Lolix' Loli <fabio.loli@disroot.org> -> https://github.com/FabioLolix
# Contributor: marcin mikołajczak <me@mkljczk.pl>

pkgname=piki-git
pkgver=0.1.0
pkgrel=1
pkgdesc="Unofficial Kirigami client for Pixiv"
arch=(x86_64)
url="https://github.com/MicrogamerCz/Piki"
license=(GPL-3.0-or-later)
depends=(qt6-declarative qt6-webengine kirigami kirigami-addons ki18n kconfig kwallet purpose futuresql piqi
    qt6-svg qt6-base kcoreaddons)
makedepends=(extra-cmake-modules git)
conflicts=(piki)
provides=(piki)
source=("git+https://github.com/MicrogamerCz/Piki")
sha256sums=('SKIP')

build() {
  cmake -B build -S Piki \
    -DBUILD_TESTING=OFF \
    -DCMAKE_INSTALL_PREFIX=/usr

  cmake --build build
}

package() {
  DESTDIR="${pkgdir}" cmake --install build
}
