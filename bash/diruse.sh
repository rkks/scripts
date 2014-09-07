diruse()
{
    echo "Recursive Disk Usage for $PWD"
    for node in *; do
        if [ -d $node ]; then
            du -hs $node
        fi
    done
    du -hs $PWD
}
diruse
