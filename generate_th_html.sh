#! /bin/bash

#dest=photos.html
#b=20120416_PHOTO_RRC
th_size=200
th_video_size=400
int_size=1920
int_dir=int
th_dir=th
js_dir=js
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
<footer style="text-align:center; font-size:small;" >
    Generated on `LANG=C date  +'%b %d, %Y - %Hh%M'`. <a href="https://github.com/eirmag/bash-gallery">Bash Gallery</a> - Gabriel Serme
</footer>
</body>
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


    cat >> "$htmlname" <<EOF
<!DOCTYPE html>
<html>
<head>
<title>$title</title>

<!-- Add jQuery library -->
<script type="text/javascript" src="js/jquery.min.js"></script>

<!-- Add mousewheel plugin (this is optional) -->
<script type="text/javascript" src="js/jquery.mousewheel-3.0.6.pack.js"></script>

<!-- Add fancyBox -->
<link rel="stylesheet" href="js/jquery.fancybox.css?v=2.1.0" type="text/css" media="screen" />
<script type="text/javascript" src="js/jquery.fancybox.pack.js?v=2.1.0"></script>

<!-- Optionally add helpers - button, thumbnail and/or media -->
<link rel="stylesheet" href="js/jquery.fancybox-buttons.css?v=1.0.3" type="text/css" media="screen" />
<script type="text/javascript" src="js/jquery.fancybox-buttons.js?v=1.0.3"></script>
<script type="text/javascript" src="js/jquery.fancybox-media.js?v=1.0.3"></script>

<link rel="stylesheet" href="js/jquery.fancybox-thumbs.css?v=1.0.6" type="text/css" media="screen" />
<script type="text/javascript" src="js/jquery.fancybox-thumbs.js?v=1.0.6"></script>

<script type="text/javascript">
    \$(function() {
        jQuery(".fancybox").fancybox({
        padding    : 0,
        margin     : 20,
        nextEffect : 'fade',
        prevEffect : 'none',
        autoCenter : false,
        arrows     : true,
    });
    });
</script>

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
    base=`basename $file`
    extension="${base##*.}"
    base="${base%.*}"
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
intfolder=$4 #folder for better browsing experience

echo "" > $dest

append_header $dest

echo "<a href='.'>Return to homepage</a><br/>"  >> $dest

log "$folder, chech existing th for the target:\n"
for file in  $folder/*.JPG $folder/*.jpg; do
    [[ -e "$file" ]] || continue
    [[ -r "$file" ]] || continue

    file=$(echo "$file" | recode "utf8..h")
    file_size=$(identify -format "%wx%h" "$file")
    file_width=${file_size%x*}
    file_height=${file_size#*x}

    max_size=$file_width
    if (( $file_height > $max_size ))
    then
        max_size=$file_height
    fi


    base=`basename "$file" .JPG`
    target=$thfolder/$base.JPG
    inttarget=$intfolder/$base.JPG
    #if the size of the original file is inferior to the size of the intermediate picture,
    #we don't generate the intermediate picture and display the original picture instead
    if (( $max_size <= $int_size ))
    then
        log "file $file too small\n"
        inttarget=$file
    fi

    #target=$(echo $target | recode "utf8..h")
    #log "$target\n"

    if [ ! -e "$target" ]
    then
        log "Create th for $file\n"
        #reorient, then normalize size.
 #       convert -auto-orient $file $target
        convert -auto-orient -resize ${th_size}x${th_size}  "$file" "$target"
    else
        #echo "Th $target exists" >&2
        log "."
    fi
    if [ ! -e "$inttarget" ] 
    then
        log "Create int for $file\n"
        #reorient, then normalize size.
 #       convert -auto-orient $file $target
        convert -auto-orient -resize ${int_size}x${int_size}  "$file" "$inttarget"
    else
        log ":"
    fi


    cat <<EOF >> $dest
    <div style="display:inline-block;">
    <a class="fancybox" rel="group" href="$inttarget"><img alt="$base" style="max-height: 150px; max-width: ${th_size}px"  src="$target"/></a>
    </div>
EOF

done
log "\n"

files=$(ls $folder/*.MOV $folder/*.AVI $folder/*.MP4)

if [[ ${#files} -gt 0 ]] #first elem of the array as not a size of zero
then

cat <<EOF >> $dest
    <h1>Videos</h1>
EOF

log "$folder, chech existing video th for the target:\n"
for file in  $files; do
    [[ -e "$file" ]] || continue

    #log "Videos from $file: \n"
    base=`basename $file`
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
intfolder=$int_dir/$folder

mkdir -p $thfolder $intfolder

htmlname="photos-$folder.html"

generate_pictures $htmlname $folder $thfolder $intfolder

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
    if [[ -d "$folder" && $folder != "$th_dir" && $folder != "$int_dir" && $folder != "$js_dir" ]]
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
        <div style="display:inline-block;max-width:255px;vertical-align:top;"><h1 style="word-wrap: break-word;"> <a href="$htmlname">$folder</a> </h1>
        $desc
        </div>
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
