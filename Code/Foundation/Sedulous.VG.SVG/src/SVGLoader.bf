using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;

namespace Sedulous.VG.SVG;

/// Loads SVG documents from string content.
/// Supports a subset of SVG for icon systems: path, rect, circle, ellipse, line, polygon, polyline, g elements.
public static class SVGLoader
{
	/// Load an SVG document from string content
	public static Result<SVGDocument> Load(StringView svgContent)
	{
		var pos = 0;
		let doc = new SVGDocument();

		// Find <svg> tag
		if (!FindTag(svgContent, ref pos, "svg"))
		{
			delete doc;
			return .Err;
		}

		// Parse svg attributes
		let svgAttrs = scope Dictionary<String, String>();
		defer { for (let kv in svgAttrs) { delete kv.key; delete kv.value; } }
		ParseAttributes(svgContent, ref pos, svgAttrs);

		if (svgAttrs.TryGetValue("width", let wStr))
			if (ParseFloatValue(wStr) case .Ok(let w))
				doc.Width = w;
		if (svgAttrs.TryGetValue("height", let hStr))
			if (ParseFloatValue(hStr) case .Ok(let h))
				doc.Height = h;

		// Parse viewBox if no explicit width/height
		if (doc.Width == 0 && doc.Height == 0)
		{
			if (svgAttrs.TryGetValue("viewBox", let viewBox))
			{
				var vbPos = 0;
				StringView vbView = viewBox;
				if (ParseFloatFromView(vbView, ref vbPos) case .Ok) {}
				if (ParseFloatFromView(vbView, ref vbPos) case .Ok) {}
				if (ParseFloatFromView(vbView, ref vbPos) case .Ok(let w))
					doc.Width = w;
				if (ParseFloatFromView(vbView, ref vbPos) case .Ok(let h))
					doc.Height = h;
			}
		}

		// Parse child elements
		if (ParseChildren(svgContent, ref pos, doc.Elements) case .Err)
		{
			delete doc;
			return .Err;
		}

		return .Ok(doc);
	}

	private static Result<void> ParseChildren(StringView content, ref int pos, List<SVGElement> elements)
	{
		while (pos < content.Length)
		{
			SkipWhitespace(content, ref pos);

			if (pos >= content.Length)
				break;

			// Check for closing tag or self-closing
			if (pos + 1 < content.Length && content[pos] == '<' && content[pos + 1] == '/')
				break;

			if (content[pos] != '<')
			{
				pos++;
				continue;
			}

			// Try to parse element
			let savedPos = pos;

			if (TryParseElement(content, ref pos, elements) case .Err)
			{
				// Skip unknown tag
				pos = savedPos;
				SkipTag(content, ref pos);
			}
		}

		return .Ok;
	}

