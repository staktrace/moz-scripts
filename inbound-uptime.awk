BEGIN {
    open = 1
    downtime = 0
    lastopened = 0
    firststamp = 0
}

/^/ {
    if ($3 == "open" && open == 1) {
        opened = timestamp($2)
        if (lastopened == 0) {
            lastopened = opened
        }
        firststamp = opened
        open = 0
    } else if ($3 == "closed" && open == 0) {
        closed = timestamp($2)
        firststamp = closed
        open = 1
        downtime += (opened - closed)
    }
}

END {
    print "Downtime:", downtime
    print "Total time:", (lastopened - firststamp)
    print "Uptime ratio:", 100 * ((lastopened - firststamp - downtime) / (lastopened - firststamp))
}

function timestamp(str) {
    return ((int(substr(str, 9, 2)) * 24 + int(substr(str, 12, 2))) * 60 + int(substr(str, 15, 2))) * 60 + int(substr(str, 18, 2))
}
