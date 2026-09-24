using System;

namespace Sedulous.Graphics;

/// The shared command line validation override.
///
/// `--gpu-validation` forces the API validation layer and the RHI's own wrapper ON,
/// `--no-gpu-validation` forces them OFF; neither leaves the caller's default standing. The
/// last flag given wins, and a longer argument that merely starts with one is not a match.
///
/// Every executable that builds a GraphicsDeviceDesc should run its arguments through this
/// rather than assign EnableValidation itself, so one binary can be measured and debugged
/// without a rebuild.
static class ValidationSelection
{
	public static bool FromArguments(String[] args, bool fallback)
	{
		if (args == null)
			return fallback;

		var enabled = fallback;
		for (let argument in args)
		{
			switch (argument)
			{
			case "--gpu-validation": enabled = true;
			case "--no-gpu-validation": enabled = false;
			default:
			}
		}
		return enabled;
	}
}
