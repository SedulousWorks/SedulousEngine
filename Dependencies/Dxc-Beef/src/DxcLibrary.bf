using System;

namespace Dxc_Beef;

/// Resolves dxcompiler at RUN TIME rather than linking it.
///
/// A static [CLink] on DxcCreateInstance puts an undefined symbol in every object that
/// references it, and a browser has no dxcompiler at all: the wasm link then fails on a symbol
/// for a path that is never taken there, because shaders arrive cooked in a pack and nothing
/// compiles at run time. Loading it instead means the failure lands where it belongs, as a
/// ShaderCompiler.Initialize that returns an error and logs a line.
///
/// Windows keeps the import library: it is the platform where the compiler is always wanted,
/// its loader semantics differ, and nothing there needs the graceful miss.
static class DxcLibrary
{
#if !BF_PLATFORM_WINDOWS
	private const int32 cRtldNow = 0x002;

	[CLink]
	private static extern void* dlopen(char8* fileName, int32 flags);

	[CLink]
	private static extern void* dlsym(void* handle, char8* name);

	private static void* sHandle = null;
	private static bool sAttempted = false;

	public function HRESULT CreateInstanceFn(in Guid rclsid, in Guid riid, out void* ppv);

	private static CreateInstanceFn sCreateInstance = null;

	/// The entry point, or null when dxcompiler is not present. Resolved ONCE: a miss is a
	/// property of the machine, so retrying it every call would only repeat the same failure.
	public static CreateInstanceFn CreateInstance
	{
		get
		{
			if (sAttempted)
				return sCreateInstance;
			sAttempted = true;

#if BF_PLATFORM_MACOS
			let name = "libdxcompiler.dylib";
#else
			let name = "libdxcompiler.so";
#endif
			// Unqualified, so the usual search runs: the loader looks beside the executable
			// through the rpath the build sets, which is where the build copies it.
			sHandle = dlopen(name, cRtldNow);
			if (sHandle == null)
				return null;

			sCreateInstance = (CreateInstanceFn)dlsym(sHandle, "DxcCreateInstance");
			return sCreateInstance;
		}
	}
#endif
}
