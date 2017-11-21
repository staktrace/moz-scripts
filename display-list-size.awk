/Painting --- after optimization:/ {
    count = 0;
}

/^/ {
    count++;
}

/Painting --- layer tree:/ {
    print count;
}
