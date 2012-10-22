#include <stdlib.h>
#include <unistd.h>
#include <stdio.h>

int main( int argc, char** argv ) {
    int megs = (argc > 1 ? atoi( argv[1] ) : 128);
    int i;
    for (i = 0; i < megs * 1024; i++) {
        char* buf = malloc( 1024 );
        if (!buf) {
            fprintf(stderr, "Failed allocation at on %d mibibyte\n");
            break;
        }
        buf[0] = 0xFF;
    }
    fprintf(stderr, "Allocation complete. Sleeping...\n");
    while (1) {
        sleep(3600);
    }
    return 0;
}
