namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;
using Sedulous.Surface;

/// Vulkan implementation of IBackend.
class VulkanBackend : IBackend
{
	private VkInstance mInstance;
	private VkDebugUtilsMessengerEXT mDebugMessenger;
	private bool mValidationEnabled;
	private bool mInitialized;
	private List<VulkanAdapter> mAdapters = new .() ~ DeleteContainerAndItems!(_);

	public bool IsInitialized => mInitialized;

	/// Creates a Vulkan backend.
	/// enableValidation: Enable Vulkan validation layers (debug only).
	public static Result<VulkanBackend> Create(bool enableValidation = false)
	{
		let backend = new VulkanBackend();
		if (backend.Init(enableValidation) case .Err)
		{
			Console.WriteLine("VulkanBackend: initialization failed");
			delete backend;
			return .Err;
		}
		return .Ok(backend);
	}

	private this() { }

	private Result<void> Init(bool enableValidation)
	{
		// Initialize Bulkan
		if (VulkanNative.Initialize() case .Err)
		{
			Console.WriteLine("VulkanBackend: Bulkan initialization failed");
			return .Err;
		}

		VulkanNative.LoadPreInstanceFunctions();

		mValidationEnabled = enableValidation;

		// Application info
		VkApplicationInfo appInfo = .();
		appInfo.pApplicationName = "Sedulous";
		appInfo.applicationVersion = VulkanNative.VK_MAKE_API_VERSION(0, 1, 0, 0);
		appInfo.pEngineName = "Sedulous";
		appInfo.engineVersion = VulkanNative.VK_MAKE_API_VERSION(0, 1, 0, 0);
		appInfo.apiVersion = VulkanNative.VK_API_VERSION_1_3;

		// Extensions
		List<char8*> extensions = scope .();
		extensions.Add(VulkanNative.VK_KHR_SURFACE_EXTENSION_NAME);
#if BF_PLATFORM_WINDOWS
		extensions.Add(VulkanNative.VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
#else
		// Enable both Linux windowing-system surface extensions; SDL3 decides at
		// runtime which one the window actually uses (X11 or Wayland).
		extensions.Add(VulkanNative.VK_KHR_XLIB_SURFACE_EXTENSION_NAME);
		extensions.Add(VulkanNative.VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME);
#endif
		if (enableValidation)
			extensions.Add("VK_EXT_debug_utils");

		// Layers
		List<char8*> layers = scope .();
		if (enableValidation)
			layers.Add("VK_LAYER_KHRONOS_validation");

		// Create instance
		VkInstanceCreateInfo createInfo = .();
		createInfo.pApplicationInfo = &appInfo;
		createInfo.enabledExtensionCount = (uint32)extensions.Count;
		createInfo.ppEnabledExtensionNames = extensions.Ptr;
		createInfo.enabledLayerCount = (uint32)layers.Count;
		createInfo.ppEnabledLayerNames = layers.Ptr;

		let result = VulkanNative.vkCreateInstance(&createInfo, null, &mInstance);
		if (result != .VK_SUCCESS)
		{
			Console.WriteLine(scope $"VulkanBackend: vkCreateInstance failed ({result})");
			return .Err;
		}

		// Load instance functions - some optional extension functions may not be
		// available (e.g. VK_KHR_display, VK_EXT_debug_report). Log failures
		// but don't treat them as fatal, matching how the legacy RHI handles this.
#if BF_PLATFORM_WINDOWS
		let platformFuncs = InstanceFunctionFlags.Win32;
#else
		let platformFuncs = InstanceFunctionFlags.Xlib | .Wayland;
#endif
		VulkanNative.LoadInstanceFunctions(mInstance, .Agnostic | platformFuncs, null,
			scope (func) => { Console.WriteLine("[Vulkan] Could not load instance function: {}", func); }
		).IgnoreError();

		VulkanNative.LoadPostInstanceFunctions(mInstance);

		// Setup debug messenger
		if (enableValidation)
			SetupDebugMessenger();

		// Enumerate physical devices
		EnumeratePhysicalDevices();

		mInitialized = true;
		return .Ok;
	}

	private static function VkBool32(
		VkDebugUtilsMessageSeverityFlagsEXT severity,
		VkDebugUtilsMessageTypeFlagsEXT types,
		VkDebugUtilsMessengerCallbackDataEXT* callbackData,
		void* userData) sDebugCallbackFn = => DebugCallback;

	private void SetupDebugMessenger()
	{
		VkDebugUtilsMessengerCreateInfoEXT createInfo = .();
		createInfo.messageSeverity =
			.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT |
			.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
		createInfo.messageType =
			.VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT |
			.VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT |
			.VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
		createInfo.pfnUserCallback = (void*)sDebugCallbackFn;

		VulkanNative.vkCreateDebugUtilsMessengerEXT(mInstance, &createInfo, null, &mDebugMessenger);
	}

	private static VkBool32 DebugCallback(
		VkDebugUtilsMessageSeverityFlagsEXT severity,
		VkDebugUtilsMessageTypeFlagsEXT types,
		VkDebugUtilsMessengerCallbackDataEXT* callbackData,
		void* userData)
	{
		let msg = StringView(callbackData.pMessage);

		if(msg.Contains("VK_FORMAT_D24_UNORM_S8_UINT") || msg.Contains("VK_ERROR_OUT_OF_DEVICE_MEMORY"))
		{

		}

		if (severity.HasFlag(.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT))
		{
			Console.WriteLine("[Vulkan ERROR] {}", msg);
			System.Diagnostics.Debug.WriteLine(scope $"[Vulkan ERROR] {msg}");
		}
		else if (severity.HasFlag(.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT))
		{
			Console.WriteLine("[Vulkan WARN] {}", msg);
			System.Diagnostics.Debug.WriteLine(scope $"[Vulkan WARN] {msg}");
		}
		return VkBool32.False;
	}

	private void EnumeratePhysicalDevices()
	{
		uint32 count = 0;
		VulkanNative.vkEnumeratePhysicalDevices(mInstance, &count, null);
		if (count == 0) return;

		VkPhysicalDevice[] devices = scope VkPhysicalDevice[count];
		VulkanNative.vkEnumeratePhysicalDevices(mInstance, &count, devices.CArray());

		for (let physDevice in devices)
		{
			mAdapters.Add(new VulkanAdapter(physDevice, mInstance));
		}

		// Order the adapters best-first (discrete GPU preferred) so callers can
		// simply take adapters[0]. Stable insertion sort keeps the driver's native
		// order among adapters of equal preference; adapter counts are tiny.
		for (int i = 1; i < mAdapters.Count; i++)
		{
			let key = mAdapters[i];
			let keyRank = AdapterSelection.PreferenceRank(key.Type);
			int j = i;
			while (j > 0 && AdapterSelection.PreferenceRank(mAdapters[j - 1].Type) > keyRank)
			{
				mAdapters[j] = mAdapters[j - 1];
				j--;
			}
			mAdapters[j] = key;
		}
	}

	public void EnumerateAdapters(List<IAdapter> adapters)
	{
		for (let adapter in mAdapters)
			adapters.Add(adapter);
	}

	public Result<ISurface> CreateSurface(SurfaceInfo info)
	{
		// The windowing system is carried in info.Type, so we create exactly the
		// matching surface - no guessing. Feeding handles to the wrong platform
		// entry point (e.g. an X11 Display* to the Wayland WSI) would segfault.
		VkSurfaceKHR surface = default;
		VkResult result;

		switch (info.Type)
		{
#if BF_PLATFORM_WINDOWS
		case .Win32:
			VkWin32SurfaceCreateInfoKHR createInfo = .();
			createInfo.hinstance = (void*)(int)Windows.GetModuleHandleA(null);
			createInfo.hwnd = info.Win32.Hwnd;
			result = VulkanNative.vkCreateWin32SurfaceKHR(mInstance, &createInfo, null, &surface);
#else
		case .X11:
			VkXlibSurfaceCreateInfoKHR createInfo = .();
			createInfo.dpy = info.X11.Display;
			createInfo.window = (void*)(int)info.X11.Window;
			result = VulkanNative.vkCreateXlibSurfaceKHR(mInstance, &createInfo, null, &surface);

		case .Wayland:
			VkWaylandSurfaceCreateInfoKHR createInfo = .();
			createInfo.display = info.Wayland.Display;
			createInfo.surface = info.Wayland.Surface;
			result = VulkanNative.vkCreateWaylandSurfaceKHR(mInstance, &createInfo, null, &surface);
#endif
		default:
			Console.WriteLine(scope $"VulkanBackend: unsupported surface type {info.Type}");
			return .Err;
		}

		if (result != .VK_SUCCESS)
		{
			Console.WriteLine(scope $"VulkanBackend: Vulkan surface creation failed ({result})");
			return .Err;
		}

		return .Ok(new VulkanSurface(surface, mInstance));
	}

	public void Destroy()
	{
		if (mDebugMessenger.Handle != 0)
			VulkanNative.vkDestroyDebugUtilsMessengerEXT(mInstance, mDebugMessenger, null);

		if (mInstance.Handle != 0)
			VulkanNative.vkDestroyInstance(mInstance, null);

		mInstance = .Null;
		mDebugMessenger = default;
		mInitialized = false;
	}

	public VkInstance Instance => mInstance;
	public bool ValidationEnabled => mValidationEnabled;
}
