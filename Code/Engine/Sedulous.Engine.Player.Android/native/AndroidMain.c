// The Android player's native entry. SDL's Java activity loads libmain.so and calls SDL_main, which
// hands the activity's arguments to Beef's main (Sedulous.Engine.Player.Android's Program.Main).
// stdout and stderr go nowhere in an app, so each is piped to logcat (tag "Sedulous") first, stderr
// at error priority: the player's log and every Console line arrive there, a line per entry.
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <android/log.h>
#include <pthread.h>
#include <stdio.h>
#include <string.h>
#include <unistd.h>

extern int BeefMain(int argc, char** argv);

typedef struct
{
    int fd;
    int priority;
} Forward;

static Forward sOut = {-1, ANDROID_LOG_INFO};
static Forward sErr = {-1, ANDROID_LOG_ERROR};

// Reads whole lines (a log line written in pieces still arrives as one entry, or as several when it
// is longer than the buffer) and drops the newline, which logcat adds itself.
static void* ForwardToLogcat(void* argument)
{
    const Forward* forward = (const Forward*)argument;
    char line[2048];
    FILE* in = fdopen(forward->fd, "r");
    while ((in != NULL) && (fgets(line, sizeof(line), in) != NULL))
    {
        size_t n = strlen(line);
        while ((n > 0) && ((line[n - 1] == '\n') || (line[n - 1] == '\r')))
            line[--n] = '\0';
        if (n > 0)
            __android_log_write(forward->priority, "Sedulous", line);
    }
    return NULL;
}

// Points `target` (stdout or stderr) at a pipe that a thread of its own empties into logcat.
static void Redirect(int target, Forward* forward)
{
    int ends[2];
    if (pipe(ends) != 0)
        return;
    dup2(ends[1], target);
    close(ends[1]);
    forward->fd = ends[0];
    pthread_t thread;
    if (pthread_create(&thread, NULL, ForwardToLogcat, forward) == 0)
        pthread_detach(thread);
}

int SDL_main(int argc, char* argv[])
{
    setvbuf(stdout, NULL, _IOLBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
    Redirect(STDOUT_FILENO, &sOut);
    Redirect(STDERR_FILENO, &sErr);
    return BeefMain(argc, argv);
}
