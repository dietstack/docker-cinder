#!/bin/bash

#pushd /glance && patch < /patches/bug-1657459.patch; popd
cd /cinder && patch -p1 < /patches/empty_export_path_fix.patch
