using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.GUI;

// DragPreview: what follows the pointer while something is dragged and its source gave no preview
// of its own: the payload's label (`dragpreview`), with a badge (`dragpreview::effect`) saying what
// a drop would do now: a plus for a copy, an arrow for a link, a barred circle where nothing takes
// it, nothing for a move.

[GuiReflect]
class DragPreview : Label
{
	private DropEffect mEffect = .Move;

	public this()
	{
		Tag = "dragpreview";
		using (StyleWriteScope(this))
		{
			SetTextAlignment(.Start, .Middle);
			Padding = .(8.0f, 4.0f, 24.0f, 4.0f); // room for the badge at its right
		}
	}

	public DropEffect Effect => mEffect;

	public override void OnDragPreviewEffect(DropEffect effect)
	{
		if (effect == mEffect)
			return;
		mEffect = effect;
		Invalidate();
	}

	public override void CollectStyleParts(List<StringView> outParts)
	{
		outParts.Add("effect");
	}

	public override void OnDraw(DrawContext ctx, Rect localBounds)
	{
		base.OnDraw(ctx, localBounds);
		if (mEffect == .Move)
			return;
		let part = GetPartStyle("effect");
		var color = part.HasBackground ? part.Box.BackgroundColor : TextColor;
		color.A *= part.Opacity;
		let b = LocalBounds;
		let r = 6.0f;
		let cx = b.X + b.Width - 8.0f - r;
		let cy = b.Y + b.Height * 0.5f;
		let pb = scope PathBuilder();
		if (mEffect == .Copy)
		{
			pb.MoveTo(cx - r, cy);
			pb.LineTo(cx + r, cy);
			pb.MoveTo(cx, cy - r);
			pb.LineTo(cx, cy + r);
		}
		else if (mEffect == .Link)
		{
			pb.MoveTo(cx - r, cy + r);
			pb.LineTo(cx + r, cy - r);
			pb.MoveTo(cx + r - 5.0f, cy - r);
			pb.LineTo(cx + r, cy - r);
			pb.LineTo(cx + r, cy - r + 5.0f);
		}
		else // none takes it
		{
			pb.MoveTo(cx - r * 0.7f, cy - r * 0.7f);
			pb.LineTo(cx + r * 0.7f, cy + r * 0.7f);
			for (int32 i = 0; i <= 24; ++i)
			{
				let a = (float)i / 24.0f * 6.2831853f;
				let p = Float2(cx + r * Math.Cos(a), cy + r * Math.Sin(a));
				if (i == 0)
					pb.MoveTo(p.X, p.Y);
				else
					pb.LineTo(p.X, p.Y);
			}
		}
		let path = pb.ToPath();
		ctx.VG.StrokePath(path, color, StrokeStyle(1.8f, .Round, .Round));
		delete path;
	}
}
