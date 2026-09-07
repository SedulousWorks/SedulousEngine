using System;
using System.Collections;
using Sedulous.Fonts;

namespace Sedulous.Fonts.Tests;

/// A font that reports no pixel height, for the degenerate case a scaled view has to
/// survive rather than divide by.
class ZeroSizeFont : StubFont
{
	public override float PixelHeight => 0.0f;
}
