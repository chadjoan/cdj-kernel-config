### Chad Joan  2024-02-18 (6.4.12) ###

Kernel 6.4.12-gentoo

Emptied the `CONFIG_EXTRA_FIRMWARE` config variable.
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

Enabled `CONFIG_NUMA_BALANCING` because it ... makes sense?
Most processors these days seem to meet the definition of NUMA.
Kernel config help text:
```
This option adds support for automatic NUMA aware memory/task placement.
The mechanism is quite primitive and is based on migrating memory when it has
references to the node the task is running on.

This system will be inactive on UMA systems.
```

Enabled `CONFIG_SCHED_CORE` for similar reasons to the NUMA balancing one.
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

Enabled `CONFIG_HYPERVISOR_GUEST` because it is nice to be able to run a system
on VMs. I suspect that this option doesn't have any significant downside.

Enabled `CONFIG_PVH`; seemed maybe useful when running as guest?

Other virtualization-related modules/options that were enabled:
* `CONFIG_X86_EXTENDED_PLATFORM` (needed for `CONFIG_X86_VSMP`)
* `CONFIG_X86_VSMP` (needed for `CONFIG_KVM_GUEST`)
* `CONFIG_XEN` and `CONFIG_XEN_PVH`
* `CONFIG_XEN_VIRTIO`, `CONFIG_XEN_PVCALLS_FRONTEND`, `CONFIG_XEN_PVCALLS_BACKEND`,
* `CONFIG_XEN_GRANT_DMA_ALLOC`, `CONFIG_XEN_GNTDEV_DMABUF`, `CONFIG_XEN_SCSI_BACKEND`,
* `CONFIG_XEN_MCE_LOG`
* `CONFIG_INTEL_TDX_GUEST`
* `CONFIG_KVM_XEN`
* `CONFIG_HYPERV`, `CONFIG_HYPERV_UTILS`, and `CONFIG_HYPERV_BALLOON`
* `CONFIG_VHOST_SCSI`, `CONFIG_VHOST_VDPA`
* `CONFIG_TDX_GUEST_DRIVER`

Enabled `CONFIG_HWSPINLOCK`. Documentation on this is sparse and I can't
find anything substantial on the internet with a quick search.
But given that it's a hardware thing (the `HW` in the name), it is probably
not going to have any disadvantage if we don't have the hardware for it.
(And if it did, the kernel docs would probably tell us.)

Enabled `CONFIG_ENERGY_MODEL` because it looks like it could help with
power management and throttling.
Title is "Energy Model for devices with DVFS (CPUs, GPUs, etc)".
As much as it says "If in doubt, say N.", I wonder if that's just for
machines that don't have GPUs, or don't have DVFS. DVFS is "dynamic voltage and
frequency switching", which sounds like something even our CPUs would have.
https://developer.toradex.com/software/linux-resources/linux-features/cpu-frequency-and-dvfs-linux/

Enabled `CONFIG_CPUFREQ_DT` as module. Similar argument to the above:
even thought it says "If in doubt, say N.", this can't hurt anything if it's
an unloaded module, but it can help if we have the appropriate hardware and
it gets loaded.

Enabled `CONFIG_X86_PCC_CPUFREQ`, `CONFIG_X86_POWERNOW_K8`, `CONFIG_X86_AMD_FREQ_SENSITIVITY`.
Ditto, same as CPUFREQ_DT above.

Enabled `CONFIG_RSEQ` because it makes it faster for processes to get current
CPU number, and because description says "If unsure, say Y."

Enabled `CONFIG_PARAVIRT_SPINLOCKS`:
```
[...]
It has a minimal impact on native kernels and gives a nice performance
benefit on paravirtualized KVM / Xen kernels.

If you are unsure how to answer this question, answer Y.
```

Enabled `CONFIG_HIGH_RES_TIMERS` ... OH GOD why didn't I have this ON already?!
I mean, this is simply nice to have, because it allows programs to measure
time more precisely.
As it turns out, it's also a dependency for some virtualization stuff.
```
This option enables high resolution timer support. If your hardware is not
capable then this option only increases the size of the kernel image.
```

