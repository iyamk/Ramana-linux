#!/bin/bash

clear

localesar=()
localesar+=(en_US.UTF-8 UTF-8)
while read a b; do
  localesar+=("$a $b" "$a")
done < /usr/share/i18n/SUPPORTED
localesel=$(dialog  --menu "Select locale" 25 50 25 "${localesar[@]}" 2>&1 >/dev/tty)
clear
sed -r "s/#$localesel/$localesel/" /etc/locale.gen
echo $localesel

exit

echo -n 'Enter partition or disk to install (for example /dev/sda1): '
read part
#mount $part /mnt

echo -e '\nEnter your country number:'
select country in $(reflector --list-countries|awk '{ print $1 }'|sed '1,2d')
do
    reflector -c $country > /etc/pacman.d/mirrorlist
    break
done

pacstrap -K /mnt base linux linux-firmware

genfstab -U /mnt >> /mnt/etc/fstab

echo -e '\nThe list of time zones will now be shown. Remember the correct number\n[ Press Enter ]'
read

packages='dhcpcd nano grub2 efibootmgr'
arch-chroot /mnt pacman --noconfirm -S $packages

timedatectl list-timezones|awk '{ print NR ") " $1 }'|less
select tz in $(timedatectl list-timezones)
o
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$tz /etc/localtime
    arch-chroot /mnt hwclock --systohc
    break
done

echo -e '\nNow the file with locales will be opened. Choose the one you want and save your changes\n[ Press Enter ]'
read

arch-chroot /mnt nano /etc/locale.gen
arch-chroot /mnt locale-gen

echo 'LANG=en_US.UTF-8' > /mnt/etc/locale.conf

echo 'Buddha' > /mnt/etc/hostname

echo -e '\nEnter the password for the root user:'
arch-chroot /mnt passwd

echo -e '\nEnter a name for a normal user (for example user): '
read user

arch-chroot /mnt useradd -m $user

echo -e '\nEnter password for a normal user:'
arch-chroot /mnt passwd $user

echo -e '\nEnter the drive (not partition) to install grub2 (for example /dev/sda): '
read disk

arch-chroot /mnt grub-install --target=i386-pc $disk
arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg

umount /mnt

echo -e '\nInstallation completed!\nNow you can reboot your computer with the command: reboot'
