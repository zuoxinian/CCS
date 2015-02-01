surf_name=$1 ; surf_ext=$2 ; mkdir -p ${surf_name}
convert ${surf_name}.${surf_ext} -crop 800x600+140+180 ${surf_name}/lh.lateral.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 800x600+140+1060 ${surf_name}/lh.medial.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 640x580+130+1920 ${surf_name}/anterior.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 800x600+1730+180 ${surf_name}/rh.lateral.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 800x600+1730+1060 ${surf_name}/rh.medial.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 640x580+1900+1890 ${surf_name}/posterior.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 880x120+880+2340 ${surf_name}/colormap.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 825x1060+920+70 ${surf_name}/dorsal.${surf_ext}
convert ${surf_name}.${surf_ext} -crop 825x1060+920+1130 ${surf_name}/ventral.${surf_ext}
