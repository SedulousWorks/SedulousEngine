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
        echo "Configuring Debug (/MTd)..."

        if(!(Test-Path build-debug))
        {
            mkdir build-debug
        }

        cmake -S ./joltc -B build-debug
    }

    if($target -eq "RELEASE" -or $target -eq "ALL")
    {
        echo "Configuring Release (/MT)..."

        if(!(Test-Path build-release))
        {
            mkdir build-release
        }

        cmake -S ./joltc -B build-release

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

            copy-item "./build-debug/lib/Debug/joltcd.lib" "$targetPath/joltcd.lib" -Force
            copy-item "./build-debug/lib/Debug/joltd.lib"  "$targetPath/joltd.lib"  -Force
            copy-item "./build-debug/bin/Debug/joltcd.dll"  "$targetPath/joltcd.dll"  -Force
            copy-item "./build-debug/bin/Debug/joltcd.pdb"  "$targetPath/joltcd.pdb"  -Force
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

            copy-item "./build-release/lib/Release/joltc.lib" "$targetPath/joltc.lib" -Force
            copy-item "./build-release/lib/Release/jolt.lib"  "$targetPath/jolt.lib"  -Force
            copy-item "./build-release/bin/Release/joltc.dll"  "$targetPath/joltc.dll"  -Force
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