	private static Result<void> TryParseElement(StringView content, ref int pos, List<SVGElement> elements)
	{
		if (pos >= content.Length || content[pos] != '<')
			return .Err;

		pos++; // Skip '<'
		SkipWhitespace(content, ref pos);

		// Get tag name
		let tagStart = pos;
		while (pos < content.Length && content[pos] != ' ' && content[pos] != '>' && content[pos] != '/' && content[pos] != '\t' && content[pos] != '\n')
			pos++;
		let tagName = scope String(content, tagStart, pos - tagStart);

		// Parse attributes
		let attrs = scope Dictionary<String, String>();
		defer { for (let kv in attrs) { delete kv.key; delete kv.value; } }
		ParseAttributes(content, ref pos, attrs);

		let isSelfClosing = pos > 0 && pos <= content.Length && content[pos - 1] == '/' ||
			(pos < content.Length && content[pos] == '/' && { pos++; true });

		// Skip '>'
		if (pos < content.Length && content[pos] == '>')
			pos++;

		SVGElement element = null;

		if (tagName.Equals("path", .OrdinalIgnoreCase))
		{
			element = new SVGElement(.Path);
			if (attrs.TryGetValue("d", let d))
			{
				let pb = scope PathBuilder();
				if (SVGPathParser.Parse(d, pb) case .Ok)
					element.Path = pb.ToPath();
			}
		}
		else if (tagName.Equals("rect", .OrdinalIgnoreCase))
		{
			element = new SVGElement(.Rect);
			float x = 0, y = 0, w = 0, h = 0, rx = 0, ry = 0;
			if (attrs.TryGetValue("x", let xStr)) if (ParseFloatValue(xStr) case .Ok(let v)) x = v;
			if (attrs.TryGetValue("y", let yStr)) if (ParseFloatValue(yStr) case .Ok(let v)) y = v;
			if (attrs.TryGetValue("width", let wStr)) if (ParseFloatValue(wStr) case .Ok(let v)) w = v;
			if (attrs.TryGetValue("height", let hStr)) if (ParseFloatValue(hStr) case .Ok(let v)) h = v;
			if (attrs.TryGetValue("rx", let rxStr)) if (ParseFloatValue(rxStr) case .Ok(let v)) rx = v;
			if (attrs.TryGetValue("ry", let ryStr)) if (ParseFloatValue(ryStr) case .Ok(let v)) ry = v;
			if (ry == 0) ry = rx;
			if (rx == 0) rx = ry;

			let pb = scope PathBuilder();
			if (rx > 0 || ry > 0)
				ShapeBuilder.BuildRoundedRect(.(x, y, w, h), .(rx), pb);
			else
			{
				pb.MoveTo(x, y);
				pb.LineTo(x + w, y);
				pb.LineTo(x + w, y + h);
				pb.LineTo(x, y + h);
				pb.Close();
			}
			element.Path = pb.ToPath();
		}
		else if (tagName.Equals("circle", .OrdinalIgnoreCase))
		{
			element = new SVGElement(.Circle);
			float cx = 0, cy = 0, r = 0;
			if (attrs.TryGetValue("cx", let cxStr)) if (ParseFloatValue(cxStr) case .Ok(let v)) cx = v;
			if (attrs.TryGetValue("cy", let cyStr)) if (ParseFloatValue(cyStr) case .Ok(let v)) cy = v;
			if (attrs.TryGetValue("r", let rStr)) if (ParseFloatValue(rStr) case .Ok(let v)) r = v;

			let pb = scope PathBuilder();
			ShapeBuilder.BuildCircle(.(cx, cy), r, pb);
			element.Path = pb.ToPath();
		}
		else if (tagName.Equals("ellipse", .OrdinalIgnoreCase))
		{
			element = new SVGElement(.Ellipse);
			float cx = 0, cy = 0, rx = 0, ry = 0;
			if (attrs.TryGetValue("cx", let cxStr)) if (ParseFloatValue(cxStr) case .Ok(let v)) cx = v;
			if (attrs.TryGetValue("cy", let cyStr)) if (ParseFloatValue(cyStr) case .Ok(let v)) cy = v;
			if (attrs.TryGetValue("rx", let rxStr)) if (ParseFloatValue(rxStr) case .Ok(let v)) rx = v;
			if (attrs.TryGetValue("ry", let ryStr)) if (ParseFloatValue(ryStr) case .Ok(let v)) ry = v;

			let pb = scope PathBuilder();
			ShapeBuilder.BuildEllipse(.(cx, cy), rx, ry, pb);
			element.Path = pb.ToPath();
		}
		else if (tagName.Equals("line", .OrdinalIgnoreCase))
		{
			element = new SVGElement(.Line);
			float x1 = 0, y1 = 0, x2 = 0, y2 = 0;
			if (attrs.TryGetValue("x1", let x1Str)) if (ParseFloatValue(x1Str) case .Ok(let v)) x1 = v;
			if (attrs.TryGetValue("y1", let y1Str)) if (ParseFloatValue(y1Str) case .Ok(let v)) y1 = v;
			if (attrs.TryGetValue("x2", let x2Str)) if (ParseFloatValue(x2Str) case .Ok(let v)) x2 = v;
			if (attrs.TryGetValue("y2", let y2Str)) if (ParseFloatValue(y2Str) case .Ok(let v)) y2 = v;

			let pb = scope PathBuilder();
			pb.MoveTo(x1, y1);
			pb.LineTo(x2, y2);
			element.Path = pb.ToPath();
		}
		else if (tagName.Equals("polygon", .OrdinalIgnoreCase) || tagName.Equals("polyline", .OrdinalIgnoreCase))
		{
			let isPolygon = tagName.Equals("polygon", .OrdinalIgnoreCase);
			element = new SVGElement(isPolygon ? .Polygon : .Polyline);

			if (attrs.TryGetValue("points", let pointsStr))
			{
				let pb = scope PathBuilder();
				var pPos = 0;
				bool first = true;
				StringView pView = pointsStr;
				while (pPos < pView.Length)
				{
					if (ParseFloatFromView(pView, ref pPos) case .Ok(let x))
					{
						if (ParseFloatFromView(pView, ref pPos) case .Ok(let y))
						{
							if (first)
							{
								pb.MoveTo(x, y);
								first = false;
							}
							else
								pb.LineTo(x, y);
						}
					}
					else
						break;
				}
				if (isPolygon)
					pb.Close();
				element.Path = pb.ToPath();
			}
		}
		else if (tagName.Equals("g", .OrdinalIgnoreCase))
		{
			element = new SVGElement(.Group);
			element.Children = new List<SVGElement>();

			if (!isSelfClosing)
				ParseChildren(content, ref pos, element.Children);

			// Skip closing </g> tag
			SkipClosingTag(content, ref pos, "g");
		}
		else
		{
			return .Err;
		}

		if (element != null)
		{
			// Apply common attributes
			if (attrs.TryGetValue("fill", let fillStr))
			{
				if (fillStr.Equals("none"))
					element.FillColor = null;
				else if (SVGColorParser.Parse(fillStr) case .Ok(let c))
					element.FillColor = c;
			}
			else
			{
				element.FillColor = Color.Black; // SVG default fill is black
			}

			if (attrs.TryGetValue("stroke", let strokeStr))
			{
				if (!strokeStr.Equals("none"))
					if (SVGColorParser.Parse(strokeStr) case .Ok(let c))
						element.StrokeColor = c;
			}

			if (attrs.TryGetValue("stroke-width", let swStr))
				if (ParseFloatValue(swStr) case .Ok(let v))
					element.StrokeWidth = v;

			if (attrs.TryGetValue("opacity", let opStr))
				if (ParseFloatValue(opStr) case .Ok(let v))
					element.Opacity = v;

			if (attrs.TryGetValue("transform", let trStr))
				if (SVGTransformParser.Parse(trStr) case .Ok(let m))
					element.Transform = m;

			elements.Add(element);
		}

		return .Ok;
	}

