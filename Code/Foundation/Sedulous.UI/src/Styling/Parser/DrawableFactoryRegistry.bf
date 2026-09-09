using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;

namespace Sedulous.UI;

/// The drawable factories a style sheet can call, by name.
///
/// Extensible: a host registers its own with Register. A factory is non capturing, so this is
/// a plain function pointer rather than a delegate and the registry owns nothing.
///
/// Every factory answers an OWNED drawable. The CALLER decides where ownership goes: a
/// drawable property gives it to the sheet so the rule can borrow, while a composite such as
/// state-list consumes its children outright.
static class DrawableFactoryRegistry
{
	public typealias FactoryFn = function Drawable(SSSParser parser, StyleSheet sheet);

	private static Dictionary<String, FactoryFn> sFactories = new .() ~ DeleteDictionaryAndKeys!(_);
	private static bool sBuiltinsRegistered = false;

	/// Registers a factory, replacing any of the same name.
	public static void Register(StringView name, FactoryFn factory)
	{
		if (sFactories.TryGetAlt(name, let existingKey, ?))
		{
			sFactories[existingKey] = factory;
			return;
		}
		sFactories[new String(name)] = factory;
	}

	/// The factory of that name, or null.
	public static FactoryFn Get(StringView name)
	{
		if (sFactories.TryGetValueAlt(name, let factory))
			return factory;
		return null;
	}

	/// The control state a state-list keyword names.
	private static ControlState ParseStateName(StringView name)
	{
		switch (name)
		{
		case "hover": return .Hover;
		case "pressed": return .Pressed;
		case "focused": return .Focused;
		case "disabled": return .Disabled;
		case "checked": return .Checked;
		case "indeterminate": return .Indeterminate;
		// `normal`, and anything unrecognised.
		default: return .Normal;
		}
	}

	/// Reads a `tint=` keyword argument, or a bare colour in its place. Null when neither
	/// follows.
	private static Color? ParseTintArg(SSSParser parser)
	{
		if (!parser.MatchComma())
			return null;
		if (parser.PeekKeywordArg() == "tint")
			parser.ConsumeKeywordArg();
		return parser.ParseColorArg();
	}

