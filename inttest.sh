#!/bin/bash
#
# Integration Test
#
# # NCI MscWebTech 2013-14
# # Deployment Project
# # Hugh Kelly 13117386 
#
# 
#

source /home/testuser/deploy/func.lib

unitTestApache
unitTestMysql
unitTestMem
