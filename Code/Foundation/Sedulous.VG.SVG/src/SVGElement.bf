using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// One parsed element.
///
/// A single type with fields for every kind rather than a hierarchy: an SVG element's
/// shape is decided by its tag and the fields it happens to carry, and a document is
/// walked far more often than it is built.
class SVGElement
{
	public SVGElementType Type = .Path;

	/// The tessellatable geometry. Null for a group, or for an element whose attributes
	/// did not describe a shape.
	public Path Path ~ delete _;

	public Float4x4 Transform = .Identity();

	/// Null means none or inherit, which are DIFFERENT from black: an element with no
	/// fill draws nothing rather than a black shape.
	public Color? FillColor;
	/// Set when the fill was a reference, and resolved through the document.
	public String FillGradientId = new .() ~ delete _;

	public Color? StrokeColor;
	public float StrokeWidth = 1.0f;
	public float Opacity = 1.0f;

	public List<SVGElement> Children = new .() ~ DeleteContainerAndItems!(_);

	// Text only.
	public String TextContent = new .() ~ delete _;
	public float TextX = 0.0f;
	public float TextY = 0.0f;
	public float FontSize = 16.0f;
	public SVGTextAnchor TextAnchor = .Start;
	public bool FontBold = false;

	public this() {}

	public this(SVGElementType type)
	{
		Type = type;
	}

	/// A group with something in it. An empty group is nothing to draw.
	public bool IsGroup => (Type == .Group) && !Children.IsEmpty;
}
