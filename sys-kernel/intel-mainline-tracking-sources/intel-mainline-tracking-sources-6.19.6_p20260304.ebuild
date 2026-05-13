# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"

# Strip Gentoo _p suffix → CKV="6.19.6" for kernel-2.eclass version detection
CKV="${PV/_p*/}"

# Genpatches 6.19-6
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="6"

# Security tracking is handled upstream by Intel
K_SECURITY_UNSUPPORTED="1"

inherit kernel-2
detect_version
detect_arch

# ── Intel mainline-tracking ──────────────────────────────────────────
INTEL_TAG_DATE="260304T080518Z"
INTEL_TAG="mainline-preprod-v${KV_MAJOR}.${KV_MINOR}-linux-${INTEL_TAG_DATE}"
INTEL_ARCHIVE="mainline-tracking-${INTEL_TAG}"

META_PATCH="genpatches-meta-${KV_MAJOR}.${KV_MINOR}-${K_GENPATCHES_VER}-${INTEL_TAG_DATE}.patch"

DESCRIPTION="Intel mainline-tracking kernel sources with Gentoo patchset"
HOMEPAGE="https://github.com/intel/mainline-tracking"

# USEフラグの定義
IUSE="experimental vanilla"

# vanilla が有効な場合は genpatches をダウンロードしない
# (※ GENPATCHES_URI 内部には自動的に experimental の条件分岐が含まれています)
SRC_URI="
	https://github.com/intel/mainline-tracking/archive/refs/tags/${INTEL_TAG}.tar.gz -> ${INTEL_ARCHIVE}.tar.gz
	!vanilla? ( ${GENPATCHES_URI} )
"

KERNEL_URI=""
LICENSE="GPL-2"
KEYWORDS="~amd64 ~x86"

# pre-compiled ELF files in kernel selftests cause QA warnings
RESTRICT="binchecks"

src_unpack() {
	default_src_unpack
	mv "${INTEL_ARCHIVE}" "linux-${KV_FULL}" || die "Failed to rename source directory"
}

src_prepare() {
	# vanilla フラグが無効な場合のみ、genpatches の処理を行う
	if ! use vanilla; then
		einfo "Applying meta-patch to genpatches..."
		cd "${WORKDIR}" || die
		eapply "${FILESDIR}/${META_PATCH}"

		cd "${S}" || die
		einfo "Applying genpatches..."
		local p
		for p in $(find "${WORKDIR}" -maxdepth 1 -name '[0-9]*.patch' | sort); do
			eapply "${p}"
		done
	fi

	cd "${S}" || die
	# ユーザーのカスタムパッチ (/etc/portage/patches/*) などは vanilla 環境でも適用させる
	kernel-2_src_prepare
}

pkg_postinst() {
	kernel-2_pkg_postinst
	einfo "Intel mainline-tracking kernel sources with Gentoo patchset"
	einfo "  Source : ${INTEL_TAG}"
	
	# インストール後のメッセージもUSEフラグに応じて切り替え
	if use vanilla; then
		einfo "  Genpatches : None (vanilla USE flag enabled)"
	else
		einfo "  Genpatches : ${KV_MAJOR}.${KV_MINOR}-${K_GENPATCHES_VER}"
	fi
}

pkg_postrm() {
	kernel-2_pkg_postrm
}