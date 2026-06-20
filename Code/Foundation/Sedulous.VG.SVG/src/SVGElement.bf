using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Text anchor alignment (maps to SVG text-anchor attribute).
public enum SVGTextAnchor
{
	Start,
	Middle,
	End
}

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

	// === Text-specific fields ===

	/// Text content string (for Text elements).
	public String TextContent ~ delete _;
	/// Text X position in SVG coordinates.
	public float TextX;
	/// Text Y position in SVG coordinates.
	public float TextY;
	/// Font size in SVG units.
	public float FontSize = 16;
	/// Text anchor alignment.
	public SVGTextAnchor TextAnchor = .Start;
	/// Font weight bold flag.
	public bool FontBold = false;

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
