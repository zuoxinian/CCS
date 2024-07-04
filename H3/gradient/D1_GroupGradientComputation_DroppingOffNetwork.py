#!/usr/bin/env python2.7.9
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 25 15:09:40 2021

Note: Calculate functional connectivity  

@author: Dong HaoMing, 2024
"""

import os, sys
import copy
import numpy as np
import nibabel as nib
import scipy.spatial.distance as SSD


mapdir = "/path/of/mapalign-master/"
sys.path.append(mapdir)
from mapalign import embed

# mask and output  directory, please replace follows with your local data directory
outdir  = "/output/directory/"
maskdir = "/path/to/medial/wall/mask/"

# load network and medialwall mask 
flh_mask = maskdir + "/lh.medialwall.nii.gz"
frh_mask = maskdir + "/rh.medialwall.nii.gz"

lh_mask = nib.load(flh_mask)
lh_mask = np.squeeze(lh_mask.get_fdata())
rh_mask = nib.load(frh_mask)
rh_mask = np.squeeze(rh_mask.get_fdata())

brainmask = np.hstack((lh_mask,rh_mask))
masksize  = np.sum(brainmask)

fnetlh = maskdir + "/netmask_lh.nii.gz" # load network or area mask to be dropped off from the brain connectome
lhnet  = nib.load(fnetlh)
lhnet  = np.squeeze(lhnet.get_fdata())
fnetrh = maskdir + "/netmask_rh.nii.gz" # load network or area mask to be dropped off from the brain connectome
rhnet  = nib.load(fnetrh)
rhnet  = np.squeeze(rhnet.get_fdata())

tmpmask = 1- np.hstack([lhnet,rhnet]) # ensure that the network mask is not overlapped with medial wall mask
tmpmask = brainmask * tmpmask
tmpmask = 1 - tmpmask[brainmask==1]
netmask = np.zeros((int(masksize),1))
netmask = copy.deepcopy(tmpmask)

srcdir =  "/path/of/FC/directory/"
listdir = "/path/of/list/directory/"
fsublist = listdir + "/subs.list" # load subject list 
subs = open(fsublist,'r').readlines()

# Subject loop for generating group-level FC matrix
k = 0
for subname in subs:
	subname = subname.replace('\n','')
	fout = srcdir + "/" + subname + "_FCz.npy"
	if k == 0:
		FC_mapz = np.load(fout)
	else:
		tmpFCmapz = np.load(fout)
		FC_mapz += tmpFCmapz
	k += 1
FC_mapz = FC_mapz/k
fout = outdir + "/HighVA_Group_FCz.npy"
np.save(fout,FC_mapz)

# Drop off the vertexes of specific network
FC_mapz_Drop = FC_mapz[netmask==1,:]
FC_mapz_Drop = FC_mapz_Drop[:,netmask==1]
del FC_mapz
# eigen decomposing
Thre = np.percentile(FC_mapz_Drop, 90, axis=0)
for vv in range(0,FC_mapz.shape[1]):
    	FC_mapz_Drop[vv,:] = np.where(FC_mapz_Drop[vv,:] > Thre[vv],FC_mapz_Drop[vv,:],0) 
FC_mapz_Drop[FC_mapz_Drop < 0] = 0

print("Caculating FC Cosine Distance...")
FCdist = 1 -  SSD.squareform(SSD.pdist(FC_mapz_Drop,'cosine'))

print("Performing eigendecomposing...")
emb, res = embed.compute_diffusion_map(FCdist, alpha = 0.5, return_result=True)

fout = outdir + "/Subs_Dropoff_Net_res.npy"
np.save(fout,res)
fout = outdir + "/Subs_Dropoff_Net_emb.npy"
np.save(fout,emb)