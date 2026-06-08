namespace Sedulous.UI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.VG;
using Sedulous.Images;

/// Registry of drawable factory functions invocable from .sss stylesheets.
/// User-extensible via Register().
public static class DrawableFactoryRegistry
{
	public delegate Drawable FactoryFn(SSSParser parser, StyleSheet sheet);

	private static Dictionary<String, FactoryFn> sFactories ~ {
		if (_ != null) { for (let kv in _) { delete kv.key; delete kv.value; } delete _; }
	};

	private static void EnsureInit()
	{
		if (sFactories == null)
			sFactories = new .();
	}

	public static void Register(StringView name, FactoryFn factory)
	{
		EnsureInit();
		for (let kv in sFactories)
		{
			if (StringView(kv.key) == name)
			{
				delete sFactories[kv.key];
				sFactories[kv.key] = factory;
				return;
			}
		}
		sFactories[new String(name)] = factory;
	}

	public static FactoryFn Get(StringView name)
	{
		EnsureInit();
		for (let kv in sFactories)
		{
			if (StringView(kv.key) == name)
				return kv.value;
		}
		return null;
	}

	public static void RegisterBuiltins()
	{
		// color($color) -> ColorDrawable
		Register("color", new (parser, sheet) => {
			let color = parser.ParseColorArg();
			let d = new ColorDrawable(color);
			sheet.OwnDrawable(d);
			return d;
		});

		// rounded-rect($color, radius=6, border=$color, border-width=1) -> RoundedRectDrawable
		Register("rounded-rect", new (parser, sheet) => {
			let fillColor = parser.ParseColorArg();
			float radius = 0;
			Color borderColor = .Transparent;
			float borderWidth = 0;

			while (parser.MatchComma())
			{
				let kw = parser.PeekKeywordArg();
				if (kw == "radius")
					{ parser.ConsumeKeywordArg(); radius = parser.ParseFloatValue(); }
				else if (kw == "border-width")
					{ parser.ConsumeKeywordArg(); borderWidth = parser.ParseFloatValue(); }
				else if (kw == "border")
					{ parser.ConsumeKeywordArg(); borderColor = parser.ParseColorArg(); }
				else
					radius = parser.ParseFloatValue();
			}

			let d = new RoundedRectDrawable(fillColor, radius, borderColor, borderWidth);
			sheet.OwnDrawable(d);
			return d;
		});

		// gradient(direction, color1, color2) -> GradientDrawable
		Register("gradient", new (parser, sheet) => {
			// Parse direction keyword
			var dir = GradientDirection.TopToBottom;
			if (parser.PeekIdent() == "top-to-bottom") { parser.ConsumeIdent(); dir = .TopToBottom; parser.MatchComma(); }
			else if (parser.PeekIdent() == "left-to-right") { parser.ConsumeIdent(); dir = .LeftToRight; parser.MatchComma(); }
			else if (parser.PeekIdent() == "top-left-to-bottom-right") { parser.ConsumeIdent(); dir = .TopLeftToBottomRight; parser.MatchComma(); }
			else if (parser.PeekIdent() == "top-right-to-bottom-left") { parser.ConsumeIdent(); dir = .TopRightToBottomLeft; parser.MatchComma(); }

			let c1 = parser.ParseColorArg();
			parser.MatchComma();
			let c2 = parser.ParseColorArg();
			let d = new GradientDrawable(c1, c2, dir);
			sheet.OwnDrawable(d);
			return d;
		});

		// state-list(normal=d, hover=d, pressed=d, ...) -> StateListDrawable
		Register("state-list", new (parser, sheet) => {
			let sl = new StateListDrawable(false); // sheet owns children via OwnDrawable
			sheet.OwnDrawable(sl);

			while (!parser.IsAtRParen())
			{
				let stateName = parser.PeekKeywordArg();
				if (stateName.Length > 0)
				{
					parser.ConsumeKeywordArg();
					let state = ParseStateName(stateName);
					let drawable = parser.ParseDrawableValue(sheet);
					if (drawable != null)
						sl.Set(state, drawable);
				}
				if (!parser.MatchComma()) break;
			}

			return sl;
		});

		// state-colors($base) -> StateListDrawable via Palette.CreateStateColors
		Register("state-colors", new (parser, sheet) => {
			let baseColor = parser.ParseColorArg();
			let sl = Palette.CreateStateColors(baseColor);
			sheet.OwnDrawable(sl);
			return sl;
		});

		// state-rounded($base, radius=6) -> StateListDrawable via Palette.CreateStateRounded
		Register("state-rounded", new (parser, sheet) => {
			let baseColor = parser.ParseColorArg();
			float radius = 0;
			if (parser.MatchComma())
			{
				let kw = parser.PeekKeywordArg();
				if (kw == "radius")
					{ parser.ConsumeKeywordArg(); radius = parser.ParseFloatValue(); }
				else
					radius = parser.ParseFloatValue();
			}
			let sl = Palette.CreateStateRounded(baseColor, .(radius));
			sheet.OwnDrawable(sl);
			return sl;
		});

		// layer(d1, d2, ...) -> LayerDrawable
		Register("layer", new (parser, sheet) => {
			let ld = new LayerDrawable(false); // sheet owns children
			sheet.OwnDrawable(ld);

			while (!parser.IsAtRParen())
			{
				let drawable = parser.ParseDrawableValue(sheet);
				if (drawable != null)
					ld.AddLayer(drawable);
				if (!parser.MatchComma()) break;
			}

			return ld;
		});

		// inset(drawable, top, right, bottom, left) -> InsetDrawable
		Register("inset", new (parser, sheet) => {
			let inner = parser.ParseDrawableValue(sheet);
			float t = 0, r = 0, b = 0, l = 0;
			if (parser.MatchComma()) t = parser.ParseFloatValue();
			if (parser.MatchComma()) r = parser.ParseFloatValue();
			if (parser.MatchComma()) b = parser.ParseFloatValue();
			if (parser.MatchComma()) l = parser.ParseFloatValue();

			let d = new InsetDrawable(inner, .(l, t, r, b), ownsInner: false); // sheet owns inner
			sheet.OwnDrawable(d);
			return d;
		});

		// svg(name, tint=$color) -> SVGDrawable
		Register("svg", new (parser, sheet) => {
			let name = parser.ConsumeIdent();
			Color? tint = null;
			if (parser.MatchComma())
			{
				let kw = parser.PeekKeywordArg();
				if (kw == "tint")
				{
					parser.ConsumeKeywordArg();
					tint = parser.ParseColorArg();
				}
				else
				{
					tint = parser.ParseColorArg();
				}
			}

			let svgText = parser.ResolveSvg(name);
			if (svgText == null)
				return null;

			SVGDrawable d;
			if (tint.HasValue)
				d = SVGDrawable.FromString(svgText.Value, tint.Value);
			else
				d = SVGDrawable.FromString(svgText.Value);

			if (d != null)
				sheet.OwnDrawable(d);
			return d;
		});

		// image(name, tint=$color) -> ImageDrawable
		Register("image", new (parser, sheet) => {
			let name = parser.ConsumeIdent();
			Color tint = .White;
			if (parser.MatchComma())
			{
				let kw = parser.PeekKeywordArg();
				if (kw == "tint")
					{ parser.ConsumeKeywordArg(); tint = parser.ParseColorArg(); }
				else
					tint = parser.ParseColorArg();
			}

			let imageData = parser.ResolveImage(name);
			if (imageData == null)
				return null;

			let d = new ImageDrawable(imageData, tint);
			sheet.OwnDrawable(d);
			return d;
		});

		// nine-slice(name, slices, tint=$color) -> NineSliceDrawable
		Register("nine-slice", new (parser, sheet) => {
			let name = parser.ConsumeIdent();
			parser.MatchComma();

			// Parse slices as 1 or 4 values
			float[4] sliceVals = default;
			int sliceCount = 0;
			while (sliceCount < 4 && parser.PeekIsNumber())
			{
				sliceVals[sliceCount++] = parser.ParseFloatValue();
			}

			NineSlice slices = default;
			if (sliceCount == 1)
				slices = .((int32)sliceVals[0], (int32)sliceVals[0], (int32)sliceVals[0], (int32)sliceVals[0]);
			else if (sliceCount == 4)
				slices = .((int32)sliceVals[0], (int32)sliceVals[1], (int32)sliceVals[2], (int32)sliceVals[3]);

			Color tint = .White;
			if (parser.MatchComma())
			{
				let kw = parser.PeekKeywordArg();
				if (kw == "tint")
					{ parser.ConsumeKeywordArg(); tint = parser.ParseColorArg(); }
				else
					tint = parser.ParseColorArg();
			}

			let imageData = parser.ResolveImage(name);
			if (imageData == null)
				return null;

			let d = new NineSliceDrawable(imageData, slices, tint);
			sheet.OwnDrawable(d);
			return d;
		});
	}

	private static ControlState ParseStateName(StringView name)
	{
		if (name == "normal")        return .Normal;
		if (name == "hover")         return .Hover;
		if (name == "pressed")       return .Pressed;
		if (name == "focused")       return .Focused;
		if (name == "disabled")      return .Disabled;
		if (name == "checked")       return .Checked;
		if (name == "indeterminate") return .Indeterminate;
		return .Normal;
	}
}
