#!/bin/bash
#  DETAILS: Script to build the gh-pages
#  CREATED: 06/09/17 19:27:48 IST
# MODIFIED: 06/12/17 10:12:00 IST
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
    echo "  -h                  - print this help"
}

set_paths()
{
    [[ $# -ne 1 ]] && { echo "usage: set_paths <repo-dir>"; exit 1; }
    [[ ! -d $1 ]] && { echo "Invalid repo=$1"; exit 1; } || { cd $1; }
    WEBREPO="$1"
    CONTENT=$WEBREPO/content
    PUBLISH=$WEBREPO/docs
    ALLPOST=$PUBLISH/allposts
    LATEST5=$PUBLISH/latest5.$PST
    STATIC=$WEBREPO/static
    FOOTER=$STATIC/html/footer.html
    NAVBAR=$STATIC/html/navbar.html

    # order if css import matters, first bootstrap.css, then color theme
    PD_OPTS="--smart --standalone -f markdown --template=website.html \
        --css=./css/bootstrap.css --css=./css/web.css \
        --css=./css/solarized-light.css -B $NAVBAR -A $FOOTER";
}

check_paths()
{
    [[ -n $WEBREPO ]] && { echo "Repo set to $WEBREPO"; return; }
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
    [[ $file -ot $PUBLISH/$post.html ]] && { continue; }

    local title="$(sed -n '1 s/% //p' "$file")";
    local pdate="$(sed -n '3 s/% //p' "$file")";
    local ddate="$($DATE "$pdate" '+%a, %d %b %Y %Z')";
    local sdate="$($DATE "$pdate" '+%y%m%d')";
    #echo "[PD] $ddate | $post | $title";
    echo "[PD] $ddate | $post.html";
    pandoc $PD_OPTS --variable=category:"$topic" --output=$PUBLISH/"$post".html "$file";

    local abstract=$(grep -m 1 -Eo '<p>.+</p>' $PUBLISH/"$post".html)
    local topic_lst=$PUBLISH/$topic.$LST
    echo "$sdate"%"$title"%"$post.html"%"$pdate"%"$ddate"%"$abstract" >> $topic_lst
}

build_topic()
{
    [[ $# -ne 1 ]] && { echo "usage: build_topic <topic>"; return; }
    local topic="$1"; local topic_lst=$PUBLISH/$topic.$LST; local topic_pst=$PUBLISH/$topic.$PST;

    [[ ! -f $topic_lst ]] && { echo "$topic_lst not found"; return; }
    [[ ! -f $topic.$HDR ]] && { echo "$topic.$HDR not found"; return; }

    cat $topic_lst >> $ALLPOST
    sort -nr $topic_lst | awk 'BEGIN{FS="%"};{print "* ["$2"]("$3") | "$4}' > $topic_pst

    echo "[PD] $(date '+%a, %d %b %Y %Z') | $topic.html";
    pandoc $PD_OPTS --output=$PUBLISH/$topic.html $CONTENT/$topic.$HDR $topic_pst;
    rm -f $topic_lst $topic_pst
}

build_html()
{
    [[ $# -ne 1 ]] && { echo "usage: build_html <file-path>"; return; }
    [[ ! -f $1 ]] && { echo "$1 file not found"; return; }
    local fpath="$1"; local file=$(basename $fpath); local name=${file%.*};
    echo "[PD] $(date '+%a, %d %b %Y %Z') | $name.html";
    pandoc $PD_OPTS -o $PUBLISH/$name.html $fpath
}

build_index()
{
    [[ ! -f $ALLPOST ]] && { echo "$ALLPOST file does not exist"; return; }
    [[ ! -f $CONTENT/index.$HDR ]] && { echo "$CONTENT/index.$HDR does not exist"; return; }

    sort -nr $ALLPOST | sed -n '1,5 p' | awk 'BEGIN{FS="%"};{print "* ["$2"]("$3") | "$4}' > $LATEST5
    echo "[PD] $(date '+%a, %d %b %Y %Z') | index.html";
    pandoc $PD_OPTS -o $PUBLISH/index.html $CONTENT/index.$HDR $LATEST5
    rm -f $ALLPOST $LATEST5

    build_html $CONTENT/about.$HDR;
    build_html $CONTENT/resume/resume.$HDR;
}

build_rss_feeds()
{
    echo "[RSS] $(date '+%a, %d %b %Y %Z') | feed.xml";
    cp $STATIC/xml/feed.xml $PUBLISH/feed.xml;
    sort -nr $ALLPOST | sed -n '1,8 p'|\
    awk 'BEGIN{FS="%"}
    {print "\t<item>"}
    {print "\t\t<title>" $2 "</title>"}
    {print "\t\t<link>http://rkks.github.io/" $3 "</link>"}
    {print "\t\t<guid>http://rkks.github.io/" $3 "</guid>"}
    {print "\t\t<pubDate>" $5 "</pubDate>"}
    {print "\t\t<description>" $6 "[...]</description>\n\t</item>"}
    END{print "</channel>\n</rss>"}'\
    >> $PUBLISH/feed.xml
}

build_website()
{
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
            if [ $(head -n 1 "$file" | awk '{print $1}') != "%" ]; then
                #echo "$file: pandoc title block not found. skip";
                continue;
            fi
            build_post "$topic" "$file";
        done
        build_topic "$topic"
        echo ""
    done
    build_rss_feeds;
    build_index;
    cp_static_data;
}

clean_website()
{
    [[ ! -d $PUBLISH ]] && { echo "Invalid publish=$PUBLISH"; exit 1; }

    rm -rf $PUBLISH/*;
    echo "Cleaned $PUBLISH/";
}

# Each shell script has to be independently testable.
# It can then be included in other files for functions.
main()
{
    PARSE_OPTS="ha:bc"
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

    ((opt_a)) && { set_paths "$optarg_a"; clean_website; }
    ((opt_b)) && { check_paths; build_website; }
    ((opt_c)) && { check_paths; clean_website; }
    ((opt_h)) && { usage; }

    exit 0;
}

if [ "mkweb.sh" == "$(basename $0)" ]; then
    main $*
fi
# VIM: ts=4:sw=4:sts=4:expandtab
