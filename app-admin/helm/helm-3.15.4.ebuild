# Copyright 1999-2025 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=8
inherit go-module shell-completion
GIT_COMMIT=fa9efb07d9d8debbb4306d72af76a383895aa8c4
GIT_SHA=fa9efb07
MY_PV=${PV/_rc/-rc.}

DESCRIPTION="Kubernetes Package Manager"
HOMEPAGE="https://github.com/helm/helm https://helm.sh"
SRC_URI="https://github.com/helm/helm/archive/v${MY_PV}.tar.gz -> k8s-${P}.tar.gz"
SRC_URI+=" https://dev.gentoo.org/~williamh/dist/${P}-deps.tar.xz"

LICENSE="Apache-2.0 BSD BSD-2 CC-BY-4.0 CC-BY-SA-4.0 ISC MIT ZLIB"
SLOT="0"
KEYWORDS="amd64 ~arm64 ~loong ~riscv"

RESTRICT=" test"

src_compile() {
	emake \
		GOFLAGS="${GOFLAGS}" \
		LDFLAGS="" \
		GIT_COMMIT=${GIT_COMMIT} \
		GIT_SHA=${GIT_SHA} \
		GIT_TAG=v${MY_PV} \
		GIT_DIRTY=clean \
		build
	bin/${PN} completion bash > ${PN}.bash || die
	bin/${PN} completion zsh > ${PN}.zsh || die
}

src_install() {
	newbashcomp ${PN}.bash ${PN}
	newzshcomp ${PN}.zsh _${PN}

	dobin bin/${PN}
	dodoc README.md
}
