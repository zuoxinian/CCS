#!/usr/bin/env python3
# -*- coding: utf-8 -*-
##################################################################
#CCS SCRIPT TO SEGEMENTATION AND ALIGNMENT
#
#Edited by Yinshan Wang, 2020-09-16
###################################################################

# import libs

from __future__ import print_function
import os
import os.path as op
import subprocess
import shutil
import math
import numpy as np


####################################################################
#define functions
def sed_str(old,new,file):
	sub_grammar = '\'s/'+ old +'/'+ new +'/g\''
	cmd = ' '.join(['sed','-i',sub_grammar,file])
	print(cmd)
	os.system(cmd)
def qsub_mission(echo_name,xshell,nnodes=1,ppn=5,servername='wanzhao'):
	ncore = 'nodes='+str(nnodes)+':ppn='+str(ppn)
	cmd = ' '.join(['qsub','-N',echo_name,'-m','n','-l',ncore,'-q',servername,xshell])
	os.system(cmd)
	os.system(' '.join(['sleep','0.5']))

#####################################################################

if __name__ == '__main__':
	#set dirs
	CCS_DIR = '/path_to_your_project/CCS' 
	SUBJECTS_DIR='/path_to_your_project/FreeSurfer60'
	hcp_dir = '/path_to_your_project/HCP' 
	subjects_list = '/path_to_your_project/scripts/subjects.list'
	subjects = np.loadtxt(subjects_list,dtype='str')
	rest_name = 'rest'
	rest_dir_name = 'rest'
	FWHM = 4
	Sigma = float(FWHM) / (2 * math.sqrt(2*math.log(2)))
	#set qsub file's dir
	set_HCP_dir =  ' '.join(['export','CIFTIFY_WORKDIR='+hcp_dir])
	set_fs_dir = ''.join(['SUBJECTS_DIR=',SUBJECTS_DIR])
	for  ccsid in subjects:
		print('assgining %s into clusters '%ccsid)
		fmri_file = op.join(CCS_DIR,ccsid,rest_dir_name,rest_name+'_pp_nofilt_sm0.nii.gz')
		subject_lef_surf = op.join(hcp_dir,ccsid,'MNINonLinear','fsaverage_LR32k','{}.L.midthickness.32k_fs_LR.surf.gii'.format(ccsid))
		subject_right_surf = op.join(hcp_dir,ccsid,'MNINonLinear','fsaverage_LR32k','{}.R.midthickness.32k_fs_LR.surf.gii'.format(ccsid))
		cifti_dt_series_sm0  = op.join(hcp_dir,ccsid,'MNINonLinear','Results',rest_dir_name,'{}_Atlas_s{}.dtseries.nii'.format(rest_name,'0'))
		cifti_dt_series_smooth =  op.join(hcp_dir,ccsid,'MNINonLinear','Results',rest_dir_name,'{}_Atlas_s{}.dtseries.nii'.format(rest_name,FWHM))
		cmd1 = ' '.join(['ciftify_recon_all','--fs-subjects-dir',SUBJECTS_DIR,'--ciftify-work-dir',hcp_dir,ccsid])
		cmd2 = ' '.join(['cifti_vis_recon_all','subject',ccsid])
		cmd3 = ' '.join(['ciftify_subject_fmri','--FLIRT-to-T1w',fmri_file,ccsid,rest_name])
		cmd4 = ' '.join(['wb_command','-cifti-smoothing',cifti_dt_series_sm0,str(Sigma), str(Sigma),'COLUMN',cifti_dt_series_smooth,'-left-surface',subject_lef_surf,'-right-surface',subject_right_surf])
		cmd5 = ' '.join(['cifti_vis_fmri','subject','--ciftify-work-dir',hcp_dir,rest_name,ccsid]) 
		#set dir
		scripts_dir = op.join(SUBJECTS_DIR,ccsid,'scripts')
		os.makedirs(scripts_dir,exist_ok=True)
		dst_xshell = op.join(scripts_dir,'ccs_preproc_CCS2HCP.sh')
		#writh bash script
		f = open(dst_xshell,'w')
		f.write(set_fs_dir+'\n')
		f.write(set_HCP_dir+'\n')
		f.write(cmd1 +'\n')
		f.write(cmd2 +'\n')
		f.write(cmd3 +'\n')
		f.write(cmd4 +'\n')
		f.write(cmd5 +'\n')
		f.close()
		subject_dtseries = op.join(hcp_dir,ccsid,'MNINonLinear','Results',rest_dir_name,rest_name+'_Atlas_s0.dtseries.nii')
		subject_rest_log = op.join(hcp_dir,ccsid,'MNINonLinear','Results',rest_dir_name,'ciftify_subject_fmri.log')
		if not op.isfile(subject_dtseries):
			if op.isfile(subject_rest_log):
				print("Detecting log file removing it")
				os.remove(subject_rest_log)
		qsub_mission(ccsid,dst_xshell)