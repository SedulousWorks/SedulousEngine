using System;
using System.Collections;
using Bulkan;
using Sedulous.Core;
using Sedulous.RHI;

namespace Sedulous.RHI.Vulkan;

/// The Vulkan instance, its adapters, and the surfaces made from native windows.
class VulkanBackend : IBackend
{
	private VkInstance mInstance;
	private VkDebugUtilsMessengerEXT mDebugMessenger;
	private bool mValidationEnabled = false;
	private bool mInitialized = false;

	private List<VulkanAdapter> mAdapters = new .() ~ DeleteContainerAndItems!(_);
	private List<IAdapter> mAdapterHandles = new .() ~ delete _;
	private List<VulkanSurface> mSurfaces = new .() ~ DeleteContainerAndItems!(_);

	/// Which Linux surface extensions the instance actually enabled. Both are usually
	/// present, and which one a window needs is not known until it exists.
	private bool mHasXlib = false;
	private bool mHasWayland = false;

	public bool IsInitialized => mInitialized;
	public VkInstance Instance => mInstance;

	public Result<void> Initialize(bool enableValidation)
	{
		if (VulkanNative.Initialize() case .Err)
		{
			Log("VulkanBackend: the Vulkan loader could not be loaded");
			return .Err;
		}
		VulkanNative.LoadPreInstanceFunctions();

		mValidationEnabled = enableValidation;

		VkApplicationInfo appInfo = .();
		appInfo.pApplicationName = "Sedulous";
		appInfo.applicationVersion = VulkanNative.VK_MAKE_API_VERSION(0, 1, 0, 0);
		appInfo.pEngineName = "Sedulous";
		appInfo.engineVersion = VulkanNative.VK_MAKE_API_VERSION(0, 1, 0, 0);
		appInfo.apiVersion = VulkanNative.VK_API_VERSION_1_3;

		let extensions = scope List<char8*>();
		extensions.Add(VulkanNative.VK_KHR_SURFACE_EXTENSION_NAME);

#if BF_PLATFORM_WINDOWS
		extensions.Add(VulkanNative.VK_KHR_WIN32_SURFACE_EXTENSION_NAME);
#else
		// Asked for rather than assumed: enabling an extension the loader does not have
		// fails instance creation outright, and a machine may have only one of these.
		if (!ProbeSurfaceExtensions(extensions))
			return .Err;
#endif

		// ASKED FOR rather than tied to validation. The debug label calls are made
		// UNCONDITIONALLY by the render graph, once per pass, and the loader only resolves
		// their entry points when the extension is enabled: leaving it off validation
		// builds left every one of those calls pointing at null, which is a crash on the
		// first pass of the first frame on the SHIPPING path. It is also what a frame
		// capture reads the pass names out of, which nobody wants only in a validation
		// build.
		if (ProbeDebugUtils())
			extensions.Add("VK_EXT_debug_utils");

		let layers = scope List<char8*>();
		if (enableValidation)
			layers.Add("VK_LAYER_KHRONOS_validation");

		VkInstanceCreateInfo createInfo = .();
		createInfo.pApplicationInfo = &appInfo;
		createInfo.enabledExtensionCount = (uint32)extensions.Count;
		createInfo.ppEnabledExtensionNames = extensions.Ptr;
		createInfo.enabledLayerCount = (uint32)layers.Count;
		createInfo.ppEnabledLayerNames = layers.Ptr;

		let result = VulkanNative.vkCreateInstance(&createInfo, null, &mInstance);
		if (result != .VK_SUCCESS)
		{
			Log(scope $"VulkanBackend: vkCreateInstance failed ({result})");
			return .Err;
		}

#if BF_PLATFORM_WINDOWS
		let platformFunctions = InstanceFunctionFlags.Win32;
#else
		let platformFunctions = InstanceFunctionFlags.Xlib | InstanceFunctionFlags.Wayland;
#endif
		// A failure to load an OPTIONAL extension function is not fatal: the instance may
		// legitimately lack one, and the call site checks for null before using it.
		VulkanNative.LoadInstanceFunctions(mInstance, .Agnostic | platformFunctions).IgnoreError();
		VulkanNative.LoadPostInstanceFunctions(mInstance);

		if (enableValidation)
			SetupDebugMessenger();

		EnumeratePhysicalDevices();

		mInitialized = true;
		return .Ok;
	}

