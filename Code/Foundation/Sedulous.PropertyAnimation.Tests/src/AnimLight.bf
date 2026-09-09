using System;
using Sedulous.Core;

namespace Sedulous.PropertyAnimation.Tests;

/// A nested value on the test component, which is what the "light.tint" path walks into.
[Reflect(.All)]
struct AnimLight
{
	public Color Tint = .(0.0f, 0.0f, 0.0f, 1.0f);

	public this() {}
}
