Spice Qemu Builder
==================

Short story
-----------
    Build and run 'qemu' with 'spice' on the fly.

A bit longer
------------
>To build and run 'qemu' with 'spice' is not easy. That involves many dependences and configurations. Especially while you have system-installed 'qemu' running.
>
>So, here comes 'Spice Qemu Builder' ('sqb'), it is a set of helper scripts to automatically do the follwing:
>
*  install build depend
*  get code from offical repository
*  get 'fedora base cloud image' as test image
*  autogen/configure/build qemu with spice in local dir, touch nothing in system
*  run test VM using our hand-made 'qemu'
*  open spice console to the VM, if you have 'spice-gtk-tools' installed

ENV
----
  At this time, 'sqb' only rocks on RHEL/CentOs/Fedora. Porting to other distro should also by easy.

Show me howto
-------------
1.  make prepare_rh     # install the build deps
2.  ./autogen.sh        # get src code , and test image
3.  make spiceqemu
4.  ./test_run_qemu.sh


Good luck :)

