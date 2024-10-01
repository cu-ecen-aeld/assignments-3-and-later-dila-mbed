#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <syslog.h>
#include <errno.h>

int main(int argc, char *argv[])
{
    // Open syslog
    openlog("writer", LOG_PID | LOG_CONS, LOG_USER);

    // Argument check
    if (argc != 3){
        fprintf(stderr, "Usage: %s <file> <string>\n", argv[0]);
        syslog(LOG_ERR, "Incorrect number of arguments: expected 2, got %d", argc-1);
        return 1;
    }

    const char *writefile = argv[1];
    const char *writestr = argv[2];

    // Log the action
    syslog(LOG_DEBUG, "Writing %s to %s", writestr, writefile);

    // Open the file
    FILE *file = fopen(writefile, "w");
    if(file == NULL)
    {
        syslog(LOG_ERR, "Error opening file %s: %s", writefile, strerror(errno));
        closelog();
        return 1;
    }

    // Write the string to the file
    if(fprintf(file, "%s", writestr) < 0){
        syslog(LOG_ERR, "Error opening file %s: %s", writefile, strerror(errno));
        fclose(file);
        closelog();
        return 1;
    }

    // Close the file
    if(fclose(file) != 0){
        syslog(LOG_ERR, "Error closing file %s: %s", writefile, strerror(errno));
        closelog();
        return 1;
    }

    // Close syslog
    closelog();
    return 0;
}
