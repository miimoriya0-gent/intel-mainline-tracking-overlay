# custom-intel-mainline-tracking-overlay

A personal Gentoo overlay containing custom ebuilds, primarily focused on providing Intel's mainline-tracking kernel sources integrated with Gentoo's patchsets.

## ⚠️ Disclaimer & Maintenance Policy

This overlay contains my personal, highly customized ebuilds. It is maintained primarily for my own specific environments and hardware.

* **USE AT YOUR OWN RISK:** The kernels and software provided here may cause system instability, data loss, or boot failures. I am not responsible for any damage to your system.
* **Issues & PRs:** You are welcome to open issues or submit Pull Requests if you find a bug or have an improvement. However, please note that **I offer no guarantees on response times or support**. I will review them only if/when I have the time and personal interest.

## 📦 Provided Packages

### `sys-kernel/intel-mainline-tracking-sources`
This package provides the Linux kernel sources from [Intel's mainline-tracking repository](https://github.com/intel/mainline-tracking). 

Unlike directly cloning the upstream repository, this ebuild integrates the standard Gentoo patchset (`genpatches`), allowing you to enjoy the benefits of Intel's latest hardware enabling patches alongside Gentoo's standard kernel fixes and features.

To resolve merge conflicts between Intel's tracking branches and Gentoo's genpatches, custom meta-patches (e.g., `genpatches-meta-*.patch`) are carefully applied during the `src_prepare` phase.

**USE Flags:**
* `vanilla`: Disables the application of Gentoo's `genpatches`. Enable this if you want the pure, unmodified Intel mainline-tracking kernel source.
* *(Note: Some older versions in this overlay may also include an `experimental` USE flag for testing experimental genpatches.)*

## 🚀 Usage

You can add this overlay to your Gentoo system using `eselect repository` or by manually creating a `repos.conf` entry.

### Method 1: Using eselect repository (If utilizing a tool like layman/eselect)
*(If you submit your overlay to the official Gentoo overlay list later, you can add the command here. Otherwise, use Method 2).*

### Method 2: Manual repos.conf entry
Create a file at `/etc/portage/repos.conf/my-overlay.conf` (replace `my-overlay` with your repository name) with the following content:

```ini
[my-overlay]
location = /var/db/repos/my-overlay
sync-type = git
sync-uri = https://github.com/miimoriya0-gent/intel-mainline-tracking-overlay.git
auto-sync = yes
```

Then sync the repository and install the kernel:

```bash
emerge --sync my-overlay
emerge -av sys-kernel/intel-mainline-tracking-sources
```

## 📄 License
The ebuilds and patches in this repository are distributed under the GPL-2 License.
