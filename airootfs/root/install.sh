#!/usr/bin/env bash

install_locale=''
install_part=''

clear

show_sel_locale()
{
    localesar=()
    localesar+=(en_US.UTF-8 1)
    c=1
    while read a b; do
        ((c++))
        localesar+=("$a $b" "$b")
    done < /usr/share/i18n/SUPPORTED
    localesel=$(dialog --menu "Select locale" 25 50 25 "${localesar[@]}" 2>&1 >/dev/tty)
    r=$?
    clear
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    install_locale=$localesel
    show_sel_country
}

show_sel_country()
{
    countries=$(reflector --list-countries|awk '{ print $1 }'|sed '1,2d')
    countriesar=()
    c=0
    for country in $countries; do
        ((c++))
        countriesar+=("$country" "$c")
    done
    countrysel=$(dialog --menu "Select country for mirrorlist" 25 50 25 "${countriesar[@]}" 2>&1 >/dev/tty)
    r=$?
    clear
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    reflector -c $countrysel > /etc/pacman.d/mirrorlist
    show_disk_partitioning
}

show_disk_partitioning()
{
    menusel=$(dialog --menu "Disk partitioning" 25 40 25 "skip" "Skip partitioning" "fdisk" "Run fdisk" 2>&1 >/dev/tty)
    r=$?
    clear
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    if [ "$menusel" = "skip" ]; then
        show_sel_part
    elif [ "$menusel" = "fdisk" ]; then
        show_fdisk
    fi
}

show_fdisk()
{
    lsblk -l -o NAME,SIZE,TYPE|grep disk > /tmp/tmp
    disksar=()
    disksar+=("back" "Return")
    while read a b c; do
        disksar+=("/dev/$a" "$b")
    done < /tmp/tmp
    rm /tmp/tmp
    disksel=$(dialog --menu "Select disk for fdisk" 25 40 25 "${disksar[@]}" 2>&1 >/dev/tty)
    r=$?
    clear
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    if [ "$disksel" = "back" ]; then
        show_disk_partitioning
    else
        fdisk $disksel
        show_sel_part
    fi
}

show_sel_part()
{
    lsblk -l -o NAME,SIZE,TYPE|grep part > /tmp/tmp
    partsar=()
    while read a b c; do
        partsar+=("/dev/$a" "$b")
    done < /tmp/tmp
    rm /tmp/tmp
    partsel=$(dialog --menu "Select partition for install" 25 40 25 "${partsar[@]}" 2>&1 >/dev/tty)
    r=$?
    clear
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    install_part=$partsel
    install_base
}

install_base()
{
    mkfs.ext4 $install_part
    mount $install_part /mnt
    pacstrap -K /mnt base linux linux-firmware | dialog --progressbox "Installing base system" 25 80
    packages='dhcpcd nano grub2 efibootmgr'
    arch-chroot /mnt pacman --noconfirm -S $packages | dialog --progressbox "Installing packages" 25 80
    genfstab -U /mnt >> /mnt/etc/fstab
    show_sel_timezone
}

show_sel_timezone()
{
    timezones=$(timedatectl list-timezones)
    timezonesar=()
    c=0
    for timezone in $timezones; do
        ((c++))
        timezonesar+=("$timezone" "$c")
    done
    timezonesel=$(dialog --menu "Select your timezone" 25 40 25 "${timezonesar[@]}" 2>&1 >/dev/tty)
    r=$?
    clear
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    arch-chroot /mnt ln -sf /usr/share/zoneinfo/$timezonesel /etc/localtime
    arch-chroot /mnt hwclock --systohc
    show_locale_gen
}

install_second()
{
	arch-chroot /mnt sed -r "s/#$install_locale/$install_locale/" -i /etc/locale.gen
	arch-chroot /mnt locale-gen | dialog --progressbox "Generation lacale" 25 80

	echo "LANG=$install_locale" > /mnt/etc/locale.conf
	echo 'linux' > /mnt/etc/hostname

    clear
	echo -e '\nEnter the password for root user: '
	arch-chroot /mnt passwd

    clear
	echo -e '\nEnter a name for a normal user: '
	read user
	arch-chroot /mnt useradd -m $user

    clear
	echo -e '\nEnter password for a normal user: '
	arch-chroot /mnt passwd $user

    clear

    bootloaderar=(
        "skip" "1"
        "grub2 without efi" "2"
    )
    bootloadersel=$(dialog --menu "Installing bootloader" 25 40 25 "${bootloaderar[@]}" 2>&1 >/dev/tty)
    r=$?
    [ "$r" -gt "0" ] && echo "Canceled by user" && exit
    if [ "$bootloadersel" = "grub2 without efi" ]; then
        echo -e '\nEnter the drive (not partition) to install grub2 (for example /dev/sda): '
        read disk
        clear
        arch-chroot /mnt grub-install --target=i386-pc $disk
        arch-chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg
    fi

	umount /mnt

    clear
	echo -e '\nInstallation completed!\nNow you can reboot your computer with the command: reboot'
}

show_sel_locale
