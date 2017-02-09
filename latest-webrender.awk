BEGIN {
    in_wr_block = 0;
}

/^webrender_traits/ {
    sub(/version = ".*"/, wrt_version, $0);
}

/dependencies.webrender/ {
    in_wr_block = 1;
}

/^version/ {
    if (in_wr_block) {
        $0 = wr_version;
        in_wr_block = 0;
    }
}

/^$/ {
    in_wr_block = 0;
}

/^/ {
    print $0;
}
