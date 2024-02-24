# Kernel Configuration #

### About this repository ###

This is the repository where I version-control my kernel configuration and share it with friends.

### Idiomatic Usage ###

In case anyone else wants to do the same thing, I have explained my setup below:

I have created a "meta" directory on my system for centralizing various files I've made that often "cut across" different machines, and that's where I clone this repository to:
```sh
# Be root
sudo su

# You can use any path for this, but this one is what I'll be using:
MY_META_PATH="/srv/meta/public"

# Create the git repository
git clone https://github.com/chadjoan/cdj-kernel-config.git "${MY_META_PATH}/cdj-kernel-config"

# Now the kernel config is in /srv/meta/public/cdj-kernel-config/kernel-config
# and the comments are in /srv/meta/public/cdj-kernel-config/README.md
```

To avoid needing to copy my `.config` back and forth between my `/usr/src/linux` directory and this repository, symlinks are useful:
```sh
# Be root
sudo su

# Be in the Linux kernel's source code directory
cd /usr/src/linux

# Back up the existing config file!
mv .config ".config.backup.$(date +'%Y-%m-%d.%H%M')"

# Make a symlink from the Git repo's config to the Linux directory's config:
ln -s /srv/meta/public/cdj-kernel-config/kernel-config .config
```

It is also helpful to symlink the comments file, to make it easy to edit comments while in a shell session that's parked in the `/etc` directory:
```sh
# Be root
sudo su

# Be in the /etc directory.
cd /etc

# Make a symlink from the Git repo's README.md (comments)
# to something more appropriately named in /etc:
ln -s /srv/meta/public/cdj-kernel-config/README.md /etc/kernel-config-comments.md
```

### Note about kernel config option names ###
ProTip for anyone who hasn't spent too much of their life staring at `make menuconfig`:<br>
Typing '/' will make the config editor open a search prompt that allows one to look up the config option names (ex:&nbsp;`CONFIG_DEFAULT_HOSTNAME`).

The information it brings up allows us to translate those names into the paths where we can find and edit those options.

For example, searching for `CONFIG_DEFAULT_HOSTNAME` will bring up this information:
```
Symbol: DEFAULT_HOSTNAME [=cdj-kernel]
Type  : string
Defined at init/Kconfig:361
Prompt: Default hostname
Location:
-> General setup
(1)   -> Default hostname (DEFAULT_HOSTNAME [=cdj-kernel])
```

From that we know we can find this option under the `General setup` top menu, and it'll be called `Default hostname` in the list of options.

The search is not an exact match either, so searching for `hostname` will also bring up the `CONFIG_DEFAULT_HOSTNAME` option's information. (It'll also bring up any other options that have `HOSTNAME` in their name, if they exist.)

### General Configuration Methodology ###

#### Goals ####
This kernel configuration is intended to be a _very good_ desktop and laptop
configuration that will handle _everything_.

After all, I observed at some point that there aren't very many situations
where the kernel configuration _actually_ has trade-offs. Usually the "trade-off"
is something along the lines of "if we enable this hardware module it will
make `/lib/modules` bigger."

Even though this kernel may never run on a system with 3 different graphics
cards plugged into it, it is still reasonable to want a kernel that can
run on a single graphics card from any vendor, and that's incredibly doable.

This kernel should be able to run on x86-64 CPUs that were made in 2012 or later.
(This year may change as time moves on, mostly if there becomes a compelling
reason to discard support for CPUs that are, in the future, really old.)

Historically, it was also very difficult to compile a kernel with every
hardware module, because it would take FOREVER for it to compile. Nowadays,
medium-to-high-end CPUs can handle compilation of this (fairly challenging)
kernel quite nicely.

As of this writing (2024-02-24), this kernel takes about 40 minutes to build
on an AMD Ryzen 9 5950X (16-core, 32-thread) CPU.

#### Hardware Modules ####
I tend to enable any hardware drivers or hardware-related modules outright,
even if I have no idea what the hardware is. This maximizes compatibility for
the system, and reduces the chance that I need to recompile my kernel if I buy
some new USB dingus and plug it into my computer.

An exception to the above is when I _know_ what the hardware is about, and
I don't expect any machine that I, or my friends, own to EVER encounter
that hardware. This is why some of the supercomputer gear is disabled in my
kernel: this system is >99.9% likely to never run on such machines.

The above methodology _does_ result in large `/lib/modules` subfolders.
As of this writing, one kernel creates about 4GB worth of modules,
or about 2GB after on-disk compression. This will probably go up as we
travel forward into the future, but it has become small compared to available
storage solutions. Even as the memory-required-for-all-modules goes up,
the fraction it occupies on a system's available non-volatile memory will
become increasingly tiny (at least for desktops, laptops, and other reasonably
ergonomic computer systems).

Some other things to note about hardware modules:
* They are set build as externel modules (m) whenever possible, NOT as built-in modules (y).
* Externalizing hardware modules seems to make them more likely to _actually work_. I've encountered numerous situations where the system could not use a piece of hardware while the kernel module was built-in (y), but it worked _perfectly fine_ when the module was compiled as an external module (m).
* Externalizing modules allows userspace to use the `modprobe` and `rmmod` to turn them on/off and to reset them.
* Externalizing modules reduces kernel image size, and kernel memory usage (because unused modules do not need to be loaded into RAM).
* Optimization of kernel image size is NOT a goal of this kernel. However, the above strategy of "build them ALL!" tends to create gigabytes worth of modules, so placing most of that into `/lib/modules`, and loading it into RAM lazily, is actually very helpful.

#### Non-hardware Modules ####
Compared to hardware modules, it is not always as clear if non-hardware modules
should be compiled as built-ins (y) or as external modules (m).

