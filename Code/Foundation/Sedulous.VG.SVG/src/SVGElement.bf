using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Represents a parsed SVG element
public class SVGElement
{
	/// Element type
	public SVGElementType Type;
	/// Path data (for path elements or converted shapes)
	public Path Path ~ delete _;
	/// Transform matrix
	public Matrix Transform = Matrix.Identity;
	/// Fill color (null = inherit or none)
	public Color? FillColor;
	/// Stroke color (null = inherit or none)
	public Color? StrokeColor;
	/// Stroke width
	public float StrokeWidth = 1.0f;
	/// Opacity
	public float Opacity = 1.0f;
	/// Children (for group elements)
	public List<SVGElement> Children ~ {
		if (_ != null)
		{
			for (let child in _)
				delete child;
			delete _;
		}
	};

	public this()
	{
	}

	public this(SVGElementType type)
	{
		Type = type;
	}

	/// Whether this element has children (is a group)
	public bool IsGroup => Type == .Group && Children != null && Children.Count > 0;
}
