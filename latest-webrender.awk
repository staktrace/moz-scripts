BEGIN {
    in_wr_block = 0;
}

/^webrender_traits/ {
    sub(/version = ".*"/, wrt_version, $0);
}

/^webrender_api/ {
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

/^euclid/ {
    $0 = euclid_version;
}

/^app_units/ {
    $0 = au_version;
}

/^log/ {
    $0 = log_version;
}

/^core-foundation/ {
    $0 = cf_version;
}

/^core-graphics/ {
    $0 = gc_version;
}

/^/ {
    print $0;
}
