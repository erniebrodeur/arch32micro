# Maintainer: Ernie Brodeur <ebrodeur@ujami.net>
# This file is not yet in AUR, please do not put it in AUR.  This file could be VERY destructive
# to a system that is NOT in an ec2 container.

pkgname=ec2-init
_subver=1
pkgver=0.${_subver}
pkgrel=1
pkgdesc="Utilities to connect ArchLinux directly to an EC2 Container."
arch=(any)
url="http://arch32micro.ujami.net/"
license=("GPL")
source=("ec2-inject-keys"
        "ec2.rc")
md5sums=('8bcc1d91a435564ac6476fffc4cba4dc'
        '1fb6eeca88e35a98faccd339974eff6c')

package() {
  cd "$srcdir/"

        # directories
        install -d "$pkgdir/etc/rc.d"
        install -d "$pkgdir/sbin"

        # ec2-inject-keys
        install -D ec2-inject-keys "$pkgdir/sbin"

        # ec2.rc
        install -D ec2.rc "$pkgdir/etc/rc.d/ec2"

}
