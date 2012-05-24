#include <stdlib.h>
#include <stdio.h>
#include <string.h>

int terminate = 0;

void shutdown(int sig) {
    terminate = 1;
}

int main(int argc, char** argv) {
    size_t bufsize = 4096;
    char *buffer = malloc(bufsize);
    if (! buffer) {
        fprintf(stderr, "Unable to allocate memory!");
        return -1;
    }

    FILE* logcat = popen("adb logcat -v time | tee log", "r");
    if (! logcat) {
        fprintf(stderr, "Error opening adb logcat!");
        return -2;
    }

    signal(SIGINT, &shutdown);

    int ret = 0;
    while (! terminate) {
        ssize_t linelen = getline(&buffer, &bufsize, logcat);
        if (linelen < 0) {
            if (! terminate) {
                fprintf(stderr, "Getline failed unexpectedly!");
                ret = linelen;
            }
            break;
        }

        buffer[linelen] = 0;
        printf("%s", buffer);
    }

    pclose(logcat);
    return ret;
}