Enabled `CONFIG_X86_CPU_RESCTRL` (x86 CPU resource control support) because
it sounds like it might help with CPU throttling:
https://forums.gentoo.org/viewtopic-t-1158039.html

Enabled `CONFIG_SCHED_AUTOGROUP` because it promises to help isolate desktop
workloads from other workloads (ex: build).

Enabled `CONFIG_MICROCODE`, `CONFIG_MICROCODE_INTEL`, and `CONFIG_MICROCODE_AMD`:
These are important for loading microcode patches released by Intel or AMD
for their CPUs. These basically fix bugs and security vulns in the CPU.
So it is important to be able to load these.

Enabled `CONFIG_KEXEC_JUMP` because it seems like it could help if I ever
get around to attaining kernel dumps and better kernel debug information in the
event of kernel panics. (Figuring out why a Linux system died has often been
a daunting process, unless we get lucky and find something in the logs. It'd
be nice to have more info when this happens... someday.)

Disabled `CONFIG_X86_KERNEL_IBT` for compatibility reasons:
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

Enabled `CONFIG_DEFERRED_STRUCT_PAGE_INIT` because it might help boot times:
https://lpc.events/event/17/contributions/1512/attachments/1256/2544/Fast%20Kernel%20Boot.pdf
`Biggest time: Initialization of struct pages (1.7 seconds – 40%)`
The PDF also mentions SMPBOOT, but not how to enable it.
There is a phoronix article that helps us with the latter:
https://www.phoronix.com/news/Parallel-CPU-Bringup-Linux-6.5
So it is apparently released in the 6.5 kernel and enabled using the
`cpuhp.parallel=` boot option or `CONFIG_HOTPLUG_PARALLEL=` config variable.
As of this writing, we're still on 6.4, so we'll have to wait for that goodness.

Disabled `CONFIG_USERFAULTFD` for security reasons:
https://bugs.archlinux.org/task/62780
(It was already disabled, but I considered enabling it and decided not to.)

Enabled `CONFIG_ANON_VMA_NAME` because it looks like it'd be a dependcy of
other software packages, and it also looks like it wouldn't hurt anything.
(Otherwise, there isn't a strong reason why this is being enabled.
It just _seems_ to be helpful.)

Enabled `CONFIG_PER_VMA_LOCK` for two reasons:
* Better locking granularity usually makes things faster and less likely to hang.
* Emprical evidence found in this article: https://lwn.net/Articles/924572/

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

Enable `CONFIG_GCC_PLUGIN_STACKLEAK` because it improves security.
Supposedly costs about 1% slowdown.

Enable `CONFIG_ZERO_CALL_USED_REGS` because it improves security.
Supposedly costs about 1% slowdown and (on x86) about 1% larger kernel size.

Enable `CONFIG_INIT_STACK_ALL_ZERO` because it improves security.
Not sure what performance impact is. Initializing things is usually pretty fast
though, and most of our time spent waiting for things will be time spent
waiting for things that are NOT in the kernel.

Enable `CONFIG_RANDSTRUCT_PERFORMANCE` because it improves security.
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

Enabled `CACHESTAT_SYSCALL` because "If unsure say Y here."

Enabled `CONFIG_ZSWAP_EXCLUSIVE_LOADS_DEFAULT_ON` because it seems like this
would reduce memory usage. The default was 'n', but if the CPU slowdown is
small from this, I'd rather avoid wasting precious memory.
(I really hope the algorithm isn't poor enough to allow pages to bounce
back and forth between normal RAM and zswap RAM repeatedly, as I would expect
it to evict things that are less frequently used or less recently used.)

Enabled `CONFIG_VIDEO_CAMERA_SENSOR` because it enables more hardware
options (and because cameras are useful and good). This is "unsure -> Y",
but felt noteworth anyways.