	/// Enables whichever Linux window system extensions the loader actually has.
	///
	/// Both are enabled when both are present, because the surface type is not decided
	/// until a window exists: a shell may hand back a Wayland surface even where X11 is
	/// also available.
	/// Whether the instance enabled VK_EXT_debug_utils, and so whether the command label
	/// entry points resolved to anything.
	///
	/// STATIC because Bulkan's entry points are: they are resolved once for the process, so
	/// what a caller needs to know is whether THOSE are live, not which backend object it
	/// came through.
	private static bool sDebugUtilsEnabled = false;
	public static bool DebugUtilsEnabled => sDebugUtilsEnabled;

	/// Whether the loader has the debug utils extension at all. Enabling one it does not
	/// have fails instance creation outright, so this is asked rather than assumed, exactly
	/// as the surface extensions are.
	private bool ProbeDebugUtils()
	{
		uint32 count = 0;
		VulkanNative.vkEnumerateInstanceExtensionProperties(null, &count, null);
		if (count == 0)
			return false;

		let available = scope VkExtensionProperties[count];
		VulkanNative.vkEnumerateInstanceExtensionProperties(null, &count, &available[0]);

		for (uint32 i = 0; i < count; i++)
		{
			if (StringView(&available[i].extensionName[0]) == "VK_EXT_debug_utils")
			{
				sDebugUtilsEnabled = true;
				return true;
			}
		}
		return false;
	}

	private bool ProbeSurfaceExtensions(List<char8*> extensions)
	{
		uint32 count = 0;
		VulkanNative.vkEnumerateInstanceExtensionProperties(null, &count, null);
		let available = scope VkExtensionProperties[count == 0 ? 1 : count];
		if (count > 0)
			VulkanNative.vkEnumerateInstanceExtensionProperties(null, &count, &available[0]);

		for (uint32 i = 0; i < count; i++)
		{
			let name = StringView(&available[i].extensionName[0]);
			if (name == "VK_KHR_xlib_surface")
				mHasXlib = true;
			else if (name == "VK_KHR_wayland_surface")
				mHasWayland = true;
		}

		if (mHasXlib)
			extensions.Add(VulkanNative.VK_KHR_XLIB_SURFACE_EXTENSION_NAME);
		if (mHasWayland)
			extensions.Add(VulkanNative.VK_KHR_WAYLAND_SURFACE_EXTENSION_NAME);

		if (!mHasXlib && !mHasWayland)
		{
			Log("VulkanBackend: no surface extension available, needing xlib or wayland");
			return false;
		}
		return true;
	}

	public Span<IAdapter> EnumerateAdapters() => mAdapterHandles;

	public Result<ISurface> CreateSurface(void* windowHandle, void* displayHandle,
		SurfacePlatform platform)
	{
		if (windowHandle == null)
		{
			Log("VulkanBackend: the window handle is null");
			return .Err;
		}

		VkSurfaceKHR surface = .Null;
		var result = VkResult.VK_ERROR_INITIALIZATION_FAILED;

#if BF_PLATFORM_WINDOWS
		VkWin32SurfaceCreateInfoKHR createInfo = .();
		createInfo.hinstance = (void*)0;
		createInfo.hwnd = windowHandle;
		result = VulkanNative.vkCreateWin32SurfaceKHR(mInstance, &createInfo, null, &surface);
#else
		// The platform the SHELL reports is authoritative, because it is the video driver
		// that actually made the window. Handing an X11 Display to the Wayland entry point
		// dereferences a pointer that is not a wl_display and segfaults inside the driver,
		// which is the classic crash from forcing X11 under a Wayland session. Only when
		// the caller says Unknown is the environment guessed at.
		var effective = platform;
		if (effective == .Unknown)
		{
			let waylandDisplay = scope String();
			var hasWaylandDisplay = false;
			if (GetEnvironmentVariable("WAYLAND_DISPLAY", waylandDisplay) case .Ok)
				hasWaylandDisplay = !waylandDisplay.IsEmpty;
			effective = (mHasWayland && hasWaylandDisplay) ? .Wayland : .X11;
		}

		if ((effective == .Wayland) && mHasWayland)
		{
			VkWaylandSurfaceCreateInfoKHR createInfo = .();
			createInfo.display = displayHandle;
			createInfo.surface = windowHandle;
			result = VulkanNative.vkCreateWaylandSurfaceKHR(mInstance, &createInfo, null, &surface);
		}
		else if ((effective == .X11) && mHasXlib)
		{
			VkXlibSurfaceCreateInfoKHR createInfo = .();
			createInfo.dpy = displayHandle;
			createInfo.window = windowHandle;
			result = VulkanNative.vkCreateXlibSurfaceKHR(mInstance, &createInfo, null, &surface);
		}
#endif

		if (result != .VK_SUCCESS)
		{
			Log(scope $"VulkanBackend: surface creation failed ({result})");
			return .Err;
		}

		let wrapper = new VulkanSurface(surface, mInstance);
		mSurfaces.Add(wrapper);
		return .Ok(wrapper);
	}

