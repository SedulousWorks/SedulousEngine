using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Engine.Input;
using Sedulous.Fonts;
using Sedulous.Input;
using Sedulous.UI;

namespace Sedulous.Engine.UI;

/// The guide to a game's touch controls, drawn over the game once a finger has touched the
/// screen (a desktop player never sees it): every touch binding of the sets in effect
/// (ActionRuntime.ForEachTouchControl), a button as a circle filling its zone with its action's
/// name (what is seen is what is tapped; stronger while held), an idle stick as a small ring low
/// in its zone, in a dark wash with a light edge that reads on snow and at night alike; a stick
/// a finger holds as a ring where the finger came down and a knob where it is. Regions are
/// normalized over the view. Never hit-tested.
class TouchGuideView : AbsoluteLayout
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

	private List<Shown> mControls = new .() ~ delete _;
	/// One per control, its action's name. Children of this view, which owns them.
	private List<Label> mLabels = new .() ~ delete _;

	public this()
	{
		IsHitTestVisible = false;
		Visibility = .Gone;
	}

	/// The controls shown (none while hidden), for tests.
	public int ControlCount => mControls.Count;

	/// This frame's controls, from every action runtime in play (`input`); `touched` = a finger
	/// has touched the screen.
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
								label.FontSize.Value = 15.0f;
								label.HAlign.Value = .Center;
								label.IsHitTestVisible = false;
								mLabels.Add(label);
								AddView(label);
							}
							mLabels[mControls.Count - 1].SetText(control.Action);
						});
				});
		}
		let w = Width;
		let h = Height;
		for (int i < mLabels.Count)
		{
			let label = mLabels[i];
			let show = (i < mControls.Count) && !mControls[i].Held;
			label.Visibility = show ? .Visible : .Gone;
			if (!show)
				continue;
			let centre = GuideCentre(mControls[i], w, h);
			let size = GuideRadius(mControls[i], w, h) * 2.0f;
			var place = LayoutStyle();
			place.Left = centre.X - size * 0.5f;
			place.Top = centre.Y - 10.0f;
			place.Width = SizeSpec.Fixed(Unit.Dp(size));
			label.SetLayout(place);
			label.TextColor.Value = Color(1.0f, 1.0f, 1.0f, mControls[i].Down ? 1.0f : 0.85f);
		}
		Visibility = mControls.IsEmpty ? .Gone : .Visible;
		Invalidate();
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let w = Width;
		let h = Height;
		for (let shown in mControls)
		{
			if (shown.Stick && shown.Held)
			{
				// A ring where the finger came down, the stick's reach; a knob where it is,
				// held inside the ring.
				let anchor = Float2(shown.Anchor.X * w, shown.Anchor.Y * h);
				let reach = shown.Radius * w;
				var knob = Float2(shown.Finger.X * w, shown.Finger.Y * h);
				let offset = Float2(knob.X - anchor.X, knob.Y - anchor.Y);
				let length = Math.Sqrt(offset.X * offset.X + offset.Y * offset.Y);
				if ((length > reach) && (length > 0.0f))
					knob = .(anchor.X + offset.X / length * reach, anchor.Y + offset.Y / length * reach);
				ctx.VG.FillCircle(anchor, reach, .(0.0f, 0.0f, 0.0f, 0.22f));
				ctx.VG.StrokeCircle(anchor, reach, .(1.0f, 1.0f, 1.0f, 0.6f), 3.0f);
				ctx.VG.FillCircle(knob, reach * 0.4f, .(1.0f, 1.0f, 1.0f, 0.7f));
				ctx.VG.StrokeCircle(knob, reach * 0.4f, .(0.0f, 0.0f, 0.0f, 0.35f), 2.0f);
				continue;
			}
			// A button fills its zone (what is seen is what is tapped); an idle stick is a small
			// ring low in its zone, where a thumb rests. A dark wash with a light edge reads on
			// snow and at night alike.
			let centre = GuideCentre(shown, w, h);
			let radius = GuideRadius(shown, w, h);
			ctx.VG.FillCircle(centre, radius, .(0.0f, 0.0f, 0.0f, shown.Down ? 0.34f : 0.2f));
			ctx.VG.StrokeCircle(centre, radius, .(1.0f, 1.0f, 1.0f, shown.Down ? 0.85f : 0.5f), 2.5f);
		}
		DrawChildren(ctx);
	}

	/// Where a control's guide is drawn, in the view's pixels: a button's at its zone's centre;
	/// an idle stick's low in its zone, a third of the way in.
	private static Float2 GuideCentre(Shown shown, float w, float h)
	{
		let across = shown.Stick ? 0.3f : 0.5f;
		let down = shown.Stick ? 0.75f : 0.5f;
		return .((shown.Region.X + shown.Region.Width * across) * w,
			(shown.Region.Y + shown.Region.Height * down) * h);
	}

	/// How large: a button fills its zone (its inscribed circle, short of the edge); an idle
	/// stick's ring is 0.35 of that.
	private static float GuideRadius(Shown shown, float w, float h)
	{
		let zoneW = shown.Region.Width * w;
		let zoneH = shown.Region.Height * h;
		let inscribed = Math.Min(zoneW, zoneH) * 0.5f;
		return shown.Stick ? inscribed * 0.35f : ((inscribed > 4.0f) ? inscribed - 3.0f : inscribed);
	}
}