Enabled `CONFIG_SND_SEQ_UMP` even though it defaults to 'n'.
This is required for ALSO to support MIDI 2.0.
Also `SND_USB_AUDIO_MIDI_V2` and `CONFIG_SND_UMP_LEGACY_RAWMIDI` (enabled).

During `make oldconfig`, most options were set to 'm' (Module) if they were
hardware related, and otherwise, the default was used.

CXL (Compute Express Link) modules (ex: CONFIG_CXL_BUS) were set to 'm'
instead of 'y', because they seem hardware-related.

Enabled `CONFIG_PCI_HYPERV` as module, because it seems useful for virtualization.
Enabled `CONFIG_DRM_HYPERV` as module, ditto.
Enabled `CONFIG_FB_HYPERV` as module, ditto.
Enabled `CONFIG_HYPERV_NET` as module, ditto.
Enabled `CONFIG_HID_HYPERV_MOUSE` as module, ditto.
Enabled `CONFIG_XEN_NETDEV_FRONTEND` as module, ditto.
Enabled `CONFIG_XEN_NETDEV_BACKEND`	as module, ditto.
Enabled `CONFIG_TCG_XEN` as module, ditto.
Enabled `CONFIG_USB_XEN_HCD` as module, ditto.
Enabled `CONFIG_DRM_XEN_FRONTEND` as module, ditto.
Enabled `CONFIG_SND_XEN_FRONTEND` as module, ditto.
Enabled `CONFIG_XEN_SCSI_FRONTEND` as module, ditto.
Enabled `CONFIG_SCSI_ENCLOSURE` as module. Not sure why it wasn't already.
Enabled `CONFIG_VMWARE_BALLOON` as module. It was probably disabled before.
Enabled `CONFIG_OPEN_DICE` as module, because it's under devices and probably is hardware.
Enabled `CONFIG_EEPROM_AT25` as module, ditto.
Enabled `CONFIG_EEPROM_93CX6` as module, ditto.
Enabled `CONFIG_V4L2_FLASH_LED_CLASS` as module, ditto.
Enabled `CONFIG_SND_SERIAL_U16550` as module, ditto.
Enabled `CONFIG_SND_MTPAV` as module, ditto.
Enabled `CONFIG_IFB` as module, ditto.
Enabled `CONFIG_MICROSOFT_MANA` as module, ditto.

Confirmed that `CONFIG_HOTPLUG_PARALLEL` is set on the new kernel. (It was 'y' by default.)

Enabled `CONFIG_X86_SGX` because it sounds like it could be useful for security
whenever userspace programs make use of it. Also `CONFIG_X86_SGX_KVM`.

Enabled `CONFIG_USB_CONFIGFS_F_TCM` and `CONFIG_USB_GADGET_TARGET` because they
might be important for some USB compatibility? I am not sure because the documentation is vague.

Enabled `CONFIG_WATCH_QUEUE` because it sounds like something that some userspace
program might depend on.

Modularized the Solarflare modules. (They were 'y' before.)

Set `CONFIG_LOCALVERSION` to `.2024-02-18.2115` because it causes the kernel
to have its own unique `/lib/modules/<kernel-name>` entry. From now on,
I intend to set `CONFIG_LOCALVERSION` to the current timestamp whenever
doing full builds of the kernel. This allows rollback to earlier kernel
builds without having done a kernel version bump. As a nice bonus, it makes
it easier to rename things and massage symlinks in the `/boot` directory
because the timestamp will be already added to the files, so I won't have
to do that by hand when storing the working kernel files.

## Chad Joan  2024-02-19 (6.7.5) ##

Kernel 6.7.5

Well, the 6.5.5 kernel was a success. (The Grub ZFS implementation, not so much.)

6.7.5 has support for bcachefs, which is quite desirable (at least at
an experimental or early-adopter level). So we're moving right on to that.

Disabled `CONFIG_X86_USER_SHADOW_STACK`, as suggested by make oldconfig.
This feature mitigates ROP attacks, but sounds like it might cause
compatibility issues on CPUs before about 2020. That is not good for this
system's use-case, so we'll have to come back to this one (a lot) later.

