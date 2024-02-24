# This file originates from the following Git repository:
# https://github.com/chadjoan/cdj-kernel-config
#
# Its purpose is to allow the Linux Kernel .config file to be a symlink
# that points to the cdj-kernel-config/k.config file from the above repo.
#
# Documentation for this environment variable can be found here:
# https://docs.kernel.org/kbuild/kconfig.html#kconfig-overwriteconfig
#
export KCONFIG_OVERWRITECONFIG=1