I tend to build really commonly used algorithmic stuff as built-ins as a preference,
even when it is possible to build them as modules.

Some not-so-commonly used algorithmic stuff (ex: some crypto algos) will still
be externalized, to balance the trade-off between CPU use and kernel image size
(though the CPU gain is probably very mild, and having small kernel image size
is NOT a goal of this kernel).

Certain filesystems, like EXT4, BTRFS, and BCACHEFS, are going to be built
as built-ins, because this system is likely to encounter those at one point
or another, and possibly even boot from them. The option to boot from those
is available without having to recompile the kernel.

Other filesystems are compiled as modules, as filesystem code could be large
and extensive, while it isn't likely to benefit from being built into
the kernel's image.

#### Security and Performance ####
Another trend I've noticed is regarding security vs performance trade-offs,
and it seems to fall into a 90-10 rule:<br>
The last 10% of performance will cost 90% of the security,<br>
while the last 10% of security will cost 90% of the performance.

This is clearly a "lie for children" (I mean, there isn't really a single way
to quantify security), but there definitely seems to be a non-linear relationship
between these things. This kernel exploits that relationship by trying to find
a balance where we get 90% of the performance and 90% of the security,
at the mild expensive of being unable to hyperoptimize for either of those.

# Kernel Config Comments #

The kernel's configuration menu lacks the ability to maintain comments for each configuration option.

So instead, these comments shall be stored in this document, below.

## Chad Joan  2024-02-18 (6.4.12) ##

Kernel 6.4.12-gentoo

#### CONFIG_EXTRA_FIRMWARE=""
On my system, this previously contained a massive list of files from
`/lib/firmware` that had to be generated with a long pipe / script.

Although that allowed me to boot without an initramfs (which was AWESOME!),
it also sucked to get it working, and it sucked to keep having to
edit some kernel header to make some variable large enough so that
the kernel wouldn't fail to build due to too many firmware files.

So I grudgingly created an initramfs to hold all of the firmware.
Then I emptied `CONFIG_EXTRA_FIRMWARE`.

This is a pretty major change from previous kernel builds on this machine.
However, the system is being changed over to root-on-zfs due to storage
constraints driving the need for on-the-fly compression, as well as
backups being incredibly tedious without CoW snapshots. And that ZFS
setup requires having an initramfs. And with an initramfs, we may as
well switch to just having the firmware loaded through the initramfs
instead of trying to jump through hoops to get a giant `CONFIG_EXTRA_FIRMWARE`
value to build without error. (Also, firmware with spaces in its path
can't be loaded by `CONFIG_EXTRA_FIRMWARE` due to bullshit makefile limitations
regarding iteration over space-separated lists.)

#### CONFIG_NUMA_BALANCING=y
Enabled because it ... makes sense?
Most processors these days seem to meet the definition of NUMA.
Kernel config help text:
```
This option adds support for automatic NUMA aware memory/task placement.
The mechanism is quite primitive and is based on migrating memory when it has
references to the node the task is running on.

This system will be inactive on UMA systems.
```
#### CONFIG_SCHED_CORE=y
Enabled for similar reasons to the NUMA balancing one.
```
This option permits Core Scheduling, a means of coordinated task selection
across SMT siblings. When enabled -- see prctl(PR_SCHED_CORE) -- task selection
ensures that all SMT siblings will execute a task from the same 'core group',
forcing idle when no matching task is found.

Use of this feature includes: - mitigation of some (not all) SMT side channels; -
limiting SMT interference to improve determinism and/or performance.

SCHED_CORE is default disabled. When it is enabled and unused, which is the likely
usage by Linux distributions, there should be no measurable impact on performance.
```

#### CONFIG_HYPERVISOR_GUEST=y
Enabled because it is nice to be able to run a system on VMs.
I suspect that this option doesn't have any significant downside.

#### CONFIG_PVH=y
Seemed maybe useful when running as guest on a VM?

#### Misc virtualization options =y
Other virtualization-related modules/options that were enabled:
* `CONFIG_X86_EXTENDED_PLATFORM=y` (needed for `CONFIG_X86_VSMP=y`)
* `CONFIG_X86_VSMP=y` (needed for `CONFIG_KVM_GUEST=y`)
* `CONFIG_XEN=y` and `CONFIG_XEN_PVH=y`
* `CONFIG_XEN_VIRTIO=y`, `CONFIG_XEN_PVCALLS_FRONTEND=m`, `CONFIG_XEN_PVCALLS_BACKEND=m`,
* `CONFIG_XEN_GRANT_DMA_ALLOC=y`, `CONFIG_XEN_GNTDEV_DMABUF=m`, `CONFIG_XEN_SCSI_BACKEND=m`,
* `CONFIG_XEN_MCE_LOG=y`
* `CONFIG_INTEL_TDX_GUEST=y`
* `CONFIG_KVM_XEN=y`
* `CONFIG_HYPERV=m`, `CONFIG_HYPERV_UTILS=m`, and `CONFIG_HYPERV_BALLOON=m`
* `CONFIG_HYPERV_TIMER=y`
* `CONFIG_VHOST_SCSI=m`, `CONFIG_VHOST_VDPA=m`
* `CONFIG_TDX_GUEST_DRIVER=m`

#### CONFIG_HWSPINLOCK=y
Enabled. Documentation on this is sparse and I can't
find anything substantial on the internet with a quick search.
But given that it's a hardware thing (the `HW` in the name), it is probably
not going to have any disadvantage if we don't have the hardware for it.
(And if it did, the kernel docs would probably tell us.)

