## Point this to your root source directory
MOZILLA_SRC=$HOME/zspace/gecko-mobile

## Put all the raw reftest logfiles into $PWD with a .log extension.

## generate list of failures in a easy-to-use format
awk '/UNEXPECTED-FAIL/ { print $6, $5, $7, $1, int($13), $18 }' *.log |
sed -e "s#file:///C:/Users/task_[0-9]*/build/tests/reftest/tests/##g" |
sed -e "s#http://10.7.205.213:8854/tests/##g" |
sed -e "s#http://localhost:[0-9/]*/##" > failures

## ensure that all the failures can be located in the reftest files
## if this chunk outputs any filenames, it means they could not be found
cat failures |
while read op f1 f2 cnt fuzz1 fuzz2; do
    folder=${f1%/*}
    subfolder=${folder##*/}
    echo "Testing $f1"
    pushd $MOZILLA_SRC/$folder >/dev/null
    ls reftest*.list 2>/dev/null | xargs grep "$op ${f1##*/} * ${f2##$folder/}" > /dev/null
    if [ $? -eq 0 ]; then
        popd >/dev/null
        continue
    fi
    ls reftest*.list 2>/dev/null | xargs grep "$op ${f1##*/} * ${f2##$subfolder/}" > /dev/null
    if [ $? -eq 0 ]; then
        popd >/dev/null
        continue
    fi
    if [[ $folder == layout/reftests/w3c-css/received/* ]]; then
        folder="layout/reftests/w3c-css/received/"
        cd $MOZILLA_SRC/$folder
        ls reftest.list 2>/dev/null | xargs grep "$op ${f1#$folder} * ${f2#$folder}" > /dev/null
        if [ $? -eq 0 ]; then
            popd >/dev/null
            continue
        fi
    fi
    echo "ERROR LOCATING $folder ${f1##*/} ${f2##$folder/} or $subfolder"
    popd >/dev/null
done

# ## do the reftest updates once the above is clean
cat failures |
while read op f1 f2 cnt fuzz1 fuzz2; do
    folder=${f1%/*}
    subfolder=${folder##*/}
    pushd $MOZILLA_SRC/$folder >/dev/null
    # put the fails-if just before the $op
    if [ $cnt -eq 2 ]; then
        annotation="fuzzy-if(geckoview\&\&webrender,${fuzz1}-${fuzz1},${fuzz2}-${fuzz2})"
    else
        annotation="fuzzy-if(geckoview\&\&webrender,0-${fuzz1},0-${fuzz2})"
    fi
    ls reftest*.list 2>/dev/null | xargs sed -i -e "s@\($op ${f1##*/} * ${f2##$folder/}\)@${annotation} \1@"
    ls reftest*.list 2>/dev/null | xargs sed -i -e "s@\($op ${f1##*/} * ${f2##$subfolder/}\)@${annotation} \1@"
    if [[ $folder == layout/reftests/w3c-css/received/* ]]; then
        folder="layout/reftests/w3c-css/received/"
        cd $MOZILLA_SRC/$folder
        ls reftest.list 2>/dev/null | xargs sed -i -e "s@\($op ${f1#$folder} * ${f2#$folder}\)@${annotation} \1@"
    fi
    # deduplicate
    # ls reftest*.list | xargs sed -i -e "s@fails-if(webrender\&\&winWidget) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget)@"
    # ls reftest*.list | xargs sed -i -e "s@fails-if(webrender\&\&winWidget) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget)@"
    # if there is an HTTP on the line, move the fails-if to before that
    ls reftest*.list 2>/dev/null | xargs sed -i -e "s@\(HTTP.*\) ${annotation}@${annotation} \1@"
    # more deduplicate (there can be duplication here, not sure why)
    # ls reftest*.list | xargs sed -i -e "s@fails-if(webrender\&\&winWidget) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget)@"
    popd >/dev/null
done

# ## ensure this shows nothing:
# pushd $MOZILLA_SRC >/dev/null
# find . -name reftest*.list | xargs grep "fails-if(geckoview) fails-if(geckoview)"
# popd >/dev/null
