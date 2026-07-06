namespace Sedulous.Surface;

using System;

/// <summary>
/// Supported native surface types.
/// </summary>
enum NativeSurfaceType
{
	Unspecified,
	Win32,
	UWP,
	X11,
	Xcb,
	Wayland,
	Android,
	MetalIOS,
	MetalMacOS
}

struct Win32NativeSurface
{
	public void* Hwnd;
}

struct UWPNativeSurface
{
	public void* Surface;
}

struct X11NativeSurface
{
	public void* Display;
	public uint64 Window;
}

struct XcbNativeSurface
{
	public void* Connection;
	public uint64 Window;
}

struct WaylandNativeSurface
{
	public void* Display;
	public void* Surface;
}

struct AndroidNativeSurface
{
	public void* JNIEnv;
	public void* Surface;
}

struct MetalIOSNativeSurface
{
	public void* View;
}

struct MetalMacOSNativeSurface
{
	public void* CAMetalLayer;
}

[Union]
struct NativeSurface
{
	public Win32NativeSurface Win32;
	public UWPNativeSurface UWP;
	public X11NativeSurface X11;
	public XcbNativeSurface Xcb;
	public WaylandNativeSurface Wayland;
	public AndroidNativeSurface Android;
	public MetalIOSNativeSurface MetalIOS;
	public MetalMacOSNativeSurface MetalMacOS;
}

/// <summary>
/// Surface info struct.
/// </summary>
struct SurfaceInfo
{
	public NativeSurfaceType Type = .Unspecified;
	public using private NativeSurface NativeSurface;

	public static SurfaceInfo FromWin32(void* hwnd)
	{
		SurfaceInfo info = .() { Type = .Win32 };
		info.Win32.Hwnd = hwnd;
		return info;
	}

	public static SurfaceInfo FromUWP(void* surface)
	{
		SurfaceInfo info = .() { Type = .UWP };
		info.UWP.Surface = surface;
		return info;
	}

	public static SurfaceInfo FromX11(void* display, uint64 window)
	{
		SurfaceInfo info = .() { Type = .X11 };
		info.X11.Display = display;
		info.X11.Window = window;
		return info;
	}

	public static SurfaceInfo FromXcb(void* connection, uint64 window)
	{
		SurfaceInfo info = .() { Type = .Xcb };
		info.Xcb.Connection = connection;
		info.Xcb.Window = window;
		return info;
	}

	public static SurfaceInfo FromWayland(void* display, void* surface)
	{
		SurfaceInfo info = .() { Type = .Wayland };
		info.Wayland.Display = display;
		info.Wayland.Surface = surface;
		return info;
	}

	public static SurfaceInfo FromAndroid(void* jniEnv, void* surface)
	{
		SurfaceInfo info = .() { Type = .Android };
		info.Android.JNIEnv = jniEnv;
		info.Android.Surface = surface;
		return info;
	}

	public static SurfaceInfo FromMetalIOS(void* view)
	{
		SurfaceInfo info = .() { Type = .MetalIOS };
		info.MetalIOS.View = view;
		return info;
	}

	public static SurfaceInfo FromMetalMacOS(void* caMetalLayer)
	{
		SurfaceInfo info = .() { Type = .MetalMacOS };
		info.MetalMacOS.CAMetalLayer = caMetalLayer;
		return info;
	}
}
