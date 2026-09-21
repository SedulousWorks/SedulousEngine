using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Reads an SVG document out of its text.
///
/// A hand written reader over the SUBSET an icon or a piece of interface art uses, rather
/// than a general XML parse: it recognises the shape and paint tags and SKIPS anything
/// else, which is what lets it survive the editor metadata real files are full of.
static class SVGLoader
{
	/// THE CALLER OWNS what comes back.
	public static Result<SVGDocument, ErrorCode> Load(StringView content)
	{
		var pos = 0;
		if (!FindTag(content, ref pos, "svg"))
			return .Err(.InvalidArgument);

		let document = new SVGDocument();

		let attributes = scope SVGAttributes();
		ParseAttributes(content, ref pos, attributes);

		document.Width = attributes.Number("width", 0.0f);
		document.Height = attributes.Number("height", 0.0f);

		// The view box is the FALLBACK, not the primary: an explicit size wins, and only a
		// file that states neither has no size at all.
		if ((document.Width == 0.0f) && (document.Height == 0.0f))
			ReadViewBoxSize(attributes, document);

		ParseChildren(content, ref pos, document.Elements, document);
		return document;
	}

	/// The third and fourth numbers of a view box are its extent. The first two are the
	/// origin, which this reader does not apply.
	private static void ReadViewBoxSize(SVGAttributes attributes, SVGDocument document)
	{
		if (!attributes.TryGet("viewBox", let text))
			return;

		var pos = 0;
		if (!ScanListNumber(text, ref pos, let ignoredX))
			return;
		if (!ScanListNumber(text, ref pos, let ignoredY))
			return;
		if (ScanListNumber(text, ref pos, let width))
			document.Width = width;
		if (ScanListNumber(text, ref pos, let height))
			document.Height = height;
	}

	private static void ParseChildren(StringView content, ref int pos, List<SVGElement> elements,
		SVGDocument document)
	{
		while (pos < content.Length)
		{
			SVGScan.SkipWhitespace(content, ref pos);
			if (pos >= content.Length)
				break;

			// A closing tag ends this level.
			if (((pos + 1) < content.Length) && (content[pos] == '<') && (content[pos + 1] == '/'))
				break;

			if (content[pos] != '<')
			{
				pos++;
				continue;
			}

			let saved = pos;
			if (TryParseElement(content, ref pos, elements, document) case .Err)
			{
				// An unrecognised tag is SKIPPED rather than failing the document: real
				// files carry editor metadata and namespaced elements that no renderer
				// needs, and refusing them would reject most of them.
				pos = saved;
				SkipTag(content, ref pos);
			}
		}
	}

	private static Result<void, ErrorCode> TryParseElement(StringView content, ref int pos,
		List<SVGElement> elements, SVGDocument document)
	{
		if ((pos >= content.Length) || (content[pos] != '<'))
			return .Err(.InvalidArgument);

		pos++;
		SVGScan.SkipWhitespace(content, ref pos);

		let tagStart = pos;
		while ((pos < content.Length) && (content[pos] != ' ') && (content[pos] != '>')
			&& (content[pos] != '/') && (content[pos] != '\t') && (content[pos] != '\n'))
			pos++;
		let tag = content.Substring(tagStart, pos - tagStart);

		let attributes = scope SVGAttributes();
		ParseAttributes(content, ref pos, attributes);

		// The attribute scan stops ON the closing bracket, so the character before it says
		// whether the tag closed itself.
		let selfClosing = (pos > 0) && (pos <= content.Length) && (content[pos - 1] == '/');

		if ((pos < content.Length) && (content[pos] == '>'))
			pos++;

		// A gradient or a defs block registers on the DOCUMENT rather than becoming an
		// element, so it is parsed and then not emitted.
		if (SVGScan.EqualsIgnoreCase(tag, "defs"))
		{
			if (!selfClosing)
			{
				let discarded = scope List<SVGElement>();
				defer { ClearAndDeleteItems!(discarded); }
				ParseChildren(content, ref pos, discarded, document);
			}
			SkipClosingTag(content, ref pos);
			return .Ok;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "linearGradient")
			|| SVGScan.EqualsIgnoreCase(tag, "radialGradient"))
		{
			ParseGradient(content, ref pos, tag, attributes, selfClosing, document);
			return .Ok;
		}

