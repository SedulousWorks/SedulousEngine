using System;
using SDL3;

namespace Sedulous.Shell.SDL3.Tests;

/// Forces SDL's headless video driver.
///
/// Without it these open a real window on whatever display is attached, which flashes on a
/// developer's screen and fails outright on a build machine that has none. Set BEFORE any
/// SDL_Init, which is why every fixture goes through here rather than constructing a shell
/// directly.
static class HeadlessDriver
{
	private static bool sApplied;

	public static void Apply()
	{
		if (sApplied)
			return;
		sApplied = true;
		// The ENVIRONMENT, not a hint: SDL reads the driver from the environment during
		// SDL_Init and a hint set beforehand does not reach that decision. Overwriting,
		// because a developer whose session already names a real driver would otherwise
		// still get a window.
		SDL3.SDL_setenv_unsafe("SDL_VIDEODRIVER", "dummy", 1);
	}
}
