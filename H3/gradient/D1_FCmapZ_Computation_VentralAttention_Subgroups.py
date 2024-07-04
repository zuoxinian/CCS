#!/usr/bin/env python2.7.9
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 25 15:09:40 2021

Note: Calculate functional connectivity  

@author: Dong HaoMing, 2024
"""

import numpy as np
import nibabel as nib
import copy
import os

# data directory, please replace follows with your local data directory
datadir = "/path/to/data/directory/"
outdir = "/output/directory/"
maskdir = "/path/to/medial/wall/mask/"

# load network and medialwall mask 
flh_mask = maskdir + "/lh.medialwall.nii.gz"
frh_mask = maskdir + "/rh.medialwall.nii.gz"
lh_mask = nib.load(flh_mask)
lh_mask = np.squeeze(lh_mask.get_fdata())
rh_mask = nib.load(frh_mask)
rh_mask = np.squeeze(rh_mask.get_fdata())
brainmask = np.hstack((lh_mask,rh_mask))
masksize = np.sum(brainmask)
fnetlh = maskdir + "/7_004netmask_lh.nii.gz" # load ventral attention network mask
lhnet = nib.load(fnetlh)
lhnet = np.squeeze(lhnet.get_fdata())
fnetrh = maskdir + "/7_004netmask_rh.nii.gz" # load ventral attention network mask
rhnet = nib.load(fnetrh)
rhnet = np.squeeze(rhnet.get_fdata())
tmpmask = 1- np.hstack([lhnet,rhnet]) # ensure that the network mask is not overlapped with medial wall mask
tmpmask = brainmask * tmpmask
tmpmask = 1 - tmpmask[brainmask==1]
netmask = np.zeros((int(masksize),1))
netmask = copy.deepcopy(tmpmask)

# your data subject ID 
subid = "SUBID" 
# Caculate FC map
subdir = "/path/to/single/subject/" + subid 
print("Caculating pairwise FC...")
flh = subdir + "rest.pp.sm6.fsaverage5.lh.nii.gz" #lh_resting_state_file
lh = nib.load(flh)
lh = np.squeeze(lh.get_fdata())
frh = subdir + "rest.pp.sm6.fsaverage5.rh.nii.gz" #rh_resting_state_file
rh = nib.load(frh)
rh = np.squeeze(rh.get_fdata())
lh = lh[lh_mask == 1,]
rh = rh[rh_mask == 1,]
brain = np.vstack((lh,rh))
FCmap = np.corrcoef(brain)
FCmapz = np.arctanh(FCmap)
FCmapz = FCmapz.astype(np.float32)
fout = outdir + "/" + subid + "_FCz.npz"
np.savez(fout,FCmapz)

Thre = np.percentile(FCmapz,90,axis=0)
for vv in range(0,FCmapz.shape[1]):
    FCmapz[vv,:] = np.where(FCmapz[vv,:] > Thre[vv],FCmapz[vv,:],0)
FCmapz[FCmapz < 0] = 0

# caculate Degree Centrality
FCmapz[FCmapz>0] =1
brainDC = np.sum(FCmapz, axis=0) # caculate the Degree Centrality for each vertex
fout = outdir + "/" + subid + "_DC.npy"
np.save(fout,brainDC)
VA_DC = np.sum(brainDC * netmask)  # caculate the Degree Centrality for ventral attention network
fout = outdir + "/" + subid + "_VADC.npy"
np.save(fout,VA_DC)
if VA_DC < 4621010: # this number is derived from age17 group in CCNP dataset
    cmd = "echo " + subid + " >> " +  outdir + "/LowVA_Group.list"
    os.system(cmd)
else:
    cmd = "echo " + subid + " >> " +  outdir + "/HighVA_Group.list"
    os.system(cmd)
