#! /bin/bash

#dest=photos.html
#b=20120416_PHOTO_RRC
th_size=200
th_video_size=400
th_dir=th
ga_script=ga.js
extern_link=links.external
title_file=title
final_index=index.html

append_links(){
htmlname=$1
if [[ ! -e "$extern_link" ]]
then
    return
fi

links=$(cat $extern_link)

if [[ ${#links} -gt 0 ]] #first elem of the array as not a size of zero
then
    echo "<nav><h1>Other links</h1><ul>" >> $htmlname

    for link in $links
    do
        cat <<EOF >> $htmlname
        <li><a href="$link">$link</a></li>
EOF
    done

    echo "</ul></nav>" >> $htmlname


fi

}

append_footer(){
htmlname=$1

    cat <<EOF >> $htmlname
<br/><br/>
</body>
<footer style="text-align:center; font-size:small;" >
    Generated on `LANG=C date  +'%b %d, %Y - %Hh%M'`. Gabriel Serme
</footer>
</html>
EOF

}

append_header(){
htmlname=$1
title=""
if [[ -e "$title_file" ]]
then  
    title=$(cat $title_file)
fi


    cat <<EOF >> $htmlname
<html>
<head>
<title>$title</title>
</head>
<body>
EOF
}

append_ga_script(){
htmlname=$1

cat $ga_script >> $htmlname
}

create_video_th(){
    #create th of the video in ogg format only
    #send back (writting to standard ooutput) the th name
    file=$1
    base=`basename $file .MOV`
    target=$thfolder/$base.ogg
    if [ ! -e $target ]
    then
        log "Create video th for $file\n"
        ffmpeg2theora -p padma $file -o $target
    else
    #    log "Th $target exists"
        log "."
    fi
    echo "$target"
}

log (){
echo -ne "$1" >& 2
}


generate_pictures(){

dest=$1 #photos.2012.html for example
folder=$2 #folder containing pictures
thfolder=$3 #folder where to generate th

echo "" > $dest

append_header $dst

echo "<a href='..'>Return to homepage</a><br/>"  >> $dest

log "$folder, chech existing th for the target:\n"
for file in  $folder/*.JPG $folder/*.jpg; do
    [[ -e "$file" ]] || continue

    base=`basename $file .JPG`
    target=$thfolder/$base.JPG
    if [ ! -e $target ]
    then
        log "Create th for $file\n"
        #reorient, then normalize size.
 #       convert -auto-orient $file $target
        convert -auto-orient -resize ${th_size}x${th_size}  $file $target 
    else
        #echo "Th $target exists" >&2
        log "."
    fi

    cat <<EOF >> $dest
    <div style="display:inline-block;">
    <a href="$file"><img alt="$base" style="max-height: 150px; max-width: ${th_size}px"  src="$target"/></a>
    </div>
EOF

done
log "\n"

files=$(ls $folder/*.MOV)

if [[ ${#files} -gt 0 ]] #first elem of the array as not a size of zero
then

cat <<EOF >> $dest
    <h1>Videos</h1>
EOF

log "$folder, chech existing video th for the target:\n"
for file in  $files; do
    [[ -e "$file" ]] || continue

    #log "Videos from $file: \n"
    base=`basename $file .MOV`
    oggf=$(create_video_th $file)
    s=$(get_size_file $file)

    cat <<EOF >> $dest
    <div style="display:inline-block;">
    <video controls="controls" width="${th_video_size}px" preload="none">
    <source src="$oggf" type="video/ogg" />
     Vous n'avez pas de navigateur moderne, donc pas de balise vid&eacute;o de <abbr lang="en" title="HyperText Markup Language" xml:lang="en">HTML</abbr>5 pour vous! Vous pouvez utiliser Firefox, Opera, ou Chrome.
     </video>
     <br/>Raw video: <a href="$file">$base</a> ($s Mo)
    </div>
EOF


done
log "\n"
fi

#end of file
append_ga_script $dest
append_footer $dest

}


generate_folder(){

if [ -z "$1" ]                           # Is parameter #1 zero length?
   then
     echo "Usage: $0 <folder name>"
   fi

folder=$1
thfolder=$th_dir/$folder

mkdir -p $thfolder

htmlname="photos-$folder.html"

generate_pictures $htmlname $folder $thfolder

append_ga_script $htmlname

#return
echo $htmlname
}

get_size_file (){
file=$1
s=$( stat -c %s $file)
s=$(expr $s / 1024 / 1024)
echo $s
}


dl_picture_txt(){
    file=$1
    s=$(get_size_file $file)
    txt=$(echo "Vous pouvez télécharger les photos à l'adresse " | recode "utf8..h)")
    txt="$txt <a href='$file'>suivante</a> ($s Mo)."
    echo $txt
}
dl_video_txt(){
    file=$1
    s=$(get_size_file $file)
    txt=$(echo "Vous pouvez télécharger les vidéos à l'adresse " | recode "utf8..h)")
    txt="$txt <a href='$file'>suivante</a> ($s Mo)."
    echo $txt
}

generate_all(){

index=index.tmp.html
echo "" > $index

append_header $index

#(
#IFS=$(echo -en "\n\b")
for folder in $(ls -dr *)
do
    log "############$folder#######\n"
    if [[ -d "$folder" && $folder != "$th_dir" ]]
    then
#string=${string//Ö/&Ouml;}
        log "-----Folder $folder -----\n"
        htmlname=$(generate_folder $folder)
        desc=""
        if [[ -e $folder.desc ]]
        then
            desc=$(cat $folder.desc | recode "utf8..h" )
        fi
        if [[ -e $folder.pictures.tar ]]
        then
            desc="${desc}<br/>$(dl_picture_txt $folder.pictures.tar)"
        fi
        if [[ -e $folder.videos.tar ]]
        then
            desc="${desc}<br/>$(dl_video_txt $folder.videos.tar)"
        fi

        cat <<EOF >> $index
        <h1> <a href="$htmlname">$folder</a> </h1>
        $desc
EOF

    fi
done
#)

append_ga_script $index

append_links $index

append_footer $index

mv $index $final_index

}



#### MAIN ####
generate_all
