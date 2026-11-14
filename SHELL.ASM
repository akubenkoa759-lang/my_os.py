name: Build FreeDOS Addon
on: [push]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Install Tools
        run: sudo apt-get update && sudo apt-get install -y nasm mtools
      - name: Build COM Program
        run: nasm -f bin SHELL.ASM -o SHELL.COM
      - name: Create Floppy Image
        run: |
          dd if=/dev/zero of=addon.img bs=1024 count=1440
          mformat -f 1440 -i addon.img ::
          mcopy -i addon.img SHELL.COM ::SHELL.COM
      - name: Upload Image
        uses: actions/upload-artifact@v4
        with:
          name: freedos-shell-disk
          path: addon.img
