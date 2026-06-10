# Copyright 2026 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI="8"
ETYPE="sources"

# Strip Gentoo _p suffix → CKV="6.19.6" for kernel-2.eclass version detection
CKV="${PV/_p*/}"

# Genpatches 7.0-18
K_WANT_GENPATCHES="base extras experimental"
K_GENPATCHES_VER="18"

# Security tracking is handled upstream by Intel
K_SECURITY_UNSUPPORTED="1"

inherit kernel-2
detect_version
detect_arch

# ── eclass のディレクトリ名自動決定ロジックを上書き ──
KV_EXTRA="-intel-mainline"

# リビジョンが "r0" 以外（-r1, -r2 など）の場合のみ、サフィックスにリビジョン番号を連結する
if [[ "${PR}" != "r0" ]]; then
	KV_EXTRA="${KV_EXTRA}-${PR}"
fi
KV_FULL="${KV_MAJOR}.${KV_MINOR}.${KV_PATCH}${KV_EXTRA}"
S="${WORKDIR}/linux-${KV_FULL}"

# ── Intel mainline-tracking ──────────────────────────────────────────
INTEL_TAG_DATE="260527T091547Z"
INTEL_TAG="mainline-preprod-v${KV_MAJOR}.${KV_MINOR}-linux-${INTEL_TAG_DATE}"
INTEL_ARCHIVE="mainline-tracking-${INTEL_TAG}"

META_PATCH="genpatches-meta-${KV_MAJOR}.${KV_MINOR}-${K_GENPATCHES_VER}-${INTEL_TAG_DATE}.patch"

DESCRIPTION="Intel mainline-tracking kernel sources with Gentoo patchset"
HOMEPAGE="https://github.com/intel/mainline-tracking"

# USEフラグの定義
IUSE+="experimental vanilla acpi-call cgroup-vram clang-polly rt-i915 sched-bore"

# CachyOS のパッチベースURL
CACHYOS_COMMIT="b87558b7c865628c48c1d6ff5c827b9df40e9281"
# ファイル名に使うための短縮ハッシュ（先頭8文字を切り出し）
CACHYOS_SHORTHASH="${CACHYOS_COMMIT:0:8}"
CACHYOS_BASE="https://raw.githubusercontent.com/CachyOS/kernel-patches/${CACHYOS_COMMIT}/${KV_MAJOR}.${KV_MINOR}"

# vanilla が有効な場合は genpatches をダウンロードしない
# (※ GENPATCHES_URI 内部には自動的に experimental の条件分岐が含まれています)
SRC_URI="
	https://github.com/intel/mainline-tracking/archive/refs/tags/${INTEL_TAG}.tar.gz -> ${INTEL_ARCHIVE}.tar.gz
	!vanilla? ( ${GENPATCHES_URI} )
	acpi-call? ( ${CACHYOS_BASE}/misc/0001-acpi-call.patch -> ${P}-cachyos-${CACHYOS_SHORTHASH}-acpi-call.patch )
	cgroup-vram? ( ${CACHYOS_BASE}/misc/0001-cgroup-vram.patch -> ${P}-cachyos-${CACHYOS_SHORTHASH}-cgroup-vram.patch )
	clang-polly? ( ${CACHYOS_BASE}/misc/0001-clang-polly.patch -> ${P}-cachyos-${CACHYOS_SHORTHASH}-clang-polly.patch )
	rt-i915? ( ${CACHYOS_BASE}/misc/0001-rt-i915.patch -> ${P}-cachyos-${CACHYOS_SHORTHASH}-rt-i915.patch )
	sched-bore?  ( ${CACHYOS_BASE}/sched/0001-bore.patch -> ${P}-cachyos-${CACHYOS_SHORTHASH}-sched-bore.patch )
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
		
		# スケジューラの競合回避
		if use sched-bore; then
			einfo "BORE scheduler selected. Excluding Gentoo experimental scheduler patches to avoid conflicts..."
			rm -f "${WORKDIR}/5020_BMQ-and-PDS-io-scheduler-v7.0-r2.patch" || die
			rm -f "${WORKDIR}/5021_BMQ-and-PDS-gentoo-defaults.patch" || die
		fi

		# メタパッチが存在する場合のみ適用
		# 1. ベースとなるメタパッチ（Intel mainline 等との全体的な競合解決用、常に適用）
		if [[ -f "${FILESDIR}/${META_PATCH}" ]]; then
			einfo "Applying meta-patch to genpatches..."
			cd "${WORKDIR}" || die
			eapply "${FILESDIR}/${META_PATCH}"
		else
			einfo "No meta-patch found for this version. Skipping meta-patch application."
		fi
		# 2. cgroup-vram 有効時のみ適用するパッチ
		# （genpatches の TTM 関連ハンクを取り除き、cgroup-vram との競合を回避する）
		META_PATCH_CGROUP_VRAM=${META_PATCH%.patch}-cgroup-vram.patch
		if use cgroup-vram && [[ -f "${FILESDIR}/${META_PATCH_CGROUP_VRAM}" ]]; then
			einfo "cgroup-vram is enabled. Modifying genpatches to avoid TTM conflicts..."
			eapply "${FILESDIR}/${META_PATCH_CGROUP_VRAM}"
		fi

		cd "${S}" || die
		einfo "Applying genpatches..."
		local p
		for p in $(find "${WORKDIR}" -maxdepth 1 -name '[0-9]*.patch' | sort); do
			eapply "${p}"
		done
	fi

	cd "${S}" || die

	# ── CachyOS パッチの適用 ──
	if use acpi-call; then
		einfo "Applying CachyOS acpi-call patch..."
		eapply "${DISTDIR}/${P}-cachyos-${CACHYOS_SHORTHASH}-acpi-call.patch"
	fi

	if use cgroup-vram; then
		einfo "Applying CachyOS cgroup-vram patch..."
		eapply "${DISTDIR}/${P}-cachyos-${CACHYOS_SHORTHASH}-cgroup-vram.patch"
	fi

	if use clang-polly; then
		einfo "Applying CachyOS clang-polly patch..."
		eapply "${DISTDIR}/${P}-cachyos-${CACHYOS_SHORTHASH}-clang-polly.patch"
	fi

	if use rt-i915; then
		einfo "Applying CachyOS rt-i915 patch..."
		eapply "${DISTDIR}/${P}-cachyos-${CACHYOS_SHORTHASH}-rt-i915.patch"
	fi

	if use sched-bore; then
		einfo "Applying CachyOS BORE scheduler patch..."
		eapply "${DISTDIR}/${P}-cachyos-${CACHYOS_SHORTHASH}-sched-bore.patch"
	fi

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
