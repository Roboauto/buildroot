################################################################################
#
# isl
#
################################################################################

ISL_VERSION = 0.26
ISL_SOURCE = isl-$(ISL_VERSION).tar.xz
ISL_SITE = https://libisl.sourceforge.io
ISL_LICENSE = MIT
ISL_INSTALL_STAGING = YES
ISL_LICENSE_FILES = LICENSE
ISL_DEPENDENCIES = gmp
HOST_ISL_DEPENDENCIES = host-gmp

$(eval $(autotools-package))
$(eval $(host-autotools-package))