#!/usr/bin/env bash

if [ ! -f "qemu_image.raw" ]; then
    qemu-img create -f raw qemu_image.raw 10G
fi

iso_file=$(ls -t out/|head -1)
qemu-system-x86_64 -cdrom out/$iso_file -m 1G qemu_image.raw
