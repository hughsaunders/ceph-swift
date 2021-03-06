#
#    Copyright (C) 2013 Loic Dachary <loic@dachary.org>
#
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU Affero General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU Affero General Public License for more details.
#
#    You should have received a copy of the GNU Affero General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.
#
set -e
set -u

DIR=$1

if ! dpkg -l ceph ; then
 wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -
 echo deb http://ceph.com/debian-dumpling/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
 sudo apt-get update
 sudo apt-get --yes install ceph ceph-common
fi

# get rid of process and directories leftovers
pkill ceph-mon || true
pkill ceph-osd || true
rm -fr $DIR

# cluster wide parameters
mkdir -p ${DIR}/log
cat >> $DIR/ceph.conf <<EOF
[global]
fsid = $(uuidgen)
osd crush chooseleaf type = 0
run dir = ${DIR}/run
auth cluster required = none
auth service required = none
auth client required = none
EOF
export CEPH_ARGS="--conf ${DIR}/ceph.conf"

# single monitor
MON_DATA=${DIR}/mon
mkdir -p $MON_DATA

cat >> $DIR/ceph.conf <<EOF
[mon.0]
log file = ${DIR}/log/mon.log
chdir = ""
mon cluster log file = ${DIR}/log/mon-cluster.log
mon data = ${MON_DATA}
mon addr = 127.0.0.1
EOF

touch ${MON_DATA}/keyring
ceph-mon --id 0 --mkfs --keyring /dev/null
ceph-mon --id 0 

# single osd
OSD_DATA=${DIR}/osd
mkdir ${OSD_DATA}

cat >> $DIR/ceph.conf <<EOF
[osd.0]
log file = ${DIR}/log/osd.log
chdir = ""
osd data = ${OSD_DATA}
osd journal = ${OSD_DATA}.journal
osd journal size = 100
EOF

OSD_ID=$(ceph osd create)
ceph osd pool set data size 1
ceph osd crush add osd.${OSD_ID} 1 root=default
ceph-osd --id ${OSD_ID} --mkjournal --mkfs
ceph-osd --id ${OSD_ID}

# check that it works
rados --pool data put group /etc/group
rados --pool data get group ${DIR}/group
diff /etc/group ${DIR}/group
ceph osd tree

# display usage instructions
echo export CEPH_ARGS="'--conf ${DIR}/ceph.conf'"
echo ceph osd tree