	/// Registers the built in factories. Idempotent, the map being process wide.
	public static void RegisterBuiltins()
	{
		if (sBuiltinsRegistered)
			return;
		sBuiltinsRegistered = true;

		// color($color)
		Register("color", (parser, sheet) => new ColorDrawable(parser.ParseColorArg()));

		// rounded-rect($color, radius=6, border=$color, border-width=1)
		Register("rounded-rect", (parser, sheet) =>
			{
				let fill = parser.ParseColorArg();
				CornerRadii radii = .();
				var borderColor = Color.Transparent;
				var borderWidth = 0.0f;

				while (parser.MatchComma())
				{
					switch (parser.PeekKeywordArg())
					{
					case "radius":
						parser.ConsumeKeywordArg();
						radii = parser.ParseCornerRadiiValue();
					case "border-width":
						parser.ConsumeKeywordArg();
						borderWidth = parser.ParseFloatValue();
					case "border":
						parser.ConsumeKeywordArg();
						borderColor = parser.ParseColorArg();
					default:
						// A bare argument is the radius.
						radii = parser.ParseCornerRadiiValue();
					}
				}

				return new RoundedRectDrawable(fill, radii, borderColor, borderWidth);
			});

		// gradient(direction, color1, color2)
		Register("gradient", (parser, sheet) =>
			{
				var direction = GradientDirection.TopToBottom;
				switch (parser.PeekIdent())
				{
				case "top-to-bottom":
					parser.ConsumeIdent();
					parser.MatchComma();
				case "left-to-right":
					parser.ConsumeIdent();
					direction = .LeftToRight;
					parser.MatchComma();
				case "top-left-to-bottom-right":
					parser.ConsumeIdent();
					direction = .TopLeftToBottomRight;
					parser.MatchComma();
				case "top-right-to-bottom-left":
					parser.ConsumeIdent();
					direction = .TopRightToBottomLeft;
					parser.MatchComma();
				default:
					// No direction given: the default stands and the colours follow.
				}

				let first = parser.ParseColorArg();
				parser.MatchComma();
				let second = parser.ParseColorArg();
				return new GradientDrawable(first, second, direction);
			});

		// state-list(normal=d, hover=d, ...)
		Register("state-list", (parser, sheet) =>
			{
				let list = new StateListDrawable();
				while (!parser.IsAtRParen)
				{
					let stateName = parser.PeekKeywordArg();
					if (!stateName.IsEmpty)
					{
						parser.ConsumeKeywordArg();
						let state = ParseStateName(stateName);
						let drawable = parser.ParseDrawableValue(sheet);
						if (drawable != null)
							list.Set(state, drawable);
					}
					if (!parser.MatchComma())
						break;
				}
				return list;
			});

		// state-colors($base)
		Register("state-colors",
			(parser, sheet) => Palette.CreateStateColors(parser.ParseColorArg()));

		// state-rounded($base, radius=6)
		Register("state-rounded", (parser, sheet) =>
			{
				let baseColor = parser.ParseColorArg();
				CornerRadii radii = .();
				if (parser.MatchComma())
				{
					if (parser.PeekKeywordArg() == "radius")
						parser.ConsumeKeywordArg();
					radii = parser.ParseCornerRadiiValue();
				}
				return Palette.CreateStateRounded(baseColor, radii);
			});

		// layer(d1, d2, ...)
		Register("layer", (parser, sheet) =>
			{
				let layers = new LayerDrawable();
				while (!parser.IsAtRParen)
				{
					let drawable = parser.ParseDrawableValue(sheet);
					if (drawable != null)
						layers.AddLayer(drawable);
					if (!parser.MatchComma())
						break;
				}
				return layers;
			});

		// inset(drawable, top, right, bottom, left)
		Register("inset", (parser, sheet) =>
			{
				let inner = parser.ParseDrawableValue(sheet);
				var top = 0.0f, right = 0.0f, bottom = 0.0f, left = 0.0f;
				if (parser.MatchComma())
					top = parser.ParseFloatValue();
				if (parser.MatchComma())
					right = parser.ParseFloatValue();
				if (parser.MatchComma())
					bottom = parser.ParseFloatValue();
				if (parser.MatchComma())
					left = parser.ParseFloatValue();

				return new InsetDrawable(inner, Thickness(left, top, right, bottom));
			});

		// svg(name, tint=$color)
		Register("svg", (parser, sheet) =>
			{
				let name = parser.ConsumeIdent();
				let tint = ParseTintArg(parser);
				let svgText = parser.ResolveSvg(name);

				if (svgText == null)
				{
					// Not registered by the host. The ten built in chrome glyph names still
					// resolve, so a cooked or runtime theme works WITHOUT a host side
					// registration, and shares the pixel snapped baked instances rather than
					// parsing a fresh live vector each time.
					let builtin = ThemeIcon.FromName(name);
					if (builtin == null)
						return null;
					return (tint != null)
						? ThemeIconSet.Acquire(builtin.Value, tint.Value)
						: ThemeIconSet.Acquire(builtin.Value);
				}

				return (tint != null)
					? SVGDrawable.FromString(svgText.Value, tint.Value)
					: SVGDrawable.FromString(svgText.Value);
			});

		// image(name, tint=$color)
		Register("image", (parser, sheet) =>
			{
				let name = parser.ConsumeIdent();
				let tint = ParseTintArg(parser);

				let image = parser.ResolveImage(name);
				if (image == null)
					return null;
				return new ImageDrawable(image, (tint != null) ? tint.Value : Color.White);
			});

		// nine-slice(name, slices, tint=$color)
		Register("nine-slice", (parser, sheet) =>
			{
				let name = parser.ConsumeIdent();
				parser.MatchComma();

				float[4] values = .();
				var count = 0;
				while ((count < 4) && parser.PeekIsNumber)
				{
					values[count] = parser.ParseFloatValue();
					count++;
				}

				NineSlice slices = .();
				if (count == 1)
					slices = .(values[0], values[0], values[0], values[0]);
				else if (count == 4)
					slices = .(values[0], values[1], values[2], values[3]);

				let tint = ParseTintArg(parser);

				let image = parser.ResolveImage(name);
				if (image == null)
					return null;
				return new NineSliceDrawable(image, slices,
					(tint != null) ? tint.Value : Color.White);
			});
	}
}
