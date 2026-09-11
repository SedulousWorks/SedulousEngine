using Sedulous.Core;
using Sedulous.UI;
using Sedulous.VG;

namespace Sedulous.UI.Gamekit;

/// One toast: a severity accent down its left edge, the message, and whatever buttons the
/// request asked for.
class ToastCard : FlexLayout
{
	public Color Accent = .(0.35f, 0.55f, 0.95f, 1.0f);

	public this()
	{
		Direction = .Horizontal;
		Spacing = 8.0f;
		Padding = .(10.0f);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		let background = ResolveStyleColor(.Background, .(0.13f, 0.14f, 0.17f, 0.97f));
		let radius = ResolveStyleFloat(.CornerRadius, 0.0f);
		let bounds = Rectangle(0, 0, Width, Height);

		if (radius > 0.0f)
		{
			ctx.VG.FillRoundedRect(bounds, radius, background);
			// The accent trim's WIDTH is the corner radius, so its own rounded left corners sit
			// exactly on the card's and the two edges cannot show a seam between them.
			ctx.VG.FillRoundedRect(Rectangle(0, 0, radius, Height),
				CornerRadii(radius, 0.0f, 0.0f, radius), Accent);
		}
		else
		{
			ctx.VG.FillRect(bounds, background);
			ctx.VG.FillRect(Rectangle(0, 0, 3.0f, Height), Accent);
		}

		DrawChildren(ctx);
	}
}
