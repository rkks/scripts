#!/bin/bash
#  DETAILS: Script to build the gh-pages
#  CREATED: 06/09/17 19:27:48 IST
# MODIFIED: 16/11/2022 05:42:14 PM IST
# REVISION: 1.0
#
#   AUTHOR: Ravikiran K.S., ravikirandotks@gmail.com
#  LICENCE: Copyright (c) 2017, Ravikiran K.S.

#set -uvx   # Warn unset vars, Verbose (echo each command), Enable debug mode

#No PATH redefine. Use environment provided settings
MD=md
HDR=md
LST=lst
PST=pst
DATE='date -d'

# place website.html pandoc template at $HOME/.pandoc/templates/

usage()
{
    echo "Usage: mkweb.sh [-h|-a|-b|-c]"
    echo "Options:"
    echo "  -a <abs-repo-path>  - absolute repo path"
    echo "  -b                  - build web pages"
    echo "  -c                  - clean web pages"
    echo "  -f                  - build full resume"
    echo "  -r                  - build rss feeds"
    echo "  -s                  - build short resume"
    echo "  -u                  - create user web"
    echo "  -t                  - delete user web"
    echo "  -h                  - print this help"
}

set_paths()
{
    [[ $# -ne 1 ]] && { echo "usage: set_paths <repo-dir>"; exit 1; }
    [[ ! -d $1 ]] && { echo "Invalid repo=$1"; exit 1; } || { cd $1; }

    WEBREPO="$1"
    [[ $(basename $1) =~ rkks.github.io ]] && { echo -n "User "; } || { echo -n "Project "; }
    echo "website repo set to $1";
    # user website rkks.github.io needs to have everything in base/root directory
    [[ $(basename $1) =~ rkks.github.io ]] && { PUBLISH=$1; CONTENT=$1; STATIC=$1; CSS=.; IMG=.; }\
        || { PUBLISH=$1/docs; CONTENT=$1/content; STATIC=$1/static; CSS=./css; IMG=./img; }
    ALLPOST=$PUBLISH/allposts
    LATEST5=$PUBLISH/latest5.$PST
    FOOTER=$STATIC/html/footer.html
    NAVBAR=$STATIC/html/navbar.html

    # order if css import matters, first bootstrap.css, then color theme
    PD_CMN_OPTS="--standalone -f markdown "; # --smart enabled by default now
#    PD_CV_OPTS+="-c $CSS/font.css -c https://fonts.googleapis.com/css?family=Open+Sans:regular,italic,bold";
    PD_CV_OPTS="$PD_CMN_OPTS -c $CSS/resume.css";
    PD_WIKI_OPTS="--template=website.html -B $NAVBAR -A $FOOTER \
        -c $CSS/bootstrap.css -c $CSS/theme.css -c $CSS/web.css";
    PD_OPTS="$PD_CMN_OPTS $PD_WIKI_OPTS"
}

check_paths()
{
    [[ ! -z $WEBREPO ]] && { echo "Repo already set to $WEBREPO"; return; }
    set_paths "$PWD";
}

cp_static_data()
{
    cp -r $STATIC/css $PUBLISH/
    cp -r $STATIC/img $PUBLISH/
}

build_post()
{
    [[ $# -ne 2 ]] && { echo "usage: build_post <topic> <file-path>"; return; }

    local topic="$1"; local file="$2";
    local post="$(basename ${file%.*})";

    # process only newer files. -nt: newer than, -ot: older than
    [[ $file -ot $PUBLISH/$post.html ]] && { return; }

    local title="$(sed -n '1 s/% //p' "$file")";
    local pdate="$(sed -n '3 s/% //p' "$file")";
    local ddate="$($DATE "$pdate" '+%a, %d %b %Y 00:00:00 +0530')";    # time important for rss
    local sdate="$($DATE "$pdate" '+%y%m%d')";
    local btopic=$(tr '[:lower:]' '[:upper:]' <<< ${topic:0:1})${topic:1};
    #echo "[PD] $ddate | $post | $title";
    echo "[PD] $ddate | $post.html";
    pandoc $PD_OPTS --variable=category:"${btopic}" --output=$PUBLISH/"$post".html "$file";

    local abstract=$(grep -m 1 -Eo '<p>.+</p>' $PUBLISH/"$post".html)
    local topic_lst=$PUBLISH/$topic.$LST
    echo "$sdate"%"$title"%"$post.html"%"$pdate"%"$ddate"%"$abstract" >> $topic_lst
}

build_topic()
{
    [[ $# -ne 1 ]] && { echo "usage: build_topic <topic>"; return; }
    local topic="$1"; local topic_lst=$PUBLISH/$topic.$LST; local topic_pst=$PUBLISH/$topic.$PST;

    [[ ! -f $topic_lst ]] && { echo "Nothing to build in $topic. $topic_lst empty"; return; }
    [[ ! -f $topic.$HDR ]] && { echo "$topic.$HDR not found"; return; }

    cat $topic_lst >> $ALLPOST
    sort -nr $topic_lst | awk 'BEGIN{FS="%"};{print "* ["$2"]("$3") | "$4}' > $topic_pst

    echo "[PD] $(date '+%a, %d %b %Y 00:00:00 +0530') | $topic.html";
    pandoc $PD_OPTS --output=$PUBLISH/$topic.html $CONTENT/$topic.$HDR $topic_pst;
    rm -f $topic_lst $topic_pst
}

build_static()
{
    build_html $CONTENT/tech.md
}

build_html()
{
    [[ $# -ne 1 ]] && { echo "usage: build_html <file-path>"; return; }
    [[ ! -f $1 ]] && { echo "$1 file not found"; return; }
    local fpath="$1"; local file=$(basename $fpath); local name=${file%.*};
    echo "[PD] $(date '+%a, %d %b %Y 00:00:00 +0530') | $name.html";
    pandoc $PD_OPTS -o $PUBLISH/$name.html $fpath
}

build_resume()
{
    [[ $# -ne 1 ]] && { echo "usage: build_resume <file-path>"; return; }
    [[ ! -f $1 ]] && { echo "$1 file not found"; return; }
    local fpath="$1"; local file=$(basename $fpath); local name=${file%.*};
    echo "[PD] $(date '+%a, %d %b %Y 00:00:00 +0530') | $name.html";
    echo "pandoc $PD_CV_OPTS -o $PUBLISH/$name.html $fpath; pwd $(pwd)"
    pandoc --verbose $PD_CV_OPTS --metadata pagetitle="Resume" -o $PUBLISH/$name.html $fpath
    #pandoc $PD_CV_OPTS --to docx -o $PUBLISH/$name.docx $fpath
    echo "[PD] $(date '+%a, %d %b %Y 00:00:00 +0530') | $name.pdf";
    # --disable-smart-shrinking 
    wkhtmltopdf --enable-local-file-access -q -s A3 $PUBLISH/$name.html $PUBLISH/$name.pdf
}

build_index()
{
    #[[ $WEBREPO =~ *github.io* ]] && { return 0; }  # bypass index.html generation for root
    [[ ! -f $ALLPOST ]] && { echo "$ALLPOST file does not exist"; return; }
    [[ ! -f $CONTENT/index.$HDR ]] && { echo "$CONTENT/index.$HDR does not exist"; return; }

    sort -nr $ALLPOST | sed -n '1,5 p' | awk 'BEGIN{FS="%"};{print "* ["$2"]("$3") | "$4}' > $LATEST5
    echo "[PD] $(date '+%a, %d %b %Y 00:00:00 +0530') | index.html";
    pandoc $PD_OPTS -o $PUBLISH/index.html $CONTENT/index.$HDR $CONTENT/about.$HDR $LATEST5 --metadata pagetitle="RK Wiki";
    rm -f $ALLPOST $LATEST5;
}

build_rss_feeds()
{
    echo "[RSS] $(date '+%a, %d %b %Y 00:00:00 +0530') | feed.xml";
    cp $STATIC/xml/feed.xml $PUBLISH/feed.xml;
    sort -nr $ALLPOST | sed -n '1,8 p' > $PUBLISH/recent_feeds;
    while read post; do
        echo "$post" |\
            awk 'BEGIN{FS="%"}
                {print "\t<item>"}
                {print "\t\t<title>" $2 "</title>"}
                {print "\t\t<link>http://rkks.github.io/wiki/" $3 "</link>"}
                {print "\t\t<guid>http://rkks.github.io/wiki/" $3 "</guid>"}
                {print "\t\t<pubDate>" $5 "</pubDate>"}
                {print "\t\t<description>" $6 "[...]</description>\n\t</item>"}'\
                >> $PUBLISH/feed.xml
    done < $PUBLISH/recent_feeds
    echo '    </channel>' >> $PUBLISH/feed.xml;
    echo '</rss>' >> $PUBLISH/feed.xml;
    perl -pi -e 's/<p>//g' $PUBLISH/feed.xml
    perl -pi -e 's/<\/p>//g' $PUBLISH/feed.xml
    rm -f $PUBLISH/recent_feeds;
}

build_proj_website()
{
    [[ $(basename $WEBREPO) =~ rkks.github.io ]] && { echo "User website, not project. Exit."; exit 0; }
    [[ ! -d $CONTENT ]] && { echo "Invalid content=$CONTENT"; exit 1; }
    [[ ! -d $PUBLISH ]] && { mkdir -p $PUBLISH; }

    local dir=""; local file=""; local topic=""; local post="";
    cd $CONTENT;
    # $(ls -l $CONTENT | awk '/^d/ {print $NF}')
    for dir in $(cat $CONTENT/post-index); do
        topic=$(basename ${dir%/});
        echo "topic: $topic";
        for file in $(ls $topic/*.$MD 2>/dev/null); do
            # process only files with proper pandoc title block
            local title="$(head -n 1 "$file" | awk '{print $1}')"
            if [ "$title" != "%" ]; then
                echo "$file: pandoc title block not found. skip";
                continue;
            fi
            build_post "$topic" "$file";
        done
        build_topic "$topic"
        echo ""
    done
    build_static
    build_rss_feeds;
    build_index;
    cp_static_data;
}

assemble_resume()
{
    [[ $(basename $WEBREPO) != rkks.github.io ]] && { echo "Project website, not User. Exit"; exit 0; }
    cat $CONTENT/title.$HDR $CONTENT/competency.$HDR $CONTENT/articles.$HDR $CONTENT/summary.$HDR > $CONTENT/resume.$HDR
    if [ ! -z $FULL_RESUME ]; then
        cat $CONTENT/versa.$HDR >> $CONTENT/resume.$HDR;
        cat $CONTENT/cisco.$HDR $CONTENT/juniper.$HDR >> $CONTENT/resume.$HDR;
        cat $CONTENT/stoke.$HDR $CONTENT/ccpu.$HDR >> $CONTENT/resume.$HDR;
        cat $CONTENT/consult.$HDR $CONTENT/education.$HDR >> $CONTENT/resume.$HDR;
    fi
    cat $CONTENT/foss.$HDR $CONTENT/footer.$HDR >> $CONTENT/resume.$HDR
    build_resume $CONTENT/resume.$HDR;
}

clean_proj_website()
{
    [[ $(basename $WEBREPO) =~ rkks.github.io ]] && { echo "User website, not project. Exit."; exit 0; }
    [[ ! -d $PUBLISH ]] && { echo "Invalid publish=$PUBLISH"; exit 1; }

    rm -rf $PUBLISH/*;
    echo "Cleaned $PUBLISH/";
}

clean_user_website()
{
    [[ $(basename $WEBREPO) != rkks.github.io ]] && { echo "Project website, not User. Exit."; exit 0; }
    [[ ! -d $PUBLISH ]] && { echo "Invalid publish=$PUBLISH"; exit 1; }

    rm -rf $PUBLISH/*.html $PUBLISH/*.pdf $PUBLISH/*.docx;
    echo "Cleaned $PUBLISH/";
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:bcfrstu"
    local opts_found=0
    while getopts ":$PARSE_OPTS" opt; do
        case $opt in
        [a-zA-Z0-9])
            #echo DEBUG "-$opt was triggered, Parameter: $OPTARG"
            local "opt_$opt"=1 && local "optarg_$opt"="$OPTARG"
            ;;
        \?)
            echo "Invalid option: -$OPTARG"; usage; exit $EINVAL
            ;;
        :)
            echo "[ERROR] Option -$OPTARG requires an argument";
            usage; exit $EINVAL
            ;;
        esac
        shift $((OPTIND-1)) && OPTIND=1 && local opts_found=1;
    done

    if ((!opts_found)); then
        usage && exit $EINVAL;
    fi

    ((opt_a)) && { set_paths "$optarg_a"; }
    ((opt_c)) && { check_paths; clean_proj_website; }
    ((opt_b)) && { check_paths; build_proj_website; }
    ((opt_r)) && { check_paths; build_rss_feeds; }
    ((opt_f)) && { FULL_RESUME=1; }
    ((opt_f || opt_s)) && { check_paths; assemble_resume; }
    ((opt_t)) && { check_paths; clean_user_website; }
    ((opt_u)) && { check_paths; build_user_website; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "mkweb.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
