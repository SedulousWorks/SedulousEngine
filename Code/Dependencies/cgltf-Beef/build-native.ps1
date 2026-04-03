$option = $args[0]
if(!$option -or $option -eq "help")
{
	echo "Arguments:"
	echo "make... runs cmake"
	echo "clean... deletes the build-directory"
	echo "build [DEBUG|RELEASE|ALL]... builds the debug or release library"
}
elseif(($option -eq "make") -or (!$option))
{
    if(!(Test-Path build))
    {
		mkdir build
    }
    cd build
    cmake ../
    cd ..
}
elseif($option -eq "clean")
{
    if(Test-Path build)
    {
        echo "Removing old build directory..."
        rm -Recurse build
    }
    else
    {
        echo "Already clean."
    }
}
elseif($option -eq "build")
{
	if(!(Test-Path build))
    {
        echo "Build directory doesn't exist."
    }
    else
    {
		if(!$args[1] -or $args[1] -eq "help")
		{
			echo "Build targets: DEBUG or RELEASE"
		}
		
		[bool] $built = $false
		
        if($args[1] -eq "DEBUG" -or $args[1] -eq "ALL")
        {
            echo "Building debug..."
            cmake --build build --config Debug
            echo "Finished build."
            echo "Copying library..."
			
            $targetPath = "./dist/Debug-Win64/"
            if(!(Test-Path $targetPath))
            {
		        mkdir $targetPath
            }
			copy-item "./build/Debug/cgltf.lib" ($targetPath + "cgltf.lib") -Force
			$built = $true
        }
        
		if($args[1] -eq "RELEASE" -or $args[1] -eq "ALL")
        {
            echo "Building release..."
            cmake --build build --config Release
            echo "Finished build."
            echo "Copying library..."
			
            $targetPath = "./dist/Release-Win64/"
            if(!(Test-Path $targetPath))
            {
		        mkdir $targetPath
            }
			copy-item "./build/Release/cgltf.lib" ($targetPath + "cgltf.lib") -Force
			$built = $true
        }
		
		if($built -eq $false)
		{
			echo "No build attempted."
		}
    }
}