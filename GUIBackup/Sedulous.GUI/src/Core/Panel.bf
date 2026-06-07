namespace Sedulous.GUI;

using Sedulous.Core.Mathematics;

/// ViewGroup with an optional background drawable.
/// The simplest container — useful for panels, cards, and sections.
public class Panel : ViewGroup
{
	/// Per-instance background override. If null, falls back to theme.
	public Property<Drawable> Background = new .(null, .Visual) ~ delete _;

	protected override void InitializePropertyOwners()
	{
		base.InitializePropertyOwners();
		Background.SetOwner(this, .Visual);
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		// Per-instance override
		let bg = Background.Value;
		if (bg != null)
		{
			bg.Draw(ctx, .(0, 0, Width, Height), GetControlState());
		}
		else
		{
			// Theme drawable
			let themeBg = ResolveStyleDrawable(.Background);
			if (themeBg != null)
				themeBg.Draw(ctx, .(0, 0, Width, Height), GetControlState());
		}

		DrawChildren(ctx);
	}
}
