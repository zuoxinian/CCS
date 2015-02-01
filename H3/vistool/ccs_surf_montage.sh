surf_name=$1 ; surf_ext=$2 ; cd ${surf_name}
montage -mode concatenate -tile 2x2 lh.lateral.${surf_ext} rh.lateral.${surf_ext} lh.medial.${surf_ext} rh.medial.${surf_ext} ${surf_name}_montage.${surf_ext}