Enabled `CONFIG_INTEL_TDX_HOST` in spite of it being 'n' by default.
Although info is sparse, there don't seem to be any caveats to this
(other than it might make VMs run slower by some unspecified amount).

Enabled `CONFIG_RANDOM_KMALLOC_CACHES` in spite of 'n' by default.
It sounds like any performance hit this could cause will be minor,
because the implementation is "performance friendly":
https://sam4k.com/exploring-linux-random-kmalloc-caches/

Enabled `CONFIG_TCP_AO` in spite of 'n'. Seems security related and also
probably has few or no downsides.

Enabled `CONFIG_PCI_DYNAMIC_OF_NODES` in spite of 'n'.
Actually looks kinda cool, if anyone on this system ever needs it:
https://patchwork.ozlabs.org/project/devicetree-bindings/cover/1690564018-11142-1-git-send-email-lizhi.hou@amd.com/#3163353

Enabled `CONFIG_NVME_TCP_TLS` in spite of 'n'.
It provides security. I imagine the only cost is the additional complexity
in the kernel binary. Meh. Would rather have more features.

Enabled `CONFIG_NVME_HOST_AUTH`, ditto.
Enabled `NVME_TARGET_TCP_TLS`, ditto.

Enabled `CONFIG_NETCONSOLE_EXTENDED_LOG`. Looks like it will add something
to the kernel's log messages, though what, exactly, is vague.
At any rate, I'm curious and want to see what it does. We can always
go back and disable this if it sucks.

Enabled `CONFIG_USB_CONFIGFS_F_MIDI2` in spite of 'n', because why not have MIDI 2.0.

Enabled `CONFIG_XEN_PRIVCMD_EVENTFD` in spite of 'n', because feature
description is vague. Hopefully it is pretty safe and the kernel devs are
just default it to 'n' to save a few kB or something.

Enabled `CONFIG_BCACHEFS_FS` as 'y'. (In spite of 'n', of course.)
This is the bcachefs we've been waiting for!
I'm setting it as 'y' and not module, because it might need to be built into
the kernel in order to boot from it directly.

Enabled `CONFIG_EROFS_FS_ZIP_DEFLATE` in spite of 'n'.
Even though this is "experimental", I'd rather not have to remember to
enable it in the future. In the meantime, I am super unlikely to
encounter any EROFS instances.

Enabled `CONFIG_LIST_HARDENED` in spite of 'n'.
This seems like the kind of thing that would lead to better crash reports.
I am willing to sacrifice a little performance for that.

(Of course there were other config changes to make. Those were typically
set to the default, with the usual exceptions: all hardware options get
compiled as module. There might have been a few other features that were
enabled in spite of 'n' defaults, just because they seemed to have very
little downsides.)

After oldconfig:

Enabled `CONFIG_X86_KERNEL_IBT` because the whole system will be compiled
with it (well, CET specifically).
As for the downside of being unable to use precompiled kernel modules
like proprietary nvidia drivers... well, we'll recompile everything if that
ever happens on this system. (I also find it unlikely that such modules
would even work without SOME kind of interface layer, because IBT is not
the only kernel option that affects linkage. There are many MANY others,
and the chances of those being compatible with some happenstance vendor's
choice of options is... rather low in general.)

Enabled `CONFIG_CRAMFS` because why not. (CRAM FS = Compressed ROM File System)

Enabled `CONFIG_JBD2_DEBUG` because it is off by default, but can be enabled
at runtime to provide debug info for ext4 filesystems.

Enabled various XFS features. Some of them are experimental, but only become
(potentially) a problem if they are actually _used_.

Enabled `CONFIG_REISERFS_PROC_INFO` because it provides optional debug/trace
info and only costs 8kB in the kernel plus some memory on each mount.
(Sounds pretty cheap on modern machines? Eh why not.)

