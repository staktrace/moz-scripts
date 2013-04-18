BEGIN {
    open = 1
    downtime_flat = 0
    downtime_weighted = 0
    laststamp = 0
    firststamp = 0

    split("4,5,8,8,6,6,8,8,10,10,14,12,11,12,10,10,8,8,7,6,6,5,6,4", hour_weights, ",")
    if (length(hour_weights) != 24) {
        print "Warning: hour_weights is the wrong length"
    }

    weight_total = 0
    for (i = 1; i <= length(hour_weights); i++) {
        weight_total += hour_weights[i]
    }
    weight_average = weight_total / length(hour_weights)
}

/^/ {
    if (laststamp == 0) {
        laststamp = timestamp($2)
    }
    firststamp = timestamp($2)

    if ($3 == "open") {
        if (open == 1) {
            # opened multiple times in a row, get the earliest timestamp
            opened = timestamp($2)
        } else {
            # going backwards in time from a closed state to an opened state, so
            # calculate the downtime we just passed through
            downtime_flat += flat(opened, closed)
            downtime_weighted += weighted(opened, closed)
            opened = timestamp($2)
            open = 1
        }
    } else if ($3 == "closed") {
        if (open == 0) {
            # closed multiple times in a row, get the earliest timestamp
            closed = timestamp($2)
        } else {
            # going backwards in time from an open state to a closed state.
            closed = timestamp($2)
            open = 0
        }
    }
}

END {
    totaltime = laststamp - firststamp
    print "Total time:", totaltime
    print "Downtime (flat):", downtime_flat, "(" (100 * ( downtime_flat / totaltime)) "%)"
    print "Downtime (weighted):", downtime_weighted, "(" (100 * (downtime_weighted / totaltime)) "%)"
}

function timestamp(str) {
    return ((int(substr(str, 9, 2)) * 24 + int(substr(str, 12, 2))) * 60 + int(substr(str, 15, 2))) * 60 + int(substr(str, 18, 2))
}

function flat(opened, closed) {
    return opened - closed
}

function weighted(opened, closed) {
    #print "Processing " closed "..." opened

    weighted_time = 0
    hour_boundary = closed - (closed % 3600) + 3600
    hour = (hour_boundary % (24*3600)) / 3600
    while (hour_boundary < opened) {
        #print "  range " closed " -> " hour_boundary " weight " (hour_weights[hour+1] / weight_average)
        weighted_time += (hour_boundary - closed) * (hour_weights[hour+1] / weight_average)
        closed = hour_boundary
        hour_boundary += 3600
        hour = (hour + 1) % 24
    }
    #print "  range " closed " -> " opened
    weighted_time += (opened - closed) * (hour_weights[hour+1] / weight_average)
    return weighted_time
}
