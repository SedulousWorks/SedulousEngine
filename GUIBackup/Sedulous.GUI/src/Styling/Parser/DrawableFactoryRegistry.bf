namespace Sedulous.GUI;

using System;
using System.Collections;
using Sedulous.Core.Mathematics;

/// Registry of drawable factory functions invocable from .sss stylesheets.
/// User-extensible via Register().
public static class DrawableFactoryRegistry
{
	public delegate Drawable FactoryFn(SSSParser parser, StyleSheet sheet);

	private static Dictionary<String, FactoryFn> sFactories = new .() ~ {
		for (let kv in _) { delete kv.key; delete kv.value; }
		delete _;
	};

	public static void Register(StringView name, FactoryFn factory)
	{
		sFactories[new String(name)] = factory;
	}

	public static FactoryFn Get(StringView name)
	{
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
			// TODO: parse direction keyword + color stops
			let c1 = parser.ParseColorArg();
			parser.MatchComma();
			let c2 = parser.ParseColorArg();
			let d = new GradientDrawable(c1, c2);
			sheet.OwnDrawable(d);
			return d;
		});

		// state-list(normal=..., hover=..., pressed=...) -> StateListDrawable
		Register("state-list", new (parser, sheet) => {
			let sl = new StateListDrawable(false);
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

		// layer(d1, d2, ...) -> LayerDrawable
		Register("layer", new (parser, sheet) => {
			let ld = new LayerDrawable(false);
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

			let d = new InsetDrawable(inner, .(l, t, r, b));
			sheet.OwnDrawable(d);
			return d;
		});

		// svg(name, tint=$color) -> SVGDrawable (stub — needs @icon registry + VFS)
		Register("svg", new (parser, sheet) => {
			parser.ParseColorArg(); // consume arg; SVG loading not yet wired
			return null;
		});

		// image(path, tint=$color) -> ImageDrawable (stub — needs VFS)
		Register("image", new (parser, sheet) => {
			parser.ParseColorArg(); // consume arg; image loading not yet wired
			return null;
		});

		// nine-slice(image, slices, tint=$color) -> NineSliceDrawable (stub — needs VFS)
		Register("nine-slice", new (parser, sheet) => {
			return null;
		});
	}

	private static ControlState ParseStateName(StringView name)
	{
		if (name == "normal")   return .Normal;
		if (name == "hover")    return .Hover;
		if (name == "pressed")  return .Pressed;
		if (name == "focused")  return .Focused;
		if (name == "disabled") return .Disabled;
		if (name == "checked")  return .Checked;
		return .Normal;
	}
}
