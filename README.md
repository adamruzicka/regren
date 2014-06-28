regren
======
[![Build Status](https://travis-ci.org/adamruzicka/regren.svg?branch=master)](https://travis-ci.org/adamruzicka/regren):

##Examples
This is what you're looking for, right?
```bash
$ ls
install53.iso  install54.iso  install55.iso

# basic rename
$ regren -b '(install)(\d\d)' 'i386_\1_\2'
install53.iso
-> i386_install_53.iso
install54.iso
-> i386_install_54.iso
install55.iso
-> i386_install_55.iso
Execute the rename? [y/N] y

$ ls
i386_install_53.iso  i386_install_54.iso  i386_install_55.iso

# show history of file
$ regren -H i386_install_53.iso
i386_install_53.iso
-> install53.iso
-> i386_install_53.iso

# rollback to the files' original names with -r flag
$ regren -r
i386_install_53.iso
-> install53.iso
i386_install_54.iso
-> install54.iso
i386_install_55.iso
-> install55.iso

# copy .backup file to another folder containing for example install54.iso
# run with -r flag to reapply renames to this file
$ regren -R
install54.iso
-> i386_install_54.iso
Execute the rename? [y/N] y
