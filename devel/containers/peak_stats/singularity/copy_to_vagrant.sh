#!/bin/bash

scp -i ~/vagrant/.vagrant/machines/default/qemu/private_key -P 50022 fragmentomics_peakStats.def vagrant@127.0.0.1:~