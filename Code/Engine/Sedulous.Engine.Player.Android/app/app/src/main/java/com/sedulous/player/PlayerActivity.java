package com.sedulous.player;

import android.content.Intent;
import android.content.pm.ApplicationInfo;

import java.util.ArrayList;
import java.util.Arrays;

import org.libsdl.app.SDLActivity;

/**
 * The player's activity: SDL's, running the player from libmain.so (SDL is linked into it, so it is
 * the one library). The player reads the game and the engine's data in place from this app's APK and
 * keeps the user's data and temporary files in the app's own storage, so it is told where each is. A
 * debuggable app also passes on the flags it was launched with (am start ... --es args "..."); a
 * release build takes none from outside.
 */
public class PlayerActivity extends SDLActivity {
    @Override
    protected String[] getLibraries() {
        return new String[] { "main" };
    }

    @Override
    protected String[] getArguments() {
        ArrayList<String> arguments = new ArrayList<>(Arrays.asList(
            "--apk", getApplicationInfo().sourceDir,
            "--files", getFilesDir().getAbsolutePath(),
            "--cache", getCacheDir().getAbsolutePath()));
        Intent intent = getIntent();
        String launched = intent != null ? intent.getStringExtra("args") : null;
        if (launched != null && (getApplicationInfo().flags & ApplicationInfo.FLAG_DEBUGGABLE) != 0) {
            for (String argument : launched.trim().split("\\s+")) {
                if (!argument.isEmpty()) {
                    arguments.add(argument);
                }
            }
        }
        return arguments.toArray(new String[0]);
    }
}