Enabled `CONFIG_GFS2_FS_LOCKING_DLM` because why not. (Only used if used.)
Enabled `CONFIG_FS_DAX` because it only costs 5kB and gives us a... whatever this is.
Enabled `CONFIG_FS_VERITY` and `CONFIG_FS_VERITY_BUILTIN_SIGNATURES` because why not.
Enabled modules of `CONFIG_QFMT_V1` and `CONFIG_QFMT_V2`. They are modules, so cost almost nothing if unused.
Enabled `CONFIG_OVERLAY_FS_INDEX` because it can be turned off at runtime.

Change 'y' to 'm' for `CONFIG_AUTOFS_FS` and `CONFIG_FUSE_FS`.
Yeah this might shrink the kernel a little (cool?), but mostly it makes things
more likely to work.

Enabled `CONFIG_NETFS_STATS`. It provides debugging info AND is recommended 'y'.
(This is another "ugh why didn't I already have this enabled?!" one.)

Enabled `CONFIG_FSCACHE` and its debugging submodules.
It's a module (low/no cost if not in use) and its debugging options are also
only in effect if they are enabled at runtime.

Enabled `CONFIG_CACHEFILES`. It allows a local filesystem to be used as a cache
for a remote filesystem (e.g. NFS), which sounds pretty interesting.

Enabled `CONFIG_ZISOFS`. It's a CD-ROM decompression thingie.
Enabled `CONFIG_NTFS_DEBUG`. Only costs if it's turned on at boot/run-time.
Enabled `CONFIG_ECRYPT_FS` as module.
Enabled `CONFIG_UBIFS_FS`. "UBIFS is a file system for flash devices which works on top of UBI."
Enabled `CONFIG_VBOXSF_FS` because maybe useful for virtualization.
Enabled `CONFIG_BLK_DEV_ZONED` ... lack of warnings, and why not have a thing.
Enabled `CONFIG_BLK_WBT` write-back throttling. No downside? (none mentioned) May as well.
Enabled `CONFIG_BLK_SED_OPAL` ... lack of warnings, and why not have a thing.
Enabled `CONFIG_BLK_INLINE_ENCRYPTION`. Allows using hardware encryption on block devices that have it.
Enabled various options for partition reading. (Still left out some extremely obscure ones.)

Enabled various BPF stuff under "General Setup", ex: `CONFIG_BPF_SYSCALL`, `CONFIG_BPF_JIT`, and others.

Enabled `CONFIG_UCLAMP_TASK`. Some kind of prioritization for CPU usage of tasks.
Sounds useful, but a bit cryptic. Enabling it just to make it easier to play with
if I ever need it. (Also enabled `CONFIG_UCLAMP_TASK_GROUP`, seems related.)

Enabled `CONFIG_KEXEC_FILE` because it might help with kernel crash handling someday.

Leaving `CONFIG_CGROUP_FAVOR_DYNMODS` off, because it slows down things that are used a lot (process fork+exit).

Enabled `CONFIG_BLK_DEV_THROTTLING` because it offers more granular control over IO.
Enabled `CONFIG_BLK_DEV_THROTTLING_LOW` for same reason. It's experimental,
	so I just won't use it for now. But the kernel will remember my choice for later.
Enabled `CONFIG_BFQ_GROUP_IOSCHED`. (Enabled by default after other options were enabled.)
Enabled `CONFIG_BLK_CGROUP_IOLATENCY`. Ditto.
Enabled `CONFIG_BLK_CGROUP_FC_APPID`. Probably unneeded, but does it really hurt anything?
Enabled `CONFIG_BLK_CGROUP_IOCOST`. More IO throttling/control maybe.
Enabled `CONFIG_BLK_CGROUP_IOPRIO`. Ditto.
Enabled `CONFIG_CGROUP_PIDS` because no downside? (Allows limiting/allocating process IDs.)
Enabled `CONFIG_CGROUP_RDMA` because no downside?
Enabled `CONFIG_CGROUP_FREEZER` makes it possible to freeze all tasks in a cgroup.
Enabled `CONFIG_CGROUP_HUGETLB` because no downside?
Enabled `CONFIG_CPUSETS`. Looks like an ability to manually allocate individual cores on an SMP/NUMA machine.
Enabled `CONFIG_CGROUP_DEVICE` because why not?
Enabled `CONFIG_CGROUP_CPUACCT`. Way to monitor CPU usage of things.
Enabled `CONFIG_CGROUP_PERF` because why not?
Enabled `CONFIG_CGROUP_BPF` because why not?
Enabled `CONFIG_CGROUP_MISC` because why not?

