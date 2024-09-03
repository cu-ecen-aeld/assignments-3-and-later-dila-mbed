#include "systemcalls.h"
#include <stdlib.h>  // for system()
#include <stdbool.h> // for bool type
#include <stdarg.h>  // for va_list, va_start, va_end
#include <unistd.h>  // for fork(), execv()
#include <sys/wait.h> // for waitpid()
#include <fcntl.h>   // for open(), O_WRONLY, O_CREAT

/**
 * @param cmd the command to execute with system()
 * @return true if the command in @param cmd was executed
 *   successfully using the system() call, false if an error occurred,
 *   either in invocation of the system() call, or if a non-zero return
 *   value was returned by the command issued in @param cmd.
 */
bool do_system(const char *cmd)
{
    // Call system() with the given command
    int result = system(cmd);

    // Return true if the system() call was successful (i.e., returned 0)
    return (result != -1 && WIFEXITED(result) && WEXITSTATUS(result) == 0);
}

/**
 * @param count - The number of variables passed to the function. The variables are command to execute,
 *   followed by arguments to pass to the command.
 *   Since exec() does not perform path expansion, the command to execute needs
 *   to be an absolute path.
 * @param ... - A list of 1 or more arguments after the @param count argument.
 *   The first is always the full path to the command to execute with execv().
 *   The remaining arguments are a list of arguments to pass to the command in execv().
 * @return true if the command @param ... with arguments @param arguments were executed successfully
 *   using the execv() call, false if an error occurred, either in invocation of the
 *   fork, waitpid, or execv() command, or if a non-zero return value was returned
 *   by the command issued in @param arguments with the specified arguments.
 */
bool do_exec(int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count+1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    va_end(args);

    pid_t pid = fork();
    if (pid == -1)
    {
        // Fork failed
        return false;
    }
    else if (pid == 0)
    {
        // Child process
        execv(command[0], command);
        // If execv returns, there was an error
        exit(EXIT_FAILURE);
    }
    else
    {
        // Parent process
        int status;
        if (waitpid(pid, &status, 0) == -1)
        {
            return false;
        }
        return (WIFEXITED(status) && WEXITSTATUS(status) == 0);
    }
}

/**
 * @param outputfile - The full path to the file to write with command output.
 *   This file will be closed at completion of the function call.
 * All other parameters, see do_exec above.
 */
bool do_exec_redirect(const char *outputfile, int count, ...)
{
    va_list args;
    va_start(args, count);
    char *command[count+1];
    int i;
    for (i = 0; i < count; i++)
    {
        command[i] = va_arg(args, char *);
    }
    command[count] = NULL;

    va_end(args);

    pid_t pid = fork();
    if (pid == -1)
    {
        // Fork failed
        return false;
    }
    else if (pid == 0)
    {
        // Child process
        // Open the output file for writing, create it if it doesn't exist
        int fd = open(outputfile, O_WRONLY | O_CREAT | O_TRUNC, 0644);
        if (fd == -1)
        {
            exit(EXIT_FAILURE); // Exit if file can't be opened
        }

        // Redirect stdout to the file
        if (dup2(fd, STDOUT_FILENO) == -1)
        {
            close(fd);
            exit(EXIT_FAILURE); // Exit if redirection fails
        }

        close(fd); // Close the file descriptor after redirection

        // Execute the command
        execv(command[0], command);
        // If execv returns, there was an error
        exit(EXIT_FAILURE);
    }
    else
    {
        // Parent process
        int status;
        if (waitpid(pid, &status, 0) == -1)
        {
            return false;
        }
        return (WIFEXITED(status) && WEXITSTATUS(status) == 0);
    }
}

