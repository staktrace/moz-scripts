## Point this to your root source directory
MOZILLA_SRC=$HOME/zspace/mozilla-w2

## Put all the raw reftest logfiles into $PWD with a .log extension.

## generate list of failures in a easy-to-use format
awk '/UNEXPECTED-FAIL/ { print $8, $7, $9 }' *.log |
while read op f1 f2; do
    if [ $op == "|" -o $f1 == "|" ]; then
        continue
    fi
    echo $op $f1 $f2
done |
sed -e "s#file:///C:/Users/task_[0-9]*/build/tests/reftest/tests/##g" |
sed -e "s#http://localhost:[0-9/]*/##" > failures

## ensure that all the failures can be located in the reftest files
## if this chunk outputs any filenames, it means they could not be found
cat failures |
while read op f1 f2; do
    folder=${f1%/*}
    subfolder=${folder##*/}
    echo "Testing $f1"
    pushd $MOZILLA_SRC/$folder >/dev/null
    ls reftest*.list | grep -v stylo | xargs grep "$op ${f1##*/} * ${f2##$folder/}" > /dev/null
    if [ $? -eq 0 ]; then
        popd >/dev/null
        continue
    fi
    ls reftest*.list | grep -v stylo | xargs grep "$op ${f1##*/} * ${f2##$subfolder/}" > /dev/null
    if [ $? -eq 0 ]; then
        popd >/dev/null
        continue
    fi
    echo "ERROR LOCATING $folder ${f1##*/} ${f2##$folder/}"
    popd >/dev/null
done

## do the reftest updates once the above is clean
cat failures |
while read op f1 f2; do
    folder=${f1%/*}
    subfolder=${folder##*/}
    pushd $MOZILLA_SRC/$folder >/dev/null
    # put the fails-if just before the $op
    ls reftest*.list | grep -v stylo | xargs sed -i -e "s@\($op ${f1##*/} * ${f2##$folder/}\)@fails-if(webrender\&\&winWidget) \1@"
    ls reftest*.list | grep -v stylo | xargs sed -i -e "s@\($op ${f1##*/} * ${f2##$subfolder/}\)@fails-if(webrender\&\&winWidget) \1@"
    # deduplicate
    ls reftest*.list | grep -v stylo | xargs sed -i -e "s@fails-if(webrender\&\&winWidget) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget)@"
    ls reftest*.list | grep -v stylo | xargs sed -i -e "s@fails-if(webrender\&\&winWidget) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget)@"
    # if there is an HTTP on the line, move the fails-if to before that
    ls reftest*.list | grep -v stylo | xargs sed -i -e "s@\(HTTP.*\) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget) \1@"
    # more deduplicate (there can be duplication here, not sure why)
    ls reftest*.list | grep -v stylo | xargs sed -i -e "s@fails-if(webrender\&\&winWidget) fails-if(webrender\&\&winWidget)@fails-if(webrender\&\&winWidget)@"
    popd >/dev/null
done

## ensure this shows nothing:
pushd $MOZILLA_SRC >/dev/null
find . -name reftest*.list | xargs grep "fails-if(webrender) fails-if(webrender)"
popd >/dev/null
