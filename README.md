# sqlab

Sqlab is used to quickly setup different multi-node database environment.


## Installation
- Install `Vagrant`
- Install `VirtualBox`
- `$ rake` to download mysql installation file.

## Power on a toplogy
- Change to any sub folder such as "master-slave"
- `$ vagrant up`
- `vagrant ssh master` to login master node

## Installed software on vm
- Mysql 5.6 is install in /usr/local/mysql
- XtraBackup binary locates in /tmp/blobs

## Master slave topology
You can connect to master on host using:
`mysql -h 127.0.0.1  -u root -P 6606 --password='password';`

If you wan to connect to slave, change port number to 6607
`mysql -h 127.0.0.1  -u root -P 6607 --password='password';`