#### CONFIG_ENERGY_MODEL=y
Enabled because it looks like it could help with
power management and throttling.
Title is "Energy Model for devices with DVFS (CPUs, GPUs, etc)".
As much as it says "If in doubt, say N.", I wonder if that's just for
machines that don't have GPUs, or don't have DVFS. DVFS is "dynamic voltage and
frequency switching", which sounds like something even our CPUs would have.
https://developer.toradex.com/software/linux-resources/linux-features/cpu-frequency-and-dvfs-linux/

#### CONFIG_CPUFREQ_DT=m
Enabled as module. Similar argument to the above:<br>
Even thought it says "If in doubt, say N.", this can't hurt anything if it's
an unloaded module, but it can help if we have the appropriate hardware and
it gets loaded.

#### CONFIG_X86_PCC_CPUFREQ=m, CONFIG_X86_POWERNOW_K8=m, CONFIG_X86_AMD_FREQ_SENSITIVITY=m
Enabled. Same as CPUFREQ_DT above.

#### CONFIG_RSEQ=y
Enabled `CONFIG_RSEQ` because it makes it faster for processes to get current
CPU number, and because description says "If unsure, say Y."

#### CONFIG_PARAVIRT_SPINLOCKS=y
Enabled. Relevant description text:
```
[...]
It has a minimal impact on native kernels and gives a nice performance
benefit on paravirtualized KVM / Xen kernels.

If you are unsure how to answer this question, answer Y.
```

#### CONFIG_HIGH_RES_TIMERS=y
Enabled ... OH GOD why didn't I have this ON already?!
I mean, this is simply nice to have, because it allows programs to measure
time more precisely.
As it turns out, it's also a dependency for some virtualization stuff.
```
This option enables high resolution timer support. If your hardware is not
capable then this option only increases the size of the kernel image.
```

#### CONFIG_X86_CPU_RESCTRL=y
Enabled (x86 CPU resource control support) because
it sounds like it might help with CPU throttling:
https://forums.gentoo.org/viewtopic-t-1158039.html

#### CONFIG_SCHED_AUTOGROUP=y
Enabled `CONFIG_SCHED_AUTOGROUP` because it promises to help isolate desktop
workloads from other workloads (ex: build).

#### CONFIG_MICROCODE=y, CONFIG_MICROCODE_INTEL=y, CONFIG_MICROCODE_AMD=y
These are important for loading microcode patches released by Intel or AMD
for their CPUs. These basically fix bugs and security vulns in the CPU.
So it is important to be able to load these.

(Retrospective note: `CONFIG_MICROCODE_INTEL` and `CONFIG_MICROCODE_AMD`
seemed to have been removed sometime before the 6.7.5 kernel.)

#### CONFIG_KEXEC_JUMP=y
Enabled because it seems like it could help if I ever
get around to attaining kernel dumps and better kernel debug information in the
event of kernel panics. (Figuring out why a Linux system died has often been
a daunting process, unless we get lucky and find something in the logs. It'd
be nice to have more info when this happens... someday.)

#### CONFIG_X86_KERNEL_IBT=![n](https://via.placeholder.com/20x20/DfDfDf/Cf6060?text=n)
IBT="Indirect Branch Tracking"
Disabled for compatibility reasons:
https://bugs.launchpad.net/ubuntu/+source/linux/+bug/1980484
(It was already disabled, but I considered enabling it and decided not to.)
From Andrea Righi:
```
Enabling IBT in the kernel is going to be problematic at the moment, because
dkms' that have a precompiled binary need to be linked against non-IBT kernels
and IBT kernels (see nvidia drivers for example).

For this reason it's safer to keep IBT disabled at the moment, until all the
kernels will have IBT enabled and the kernel modules / binaries will use the
proper flags to generate IBT-compliant binaries.
```

**ERRATA**: I ended up re-enabling this one later (6.7.5 kernel)
because it is aligned with the way the rest of the system is compiled.
Also, nVidia seems to have fixed their IBT-incompatibility sometime since
this config description was written:
https://www.phoronix.com/news/NVIDIA-525.105.17-Linux
(Fixed in 530 series driver, and backported to 525 series.)

#### CONFIG_DEFERRED_STRUCT_PAGE_INIT=y
Enabled because it might help boot times:
https://lpc.events/event/17/contributions/1512/attachments/1256/2544/Fast%20Kernel%20Boot.pdf
`Biggest time: Initialization of struct pages (1.7 seconds – 40%)`
The PDF also mentions SMPBOOT, but not how to enable it.
There is a phoronix article that helps us with the latter:
https://www.phoronix.com/news/Parallel-CPU-Bringup-Linux-6.5
So it is apparently released in the 6.5 kernel and enabled using the
`cpuhp.parallel=` boot option or `CONFIG_HOTPLUG_PARALLEL=` config variable.
As of this writing, we're still on 6.4, so we'll have to wait for that goodness.

#### CONFIG_USERFAULTFD=n
Disabled for security reasons:
https://bugs.archlinux.org/task/62780
(It was already disabled, but I considered enabling it and decided not to.)

Relevant text from above source:
```
Generally userfaultfd is not particularly useful in real world, except maybe some stuff you gain in kvm.
So question is to weight risk vs. gain. my recommendation (which i advocated in the past as well) is that
its just better to not enable it as the real gain is very limited.

The problem with userfaultfd is that its an attack primitive used in kernel exploits to leverage use after
free bugs by being able to temporarily halt the kernel in order to exploit it.
An example demonstration of this primitive is CVE-2016-6187 by a nice writup from https://cyseclabs.com/blog/cve-2016-6187-heap-off-by-one-exploit
plus CVE-2016-4557 and others (just to name some).

Besides being an attack primitive to exploit other bugs, it itself has proven to be the source of several
privilege escalation, information disclosure, access restriction bypass and denial of service issues.
To name a few: CVE-2019-11599 CVE-2018-18397 CVE-2017-15126

so to summarize it: I don't believe this is a _really_ useful thing that a standard kernel should have as the gain is limited
(besides aiding exploitation) :p In fact this is the very reason this won't ever make it into linux-hardened and I
recommend the same for general purpose kernels.

-- Levente Polyak (anthraxx) - 2019-06-21, 18:06 GMT
```

