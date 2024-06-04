################################################################################
#
# gcc-target
#
################################################################################

GCC_TARGET_VERSION = $(GCC_VERSION)
GCC_TARGET_SITE = $(GCC_SITE)
GCC_TARGET_SOURCE = $(GCC_SOURCE)
VENDOR = $(BR2_TOOLCHAIN_BUILDROOT_VENDOR)

# Use the same archive as gcc-initial and gcc-final
GCC_TARGET_DL_SUBDIR = gcc

GCC_TARGET_DEPENDENCIES = gmp mpfr mpc

# First, we use HOST_GCC_COMMON_MAKE_OPTS to get a lot of correct flags (such as
# the arch, abi, float support, etc.) which are based on the config used to
# build the internal toolchain
GCC_TARGET_CONF_OPTS = $(HOST_GCC_COMMON_CONF_OPTS)
# Then, we modify incorrect flags from HOST_GCC_COMMON_CONF_OPTS
GCC_TARGET_CONF_OPTS += \
        --with-sysroot=/ \
        --with-build-sysroot=$(STAGING_DIR) \
        --enable-libstdcxx-debug --enable-libstdcxx-time=yes --with-default-libstdcxx-abi=new --enable-gnu-unique-object --disable-vtable-verify --enable-default-pie --with-system-zlib --enable-libphobos-checking=release --with-target-system-zlib=auto \
        --with-gmp=$(STAGING_DIR) \
        --with-mpc=$(STAGING_DIR) \
        --with-mpfr=$(STAGING_DIR) \
        --prefix=/usr \
        --enable-multiarch
        #--libdir=/usr/lib/aarch64-linux-gnu \
        --oldincludedir=/usr/include/aarch64-linux-gnu \
        --includedir=/usr/include/aarch64-linux-gnu
# Then, we force certain flags that may appear in HOST_GCC_COMMON_CONF_OPTS
GCC_TARGET_CONF_OPTS += \
        --disable-libquadmath \
        --disable-libsanitizer \
        --disable-lto
# Finally, we add some of our own flags
GCC_TARGET_CONF_OPTS += \
        --enable-languages=c,c++ \
        --disable-boostrap \
        --disable-libgomp \
        --disable-nls \
        --disable-libmpx \
        --disable-gcov \
        $(EXTRA_TARGET_GCC_CONFIG_OPTIONS)

ifeq ($(BR2_GCC_ENABLE_GRAPHITE),y)
GCC_TARGET_DEPENDENCIES += isl
GCC_TARGET_CONF_OPTS += --with-isl=$(STAGING_DIR)
else
GCC_TARGET_CONF_OPTS += --without-isl --without-cloog
endif

#disable zstd support if not enabled
ifeq ($(BR2_PACKAGE_ZSTD),y)
GCC_TARGET_CONF_OPTS += --with-zstd=$(STAGING_DIR)
GCC_TARGET_DEPENDENCIES += zstd
else
GCC_TARGET_CONF_OPTS += --without-zstd
endif

GCC_TARGET_CONF_ENV = $(HOST_GCC_COMMON_CONF_ENV)

GCC_TARGET_MAKE_OPTS += $(HOST_GCC_COMMON_MAKE_OPTS)

# Install standard C headers (from glibc)
define GCC_TARGET_INSTALL_HEADERS
        cp -r $(STAGING_DIR)/usr/include $(TARGET_DIR)/usr/
endef
GCC_TARGET_POST_INSTALL_TARGET_HOOKS += GCC_TARGET_INSTALL_HEADERS

# Install standard C libraries (from glibc)
GCC_TARGET_GLIBC_LIBS = \
        *crt*.o *_nonshared.a \
        libBrokenLocale.so libanl.so libbfd.so libc.so libcrypt.so libdl.so \
        libm.so libnss_compat.so libnss_db.so libnss_files.so libnss_hesiod.so \
        libpthread.so libresolv.so librt.so libthread_db.so libutil.so \
        *.a

define GCC_TARGET_INSTALL_LIBS
        for libpattern in $(GCC_TARGET_GLIBC_LIBS); do \
                $(call copy_toolchain_lib_root,$$libpattern) ; \
        done
endef
GCC_TARGET_POST_INSTALL_TARGET_HOOKS += GCC_TARGET_INSTALL_LIBS

# Remove unnecessary files (extra links to gcc binaries, and libgcc which is
# already in `/lib`)
define GCC_TARGET_RM_FILES
        rm -f $(TARGET_DIR)/usr/bin/$(ARCH)-${BR2_TOOLCHAIN_BUILDROOT_VENDOR}-linux-gnu-gcc*
        rm -f $(TARGET_DIR)/usr/lib/libgcc_s*.so*
        rm -f $(TARGET_DIR)/usr/$(ARCH)-${BR2_TOOLCHAIN_BUILDROOT_VENDOR}-linux-gnu/lib/ldscripts/elf32*
        rm -f $(TARGET_DIR)/usr/$(ARCH)-${BR2_TOOLCHAIN_BUILDROOT_VENDOR}-linux-gnu/lib/ldscripts/elf64b*
endef
GCC_TARGET_POST_INSTALL_TARGET_HOOKS += GCC_TARGET_RM_FILES

$(eval $(autotools-package))
