using System.Collections;

namespace Sedulous.VG.SVG;

/// Represents a parsed SVG document
public class SVGDocument
{
	/// Document width
	public float Width;
	/// Document height
	public float Height;
	/// Root elements
	public List<SVGElement> Elements = new .() ~ {
		for (let el in _)
			delete el;
		delete _;
	};

	public this()
	{
	}

	public this(float width, float height)
	{
		Width = width;
		Height = height;
	}
}
