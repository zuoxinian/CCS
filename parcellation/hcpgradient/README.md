This is the data and code for the Gong's paper: Connectivity gradients revealed by resting-state fMRI at multiple frequency bands.

![Connectivity Gradients across Frequency Bands](https://github.com/zuoxinian/CCS/blob/master/parcellation/hcpgradient/fig2.jpg)

Gradient Data
======
Data of the first and second gradients of six frequency bands are saved in cifti files. For example, the first gradient of slow-1 is saved as "gradient1s1.dscalar.nii". All the gradient data are saved in the "dscalar" field in the cifti objects.

Parcellation Data
======
The frequency-rank parcellation data are also saved in the "dscalar" field in each cifti object. For example, the frequency-rank parcellation data of the highest and lowest gradient values for the first gradient are saved as "gradient1rank1.dscalar.nii" and "gradient1rank2.dscalar.nii", respectively.
