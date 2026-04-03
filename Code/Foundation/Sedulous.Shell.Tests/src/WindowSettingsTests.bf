using System;
using Sedulous.Shell;

namespace Sedulous.Shell.Tests;

class WindowSettingsTests
{
	[Test]
	public static void TestDefaultSettings()
	{
		// Use the Default property for recommended defaults
		let settings = WindowSettings.Default;

		Test.Assert(settings.Title == null);
		Test.Assert(settings.Width == 1280);
		Test.Assert(settings.Height == 720);
		Test.Assert(settings.X == WindowSettings.Centered);
		Test.Assert(settings.Y == WindowSettings.Centered);
		Test.Assert(settings.Resizable == true);
		Test.Assert(settings.Bordered == true);
		Test.Assert(settings.Minimized == false);
		Test.Assert(settings.Maximized == false);
		Test.Assert(settings.Fullscreen == false);
		Test.Assert(settings.Hidden == false);
	}

	[Test]
	public static void TestZeroInitializedSettings()
	{
		// Raw struct initialization has field defaults
		let settings = WindowSettings();

		Test.Assert(settings.Title == null);
		Test.Assert(settings.Width == 0);
		Test.Assert(settings.Height == 0);
		// X and Y default to Undefined
		Test.Assert(settings.X == WindowSettings.Undefined);
		Test.Assert(settings.Y == WindowSettings.Undefined);
		Test.Assert(settings.Resizable == false);
		Test.Assert(settings.Bordered == false);
	}

	[Test]
	public static void TestCustomSettings()
	{
		let settings = WindowSettings()
		{
			Title = "Test Window",
			Width = 1920,
			Height = 1080,
			X = 100,
			Y = 200,
			Resizable = true,
			Bordered = false,
			Fullscreen = true
		};

		Test.Assert(settings.Title == "Test Window");
		Test.Assert(settings.Width == 1920);
		Test.Assert(settings.Height == 1080);
		Test.Assert(settings.X == 100);
		Test.Assert(settings.Y == 200);
		Test.Assert(settings.Resizable == true);
		Test.Assert(settings.Bordered == false);
		Test.Assert(settings.Fullscreen == true);
	}
}
