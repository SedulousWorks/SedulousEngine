using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Fonts;
using Sedulous.VG;
using internal Sedulous.GUI;

namespace Sedulous.GUI;

// The debug overlay's input half, drawn by a root over its tree in its own space: the focus path,
// the tab order, the last directional move, the node under the pointer. Hairlines are a device
// pixel; text is in the host's debug font, and left out without one.

extension SceneRoot
{
	// This frame's redraws join the flashes, which fade over half a second.
	private void DrawRedrawFlashes(DrawContext ctx)
	{
		const double cFade = 0.5; // seconds
		let toRoot = Transform.GetInverse();
		for (let world in mFrameRedraws)
		{
			let flash = new RedrawFlash();
			flash.Box = toRoot.TransformRect(world);
			mFlashes.Add(flash);
		}
		mFrameRedraws.Clear();
		let g = ctx.VG;
		for (int i = 0; i < mFlashes.Count;)
		{
			let age = mFlashes[i].Age.Elapsed.TotalSeconds;
			if (age >= cFade)
			{
				delete mFlashes[i];
				mFlashes.RemoveAt(i);
				continue;
			}
			let strength = (float)(1.0 - age / cFade);
			g.FillRect(mFlashes[i].Box.ToRectangle(), .(1.0f, 0.2f, 0.2f, 0.35f * strength));
			i++;
		}
	}

	// The debug overlay's input half, in this root's space.
	private void DrawInputOverlay(DrawContext ctx)
	{
		let g = ctx.VG;
		let hair = 1.0f / Math.Max(ctx.DeviceScale, 0.01f);
		let tab = DebugOverlayImplDetail.cTab;
		let focusColor = DebugOverlayImplDetail.cFocus;

		if (mDebugOverlay.TabOrder)
		{
			// Each stop numbered at its top-left, joined centre to centre in the order Tab takes.
			let stops = scope List<Node>();
			mEventDispatcher.TabStops(stops);
			Float2 previous = .(0.0f, 0.0f);
			for (int i = 0; i < stops.Count; i++)
			{
				let frame = InRootSpace(stops[i]);
				let centre = Float2(frame.X + frame.Width * 0.5f, frame.Y + frame.Height * 0.5f);
				if (i > 0)
					g.DrawLine(previous, centre, .(tab.R, tab.G, tab.B, 0.6f), 1.5f * hair);
				previous = centre;
				g.StrokeRect(frame.ToRectangle(), .(tab.R, tab.G, tab.B, 0.5f), hair);
				g.FillCircle(.(frame.X, frame.Y), 9.0f, tab);
				if (mDebugFont != null)
				{
					let number = scope String();
					number.AppendF("{}", i + 1);
					g.DrawText(number, mDebugFont, .(frame.X - 9.0f, frame.Y - 9.0f, 18.0f, 18.0f), .Center, .Middle, .(0.0f, 0.0f, 0.0f, 1.0f));
				}
			}
		}

		if (mDebugOverlay.Navigation)
		{
			let trace = mEventDispatcher.LastNavigation;
			if (trace.Any)
			{
				// Where it moved from, every candidate it weighed (scored; "~" for one not
				// overlapping across the move), and an arrow to the one chosen.
				let toRoot = Transform.GetInverse();
				let from = toRoot.TransformRect(trace.From);
				let fromCentre = Float2(from.X + from.Width * 0.5f, from.Y + from.Height * 0.5f);
				g.StrokeRect(from.ToRectangle(), .(1.0f, 1.0f, 1.0f, 0.9f), 2.0f * hair);
				for (let c in trace.Candidates)
				{
					let frame = toRoot.TransformRect(c.Bounds);
					let color = (c.Verdict == .Chosen) ? DebugOverlayImplDetail.cChosen
						: (c.Verdict == .Beaten) ? DebugOverlayImplDetail.cBeaten
						: (c.Verdict == .Clipped) ? DebugOverlayImplDetail.cClipped
						: DebugOverlayImplDetail.cBehind;
					g.StrokeRect(frame.ToRectangle(), color, ((c.Verdict == .Chosen) ? 2.0f : 1.0f) * hair);
					if (c.Verdict == .Chosen)
						g.DrawLine(fromCentre, .(frame.X + frame.Width * 0.5f, frame.Y + frame.Height * 0.5f), DebugOverlayImplDetail.cChosen, 2.0f * hair);
					if ((mDebugFont != null) && ((c.Verdict == .Chosen) || (c.Verdict == .Beaten)))
					{
						let far = c.Score >= NavTrace.cNoOverlapTier;
						let score = (int32)(far ? c.Score - NavTrace.cNoOverlapTier : c.Score);
						let text = scope String();
						if (far)
							text.AppendF("~{}", score);
						else
							text.AppendF("{}", score);
						g.DrawText(text, mDebugFont, .(frame.Right - 48.0f, frame.Bottom - 16.0f, 46.0f, 16.0f), .Right, .Middle, color);
					}
				}
				if (trace.Overridden || trace.Wrapped)
					DebugOverlayImplDetail.Tag(g, mDebugFont, from, trace.Overridden ? "nav override" : "wrapped", DebugOverlayImplDetail.cChosen);
			}
		}

		if (mDebugOverlay.FocusPath)
		{
			let focused = mEventDispatcher.FocusNode;
			if (focused != null)
			{
				// The focused node strong, each node holding it fainter the further out, and the
				// path named from the focused node outward.
				let path = scope String();
				float alpha = 0.7f;
				int depth = 0;
				for (var n = focused.Parent; (n != null) && (n != this); n = n.Parent)
				{
					g.StrokeRect(InRootSpace(n).ToRectangle(), .(focusColor.R, focusColor.G, focusColor.B, alpha), hair);
					alpha = Math.Max(0.15f, alpha * 0.75f);
					if (depth++ < 4)
					{
						path.Append(" < ");
						n.DebugName(path);
					}
				}
				let frame = InRootSpace(focused);
				g.StrokeRect(frame.ToRectangle(), focusColor, 2.0f * hair);
				let name = scope String();
				focused.DebugName(name);
				name.Append(path);
				DebugOverlayImplDetail.Tag(g, mDebugFont, frame, name, focusColor);
			}
		}

		if (mDebugOverlay.Pointer)
		{
			let over = mEventDispatcher.OverNode;
			if ((over != null) && (over != this))
			{
				let frame = InRootSpace(over);
				g.StrokeRect(frame.ToRectangle(), DebugOverlayImplDetail.cPointer, 2.0f * hair);
				let name = scope String();
				over.DebugName(name);
				name.AppendF(" {}x{}", (int32)over.Size.X, (int32)over.Size.Y);
				DebugOverlayImplDetail.Tag(g, mDebugFont, .(frame.X, frame.Bottom + 16.0f, frame.Width, frame.Height), name, DebugOverlayImplDetail.cPointer);
			}
		}
	}
}

