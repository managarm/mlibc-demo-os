# mlibc-demo-os

This is a toy kernel intended to demonstrate how to port [mlibc](https://github.com/managarm/mlibc) to a new operating system. It is written in Rust and runs on a 64-bit RISC-V target.

For pedagogical purposes we cut some corners. For example we do not implement a scheduler (only a single hardcoded task may run). There are no external interrupts, meaning no pre-emption. Only a single hart is supported.

Currently this kernel can run a statically linked hello world program. We plan to support a dynamically linked hello world in future.

To build the kernel, first build the userpace application and then the kernel. It is done in this order because the kernel embeds the application inside itself.
```
# Build user application
# This requires a built mlibc. By default, it is in "$HOME/mlibc", but you can change it by setting the "MLIBC_DIR=/path/to/mlibc" environment.
$ ./user/make_user.sh
# Build kernel
$ cargo build
```

TODO: How to build the userspace (including mlibc)

## Example output

```
$ cargo run
[INFO ] Booting mlibc-demo-os...
[INFO ] Loading userspace program...
[INFO ] Jumping to userspace entrypoint at 0x10158
Hello world!
[INFO ] Userspace program exited with status code 0
```