		let element = new SVGElement();
		if (!BuildGeometry(content, ref pos, tag, attributes, selfClosing, element, document))
		{
			delete element;
			return .Err(.InvalidArgument);
		}

		ApplyStyle(attributes, element);
		elements.Add(element);
		return .Ok;
	}

	/// Fills in the element's type and geometry. False means the tag is not one this
	/// reader draws.
	private static bool BuildGeometry(StringView content, ref int pos, StringView tag,
		SVGAttributes attributes, bool selfClosing, SVGElement element, SVGDocument document)
	{
		if (SVGScan.EqualsIgnoreCase(tag, "path"))
		{
			element.Type = .Path;
			if (attributes.TryGet("d", let data))
			{
				let builder = scope PathBuilder();
				// A path whose data does not parse becomes an element with NO geometry
				// rather than a failure, so its siblings still draw.
				if (SVGPathParser.Parse(data, builder) case .Ok)
					element.Path = builder.ToPath();
			}
			return true;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "rect"))
		{
			element.Type = .Rectangle;
			element.Path = BuildRect(attributes);
			return true;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "circle"))
		{
			element.Type = .Circle;
			let builder = scope PathBuilder();
			ShapeBuilder.BuildCircle(.(attributes.Number("cx"), attributes.Number("cy")),
				attributes.Number("r"), builder);
			element.Path = builder.ToPath();
			return true;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "ellipse"))
		{
			element.Type = .Ellipse;
			let builder = scope PathBuilder();
			ShapeBuilder.BuildEllipse(.(attributes.Number("cx"), attributes.Number("cy")),
				attributes.Number("rx"), attributes.Number("ry"), builder);
			element.Path = builder.ToPath();
			return true;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "line"))
		{
			element.Type = .Line;
			let builder = scope PathBuilder();
			builder.MoveTo(attributes.Number("x1"), attributes.Number("y1"));
			builder.LineTo(attributes.Number("x2"), attributes.Number("y2"));
			element.Path = builder.ToPath();
			return true;
		}

		let polygon = SVGScan.EqualsIgnoreCase(tag, "polygon");
		if (polygon || SVGScan.EqualsIgnoreCase(tag, "polyline"))
		{
			element.Type = polygon ? .Polygon : .Polyline;
			element.Path = BuildPoly(attributes, polygon);
			return true;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "g"))
		{
			element.Type = .Group;
			if (!selfClosing)
				ParseChildren(content, ref pos, element.Children, document);
			SkipClosingTag(content, ref pos);
			return true;
		}

		if (SVGScan.EqualsIgnoreCase(tag, "text"))
		{
			element.Type = .Text;
			ReadText(content, ref pos, attributes, selfClosing, element);
			return true;
		}

		return false;
	}

	private static Path BuildRect(SVGAttributes attributes)
	{
		let x = attributes.Number("x");
		let y = attributes.Number("y");
		let width = attributes.Number("width");
		let height = attributes.Number("height");

		// Either radius alone implies the other, which is what SVG says: rx="4" alone is a
		// uniformly rounded rectangle rather than an elliptical one.
		var rx = attributes.Number("rx");
		var ry = attributes.Number("ry");
		if (ry == 0.0f)
			ry = rx;
		if (rx == 0.0f)
			rx = ry;

		let builder = scope PathBuilder();
		if ((rx > 0.0f) || (ry > 0.0f))
		{
			ShapeBuilder.BuildRoundedRect(.(x, y, width, height), CornerRadii(rx), builder);
		}
		else
		{
			builder.MoveTo(x, y);
			builder.LineTo(x + width, y);
			builder.LineTo(x + width, y + height);
			builder.LineTo(x, y + height);
			builder.Close();
		}
		return builder.ToPath();
	}

	private static Path BuildPoly(SVGAttributes attributes, bool closed)
	{
		if (!attributes.TryGet("points", let text))
			return null;

		let builder = scope PathBuilder();
		var pos = 0;
		var first = true;

		while (pos < text.Length)
		{
			if (!ScanListNumber(text, ref pos, let x))
				break;
			// A trailing lone number is DROPPED rather than paired with a zero, which
			// would put a stray vertex on the axis.
			if (!ScanListNumber(text, ref pos, let y))
				break;

			if (first)
			{
				builder.MoveTo(x, y);
				first = false;
			}
			else
			{
				builder.LineTo(x, y);
			}
		}

		if (closed)
			builder.Close();
		return builder.ToPath();
	}

	private static void ReadText(StringView content, ref int pos, SVGAttributes attributes,
		bool selfClosing, SVGElement element)
	{
		element.TextX = attributes.Number("x");
		element.TextY = attributes.Number("y");
		element.FontSize = attributes.Number("font-size", 16.0f);
		element.FontBold = attributes.EqualsIgnoreCase("font-weight", "bold");

		if (attributes.EqualsIgnoreCase("text-anchor", "middle"))
			element.TextAnchor = .Middle;
		else if (attributes.EqualsIgnoreCase("text-anchor", "end"))
			element.TextAnchor = .End;

		if (selfClosing)
			return;

		let textStart = pos;
		while ((pos + 1) < content.Length)
		{
			if ((content[pos] == '<') && (content[pos + 1] == '/'))
				break;
			pos++;
		}

		AppendCollapsedText(content.Substring(textStart, pos - textStart), element.TextContent);
		SkipClosingTag(content, ref pos);
	}

	/// The style attributes every element kind shares.
	private static void ApplyStyle(SVGAttributes attributes, SVGElement element)
	{
		if (attributes.TryGet("fill", let fill))
		{
			if (SVGScan.EqualsIgnoreCase(fill, "none"))
			{
				// Explicitly nothing, which is DIFFERENT from absent: an element with
				// fill="none" draws no fill at all.
				element.FillColor = null;
			}
			else if (ParseUrlReference(fill, element.FillGradientId))
			{
				// Black stands in until the reference resolves, so an element pointing at
				// a gradient that is missing still draws something.
				element.FillColor = Color.Black;
			}
			else if (SVGColorParser.Parse(fill) case .Ok(let color))
			{
				element.FillColor = color;
			}
		}
		else
		{
			// The SVG default fill is black, not nothing.
			element.FillColor = Color.Black;
		}

		if (attributes.TryGet("stroke", let stroke) && !SVGScan.EqualsIgnoreCase(stroke, "none"))
		{
			if (SVGColorParser.Parse(stroke) case .Ok(let color))
				element.StrokeColor = color;
		}

		element.StrokeWidth = attributes.Number("stroke-width", 1.0f);
		element.Opacity = attributes.Number("opacity", 1.0f);

		if (attributes.TryGet("transform", let transform))
		{
			// A transform that does not parse leaves the element UNTRANSFORMED rather than
			// somewhere arbitrary.
			if (SVGTransformParser.Parse(transform) case .Ok(let matrix))
				element.Transform = matrix;
		}
	}

	/// The id out of a paint reference of the form url(#id).
	private static bool ParseUrlReference(StringView text, String outId)
	{
		var pos = 0;
		SVGScan.SkipWhitespace(text, ref pos);

		if (!SVGScan.StartsWith(text, pos, "url("))
			return false;
		pos += 4;

		SVGScan.SkipWhitespace(text, ref pos);
		if ((pos >= text.Length) || (text[pos] != '#'))
			return false;
		pos++;

		let start = pos;
		while ((pos < text.Length) && (text[pos] != ')') && (text[pos] != ' '))
			pos++;

		if (pos == start)
			return false;

		outId.Set(text.Substring(start, pos - start));
		return true;
	}

	// === gradients ===

	private static void ParseGradient(StringView content, ref int pos, StringView tag,
		SVGAttributes attributes, bool selfClosing, SVGDocument document)
	{
		let gradient = new SVGGradient();
		gradient.Radial = SVGScan.EqualsIgnoreCase(tag, "radialGradient");

		// The defaults are the SVG ones: a linear gradient runs left to right across the
		// element, and a radial one fills it from the middle.
		if (gradient.Radial)
		{
			gradient.Cx = attributes.Fraction("cx", 0.5f);
			gradient.Cy = attributes.Fraction("cy", 0.5f);
			gradient.R = attributes.Fraction("r", 0.5f);
		}
		else
		{
			gradient.X1 = attributes.Fraction("x1", 0.0f);
			gradient.Y1 = attributes.Fraction("y1", 0.0f);
			gradient.X2 = attributes.Fraction("x2", 1.0f);
			gradient.Y2 = attributes.Fraction("y2", 0.0f);
		}

		gradient.UserSpace = attributes.EqualsIgnoreCase("gradientUnits", "userSpaceOnUse");

		if (attributes.EqualsIgnoreCase("spreadMethod", "repeat"))
			gradient.Spread = .Repeat;
		else if (attributes.EqualsIgnoreCase("spreadMethod", "reflect"))
			gradient.Spread = .Reflect;

		if (!selfClosing)
			ParseGradientStops(content, ref pos, gradient);

		// An UNNAMED gradient can never be referenced, so there is nothing to keep.
		if (!attributes.TryGet("id", let id))
		{
			delete gradient;
			return;
		}

		let key = new String(id);
		if (document.Gradients.TryGetValue(key, let existing))
		{
			// A repeated id replaces, which is what a later definition means.
			delete existing;
			document.Gradients[key] = gradient;
			delete key;
			return;
		}
		document.Gradients[key] = gradient;
	}

	private static void ParseGradientStops(StringView content, ref int pos, SVGGradient gradient)
	{
		while (pos < content.Length)
		{
			SVGScan.SkipWhitespace(content, ref pos);

			if (((pos + 1) < content.Length) && (content[pos] == '<') && (content[pos + 1] == '/'))
				break;

			if ((pos >= content.Length) || (content[pos] != '<'))
			{
				pos++;
				continue;
			}

			let saved = pos;
			pos++;
			SVGScan.SkipWhitespace(content, ref pos);

			let tagStart = pos;
			while ((pos < content.Length) && (content[pos] != ' ') && (content[pos] != '>')
				&& (content[pos] != '/') && (content[pos] != '\t') && (content[pos] != '\n'))
				pos++;

			if (!SVGScan.EqualsIgnoreCase(content.Substring(tagStart, pos - tagStart), "stop"))
			{
				pos = saved;
				SkipTag(content, ref pos);
				continue;
			}

			let attributes = scope SVGAttributes();
			ParseAttributes(content, ref pos, attributes);
			if ((pos < content.Length) && (content[pos] == '>'))
				pos++;

			gradient.Stops.Add(ReadStop(attributes));
		}

		SkipClosingTag(content, ref pos);
	}

	private static GradientStop ReadStop(SVGAttributes attributes)
	{
		let offset = attributes.Fraction("offset", 0.0f);

		var color = Color.Black;
		var alpha = 1.0f;

		if (attributes.TryGet("stop-color", let colorText))
		{
			if (SVGColorParser.Parse(colorText) case .Ok(let parsed))
				color = parsed;
		}
		if (attributes.TryGet("stop-opacity", let alphaText))
		{
			if (SVGAttributes.ParseNumber(alphaText) case .Ok(let parsed))
				alpha = parsed;
		}

		// The style form OVERRIDES the attributes, because a style declaration wins in CSS
		// and that is the form most editors export.
		if (attributes.TryGet("style", let style))
			ReadStopStyle(style, ref color, ref alpha);

		// The opacity MULTIPLIES whatever alpha the colour already carried, so a colour
		// with alpha and a stop-opacity compose rather than one replacing the other.
		color.A *= alpha;
		return .(offset, color);
	}

	/// The two stop properties out of a style attribute.
	///
	/// A minimal splitter rather than a CSS parser: these are the only two declarations
	/// that mean anything on a stop.
	private static void ReadStopStyle(StringView style, ref Color color, ref float alpha)
	{
		var i = 0;
		while (i < style.Length)
		{
			var end = i;
			while ((end < style.Length) && (style[end] != ';'))
				end++;

			let declaration = style.Substring(i, end - i);
			var colon = 0;
			while ((colon < declaration.Length) && (declaration[colon] != ':'))
				colon++;

			if (colon < declaration.Length)
			{
				let name = SVGScan.Trim(declaration.Substring(0, colon));
				let value = SVGScan.Trim(declaration.Substring(colon + 1));

				if (SVGScan.EqualsIgnoreCase(name, "stop-color"))
				{
					if (SVGColorParser.Parse(value) case .Ok(let parsed))
						color = parsed;
				}
				else if (SVGScan.EqualsIgnoreCase(name, "stop-opacity"))
				{
					if (SVGAttributes.ParseNumber(value) case .Ok(let parsed))
						alpha = parsed;
				}
			}

			i = end + 1;
		}
	}

	// === the tag scanning ===

	/// Advances to just past the named tag's name. False when it is not there.
	private static bool FindTag(StringView content, ref int pos, StringView tagName)
	{
		while (pos < content.Length)
		{
			if (content[pos] == '<')
			{
				let start = pos + 1;
				var end = start;
				while ((end < content.Length) && (content[end] != ' ') && (content[end] != '>')
					&& (content[end] != '/'))
					end++;

				if (SVGScan.EqualsIgnoreCase(content.Substring(start, end - start), tagName))
				{
					pos = end;
					return true;
				}
			}
			pos++;
		}
		return false;
	}

	/// Reads attributes up to the end of the opening tag.
	///
	/// An attribute with no value is SKIPPED rather than stored empty, because the reader
	/// only ever asks for ones that carry a value.
	private static void ParseAttributes(StringView content, ref int pos, SVGAttributes attributes)
	{
		while (pos < content.Length)
		{
			SVGScan.SkipWhitespace(content, ref pos);

			if ((pos >= content.Length) || (content[pos] == '>') || (content[pos] == '/'))
			{
				// Stops just PAST the bracket, so the caller reads the character before it
				// to learn whether the tag closed itself.
				if ((pos < content.Length) && (content[pos] == '/'))
				{
					pos++;
					if ((pos < content.Length) && (content[pos] == '>'))
						pos++;
				}
				else if ((pos < content.Length) && (content[pos] == '>'))
				{
					pos++;
				}
				break;
			}

			let nameStart = pos;
			while ((pos < content.Length) && (content[pos] != '=') && (content[pos] != ' ')
				&& (content[pos] != '>'))
				pos++;
			let name = content.Substring(nameStart, pos - nameStart);

			SVGScan.SkipWhitespace(content, ref pos);
			if ((pos >= content.Length) || (content[pos] != '='))
				continue;

			pos++;
			SVGScan.SkipWhitespace(content, ref pos);

			// Either quote, because both are legal and editors use both.
			if ((pos >= content.Length) || ((content[pos] != '"') && (content[pos] != '\'')))
				continue;

			let quote = content[pos];
			pos++;

			let valueStart = pos;
			while ((pos < content.Length) && (content[pos] != quote))
				pos++;

			attributes.Add(name, content.Substring(valueStart, pos - valueStart));

			if (pos < content.Length)
				pos++;
		}
	}

	/// Steps over a tag AND EVERYTHING INSIDE IT.
	///
	/// Skipping only the opening tag would leave an unrecognised element's children at
	/// this level, and its closing tag would then end the level: a `<metadata>` or
	/// `<style>` block near the top of an editor's file would drop every sibling after it,
	/// which in practice is the whole drawing.
	private static void SkipTag(StringView content, ref int pos)
	{
		if (SkipComment(content, ref pos))
			return;

		// The name is read before the cursor moves, because the cursor has to end past the
		// opening bracket either way.
		let nameStart = ((pos < content.Length) && (content[pos] == '<')) ? pos + 1 : pos;
		var cursor = nameStart;
		while ((cursor < content.Length) && !IsNameEnd(content[cursor]))
			cursor++;
		let name = content.Substring(nameStart, cursor - nameStart);

		while ((pos < content.Length) && (content[pos] != '>'))
			pos++;
		let selfClosing = (pos > 0) && (pos <= content.Length) && (content[pos - 1] == '/');
		if (pos < content.Length)
			pos++;

		// An empty element has no body, and neither does a declaration or a doctype, which
		// have no closing tag to look for.
		if (selfClosing || name.IsEmpty || (name[0] == '?') || (name[0] == '!'))
			return;

		// Same named elements NEST, so the first closing tag is not necessarily the match.
		var depth = 1;
		while ((pos < content.Length) && (depth > 0))
		{
			if (content[pos] != '<')
			{
				pos++;
				continue;
			}

			if (SkipComment(content, ref pos))
				continue;

			if (NameAt(content, pos + 2, name) && ((pos + 1) < content.Length)
				&& (content[pos + 1] == '/'))
				depth--;
			else if (NameAt(content, pos + 1, name))
				depth++;

			pos++;
			while ((pos < content.Length) && (content[pos] != '>'))
			{
				// A self closing occurrence opened and closed in one tag.
				if ((content[pos] == '/') && ((pos + 1) < content.Length)
					&& (content[pos + 1] == '>') && (depth > 1))
					depth--;
				pos++;
			}
			if (pos < content.Length)
				pos++;
		}
	}

	/// A comment ends at `-->` and can hold anything up to it, brackets included, so it is
	/// stepped over as one unit rather than read as a tag.
	private static bool SkipComment(StringView content, ref int pos)
	{
		if (!Matches(content, pos, "<!--"))
			return false;

		pos += 4;
		while (pos < content.Length)
		{
			if (Matches(content, pos, "-->"))
			{
				pos += 3;
				return true;
			}
			pos++;
		}
		return true;
	}

	private static bool IsNameEnd(char8 c) =>
		(c == ' ') || (c == '>') || (c == '/') || (c == '\t') || (c == '\n') || (c == '\r');

	private static bool Matches(StringView content, int at, StringView literal)
	{
		if ((at < 0) || ((at + literal.Length) > content.Length))
			return false;
		return content.Substring(at, literal.Length) == literal;
	}

	/// True when `name` sits at `at` as a WHOLE tag name rather than as the start of a
	/// longer one, so `<lineargradient>` does not close `<line>`.
	private static bool NameAt(StringView content, int at, StringView name)
	{
		if ((at < 0) || ((at + name.Length) > content.Length))
			return false;
		if (!SVGScan.EqualsIgnoreCase(content.Substring(at, name.Length), name))
			return false;

		let after = at + name.Length;
		return (after >= content.Length) || IsNameEnd(content[after]);
	}

	/// Steps over a closing tag when one is next.
	///
	/// The NAME is not checked: the reader is positional, and a mismatched close in a
	/// malformed file would leave it stuck rather than recovering.
	private static void SkipClosingTag(StringView content, ref int pos)
	{
		SVGScan.SkipWhitespace(content, ref pos);
		if (((pos + 1) >= content.Length) || (content[pos] != '<') || (content[pos + 1] != '/'))
			return;

		pos += 2;
		while ((pos < content.Length) && (content[pos] != '>'))
			pos++;
		if (pos < content.Length)
			pos++;
	}

	/// One number from a whitespace or comma separated list, such as a points attribute.
	private static bool ScanListNumber(StringView text, ref int pos, out float value)
	{
		value = 0.0f;

		while ((pos < text.Length) && ((text[pos] == ' ') || (text[pos] == '\t')
			|| (text[pos] == ',') || (text[pos] == '\n') || (text[pos] == '\r')))
			pos++;

		if (pos >= text.Length)
			return false;

		return SVGScan.ScanNumber(text, ref pos, out value);
	}

	/// Appends inner text with runs of whitespace collapsed to single spaces, then trims.
	private static void AppendCollapsedText(StringView innerText, String outText)
	{
		for (let c in innerText)
		{
			if ((c == '\n') || (c == '\r') || (c == '\t'))
			{
				// One space per RUN, so text laid out across several lines reads as one
				// line rather than carrying the file's indentation.
				if (!outText.IsEmpty && (outText[outText.Length - 1] != ' '))
					outText.Append(' ');
				continue;
			}
			outText.Append(c);
		}

		outText.Trim();
	}
}
