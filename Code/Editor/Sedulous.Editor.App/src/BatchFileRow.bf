using System;
using Sedulous.Core;
using Sedulous.UI;

namespace Sedulous.Editor.App;

/// A selectable source-file row in the batch list: selection is drawn as an accent fill,
/// since a Button per file could not show which file's detail was active. Hosts the enable
/// check box, name label and importer dropdown as children; clicks the children do not
/// consume select the row via the bubble phase.
class BatchFileRow : FlexLayout
{
	/// Owned.
	public delegate void() OnSelect ~ delete _;

	private bool mSelected = false;

	public this()
	{
		Direction = .Horizontal;
		Spacing = 4.0f;
	}

	public bool IsSelected => mSelected;

	public void SetSelected(bool selected)
	{
		if (mSelected != selected)
		{
			mSelected = selected;
			InvalidateVisual(); // the highlight only; geometry unchanged
		}
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		if (mSelected)
		{
			let accent = ResolveStyleColor(.AccentColor, Color(60.0f / 255.0f, 120.0f / 255.0f, 200.0f / 255.0f, 100.0f / 255.0f));
			ctx.VG.FillRoundedRect(.(0, 0, Width, Height), 3.0f, Color(accent.R, accent.G, accent.B, 0.35f));
		}
		base.OnDraw(ctx);
	}

	public override void OnMouseDown(MouseEventArgs e)
	{
		if (e.Button == .Left)
		{
			if (OnSelect != null)
				OnSelect();
			e.Handled = true;
		}
	}
}
