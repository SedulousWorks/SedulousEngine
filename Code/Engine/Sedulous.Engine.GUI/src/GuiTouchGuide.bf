using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Input;
using Sedulous.GUI;
using Sedulous.Input;

namespace Sedulous.Engine.GUI;

/// The guide to a game's touch controls, drawn over the game once a finger has touched the screen
/// (a desktop player never sees it), on the GUI: every
/// touch binding of the sets in effect (ActionRuntime.ForEachTouchControl), a button as a circle
/// filling its zone with its action's name (what is seen is what is tapped; stronger while held), an
/// idle stick as a small ring low in its zone, in a dark wash with a light edge that reads on snow
/// and at night alike; a stick a finger holds as a ring where the finger came down and a knob where
/// it is. Regions are normalized over the guide. It takes no pointer.
class GuiTouchGuide : UIWidget
{
	private struct Shown
	{
		/// Normalized.
		public Rectangle Region;
		public bool Stick;
		public bool Down;
		public bool Held;
		/// Normalized.
		public Float2 Anchor;
		public Float2 Finger;
		/// Normalized, over the width.
		public float Radius;
	}

	/// A control's name is this share of its guide's diameter, and never smaller than the least.
	private const float cGuideFontPerSize = 0.16f;
	private const float cGuideMinFontSize = 15.0f;

	private List<Shown> mControls = new .() ~ delete _;
	/// One per control, its action's name: children of this guide, with a reference each of ours.
	private List<Label> mLabels = new .() ~ { for (let label in _) label.ReleaseRef(); delete _; };

	public this()
	{
		Tag = "touchguide";
		HitTestVisible = false;
		Visible = false;
	}

	/// The controls shown (none while hidden), for tests.
	public int ControlCount => mControls.Count;

	/// This frame's controls, from every action runtime in play (`input`); `touched` = a finger has
	/// touched the screen.
	public void Update(InputSubsystem input, bool touched)
	{
		mControls.Clear();
		if (touched)
		{
			input.ForEachActionRuntime(scope [&] (runtime) =>
				{
					runtime.ForEachTouchControl(scope [&] (control) =>
						{
							let b = control.Binding;
							var shown = Shown();
							shown.Region = .(b.RegionX, b.RegionY, b.RegionW, b.RegionH);
							shown.Stick = b.Source == .TouchStick;
							shown.Down = control.Down;
							shown.Held = control.Held;
							shown.Anchor = control.Anchor;
							shown.Finger = control.Finger;
							shown.Radius = (b.StickRadius > 0.0f) ? b.StickRadius : 0.15f;
							mControls.Add(shown);
							// The action's name, centred in its zone (a stick's while no finger holds it).
							if (mLabels.Count < mControls.Count)
							{
								let label = new Label();
								label.HitTestVisible = false;
								label.SetInlineStyle("text-align", "center");
								label.SetInlineStyle("color", "#ffffff");
								mLabels.Add(label);
								AddChild(label);
							}
							mLabels[mControls.Count - 1].Text = control.Action;
						});
				});
		}
		let w = Size.X;
		let h = Size.Y;
		for (int i < mLabels.Count)
		{
			let label = mLabels[i];
			let show = (i < mControls.Count) && !mControls[i].Held;
			label.Visible = show;
			if (!show)
				continue;
			let centre = GuideCentre(mControls[i], w, h);
			let size = GuideRadius(mControls[i], w, h) * 2.0f;
			// The name grows with its button, as the button grows with the screen: a fixed size was
			// legible on a desktop window and tiny on a phone's many pixels.
			let fontSize = Math.Max(cGuideMinFontSize, size * cGuideFontPerSize);
			label.SetInlineStyle("font-size", scope $"{fontSize}px");
			label.SetInlineStyle("opacity", mControls[i].Down ? "1" : "0.85");
			label.EditLayoutStyle(scope (s) =>
				{
					s.Placement = .Absolute;
					s.Left = LayoutLength.Px(centre.X - size * 0.5f);
					s.Top = LayoutLength.Px(centre.Y - fontSize * 0.65f); // the line's middle on the centre
					s.Width = LayoutLength.Px(size);
				});
		}
		// Redraw while a control shows (fingers move), and once more as the last one goes; idle with
		// nothing shown it asks for nothing.
		let wasShown = Visible;
		Visible = !mControls.IsEmpty;
		if (!mControls.IsEmpty || wasShown)
			Invalidate();
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		let w = localBounds.Width;
		let h = localBounds.Height;
		let g = ctx.VG;
		for (let shown in mControls)
		{
			if (shown.Stick && shown.Held)
			{
				// A ring where the finger came down, the stick's reach; a knob where it is, held
				// inside the ring.
				let anchor = Float2(shown.Anchor.X * w, shown.Anchor.Y * h);
				let reach = shown.Radius * w;
				var knob = Float2(shown.Finger.X * w, shown.Finger.Y * h);
				let offset = Float2(knob.X - anchor.X, knob.Y - anchor.Y);
				let length = Math.Sqrt(offset.X * offset.X + offset.Y * offset.Y);
				if ((length > reach) && (length > 0.0f))
					knob = .(anchor.X + offset.X / length * reach, anchor.Y + offset.Y / length * reach);
				g.FillCircle(anchor, reach, .(0.0f, 0.0f, 0.0f, 0.22f));
				g.StrokeCircle(anchor, reach, .(1.0f, 1.0f, 1.0f, 0.6f), 3.0f);
				g.FillCircle(knob, reach * 0.4f, .(1.0f, 1.0f, 1.0f, 0.7f));
				g.StrokeCircle(knob, reach * 0.4f, .(0.0f, 0.0f, 0.0f, 0.35f), 2.0f);
				continue;
			}
			// A button fills its zone (what is seen is what is tapped); an idle stick is a small ring
			// low in its zone, where a thumb rests. A dark wash with a light edge reads on snow and at
			// night alike.
			let centre = GuideCentre(shown, w, h);
			let radius = GuideRadius(shown, w, h);
			g.FillCircle(centre, radius, .(0.0f, 0.0f, 0.0f, shown.Down ? 0.34f : 0.2f));
			g.StrokeCircle(centre, radius, .(1.0f, 1.0f, 1.0f, shown.Down ? 0.85f : 0.5f), 2.5f);
		}
	}

	/// Where a control's guide is drawn, in the guide's units: a button's at its zone's centre; an
	/// idle stick's low in its zone, a third of the way in.
	private static Float2 GuideCentre(Shown shown, float w, float h)
	{
		let across = shown.Stick ? 0.3f : 0.5f;
		let down = shown.Stick ? 0.75f : 0.5f;
		return .((shown.Region.X + shown.Region.Width * across) * w, (shown.Region.Y + shown.Region.Height * down) * h);
	}

	/// How large: a button fills its zone (its inscribed circle, short of the edge); an idle stick's
	/// ring is 0.35 of that.
	private static float GuideRadius(Shown shown, float w, float h)
	{
		let zoneW = shown.Region.Width * w;
		let zoneH = shown.Region.Height * h;
		let inscribed = Math.Min(zoneW, zoneH) * 0.5f;
		return shown.Stick ? inscribed * 0.35f : ((inscribed > 4.0f) ? inscribed - 3.0f : inscribed);
	}
}
