###################################################################
#CCS SCRIPT TO FREESURFER RECON-ALL BY CHANGE DEFAULT BRAINMASK INTO
#VOBRAIN MASK
#
#Edited by Yinshan Wang, 2020-09-16
###################################################################

# import libs

from __future__ import print_function
import os
import os.path as op
import shutil
import numpy as np


####################################################################
#define functions
def sed_str(old,new,file):
	sub_grammar = '\'s/'+ old +'/'+ new +'/g\''
	cmd = ' '.join(['sed','-i',sub_grammar,file])
	print(cmd)
	os.system(cmd)
def qsub_mission(echo_name,xshell,nnodes=1,ppn=4,servername='short'):
	ncore = 'nodes='+str(nnodes)+':ppn='+str(ppn)
	echo_cmd = '{}{}{}{}{}'.format("echo"," ","\"",xshell,"\"")
	cmd = ' '.join([echo_cmd,'|','qsub','-N',echo_name,'-m','n','-l',ncore,'-q',servername])
	print(cmd)
	os.system(cmd)
	os.system(' '.join(['sleep','0.5']))

#####################################################################

if __name__ == '__main__':
	#set dirs
	CCS_DIR = '/path_to_your_project/CCS' 
	SUBJECTS_DIR='/path_to_your_project/FreeSurfer60'
	template_file = '/path_to_CCS_APP/CCS_APP/ccs_anat_02_freesurfer.sh'
	subjects_list = '/path_to_your_project/scripts/subjects.list'
    #start to assign missions 
	subjects = np.loadtxt(subjects_list,dtype='str')
	for ccsid in subjects:
		dst_xshell = op.join(SUBJECTS_DIR,ccsid,'scripts','ccs_anat_02_freesurfer.sh')
		dst_cmd = ' '.join([dst_xshell,CCS_DIR,SUBJECTS_DIR,ccsid])
		os.makedirs(op.dirname(dst_xshell),exist_ok=True)
		shutil.copy(template_file,dst_xshell)
        #sed_str('CCSsubjectname',ccsid,dst_xshell)
		qsub_mission(ccsid,dst_cmd)
