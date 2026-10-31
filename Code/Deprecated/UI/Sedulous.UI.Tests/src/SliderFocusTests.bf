using System;
using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Tests;

/// A slider's focus shows. Its parts were drawn without the control's state, so a state-list
/// thumb (a knob that lights up when focused) only ever drew its normal entry and a pad player
/// could not tell which slider they were moving; and the built-in themes gave the knob no
/// focused look to draw.
class SliderFocusTests
{
	/// Records the state each draw was given.
	private class StateProbe : Drawable
	{
		public int Draws = 0;
		public ControlState LastState = .Normal;

		public override void Draw(UIDrawContext ctx, Rectangle bounds)
		{
			Draws++;
			LastState = .Normal;
		}

		protected override void DrawState(UIDrawContext ctx, Rectangle bounds, ControlState state)
		{
			Draws++;
			LastState = state;
		}
	}

	[Test]
	public static void ASlidersThumbIsDrawnWithItsFocus()
	{
		let context = new UIContext();
		let root = new RootView();
		UITest.Init(context, root);
		defer { root.ReleaseRef(); delete context; }

		let sheet = new StyleSheet();
		context.SetStyleSheet(sheet);
		let probe = new StateProbe();
		sheet.OwnDrawable(probe);
		sheet.ForTypePseudo(typeof(Slider), "thumb").Set(.Background, probe);

		let slider = new Slider(0.0f, 1.0f, 0.5f);
		root.AddView(slider);
		slider.Measure(BoxConstraints.Tight(200, 24));
		slider.Layout(0, 0, 200, 24);

		let vg = scope VGContext();
		let draw = scope UIDrawContext(vg, 1.0f, null);

		// Focus as keys or a pad give it: the ring's state reaches the thumb.
		context.GetFocusManager().SetFocus(slider, .Keyboard);
		slider.OnDraw(draw);
		Test.Assert(probe.Draws > 0, "the thumb was drawn");
		Test.Assert(probe.LastState.HasFlag(.Focused), "drawn focused");

		// Without focus it is not.
		context.GetFocusManager().ClearFocus();
		slider.OnDraw(draw);
		Test.Assert(!probe.LastState.HasFlag(.Focused), "drawn unfocused");
	}

	/// Every built-in theme gives the thumb a focused look of its own, not the normal one.
	[Test]
	public static void EveryBuiltInThemeHasAFocusedThumb()
	{
		StyleSheetLoader.InitializeGlobals();
		let context = new UIContext();
		let root = new RootView();
		UITest.Init(context, root);
		defer { root.ReleaseRef(); delete context; }

		let slider = new Slider(0.0f, 1.0f, 0.5f);
		root.AddView(slider);

		for (let theme in StringView[3]("dark", "light", "rounded-dark"))
		{
			switch (theme)
			{
			case "dark": context.SetStyleSheet(DarkTheme.Create());
			case "light": context.SetStyleSheet(LightTheme.Create());
			default: context.SetStyleSheet(RoundedDarkTheme.Create());
			}
			let thumb = slider.ResolvePartDrawable("thumb", .Background, .Normal) as StateListDrawable;
			Test.Assert(thumb != null, scope $"{theme}: the thumb is a state list");
			Test.Assert((thumb.Get(.Focused) != null) && (thumb.Get(.Focused) !== thumb.Get(.Normal)),
				scope $"{theme}: focused differs from normal");
		}
	}
}
