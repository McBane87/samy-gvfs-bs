# samy-gvfs-bs

This buildsystem was created to build the GNU-Virtual-File-System (GVFS) for Samsung TVs with SamyGo installed.
It is able to mount WebDav, Samba, NFS & FTP Shares.

This buildsystem was intially created to work with Debian 8 (Jessie).


## How to build
```
./config.sh
make
make package
```

## Is it working on my TV?
Well, I was only able to test it on my Samsung UE40FXXX TV. But I guess chances are not that bad if your TV (with SamyGo) has the following prequisites:
1. Your SamyGo needs an permanent USB-Stick/Pendrive connected to work.
2. On your TV there is this Path/Folder existing: `/mnt/opt/privateer`
3. On your TV there is this Path/Folder existing: `/mnt/etc/init.d`
4. On your TV there is a File called `/dtv/SGO.env` , which includes definitions for `MOUNT_PATH=XYZ` and `TMPDIR=XYZ`. OR your Virtual USB is located here `/dtv/usb/sdb` and you have a directory called `/tmp` on your TV.

## Howto install
1. Copy the contents of the Zip-File, which was created by `make package` onto your USB-Stick/Pendrive. Or in other words. Copy the folder `GVFS` inside the zip onto your USB-Stick/Pendrive.
2. Copy the file `<Your_USB_Stick>/GVFS/04_04_gvfs.init.dis` to `/mnt/etc/init.d/`
3. Change permissions to make it executable: `chmod 755 /mnt/etc/init.d/04_04_gvfs.init.dis`.
4. Edit the file `<Your_USB_Stick>/GVFS/gvfs_mounts.cfg` and add the shares you want to mount.
5. Test if everything workes by executing the Init-Script manually: `/mnt/etc/init.d/04_04_gvfs.init.dis start`

   If the daemon started successfully and you don't want to start the hole daemon over and over again, you can also use `/mnt/etc/init.d/04_04_gvfs.init.dis umount` and `/mnt/etc/init.d/04_04_gvfs.init.dis mount` for testing your mounts configured by `<Your_USB_Stick>/GVFS/gvfs_mounts.cfg`
6. If everything works then make the Init-Script enabled. This way it will start with every boot of your TV. 
   
   `mv /mnt/etc/init.d/04_04_gvfs.init.dis /mnt/etc/init.d/04_04_gvfs.init`
   
Error Logs can be found directly on the console (if Init-Script was started manually) or inside `/mnt/sam.log` (if started on boot) and additionally you can find Errors inside `$TMPDIR/.gvfs/.log_gvfs`
