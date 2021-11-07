#!/usr/bin/env python3
# -*- coding: utf-8 -*-

"""
The first step of this script is to run on bash will move to python eventually
Usage:
 pre_ccs_bids2ccs.py --BIDS_DIR <dir> --CCS_DIR <dir>

Options:
  --BIDS_DIR PATH     The directory for CCS
  --CCS_DIR PATH     The directory for SUBJECTS
"""

import glob
import os
import os.path as op
import shutil
from docopt import docopt

class BIDS_INFO(object):
    def __init__(self,bids_data):
        self.bids_split = op.basename(bids_data).replace(".nii.gz","").split("_")
            
    def get_modality(self):
        runinfo = [ x for x in self.bids_split if 'run-' in x]
        if len(runinfo) !=0:
            run_number = runinfo[0][4:]
        else:
            run_number = ''
        
        if "T1w" in self.bids_split:
            return "anat" + run_number + "/T1"
        elif "T2w" in self.bids_split:
            return "anat" + run_number + "/T2"
        elif "task-rest" in self.bids_split:
            return "rest" +run_number+"/rest"
        elif "DTI" in self.bids_split:
            return "dti" + run_number + "/dti"
        elif "DWI" in self.bids_split:
            return "dti" + run_number + "/dti"
        else:
            return "unknown/unknown"
        
    def get_subid(self):
        subid = self.bids_split[0]
        return subid[4:]
    
    def get_sesid(self):
        sesinfo = [ x for x in self.bids_split if 'ses-' in x]
        if len(sesinfo) !=0:
            return sesinfo[0][4:]
        else:
            return ''
    def get_runid(self):
        runinfo = [ x for x in self.bids_split if 'run-' in x]
        if len(runinfo) !=0:
            return runinfo[0][4:]
        else:
            return ''

def session_info(BIDS_DIR):
    third_level = BIDS_DIR + '/*/*/*/*'
    file_list=glob.glob(third_level)
    if len(file_list) == 0:
        is_session = False
    else:
        is_session = True
    return is_session


def find_bids_file(BIDS_DIR,session):
    if session:
        bids_file_list = glob.glob(BIDS_DIR + '/*/*/*/*.nii.gz')
    else:
        bids_file_list = glob.glob(BIDS_DIR + '/*/*/*.nii.gz')
    return bids_file_list 


def split_bids_file(bidsfile):
    ccs_list = []
    for nii in bidsfile:
        bids_info = BIDS_INFO(nii)
        modality = bids_info.get_modality()
        subid = bids_info.get_subid()
        sesid = bids_info.get_sesid()
        #runid = bids_info.get_runid()
        if sesid:
            ccs_filename = subid +'_'+sesid + '/' + modality + '.nii.gz'
        else:
            ccs_filename = subid + '/' + modality + '.nii.gz'
        ccs_list.append(ccs_filename)
    return ccs_list

def copy_bids_file(bids_list,ccs_list,CCS_DIR):
    
    if len(bids_list) == len(ccs_list):
        for i in range(len(bids_list)):
            bids_file = bids_list[i]
            ccs_file = op.join(CCS_DIR,ccs_list[i])
            sub_dir = op.dirname(ccs_file)
            os.makedirs(sub_dir,exist_ok=True)
            shutil.copy(bids_file,ccs_file)
    else:
         print('bids file number are not matched ccs file number exit')
         exit()

def main():
    print("Start to transfer bids data")
    arguments = docopt(__doc__)
    print(arguments['--BIDS_DIR'])
    BIDS_DIR = arguments['--BIDS_DIR']
    CCS_DIR = arguments['--CCS_DIR']
    session_yes = session_info(BIDS_DIR)
    bids_file_list = find_bids_file(BIDS_DIR,session_yes)
    ccs_file_list = split_bids_file(bids_file_list)
    copy_bids_file(bids_file_list,ccs_file_list,CCS_DIR)
    
main()