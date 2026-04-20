namespace Sedulous.RHI.Vulkan;

using System;
using System.Collections;
using Bulkan;

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
			System.Diagnostics.Debug.WriteLine("VulkanBackend: initialization failed");
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
			System.Diagnostics.Debug.WriteLine("VulkanBackend: Bulkan initialization failed");
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
			System.Diagnostics.Debug.WriteLine(scope $"VulkanBackend: vkCreateInstance failed ({result})");
			return .Err;
		}

		// Load instance functions - some optional extension functions may not be
		// available (e.g. VK_KHR_display, VK_EXT_debug_report). Log failures
		// but don't treat them as fatal, matching how the legacy RHI handles this.
		VulkanNative.LoadInstanceFunctions(mInstance, .Agnostic | .Win32, null,
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
	}

	public void EnumerateAdapters(List<IAdapter> adapters)
	{
		for (let adapter in mAdapters)
			adapters.Add(adapter);
	}

	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle = null)
	{
#if BF_PLATFORM_WINDOWS
		VkWin32SurfaceCreateInfoKHR createInfo = .();
		createInfo.hinstance = (void*)(int)Windows.GetModuleHandleA(null);
		createInfo.hwnd = windowHandle;

		VkSurfaceKHR surface = default;
		let result = VulkanNative.vkCreateWin32SurfaceKHR(mInstance, &createInfo, null, &surface);
		if (result != .VK_SUCCESS)
		{
			System.Diagnostics.Debug.WriteLine(scope $"VulkanBackend: vkCreateWin32SurfaceKHR failed ({result})");
			return .Err;
		}

		return .Ok(new VulkanSurface(surface, mInstance));
#else
		System.Diagnostics.Debug.WriteLine("VulkanBackend: surface creation not supported on this platform");
		return .Err;
#endif
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
