// The Android player's native entry. SDL's Java activity loads libmain.so and calls SDL_main, which
// hands the activity's arguments to Beef's main (Sedulous.Engine.Player.Android's Program.Main).
// stdout and stderr go nowhere in an app, so both are piped to logcat (tag "Sedulous") first: the
// player's log and every Console line arrive there.
#include <SDL3/SDL.h>
#include <SDL3/SDL_main.h>
#include <android/log.h>
#include <pthread.h>
#include <stdio.h>
#include <unistd.h>

extern int BeefMain(int argc, char** argv);

static int sPipe[2];

static void* ForwardToLogcat(void* unused)
{
    (void)unused;
    char line[2048];
    FILE* in = fdopen(sPipe[0], "r");
    while ((in != NULL) && (fgets(line, sizeof(line), in) != NULL))
        __android_log_write(ANDROID_LOG_INFO, "Sedulous", line);
    return NULL;
}

int SDL_main(int argc, char* argv[])
{
    setvbuf(stdout, NULL, _IOLBF, 0);
    setvbuf(stderr, NULL, _IONBF, 0);
    if (pipe(sPipe) == 0)
    {
        dup2(sPipe[1], STDOUT_FILENO);
        dup2(sPipe[1], STDERR_FILENO);
        pthread_t thread;
        if (pthread_create(&thread, NULL, ForwardToLogcat, NULL) == 0)
            pthread_detach(thread);
    }
    return BeefMain(argc, argv);
}
