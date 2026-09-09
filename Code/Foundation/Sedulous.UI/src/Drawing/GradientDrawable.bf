using Sedulous.Core;
using Sedulous.VG;

namespace Sedulous.UI;

/// A linear gradient between two colours, along one of four directions.
class GradientDrawable : Drawable
{
	public Color StartColor = .();
	public Color EndColor = .();
	public GradientDirection Direction = .TopToBottom;

	public this() {}

	public this(Color start, Color end, GradientDirection direction = .TopToBottom)
	{
		StartColor = start;
		EndColor = end;
		Direction = direction;
	}

	public override void Draw(UIDrawContext ctx, Rectangle bounds)
	{
		let x = bounds.X;
		let y = bounds.Y;
		let width = bounds.Width;
		let height = bounds.Height;

		Float2 from = .Zero;
		Float2 to = .Zero;
		switch (Direction)
		{
		case .TopToBottom:
			from = .(x, y);
			to = .(x, y + height);
		case .LeftToRight:
			from = .(x, y);
			to = .(x + width, y);
		case .TopLeftToBottomRight:
			from = .(x, y);
			to = .(x + width, y + height);
		case .TopRightToBottomLeft:
			from = .(x + width, y);
			to = .(x, y + height);
		}

		let fill = scope VGLinearGradientFill(from, to);
		fill.AddStop(0.0f, StartColor);
		fill.AddStop(1.0f, EndColor);

		let builder = scope PathBuilder();
		builder.MoveTo(x, y);
		builder.LineTo(x + width, y);
		builder.LineTo(x + width, y + height);
		builder.LineTo(x, y + height);
		builder.Close();

		let path = builder.ToPath();
		defer delete path;
		ctx.VG.FillPath(path, fill);
	}
}