	// --- XML Helpers ---

	private static bool FindTag(StringView content, ref int pos, StringView tagName)
	{
		while (pos < content.Length)
		{
			if (content[pos] == '<')
			{
				let start = pos + 1;
				var end = start;
				while (end < content.Length && content[end] != ' ' && content[end] != '>' && content[end] != '/')
					end++;
				let name = content.Substring(start, end - start);
				if (name.Equals(tagName, true))
				{
					pos = end;
					return true;
				}
			}
			pos++;
		}
		return false;
	}

	private static void ParseAttributes(StringView content, ref int pos, Dictionary<String, String> attrs)
	{
		while (pos < content.Length)
		{
			SkipWhitespace(content, ref pos);

			if (pos >= content.Length || content[pos] == '>' || content[pos] == '/')
			{
				if (pos < content.Length && content[pos] == '/')
				{
					pos++;
					if (pos < content.Length && content[pos] == '>')
						pos++;
				}
				else if (pos < content.Length && content[pos] == '>')
					pos++;
				break;
			}

			// Attribute name
			let nameStart = pos;
			while (pos < content.Length && content[pos] != '=' && content[pos] != ' ' && content[pos] != '>')
				pos++;
			let attrName = new String(content, nameStart, pos - nameStart);

			SkipWhitespace(content, ref pos);
			if (pos < content.Length && content[pos] == '=')
			{
				pos++;
				SkipWhitespace(content, ref pos);

				// Attribute value
				if (pos < content.Length && (content[pos] == '"' || content[pos] == '\''))
				{
					let quote = content[pos];
					pos++;
					let valStart = pos;
					while (pos < content.Length && content[pos] != quote)
						pos++;
					let attrValue = new String(content, valStart, pos - valStart);
					if (pos < content.Length)
						pos++; // Skip closing quote
					attrs[attrName] = attrValue;
				}
				else
				{
					delete attrName;
				}
			}
			else
			{
				delete attrName;
			}
		}
	}

	private static void SkipTag(StringView content, ref int pos)
	{
		// Skip past '>'
		while (pos < content.Length && content[pos] != '>')
			pos++;
		if (pos < content.Length)
			pos++;
	}

	private static void SkipClosingTag(StringView content, ref int pos, StringView tagName)
	{
		SkipWhitespace(content, ref pos);
		if (pos + 1 < content.Length && content[pos] == '<' && content[pos + 1] == '/')
		{
			pos += 2;
			while (pos < content.Length && content[pos] != '>')
				pos++;
			if (pos < content.Length)
				pos++;
		}
	}

	private static void SkipWhitespace(StringView s, ref int pos)
	{
		while (pos < s.Length && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == '\n' || s[pos] == '\r'))
			pos++;
	}

	private static Result<float> ParseFloatValue(StringView s)
	{
		// Remove trailing units like "px"
		var end = 0;
		while (end < s.Length && (s[end] >= '0' && s[end] <= '9' || s[end] == '.' || s[end] == '-' || s[end] == '+'))
			end++;
		if (end == 0)
			return .Err;

		let numStr = s.Substring(0, end);
		if (float.Parse(numStr) case .Ok(let val))
			return .Ok(val);
		return .Err;
	}

	private static Result<float> ParseFloatFromView(StringView s, ref int pos)
	{
		// Skip whitespace and commas
		while (pos < s.Length && (s[pos] == ' ' || s[pos] == '\t' || s[pos] == ',' || s[pos] == '\n'))
			pos++;
		if (pos >= s.Length)
			return .Err;

		let start = pos;
		if (pos < s.Length && (s[pos] == '-' || s[pos] == '+'))
			pos++;
		while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
			pos++;
		if (pos < s.Length && s[pos] == '.')
		{
			pos++;
			while (pos < s.Length && s[pos] >= '0' && s[pos] <= '9')
				pos++;
		}

		if (pos == start)
			return .Err;

		let numStr = s.Substring(start, pos - start);
		if (float.Parse(numStr) case .Ok(let val))
			return .Ok(val);
		return .Err;
	}
}
