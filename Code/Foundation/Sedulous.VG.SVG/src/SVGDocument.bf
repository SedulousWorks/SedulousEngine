using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG.SVG;

/// A parsed document: its size, its elements, and the gradients they refer to.
class SVGDocument
{
	public float Width = 0.0f;
	public float Height = 0.0f;
	/// The user coordinates the elements are in (`viewBox`), null when none: it is fitted into
	/// Width by Height, uniformly and centred (SVG's default `xMidYMid meet`).
	public Rectangle? ViewBox = null;

	public List<SVGElement> Elements = new .() ~ DeleteContainerAndItems!(_);

	/// By id, from a defs block or declared inline. The elements refer to these by name,
	/// so they outlive whichever element first mentioned one.
	public Dictionary<String, SVGGradient> Gradients = new .()
		~ DeleteDictionaryAndKeysAndValues!(_);

	public this() {}

	public this(float width, float height)
	{
		Width = width;
		Height = height;
	}
}