Enabled `CONFIG_CORE_DUMP_DEFAULT_ELF_HEADERS`. It is incompatible with
GDB versions <=6.7. At time of writing, GDB installed is 13.2-r1. I think we'll be fine.

Enabled `CONFIG_BINFMT_MISC` because recommended 'y'.

Enabled `CONFIG_MAC80211_MESH` because why not?
Enabled `CONFIG_CFG80211_CRDA_SUPPORT`. This is really supposed to be 'y'. Oops?
Enabled `CONFIG_MCTP` because why not?
Enabled `CONFIG_AF_KCM` because why not?
Enabled `CONFIG_XDP_SOCKETS` because why not?
Enabled `CONFIG_IP_ADVANCED_ROUTER` (and related options) in case this thing ever needs to do routing.
Enabled `CONFIG_NET_IPVTI`. Routing/VM related stuff?
Enabled `CONFIG_IP_VS`. Ditto. (Also enabled almost all sub-options, usually modules.)
Enabled `CONFIG_TCP_CONG_ADVANCED`. Congestion control. But didn't config the suboptions.
Enabled `CONFIG_NETLABEL` sounds useful for compatibility reasons.
Enabled `CONFIG_BPFILTER` I think this makes BPF stuff available for networking.
Enabled more options under `CONFIG_BRIDGE_NF_EBTABLES`. Switched a few 'y' to 'm'.
Enabled a bunch of other networking+routing related options. Usually 'm'.

### Chad Joan  2024-02-22  (6.7.5 cont.) ###

Enabled `CONFIG_UHID` because it was required by `net-wireless/bluez-5.70-r1`.

Enabled `CONFIG_BOOTTIME_TRACING`, `CONFIG_FUNCTION_TRACER`,
	`CONFIG_FUNCTION_GRAPH_TRACER` (default with CONFIG_FUNCTION_TRACER),
	`CONFIG_FUNCTION_GRAPH_RETVAL`,
	`CONFIG_DYNAMIC_FTRACE` (default with CONFIG_FUNCTION_TRACER),
	`CONFIG_FTRACE_SYSCALLS`
Some of this was originally aimed at getting `CONFIG_DYNAMIC_FTRACE_WITH_DIRECT_CALLS`
to be enabled so that `CONFIG_HID_BPF` could be enabled too.
But it also seems useful to have these things. They seem like the kind of thing
that takes some extra memory at worse, and maybe a small amount of runtime overhead,
and really only take significant overhead if turned on at boot-time or run-time.
So we may as well build them into the kernel, and leave the option open to use
these in the future without having to do a kernel recompile in the future to get them.

Enabled `CONFIG_STACK_TRACER` because it is off by default on bootup.
"This special tracer records the maximum stack footprint of the kernel and displays it in /sys/kernel/tracing/stack_trace."
Can be enabled at boot-time by passing the `stacktrace` option,
or at run-time by using `sysctl kernel.stack_tracer_enabled`.

Enabled `CONFIG_IRQSOFF_TRACER` and `CONFIG_PREEMPT_TRACER` because they are
off by default. Both are enabled by this command:
echo 0 > /sys/kernel/tracing/tracing_max_latency

The above two also seem to pull in `CONFIG_TRACER_SNAPSHOT` and `CONFIG_TRACER_SNAPSHOT_PER_CPU_SWAP`
which are enabled by these commands:
echo 1 > /sys/kernel/tracing/snapshot
echo 1 > /sys/kernel/tracing/per_cpu/cpu2/snapshot

Leaving `CONFIG_DEBUG_KOBJECT` disabled.
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

