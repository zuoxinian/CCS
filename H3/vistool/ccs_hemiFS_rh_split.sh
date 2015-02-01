surf_name=$1 ; surf_ext=$2 ; mkdir -p ${surf_name}
convert ${surf_name}.${surf_ext} -crop 1020x720+160+240 ${surf_name}/medial.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 1020x720+160+1340 ${surf_name}/lateral.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 400x720+2165+240 ${surf_name}/anterior.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 400x720+2165+1340 ${surf_name}/posterior.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 1020x120+1160+2940 ${surf_name}/colormap.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 530x1340+1400+80 ${surf_name}/dorsal.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 530x1340+1400+1420 ${surf_name}/ventral.${surf_ext}
