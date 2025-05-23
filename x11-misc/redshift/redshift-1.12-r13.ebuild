# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8

PYTHON_COMPAT=( python3_{9..13} )

inherit autotools flag-o-matic systemd xdg-utils python-r1

DESCRIPTION="A screen color temperature adjusting software"
HOMEPAGE="http://jonls.dk/redshift/"
SRC_URI="https://github.com/jonls/${PN}/releases/download/v${PV}/${P}.tar.xz"

LICENSE="GPL-3"
SLOT="0"
KEYWORDS="amd64 arm64 ppc64 ~riscv x86"
IUSE="appindicator geoclue gtk nls"

COMMON_DEPEND=">=x11-libs/libX11-1.4
	x11-libs/libXxf86vm
	x11-libs/libxcb
	x11-libs/libdrm
	appindicator? ( dev-libs/libayatana-appindicator )
	geoclue? ( app-misc/geoclue:2.0 dev-libs/glib:2 )
	gtk? ( ${PYTHON_DEPS} )"
RDEPEND="${COMMON_DEPEND}
	gtk? ( dev-python/pygobject[${PYTHON_USEDEP}]
		x11-libs/gtk+:3[introspection]
		dev-python/pyxdg[${PYTHON_USEDEP}] )"
DEPEND="${COMMON_DEPEND}
	>=dev-util/intltool-0.50
	nls? ( sys-devel/gettext )
"
REQUIRED_USE="gtk? ( ${PYTHON_REQUIRED_USE} )"

PATCHES=(
	"${FILESDIR}"/${P}-apparmor.patch
	"${FILESDIR}"/${P}-libayatana-appindicator.patch
)

src_prepare() {
	default

	# we need to re-generate file py-compile with a version
	# that supports Python >=3.12 to not fail with error:
	# ModuleNotFoundError: No module named 'imp'
	rm py-compile || die
	eautoreconf
}

src_configure() {
	use gtk && python_setup

	# Fix compile for Clang (bug #732438)
	append-cflags -fPIE

	econf \
		$(use_enable nls) \
		--enable-drm \
		--enable-randr \
		--enable-vidmode \
		--disable-wingdi \
		\
		--disable-corelocation \
		$(use_enable geoclue geoclue2) \
		\
		$(use_enable gtk gui) \
		--with-systemduserunitdir="$(systemd_get_userunitdir)" \
		--enable-apparmor \
		--disable-quartz \
		--disable-ubuntu
}

_impl_specific_src_install() {
	emake DESTDIR="${D}" \
		PYTHON="${PYTHON}" \
		pythondir="$(python_get_sitedir)" \
		-C src/redshift-gtk install
}

src_install() {
	emake DESTDIR="${D}" UPDATE_ICON_CACHE=/bin/true install

	if use gtk; then
		python_foreach_impl _impl_specific_src_install
		python_replicate_script "${D}"/usr/bin/redshift-gtk
		dosym redshift-gtk /usr/bin/gtk-redshift

		python_foreach_impl python_optimize

		# https://bugs.gentoo.org/784281
		mv "${D}"/usr/share/{appdata,metainfo}/ || die
	fi
}

pkg_postinst() {
	use gtk && xdg_icon_cache_update
}

pkg_postrm() {
	use gtk && xdg_icon_cache_update
}
