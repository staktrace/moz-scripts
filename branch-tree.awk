BEGIN {
    wtree = 1
}

/^/ {
    if ($0 == "-") {
        wtree = 0
    } else if (wtree) {
        map[$3] = $1
    } else if ($1 == "*") {
        print $0, map["[" $2 "]"]
    } else if (map["[" $1 "]"]) {
        print "*", $1, map["[" $1 "]"]
    } else {
        print $0
    }
}
