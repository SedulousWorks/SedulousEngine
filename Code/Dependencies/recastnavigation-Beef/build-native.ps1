$option = $args[0]

function PrintHelp()
{
    echo "Arguments:"
    echo "make [DEBUG|RELEASE|ALL]... configure cmake"
    echo "build [DEBUG|RELEASE|ALL]... build libraries"
    echo "clean... remove build directories"
}

if(!$option -or $option -eq "help")
{
    PrintHelp
}
elseif($option -eq "make")
{
    $target = $args[1]
    if(!$target) { $target = "ALL" }

    if($target -eq "DEBUG" -or $target -eq "ALL")
    {
        echo "Configuring Debug..."

        if(!(Test-Path build-debug))
        {
            mkdir build-debug
        }

        cmake -S ./recastnavigation-c -B build-debug -DBUILD_SHARED_LIBS=OFF
    }

    if($target -eq "RELEASE" -or $target -eq "ALL")
    {
        echo "Configuring Release..."

        if(!(Test-Path build-release))
        {
            mkdir build-release
        }

        cmake -S ./recastnavigation-c -B build-release -DBUILD_SHARED_LIBS=OFF
    }
}
elseif($option -eq "build")
{
    $target = $args[1]
    if(!$target)
    {
        echo "Build targets: DEBUG or RELEASE or ALL"
        return
    }

    if($target -eq "DEBUG" -or $target -eq "ALL")
    {
        if(!(Test-Path build-debug))
        {
            echo "Debug build directory missing. Run 'make DEBUG' first."
        }
        else
        {
            echo "Building Debug..."
            cmake --build build-debug --config Debug

            $targetPath = "./dist/Debug-Win64/"
            if(!(Test-Path $targetPath))
            {
                mkdir $targetPath
            }

            copy-item "./build-debug/lib/Debug/Recast-c.lib" "$targetPath/Recast-c.lib" -Force
            copy-item "./build-debug/lib/Debug/Detour-c.lib" "$targetPath/Detour-c.lib" -Force
            copy-item "./build-debug/lib/Debug/DetourCrowd-c.lib" "$targetPath/DetourCrowd-c.lib" -Force
            copy-item "./build-debug/lib/Debug/DetourTileCache-c.lib" "$targetPath/DetourTileCache-c.lib" -Force
            copy-item "./build-debug/lib/Debug/DebugUtils-c.lib" "$targetPath/DebugUtils-c.lib" -Force
        }
    }

    if($target -eq "RELEASE" -or $target -eq "ALL")
    {
        if(!(Test-Path build-release))
        {
            echo "Release build directory missing. Run 'make RELEASE' first."
        }
        else
        {
            echo "Building Release..."
            cmake --build build-release --config Release

            $targetPath = "./dist/Release-Win64/"
            if(!(Test-Path $targetPath))
            {
                mkdir $targetPath
            }

            copy-item "./build-release/lib/Release/Recast-c.lib" "$targetPath/Recast-c.lib" -Force
            copy-item "./build-release/lib/Release/Detour-c.lib" "$targetPath/Detour-c.lib" -Force
            copy-item "./build-release/lib/Release/DetourCrowd-c.lib" "$targetPath/DetourCrowd-c.lib" -Force
            copy-item "./build-release/lib/Release/DetourTileCache-c.lib" "$targetPath/DetourTileCache-c.lib" -Force
            copy-item "./build-release/lib/Release/DebugUtils-c.lib" "$targetPath/DebugUtils-c.lib" -Force
        }
    }
}
elseif($option -eq "clean")
{
    if(Test-Path build-debug)
    {
        echo "Removing build-debug..."
        rm -Recurse -Force build-debug
    }

    if(Test-Path build-release)
    {
        echo "Removing build-release..."
        rm -Recurse -Force build-release
    }

    echo "Clean complete."
}
