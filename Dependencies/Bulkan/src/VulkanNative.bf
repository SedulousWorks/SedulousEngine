using System;
using System.Collections;
using System;
namespace Bulkan;

public static class VulkanNative
{
	public static uint32 VK_API_VERSION_VARIANT(uint32 version) => ((uint32)(version) >> 29);
	
	public static uint32 VK_API_VERSION_MAJOR(uint32 version) => (((uint32)(version) >> 22) & 0x7FU);
	
	public static uint32 VK_API_VERSION_MINOR(uint32 version) => (((uint32)(version) >> 12) & 0x3FFU);
	
	public static uint32 VK_API_VERSION_PATCH(uint32 version) => ((uint32)(version) & 0xFFFU);

	public static uint32 VK_MAKE_API_VERSION(uint32 variant, uint32 major, uint32 minor, uint32 patch) => ((((uint32)(variant)) << 29) | (((uint32)(major)) << 22) | (((uint32)(minor)) << 12) | ((uint32)(patch)));

	public const uint32 VK_API_VERSION_1_0 = VK_MAKE_API_VERSION(0, 1, 0, 0);
	public const uint32 VK_API_VERSION_1_1 = VK_MAKE_API_VERSION(0, 1, 1, 0);
	public const uint32 VK_API_VERSION_1_2 = VK_MAKE_API_VERSION(0, 1, 2, 0);
	public const uint32 VK_API_VERSION_1_3 = VK_MAKE_API_VERSION(0, 1, 3, 0);
	public const uint32 VK_API_VERSION_1_4 = VK_MAKE_API_VERSION(0, 1, 4, 0);

	private const CallingConventionAttribute.Kind CallConv = .Stdcall;

	private static NativeLibrary mNativeLib;

	private static bool mInitialized = false;

	public static bool Initialized => mInitialized;

	private static List<String> mLoadedFunctions = new .() ~ delete _;

	public static readonly Span<String> LoadedFunctions { get => mLoadedFunctions; }

	private static List<String> mPreInstanceFunctions = new .()
		{
			"vkGetInstanceProcAddr",
			"vkCreateInstance",
			"vkEnumerateInstanceExtensionProperties",
			"vkEnumerateInstanceLayerProperties"
		} ~ delete _;

	static this()
	{
	}

	static ~this()
	{
		if (mNativeLib != null)
		{
			mNativeLib.Dispose();
			delete mNativeLib;
		}
	}

	public static Result<void> Initialize(String libraryName = null)
	{
		if (!mInitialized)
		{
			LoadNativeLibrary(libraryName, out mNativeLib);

			mInitialized = true;
		}

		return .Ok;
	}

	public static void SetLoadFunctionErrorCallBack(LoanFunctionErrorCallBack callback)
	{
		mNativeLib.LoanFunctionErrorCallBack = callback;
	}

	public static void LoadFunction<T>(StringView name, out T field, VkInstance? instance = null, bool invokeErrorCallback = true)
	{
		Runtime.Assert(mInitialized);

		void* funcPtr = null;

		if (instance != null && vkGetInstanceProcAddr_ptr != null)
		{
			funcPtr = vkGetInstanceProcAddr_ptr(instance.Value, name.Ptr);
		}

		if (funcPtr != null)
		{
			field = *(T*)(void*)(int*)&funcPtr;
		} else
		{
			mNativeLib.LoadFunction(name, out field, invokeErrorCallback);
		}
	}

	public static Result<void, String> LoadFunctions(Span<String> functions)
	{
		Runtime.Assert(mInitialized);

		for (var func in functions)
		{
			if (LoadFunction(func) case .Err)
				return .Err(func);
		}
		return .Ok;
	}

	public static Result<void> LoadPreInstanceFunctions(List<String> additionalFunctions = null)
	{
		Runtime.Assert(mInitialized);

		if (additionalFunctions != null)
		{
			for (var func in additionalFunctions)
			{
				if (func != null && !mPreInstanceFunctions.Contains(func))
				{
					mPreInstanceFunctions.Add(func);
				}
			}
		}

		LoadFunctions(mPreInstanceFunctions);

		mLoadedFunctions.AddRange(mPreInstanceFunctions);

		return .Ok;
	}

	public static Result<void> LoadInstanceFunctions(VkInstance instance, InstanceFunctionFlags flags, List<String> additionalFunctions = null, delegate void(String) onError = null)
	{
		Runtime.Assert(mInitialized);

		List<String> functionsToLoad = scope .();
		if (additionalFunctions != null)
		{
			functionsToLoad.AddRange(additionalFunctions);
		}

		for (var knownInstanceCommand in sKnownInstanceCommands)
		{
			if (flags.HasFlag(knownInstanceCommand.Flags))
				functionsToLoad.Add(knownInstanceCommand.Name);
		}

		for (var functionToLoad in functionsToLoad)
		{
			if (LoadFunction(functionToLoad, instance) case .Err)
			{
				if (onError != null)
					onError(functionToLoad);
				return .Err;
			} else
			{
				mLoadedFunctions.Add(functionToLoad);
			}
		}

		/*if (LoadFunctions(functionsToLoad) case .Err(let func))
		{
			if (onError != null)
				onError(func);
			return .Err;
		}*/

		return .Ok;
	}

	public static Result<void> LoadPostInstanceFunctions(VkInstance? instance = null)
	{
		Runtime.Assert(mInitialized);

		LoadAllFuncions(instance, mLoadedFunctions);
		return .Ok;
	}

	private static void LoadNativeLibrary(String libraryName, out NativeLibrary handle)
	{
		NativeLibrary.Load(libraryName ?? GetVulkanName(), out handle);
	}

	private static String GetVulkanName()
	{
#if BF_PLATFORM_WINDOWS 
		return "vulkan-1.dll";
		#elif BF_PLATFORM_LINUX  
		return "libvulkan.so.1";
		#elif BF_PLATFORM_MACOS  
		return "libvulkan.dylib";
#else
		Runtime.FatalError("Unsupported platform.");
#endif
	}
}
