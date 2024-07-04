#!/usr/bin/env python2.7.9
# -*- coding: utf-8 -*-
"""
Created on Tue Dec 25 15:09:40 2021

Note: Calculate functional connectivity  

@author: Dong HaoMing, 2024
"""

import numpy as np
import nibabel as nib
import scipy.spatial.distance as SSD
import os, sys

mapdir = "/path/of/mapalign-master/"
sys.path.append(mapdir)
from mapalign import embed

# mask and output  directory, please replace follows with your local data directory
srcdir 	=  "/path/of/FC/directory/"
listdir = "/path/of/list/directory/"
outdir 	= "/output/directory/"

fsublist = listdir + "/HighVA.list" # load subject list generated from last step
subs 	 = open(fsublist, 'r').readlines()

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

# eigen decomposing
Thre = np.percentile(FC_mapz, 90, axis=0)
for vv in range(0, FC_mapz.shape[1]):
    	FC_mapz[vv,:] = np.where(FC_mapz[vv,:] > Thre[vv],FC_mapz[vv,:],0) 
FC_mapz[FC_mapz < 0] = 0

print("Caculating FC Cosine Distance...")
FCdist = 1 -  SSD.squareform(SSD.pdist(FC_mapz,'cosine'))

print("Performing eigendecomposing...")
emb, res = embed.compute_diffusion_map(FCdist, alpha = 0.5, return_result=True)

fout = outdir + "/HighVA_res.npy"
np.save(fout,res)
fout = outdir + "/HighVA_emb.npy"
np.save(fout,emb)