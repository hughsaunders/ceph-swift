#!/usr/bin/env python

#imports

#stdlib
import datetime
import math
import os
import sys

#ceph
import rados
import rbd


class CephConnector:

    def __init__(self, rados_user, conf_file, chunk_size=1024*1024*4):
        self.rados_id = rados_user
        self.conf_file = conf_file
        self.rbd = rbd.RBD()
        self.chunk_size = chunk_size

    def open_pool(self,pool_name):
        self.rados_client = rados.Rados(rados_id=self.rados_id,
                                   conffile=self.conf_file)
        self.rados_client.connect()
        self.rados_pool = self.rados_client.open_ioctx(pool_name)

    def test_rados_rw(self):
        self.rados_pool.write('py_obj_name',str(datetime.datetime.now()))
        print 'hostname obj:',self.rados_pool.read('hostname')

    def write_rbd_file(self, rbd_image_name, file_name):
        existing_rbd_image_names = self.rbd.list(self.rados_pool)
        if rbd_image_name in existing_rbd_image_names:
            #image already exists
            print "image %s exists, removing" % (rbd_image_name,)
            self.rbd.remove(self.rados_pool, rbd_image_name)
        
        file_size = os.stat(file_name).st_size
        self.rbd.create(ioctx=self.rados_pool,
                        name=rbd_image_name,
                        size=file_size,
                        order=int(math.log(self.chunk_size,2))) #RBD.create does 2**order to work out chunk size. We already have the chunk size for reading so log2 it before passing.
        print "created image"
        rbd_image = rbd.Image(self.rados_pool,rbd_image_name) 
        print "retrieved image:", rbd_image.name
        file_handle = open(file_name,'rb')
        while True:
            chunk_start_offset=file_handle.tell()
            chunk = file_handle.read(self.chunk_size)
            print '%i/%i %i %f%%' % (
                file_handle.tell(), 
                file_size, 
                len(chunk), 
                (file_handle.tell()/file_size)*100.0
            )
            sys.stdout.flush()
            if len(chunk) == 0:
                print "Finished reading %s" % (file_name,)
                break
            else:
                rbd_image.write(chunk, chunk_start_offset)
        print "finished creating rbd image %s." % (rbd_image_name,)

    def close(self):
        self.rados_pool.close()
        self.rados_client.shutdown()


def main():
   cc = CephConnector('admin','/etc/ceph/ceph.conf') 
   cc.open_pool(pool_name='data')
   cc.test_rados_rw()
   cc.write_rbd_file('test_rbd','/tmp/bigfile')
   cc.close()


if __name__ == '__main__':
    main()
