using System;

namespace Sedulous.Shell;

/// Configuration settings for creating a window.
public struct WindowSettings
{
	/// Window title.
	public String Title;
	/// Window X position (or Centered for centered).
	public int32 X = Undefined;
	/// Window Y position (or Centered for centered).
	public int32 Y = Undefined;
	/// Window width in pixels.
	public int32 Width;
	/// Window height in pixels.
	public int32 Height;
	/// Whether the window is resizable.
	public bool Resizable;
	/// Whether the window has a border.
	public bool Bordered;
	/// Whether the window starts maximized.
	public bool Maximized;
	/// Whether the window starts minimized.
	public bool Minimized;
	/// Whether the window starts in fullscreen.
	public bool Fullscreen;
	/// Whether the window starts hidden.
	public bool Hidden;

	/// Special value for centered window position.
	public const int32 Centered = -1;
	/// Special value for undefined window position.
	public const int32 Undefined = -2;

	/// Creates default window settings.
	public static WindowSettings Default
	{
		get
		{
			WindowSettings settings = .();
			settings.Title = null;
			settings.X = Centered;
			settings.Y = Centered;
			settings.Width = 1280;
			settings.Height = 720;
			settings.Resizable = true;
			settings.Bordered = true;
			settings.Maximized = false;
			settings.Minimized = false;
			settings.Fullscreen = false;
			settings.Hidden = false;
			return settings;
		}
	}
}
