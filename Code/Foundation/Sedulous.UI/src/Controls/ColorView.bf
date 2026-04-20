namespace Sedulous.UI;

using Sedulous.Core.Mathematics;

/// Simplest concrete view - fills its bounds with a solid color.
/// Phase 1 "Hello World" widget. Drawable system replaces this in Phase 2.
public class ColorView : View
{
	public Color Color = .White;

	/// Optional fixed size. If > 0, measure returns this instead of
	/// filling parent.
	public float PreferredWidth;
	public float PreferredHeight;

	protected override void OnMeasure(MeasureSpec wSpec, MeasureSpec hSpec)
	{
		let w = (PreferredWidth > 0) ? PreferredWidth : 0;
		let h = (PreferredHeight > 0) ? PreferredHeight : 0;
		MeasuredSize = .(wSpec.Resolve(w), hSpec.Resolve(h));
	}

	public override void OnDraw(UIDrawContext ctx)
	{
		ctx.VG.FillRect(.(0, 0, Width, Height), Color);
	}
}