/// What DebugOverlayImpl.bf keeps out of the public surface: the overlay's colours and its tags.
internal static class DebugOverlayImplDetail
{
	public static readonly Color cFocus = .(0.2f, 0.85f, 1.0f, 1.0f);
	public static readonly Color cTab = .(1.0f, 0.85f, 0.2f, 1.0f);
	public static readonly Color cPointer = .(1.0f, 0.3f, 0.85f, 1.0f);
	public static readonly Color cLabelBack = .(0.0f, 0.0f, 0.0f, 0.75f);
	public static readonly Color cChosen = .(0.3f, 1.0f, 0.4f, 1.0f);
	public static readonly Color cBeaten = .(0.45f, 0.65f, 1.0f, 0.9f);
	public static readonly Color cBehind = .(0.6f, 0.6f, 0.6f, 0.35f);
	public static readonly Color cClipped = .(1.0f, 0.35f, 0.3f, 0.6f);

	/// A name tag over the top-left of `frame` (inside it when the frame is at the top).
	public static void Tag(VGContext g, CachedFont font, Rect frame, StringView text, Color color)
	{
		if ((font == null) || (text.Length == 0))
			return;
		let height = 16.0f;
		let width = 7.0f * (float)text.Length + 8.0f; // a debug font's rough advance
		let y = (frame.Y >= height) ? frame.Y - height : frame.Y;
		g.FillRect(.(frame.X, y, width, height), cLabelBack);
		g.DrawText(text, font, .(frame.X + 4.0f, y, width - 4.0f, height), .Left, .Middle, color);
	}
}
