using System;
using System.IO;
namespace Bulkan;

using internal Bulkan;

internal class Libdl
{
	[CLink]
	public static extern int dlopen(char8* fileName, int flags);

	[CLink]
	public static extern int dlsym(int handle, char8* name);

	[CLink]
	public static extern int dlclose(int handle);

	[CLink]
	public static extern char8* dlerror();

	public const int32 RTLD_NOW = 0x002;
}

delegate void LoanFunctionErrorCallBack(in StringView procName);

abstract class NativeLibrary : IDisposable
{
	private readonly String mLibraryName;
	private readonly int mLibraryHandle;

	public int NativeHandle => mLibraryHandle;

	public LoanFunctionErrorCallBack LoanFunctionErrorCallBack = null;

	public this(String libraryName)
	{
		mLibraryName = libraryName;

		mLibraryHandle = LoadLibrary(mLibraryName);
		if (mLibraryHandle == default)
		{
			Runtime.FatalError(scope $"Could not load {libraryName}.");
		}
	}

	public ~this()
	{
		if (LoanFunctionErrorCallBack != null)
		{
			delete LoanFunctionErrorCallBack;
			LoanFunctionErrorCallBack = null;
		}
	}

	public abstract int LoadLibrary(StringView libraryName);

	public abstract void FreeLibrary(int libraryHandle);

	public abstract void LoadFunction(StringView functionName, out void* handle);

	public void LoadFunction<T>(StringView name, out T field, bool invokeErrorCallback = true)
	{
		void* funcPtr = null;
		LoadFunction(name, out funcPtr);

		if (funcPtr != null)
		{
			field = *(T*)(void*)(int*)&funcPtr;
		} else
		{
			field = default;
			if (LoanFunctionErrorCallBack != null && invokeErrorCallback)
			{
				LoanFunctionErrorCallBack.Invoke(name);
			}
		}
	}

	public void Dispose()
	{
		FreeLibrary(mLibraryHandle);
	}

	public static void Load(String libraryName, out NativeLibrary handle)
	{
		handle = ?;

#if BF_PLATFORM_WINDOWS
		handle = new WindowsNativeLibrary(libraryName);
		#elif BF_PLATFORM_LINUX || BF_PLATFORM_MACOS
		handle = new UnixNativeLibrary(libraryName);
#else
		Runtime.FatalError("Unsupported platform.");
#endif
	}

#if BF_PLATFORM_WINDOWS
	private class WindowsNativeLibrary : NativeLibrary
	{
		public this(String libraryName) : base(libraryName)
		{
		}
		public override int LoadLibrary(StringView libraryName)
		{
			var handle = System.Windows.LoadLibraryA(libraryName.Ptr);
			return (int)handle;
		}

		public override void FreeLibrary(int libraryHandle)
		{
			System.Windows.FreeLibrary((System.Windows.HInstance)libraryHandle);
		}

		public override void LoadFunction(StringView functionName, out void* handle)
		{
			handle = System.Windows.GetProcAddress((System.Windows.HModule)NativeHandle, functionName.Ptr);
		}
	}
#endif

	private class UnixNativeLibrary : NativeLibrary
	{
		public this(String libraryName) : base(libraryName)
		{
		}

		public override int LoadLibrary(StringView libraryName)
		{
			Libdl.dlerror();
			int handle = Libdl.dlopen(libraryName.Ptr, Libdl.RTLD_NOW);
			if (handle == 0 && !Path.IsPathRooted(libraryName))
			{
				String baseDir = scope String();
				Environment.GetExecutableFilePath(baseDir);
				if (!String.IsNullOrWhiteSpace(baseDir))
				{
					String localPath = scope String();
					Path.InternalCombine(localPath, baseDir, libraryName);
					handle = Libdl.dlopen(localPath, Libdl.RTLD_NOW);
				}
			}

			return handle;
		}

		public override void FreeLibrary(int libraryHandle)
		{
			Libdl.dlclose(libraryHandle);
		}

		public override void LoadFunction(StringView functionName, out void* handle)
		{
			handle = (void*)Libdl.dlsym(NativeHandle, functionName.Ptr);
		}
	}
}