There is other nice info in that thread, including possible workarounds
for not having this enabled. (Caveat: I haven't tried any of it.)

#### CONFIG_ANON_VMA_NAME=y
Enabled because it looks like it'd be a dependcy of other software packages,
and it also looks like it wouldn't hurt anything.
(Otherwise, there isn't a strong reason why this is being enabled.
It just _seems_ to be helpful.)

#### CONFIG_PER_VMA_LOCK=y
Enabled for two reasons:
* Better locking granularity usually makes things faster and less likely to hang.
* Emprical evidence found in this article: https://lwn.net/Articles/924572/

#### CONFIG_ZSWAP_ZPOOL_DEFAULT_ZBUD=n, CONFIG_ZSWAP_ZPOOL_DEFAULT_ZSMALLOC=y
Switch the default zswap allocator from `zbud` to `zsmalloc`. So:
`CONFIG_ZSWAP_ZPOOL_DEFAULT_ZBUD` -> `CONFIG_ZSWAP_ZPOOL_DEFAULT_ZSMALLOC`
The `zsmalloc` allocated might be better than both `zbud` and `z3fold`:
https://wiki.archlinux.org/title/zswap
```
In later kernels (after 6.3.arch1-1+) zsmalloc allocator was added.
It is supposed to work well under low memory conditions and it saves more memory.
```
But it is difficult to find any empirical evidence, or even strong+knowledgable
statements, that affirm this.

#### CONFIG_GCC_PLUGIN_STACKLEAK=y
Enabled because it improves security. Supposedly costs about 1% slowdown.

#### CONFIG_ZERO_CALL_USED_REGS=y
Enabled because it improves security.
Supposedly costs about 1% slowdown and (on x86) about 1% larger kernel size.

#### CONFIG_INIT_STACK_ALL_ZERO=y
Enable because it improves security.
I'm not sure what performance impact is. Initializing things is usually pretty
fast though, and most of our time spent waiting for things will be time spent
waiting for things that are NOT in the kernel.

#### CONFIG_RANDSTRUCT_PERFORMANCE=y
Enabled because it improves security.
It randomizes layout of sensitive kernel structures. This option is the
balance between performance and security.

## Chad Joan  2018-02-18 (6.5.5) ##

Kernel 6.5.5-gentoo

Just to make the changes in `/boot` less messy, and _especially_ to ensure
that I get a new set of kernel modules without overwriting the previous set,
I decided to merge a new kernel version and configure it before attempting
to make and install a new kernel. This means that the previous 6.4.12 binaries
should still have the configuration from BEFORE today (and the previous section
in this doc).

During `make oldconfig`, most options were set to 'm' (Module) if they were
hardware related, and otherwise, the default was used. This document only
covers the more noteworthy choices.

#### CACHESTAT_SYSCALL=y
Enabled because "If unsure say Y here."

#### CONFIG_ZSWAP_EXCLUSIVE_LOADS_DEFAULT_ON=y
Enabled because it seems like this would reduce memory usage signficantly.
The default was 'n', but if the CPU slowdown is small from this,
I'd rather avoid wasting a bunch of RAM.
(I really hope the algorithm isn't poor enough to allow pages to bounce
back and forth between normal RAM and zswap RAM repeatedly, as I would expect
it to evict things that are less frequently used or less recently used.)

#### CONFIG_VIDEO_CAMERA_SENSOR=y
Enabled because it enables more hardware options (and because cameras are useful and good).
This is "unsure -> Y", but felt noteworthy anyways.

#### CONFIG_SND_SEQ_UMP=y, SND_USB_AUDIO_MIDI_V2=y, CONFIG_SND_UMP_LEGACY_RAWMIDI=y
Enabled even though it defaults to 'n'.
This is required for ALSO to support MIDI 2.0.
Also `SND_USB_AUDIO_MIDI_V2` and `CONFIG_SND_UMP_LEGACY_RAWMIDI` (enabled).

#### CXL (Compute Express Link) modules (ex:&nbspCONFIG_CXL_BUS=m&nbsp;)
CXL (Compute Express Link) modules (ex: CONFIG_CXL_BUS) were set to 'm'
instead of 'y', because they seem hardware-related.

#### Various virtualization modules
I'd like the system to be prepared for virtualization, both as a guest and a host,
just in case that ever becomes useful (for me or anyone else). So there were
some miscellaneous virtualization modules that were enabled:
* `CONFIG_PCI_HYPERV=m`
* `CONFIG_DRM_HYPERV=m` as module, ditto.
* `CONFIG_FB_HYPERV=m` as module, ditto.
* `CONFIG_HYPERV_NET=m` as module, ditto.
* `CONFIG_HID_HYPERV_MOUSE=m` as module, ditto.
* `CONFIG_XEN_NETDEV_FRONTEND=m` as module, ditto.
* `CONFIG_XEN_NETDEV_BACKEND=m`	as module, ditto.
* `CONFIG_TCG_XEN=m` as module, ditto.
* `CONFIG_USB_XEN_HCD=m` as module, ditto.
* `CONFIG_DRM_XEN_FRONTEND=m` as module, ditto.
* `CONFIG_SND_XEN_FRONTEND=m` as module, ditto.
* `CONFIG_XEN_SCSI_FRONTEND=m` as module, ditto.
* `CONFIG_VMWARE_BALLOON=m` as module. It was probably disabled before.

#### Various hardware modules
* `CONFIG_SCSI_ENCLOSURE=m` as module. Not sure why it wasn't already.
* `CONFIG_OPEN_DICE=m` as module, because it's under devices and probably is hardware.
* `CONFIG_EEPROM_AT25=m` as module, ditto.
* `CONFIG_EEPROM_93CX6=m` as module, ditto.
* `CONFIG_V4L2_FLASH_LED_CLASS=m` as module, ditto.
* `CONFIG_SND_SERIAL_U16550=m` as module, ditto.
* `CONFIG_SND_MTPAV=m` as module, ditto.
* `CONFIG_IFB=m` as module, ditto.
* `CONFIG_MICROSOFT_MANA=m` as module, ditto.

#### CONFIG_HOTPLUG_PARALLEL=y
Confirmed that is set on the new kernel. (It was 'y' by default.)

#### CONFIG_X86_SGX=y, X86_SGX_KVM=y
SGX="Software Guard eXtensions"
Enabled because it sounds like it could be useful for security
whenever userspace programs make use of it. Also `CONFIG_X86_SGX_KVM`.

#### CONFIG_USB_CONFIGFS_F_TCM=y, CONFIG_USB_GADGET_TARGET=m
Enabled because they might be important for some USB compatibility?
I am not sure because the documentation is vague.

#### CONFIG_WATCH_QUEUE=y
Enabled because it sounds like something that some userspace program might depend on.

#### CONFIG_SFC=m, CONFIG_SFC_FALCON=m, CONFIG_SFC_SIENA=m
Modularized the Solarflare modules. (They were 'y' before.)
I don't _think_ it matters whether these are modules or not, but there are times
when hardware driver modules need to be externalized to work correctly, and
being able to `modprobe` and `rmmod` is helpful. (Externalizing modules
also shrinks the kernel image size to have more things as modules, though
that isn't a priority in this kernel.)

#### CONFIG_LOCALVERSION=".2024-02-18.2115"
This is part of a new practice I am adopting that allows me to avoid boot
failures that can happen when a kernel is overwritten by a newly compiled
kernel of the same version.

When rebuilding the kernel, the kernel's `make` helpfully provides `.old`
versions, but trying to boot them might not work because the modules in
`/lib/modules` will be built for the new kernel, and the old kernel's modules
won't exist anymore. If the new kernel doesn't work for any other reason,
and the newly built modules aren't backwards compatible for the old kernel,
then the system WILL fail to boot. Also, any incidental rebuilds of the latest
reconfiguration will overwrite the `.old` kernels, thus defeating that safety
mechanism entirely.

As it turns out, setting `CONFIG_LOCALVERSION` to some non-empty value will
cause the kernel to have its own unique `/lib/modules/<kernel-name>` entry.

It also provides a way to explicitly create a new kernel image, and compile
it multiple times (minor revisions), without overwriting kernels from previous
sessions of kernel-related work. This works because the new kernel's image
files will have a new suffix (".2024-02-18.2115", in this case), and
the previous kernel will have an earlier suffix (ex: ".2023-08-08.1616").

From now on, I intend to set `CONFIG_LOCALVERSION` to the current timestamp
whenever doing full builds of the kernel. This allows rollback to earlier
kernel builds without having done a kernel version bump. As a nice bonus,
it becomes easier to rename things and massage symlinks in the `/boot`
directory because the timestamp will be already added to the files, so
I won't have to do that by hand when storing the working kernel files.

## Chad Joan  2024-02-19 (6.7.5) ##

Kernel 6.7.5

Well, the 6.5.5 kernel was a success. (The Grub ZFS implementation, not so much.)

6.7.5 has support for bcachefs, which is quite desirable (at least at
an experimental or early-adopter level). So we're moving right on to that.

#### CONFIG_X86_USER_SHADOW_STACK=n
Disabled as suggested by `make oldconfig`.
This feature mitigates ROP attacks, but sounds like it might cause
compatibility issues on CPUs before about 2020. That is not good for this
system's use-case, so we'll have to come back to this one (a lot) later.

#### CONFIG_INTEL_TDX_HOST=y
Enabled in spite of it being 'n' by default.
Although info is sparse, there don't seem to be any caveats to this
(other than it might make VMs run slower by some unspecified amount).

#### CONFIG_RANDOM_KMALLOC_CACHES=y
Enabled in spite of 'n' by default.
It sounds like any performance hit this could cause will be minor,
because the implementation is "performance friendly":
https://sam4k.com/exploring-linux-random-kmalloc-caches/

#### CONFIG_TCP_AO=y
Enabled in spite of 'n' by default.
Seems security related and also probably has few or no downsides.

#### CONFIG_PCI_DYNAMIC_OF_NODES=y
Enabled in spite of 'n'.
Actually looks kinda cool, if anyone on this system ever needs it:
https://patchwork.ozlabs.org/project/devicetree-bindings/cover/1690564018-11142-1-git-send-email-lizhi.hou@amd.com/#3163353

#### CONFIG_NVME_TCP_TLS=y
Enabled in spite of 'n'.
It provides security. I imagine the only cost is the additional complexity
in the kernel binary. Meh. Would rather have more features/security.

#### CONFIG_NVME_HOST_AUTH=y
Same reasons as `CONFIG_NVME_TCP_TLS` above.

#### NVME_TARGET_TCP_TLS=y
Same reasons as `CONFIG_NVME_TCP_TLS` above.

#### CONFIG_NETCONSOLE_EXTENDED_LOG=y
Looks like it will add something to the kernel's log messages, though what,
exactly, is vague. At any rate, I'm curious and want to see what it does.
We can always go back and disable this if it sucks.

(Retrospective: After booting the kernel (2024-02-24, 06:46), the log messages
seem to be fine. They kinda just look like they did before. Perhaps this feature
will come into play if there is an error, or some message that is more interesting.)

#### CONFIG_USB_CONFIGFS_F_MIDI2=y
Enabled in spite of 'n', because why not have MIDI 2.0.

#### CONFIG_XEN_PRIVCMD_EVENTFD=y
Enabled in spite of 'n', because feature
description is vague. Hopefully it is pretty safe and the kernel devs are
just default it to 'n' to save a few kB or something.

#### CONFIG_BCACHEFS_FS=y
Enabled. (In spite of 'n', of course.)
This is the bcachefs we've been waiting for!
I'm setting it as 'y' and not module, because it might need to be built into
the kernel in order to boot from it directly.

#### CONFIG_EROFS_FS_ZIP_DEFLATE=y
Enabled in spite of 'n'.
Even though this is "experimental", I'd rather not have to remember to
enable it in the future. In the meantime, I am super unlikely to
encounter any EROFS instances.

#### CONFIG_LIST_HARDENED=y
Enabled in spite of 'n'.
This seems like the kind of thing that would lead to better crash reports.
I am willing to sacrifice a little performance for that.

(Of course there were other config changes to make. Those were typically
set to the default, with the usual exceptions: all hardware options get
compiled as module. There might have been a few other features that were
enabled in spite of 'n' defaults, just because they seemed to have very
little downsides.)

### After oldconfig: ###

#### CONFIG_X86_KERNEL_IBT=y
IBT="Indirect Branch Tracking"

Enabled because the whole system will be compiled with it (well, CET specifically).

As for the downside of being unable to use precompiled kernel modules
like proprietary nvidia drivers: nVidia seems to have fixed their
IBT-incompatibility sometime since this config description was written:
https://www.phoronix.com/news/NVIDIA-525.105.17-Linux
(Fixed in 530 series driver, and backported to 525 series.)

#### CONFIG_CRAMFS=m
Enabled because why not. (CRAM FS = Compressed ROM File System)

#### CONFIG_JBD2_DEBUG=y
Enabled because it is off by default, but can be enabled
at runtime to provide debug info for ext4 filesystems.

#### CONFIG_XFS_ONLINE_REPAIR=y, and others
Enabled various XFS features. Some of them are experimental, but only become
(potentially) a problem if they are actually _used_.

#### CONFIG_REISERFS_PROC_INFO=y
Enabled because it provides optional debug/trace info and only costs 8kB
in the kernel plus some memory on each mount.
(Sounds pretty cheap on modern machines? Eh why not.)

#### CONFIG_GFS2_FS_LOCKING_DLM=y
Enabled because why not. (Only costs if used: parent option is external module: `CONFIG_GFS2_FS=m`)

#### CONFIG_FS_DAX=y
Enabled ecause it only costs 5kB and gives us a... whatever this is.

#### CONFIG_FS_VERITY=y, CONFIG_FS_VERITY_BUILTIN_SIGNATURES=y
Enabled because why not. (No downsides?)

#### CONFIG_QFMT_V1=m, CONFIG_QFMT_V2=m
Enabled. I do not know what these do, but they are modules, so cost almost nothing if unused.

#### CONFIG_OVERLAY_FS_INDEX=y
It says "If unsure, say N."
Also this:
```
Note, that the inodes index feature is not backward compatible
That is, mounting an overlay which has an inodes index on a
that doesn't support this feature will have unexpected results.
```
Enabled anyways because it can be turned off at runtime.

#### CONFIG_AUTOFS_FS=m, CONFIG_FUSE_FS=m
Change 'y' to 'm' for `CONFIG_AUTOFS_FS` and `CONFIG_FUSE_FS`.
Yeah this might shrink the kernel a little (cool?), but mostly it makes things
more likely to work.

#### CONFIG_NETFS_STATS=y
It provides debugging info AND is recommended 'y'.
(This is another "ugh why didn't I already have this enabled?!" one.)

#### CONFIG_FSCACHE=m
Enabled `CONFIG_FSCACHE` and its debugging submodules.
It's a module (low/no cost if not in use) and its debugging options are also
only in effect if they are enabled at runtime.

#### CONFIG_CACHEFILES=m
Enabled `CONFIG_CACHEFILES`. It allows a local filesystem to be used as a cache
for a remote filesystem (e.g. NFS), which sounds pretty interesting.

#### CONFIG_ZISOFS=y
It's a CD-ROM decompression thingie.

#### CONFIG_NTFS_DEBUG=y
Only costs if it's turned on at boot/run-time.

#### CONFIG_ECRYPT_FS=m

#### CONFIG_UBIFS_FS=m
"UBIFS is a file system for flash devices which works on top of UBI."

#### CONFIG_VBOXSF_FS=m
Enabled because maybe useful for virtualization.

#### CONFIG_BLK_DEV_ZONED=y
Enabled because there are no stated downsides, so why not have a thing.

#### CONFIG_BLK_WBT=y
Enabled write-back throttling. No downside? (none mentioned) May as well.

#### CONFIG_BLK_SED_OPAL=y
Enabled because there are no stated downsides, so why not have a thing.

#### CONFIG_BLK_INLINE_ENCRYPTION=y
Allows using hardware encryption on block devices that have it.

#### Enabled various options for partition reading.
(Still left out some extremely obscure ones.)
These are the ones found under this path:<br>
`Enable the block layer -> Paritition Types -> ...`

#### CONFIG_BPF_SYSCALL=y, CONFIG_BPF_JIT=y, etc
Enabled various BPF stuff under "General Setup".

#### CONFIG_UCLAMP_TASK=y, CONFIG_UCLAMP_TASK_GROUP=y
Some kind of prioritization for CPU usage of tasks.
Sounds useful, but a bit cryptic. Enabling it just to make it easier to play with
if I ever need it. (Also enabled `CONFIG_UCLAMP_TASK_GROUP`, seems related.)

#### CONFIG_KEXEC_FILE=y
Enabled `CONFIG_KEXEC_FILE` because it might help with kernel crash handling someday.

#### CONFIG_CGROUP_FAVOR_DYNMODS=n
Leaving `CONFIG_CGROUP_FAVOR_DYNMODS` off, because it slows down things that are used a lot (process fork+exit).

#### CONFIG_BLK_DEV_THROTTLING=y
Enabled because it offers more granular control over IO.

#### CONFIG_BLK_DEV_THROTTLING_LOW=y
Enabled for same reason.<br>
It's experimental, so I just won't use it for now.<br>
But the kernel will remember my choice for later.

#### CONFIG_BFQ_GROUP_IOSCHED=y, CONFIG_BLK_CGROUP_IOLATENCY=y
(Enabled by default after other options were enabled.)

#### Other CGROUP and I/O Scheduling:
* `CONFIG_BLK_CGROUP_FC_APPID=y`. Probably unneeded, but does it really hurt anything?
* `CONFIG_BLK_CGROUP_IOCOST=y`. More IO throttling/control maybe.
* `CONFIG_BLK_CGROUP_IOPRIO=y`. Ditto.
* `CONFIG_CGROUP_PIDS=y` because no downside? (Allows limiting/allocating process IDs.)
* `CONFIG_CGROUP_RDMA=y` because no downside?
* `CONFIG_CGROUP_FREEZER=y` makes it possible to freeze all tasks in a cgroup.
* `CONFIG_CGROUP_HUGETLB=y` because no downside?
* `CONFIG_CPUSETS=y`. Looks like an ability to manually allocate individual cores on an SMP/NUMA machine.
* `CONFIG_CGROUP_DEVICE=y` because why not?
* `CONFIG_CGROUP_CPUACCT=y`. Way to monitor CPU usage of things.
* `CONFIG_CGROUP_PERF=y` because why not?
* `CONFIG_CGROUP_BPF=y` because why not?
* `CONFIG_CGROUP_MISC=y` because why not?

#### CONFIG_CORE_DUMP_DEFAULT_ELF_HEADERS=y
It is incompatible with GDB versions <=6.7.<br>
At time of writing, GDB installed is 13.2-r1.<br>
I think we'll be fine.

#### CONFIG_BINFMT_MISC=y
Enabled because recommended 'y'.

#### Netwoking options
* `CONFIG_MAC80211_MESH` because why not?
* `CONFIG_CFG80211_CRDA_SUPPORT`. This is really supposed to be 'y'. Oops?
* `CONFIG_MCTP` because why not?
* `CONFIG_AF_KCM` because why not?
* `CONFIG_XDP_SOCKETS` because why not?
* `CONFIG_IP_ADVANCED_ROUTER` (and related options) in case this thing ever needs to do routing.
* `CONFIG_NET_IPVTI`. Routing/VM related stuff?
* `CONFIG_IP_VS`. Ditto. (Also enabled almost all sub-options, usually modules.)
* `CONFIG_TCP_CONG_ADVANCED`. Congestion control. But didn't config the suboptions.
* `CONFIG_NETLABEL` sounds useful for compatibility reasons.
* `CONFIG_BPFILTER` I think this makes BPF stuff available for networking.
* Enabled more options under `CONFIG_BRIDGE_NF_EBTABLES`. Switched a few 'y' to 'm'.
* Enabled a bunch of other networking+routing related options. Usually 'm'.

## Chad Joan  2024-02-22  (6.7.5 cont.) ##

#### CONFIG_UHID
Enabled `CONFIG_UHID` because it was required by `net-wireless/bluez-5.70-r1`.

#### CONFIG_BOOTTIME_TRACING=y. CONFIG_FUNCTION_TRACER=y, CONFIG_FUNCTION_GRAPH_RETVAL=y, CONFIG_FTRACE_SYSCALLS=y
Some of this was originally aimed at getting `CONFIG_DYNAMIC_FTRACE_WITH_DIRECT_CALLS`
to be enabled so that `CONFIG_HID_BPF` could be enabled too.<br>
But it also seems useful to have these things. They seem like the kind of thing
that takes some extra memory at worse, and maybe a small amount of runtime overhead,
and really only take significant overhead if turned on at boot-time or run-time.
So we may as well build them into the kernel, and leave the option open to use
these in the future without having to do a kernel recompile in the future to get them.

#### CONFIG_FUNCTION_GRAPH_TRACER=y
Enabled by default with `CONFIG_FUNCTION_TRACER=y`.

#### CONFIG_DYNAMIC_FTRACE=y
Enabled by default with `CONFIG_FUNCTION_TRACER=y`

#### CONFIG_STACK_TRACER=y
Enabled because it probably has no cost until turned on at runtime.
"This special tracer records the maximum stack footprint of the kernel and displays it in /sys/kernel/tracing/stack_trace."
Can be enabled at boot-time by passing the `stacktrace` option,
or at run-time by using `sysctl kernel.stack_tracer_enabled`.

#### CONFIG_IRQSOFF_TRACER=y, CONFIG_PREEMPT_TRACER=y
Enabled because they probably have no cost until turned on at runtime.
Both are enabled by this command:
```
echo 0 > /sys/kernel/tracing/tracing_max_latency
```

#### CONFIG_TRACER_SNAPSHOT=y, CONFIG_TRACER_SNAPSHOT_PER_CPU_SWAP=y
The above two (`CONFIG_IRQSOFF_TRACER` and `CONFIG_PREEMPT_TRACER`) also seem to
pull in `CONFIG_TRACER_SNAPSHOT` and `CONFIG_TRACER_SNAPSHOT_PER_CPU_SWAP`,
which are enabled by these commands:
```
echo 1 > /sys/kernel/tracing/snapshot
echo 1 > /sys/kernel/tracing/per_cpu/cpu2/snapshot
```

#### CONFIG_DEBUG_KOBJECT=n
Leaving this disabled.
"If you say Y here, some extra kobject debugging messages will be sent to the syslog."
Sounds innocuous, right?
Nah!
https://bugzilla.redhat.com/show_bug.cgi?id=513606
```
Enabling this causes massive spew of debug messages to the kernel log.
Looks like it will have to be disabled even in debug kernels.
-- Chuck Ebbert 2009-07-27 13:02:30 UTC
```
And, of course, for anyone looking for a bit of good schadenfreude,
here is another comment:
```
This is MADNESS. Seriously, Amit, what were you thinking?
Pete Zaitcev 2009-07-31 18:43:42 UTC
```
FWIW, I suspect the banter is tongue-in-cheek. I hope. <3

#### CONFIG_TRACE_EVAL_MAP_FILE=y
Hard to precisely understand the documentation, but it looks like it makes it
more likely that kernel debug info will include enum/sizeof names. Good.
Only downside is that this metadata doesn't get freed after bootup or
module load, so it increases the memory footprint of the kernel.
(But on modern systems, I doubt a bunch of variable names will be significant
compared to the amount of RAM required to reasonably use browsers these days.)

#### CONFIG_DYNAMIC_FTRACE_WITH_DIRECT_CALLS=y
Some combination of the above tracer options enables this option,
which then allows us to enable `CONFIG_HID_BPF`.

#### CONFIG_HID_BPF=y
```
This option allows to support eBPF programs on the HID subsystem.
eBPF programs can fix HID devices in a lighter way than a full
kernel patch and allow a lot more flexibility.
```
Maybe useful for some hardware? Falls in to the
"better to have it and not need it, than to need it and not have it" category.

#### CONFIG_SCHED_TRACER=y
The below reference describes how this is used, and that usage suggests that
even if this module is built, it will be off by default. It needs to be
turned on with a command like `echo 1 > /sys/kernel/debug/tracing/tracing_enabled`.
This is possibly VERY useful for checking in on the kernel scheduler, as it measures
scheduling latencies! More info here, including how to use it:
https://hugh712.gitbooks.io/embeddedsystem/content/RT_debug.html#scheduling-latency-tracer

#### CONFIG_FUNCTION_PROFILER=y
Enabled despite "If in doubt, say N."
It doesn't seem to do anything unless explicitly enabled. Kernel help actually says it well:
```
This option enables the kernel function profiler. A file is created
in debugfs called function_profile_enabled which defaults to zero.
When a 1 is echoed into this file profiling begins, and when a
zero is entered, profiling stops. A "functions" file is created in
the trace_stat directory; this file shows the list of functions that
have been hit and their counters.
```

#### CONFIG_DEBUG_CLOSURES=y
Enabled because it is related to bcache (maybe useful for debuggin bcachefs?).
```
Keeps all active closures in a linked list and provides a debugfs
interface to list them, which makes it possible to see asynchronous
operations that get stuck.
```

#### CONFIG_DEBUG_PAGE_REF=y
```
[...]
Be careful when enabling this feature because it adds about 30 KB to the
kernel code.  However the runtime performance overhead is virtually
nil until the tracepoints are actually enabled.
```
30kB is nothing, and if it doesn't affect runtime overhead, the heck yeah,
let's add a maybe useful feature.

#### CONFIG_PAGE_OWNER=y
Disabled by default, and only causes overhead if enabled at boot, so yeah why not.
```
This keeps track of what call chain is the owner of a page, may
help to find bare alloc_page(s) leaks. Even if you include this
feature on your build, it is disabled in default. You should pass
"page_owner=on" to boot parameter in order to enable it. Eats
a fair amount of memory if enabled. See tools/mm/page_owner_sort.c
for user-space helper.
```

#### CONFIG_PAGE_EXTENSION=y
The above also forced this option to be enabled.
I'm not entirely sure what this means, but it at least doesn't mention any caveats.
```
Extend memmap on extra space for more information on page. This
could be used for debugging features that need to insert extra
field for every page. This extension enables us to save memory
by not allocating this extra memory according to boottime
configuration.
```

#### CONFIG_HEADERS_INSTALL=y
This might be a bad idea because Gentoo already provides `sys-kernel/linux-headers`,
but I'm not sure if that includes UAPI headers, or if those are useful for
some programs. Going to enable it and "Find Out".
Looks possibly handy for whoever might use it:
https://www.kernel.org/doc/html/v4.14/doc-guide/parse-headers.html

#### CONFIG_DYNAMIC_DEBUG=y, implies CONFIG_DYNAMIC_DEBUG_CORE=y
Looks like it might give more info in debug messages? Good?
"enlarges the kernel text size by about 2%"
(Probably insignificant on modern desktop+laptop systems.)

#### CONFIG_NTB=m, CONFIG_NTB_MSI=m, etc
"Non-Transparent Bridge support" (under Device Drivers)
```The PCI-E Non-transparent bridge hardware is a point-to-point PCI-E bus connecting 2 systems.```
Sounds cool, why not. Also enabled `CONFIG_NTB_MSI` and all other sub-options as modules.

#### CONFIG_LOCALVERSION=".2024-02-22.1315"