	public void Destroy()
	{
		for (let surface in mSurfaces)
			surface.Destroy();
		ClearAndDeleteItems!(mSurfaces);

		ClearAndDeleteItems!(mAdapters);
		mAdapterHandles.Clear();

		if (mDebugMessenger != .Null)
		{
			VulkanNative.vkDestroyDebugUtilsMessengerEXT(mInstance, mDebugMessenger, null);
			mDebugMessenger = .Null;
		}

		if (mInstance != .Null)
		{
			VulkanNative.vkDestroyInstance(mInstance, null);
			mInstance = .Null;
		}
		mInitialized = false;
	}

	/// Every physical device, ordered best GPU first so a caller taking element zero gets
	/// the discrete one where there is one.
	private void EnumeratePhysicalDevices()
	{
		uint32 count = 0;
		VulkanNative.vkEnumeratePhysicalDevices(mInstance, &count, null);
		if (count == 0)
			return;

		let devices = scope VkPhysicalDevice[count];
		VulkanNative.vkEnumeratePhysicalDevices(mInstance, &count, &devices[0]);

		for (uint32 i = 0; i < count; i++)
		{
			let adapter = new VulkanAdapter(devices[i], mInstance);
			mAdapters.Add(adapter);
			mAdapterHandles.Add(adapter);
		}

		AdapterSelection.SortByPreference(mAdapterHandles);
	}

	private void SetupDebugMessenger()
	{
		VkDebugUtilsMessengerCreateInfoEXT createInfo = .();
		createInfo.messageSeverity = .VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT
			| .VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT;
		createInfo.messageType = .VK_DEBUG_UTILS_MESSAGE_TYPE_GENERAL_BIT_EXT
			| .VK_DEBUG_UTILS_MESSAGE_TYPE_VALIDATION_BIT_EXT
			| .VK_DEBUG_UTILS_MESSAGE_TYPE_PERFORMANCE_BIT_EXT;
		createInfo.pfnUserCallback = (void*)(function VkBool32(VkDebugUtilsMessageSeverityFlagsEXT, VkDebugUtilsMessageTypeFlagsEXT, VkDebugUtilsMessengerCallbackDataEXT*, void*))(=> DebugCallback);

		VulkanNative.vkCreateDebugUtilsMessengerEXT(mInstance, &createInfo, null,
			&mDebugMessenger);
	}

	/// Prints validation output straight out rather than only through a log sink, because a
	/// swallowed sink defeats the whole point of running with the layers on.
	private static VkBool32 DebugCallback(VkDebugUtilsMessageSeverityFlagsEXT severity,
		VkDebugUtilsMessageTypeFlagsEXT types,
		VkDebugUtilsMessengerCallbackDataEXT* data, void* userData)
	{
		if (data != null)
		{
			let message = StringView(data.pMessage);
			if (severity.HasFlag(.VK_DEBUG_UTILS_MESSAGE_SEVERITY_ERROR_BIT_EXT))
				Console.Error.WriteLine(scope $"[Vulkan ERROR] {message}");
			else if (severity.HasFlag(.VK_DEBUG_UTILS_MESSAGE_SEVERITY_WARNING_BIT_EXT))
				Console.Error.WriteLine(scope $"[Vulkan WARN] {message}");
		}
		return VkBool32(false);
	}

	private static void Log(StringView message) => Console.Error.WriteLine(message);
}

/// Bringing the Vulkan backend up.
static class VulkanRhi
{
	/// A Vulkan backend, or an error when there is no loader, no surface extension, or no
	/// instance. The CALLER owns what comes back.
	public static Result<IBackend> CreateBackend(bool enableValidation = false)
	{
		let backend = new VulkanBackend();
		if (backend.Initialize(enableValidation) case .Err)
		{
			delete backend;
			return .Err;
		}
		return .Ok(backend);
	}
}