Enabled `CONFIG_TRACE_EVAL_MAP_FILE`.
Hard to precisely understand the documentation, but it looks like it makes it
more likely that kernel debug info will include enum/sizeof names. Good.
Only downside is that this metadata doesn't get freed after bootup or
module load, so it increases the memory footprint of the kernel.
(But on modern systems, I doubt a bunch of variable names will be significant
compared to the amount of RAM required to reasonably use browsers these days.)

Some combination of the above tracer options enables
the `CONFIG_DYNAMIC_FTRACE_WITH_DIRECT_CALLS` option, which then allows us to...

Enable the `HID_BPF` option.
```
This option allows to support eBPF programs on the HID subsystem.
eBPF programs can fix HID devices in a lighter way than a full
kernel patch and allow a lot more flexibility.
```
Maybe useful for some hardware? Falls in to the
"better to have it and not need it, than to need it and not have it" category.

Enabled `CONFIG_SCHED_TRACER`; seems to be off by default, but possibly
VERY useful for checking in on the kernel scheduler, as it measures
scheduling latencies! More info here, including how to use it:
https://hugh712.gitbooks.io/embeddedsystem/content/RT_debug.html

Enabled `CONFIG_FUNCTION_PROFILER` despite "If in doubt, say N."
It doesn't seem to do anything unless explicitly enabled. Kernel help actually says it well:
```
This option enables the kernel function profiler. A file is created
in debugfs called function_profile_enabled which defaults to zero.
When a 1 is echoed into this file profiling begins, and when a
zero is entered, profiling stops. A "functions" file is created in
the trace_stat directory; this file shows the list of functions that
have been hit and their counters.
```

Enabled `CONFIG_DEBUG_CLOSURES` because it is related to bcache (maybe useful for debuggin bcachefs?).
```
Keeps all active closures in a linked list and provides a debugfs
interface to list them, which makes it possible to see asynchronous
operations that get stuck.
```

Enabled `CONFIG_DEBUG_PAGE_REF`
```
[...]
Be careful when enabling this feature because it adds about 30 KB to the
kernel code.  However the runtime performance overhead is virtually
nil until the tracepoints are actually enabled.
```
30kB is nothing, and if it doesn't affect runtime overhead, the heck yeah,
let's add a maybe useful feature.

Enabled `CONFIG_PAGE_OWNER`
Disabled by default, and only causes overhead if enabled at boot, so yeah why not.
```
This keeps track of what call chain is the owner of a page, may
help to find bare alloc_page(s) leaks. Even if you include this
feature on your build, it is disabled in default. You should pass
"page_owner=on" to boot parameter in order to enable it. Eats
a fair amount of memory if enabled. See tools/mm/page_owner_sort.c
for user-space helper.
```

The above also forced the `CONFIG_PAGE_EXTENSION` option enabled.
I'm not entirely sure what this means, but it at least doesn't mention any caveats.
```
Extend memmap on extra space for more information on page. This
could be used for debugging features that need to insert extra
field for every page. This extension enables us to save memory
by not allocating this extra memory according to boottime
configuration.
```

Enabled `CONFIG_HEADERS_INSTALL`
This might be a bad idea because Gentoo already provides `sys-kernel/linux-headers`,
but I'm not sure if that includes UAPI headers, or if those are useful for
some programs.
Looks possibly handy for whoever might use it:
https://www.kernel.org/doc/html/v4.14/doc-guide/parse-headers.html

Enabled `CONFIG_DYNAMIC_DEBUG` (and implied `CONFIG_DYNAMIC_DEBUG_CORE`)
Looks like it might give more info in debug messages? Good?
"enlarges the kernel text size by about 2%"
(Probably insignificant on modern desktop+laptop systems.)

Enabling `CONFIG_NTB` as module, "Non-Transparent Bridge support" (under Device Drivers)
```The PCI-E Non-transparent bridge hardware is a point-to-point PCI-E bus connecting 2 systems.```
Sounds cool, why not. Also enabled `CONFIG_NTB_MSI` and all other sub-options as modules.

Set `CONFIG_LOCALVERSION` to `.2024-02-22.1315`
