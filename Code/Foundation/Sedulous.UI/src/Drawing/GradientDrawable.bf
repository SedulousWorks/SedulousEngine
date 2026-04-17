namespace Sedulous.UI;

using Sedulous.Core.Mathematics;
using Sedulous.VG;

public enum GradientDirection { TopToBottom, LeftToRight, TopLeftToBottomRight, TopRightToBottomLeft }

/// Linear gradient fill with two colors and a direction.
public class GradientDrawable : Drawable
{
	public Color StartColor;
	public Color EndColor;
	public GradientDirection Direction;

	public this(Color start, Color end, GradientDirection dir = .TopToBottom)
	{
		StartColor = start;
		EndColor = end;
		Direction = dir;
	}

	public override void Draw(UIDrawContext ctx, RectangleF bounds)
	{
		Vector2 from, to;
		switch (Direction)
		{
		case .TopToBottom:          from = .(bounds.X, bounds.Y); to = .(bounds.X, bounds.Y + bounds.Height);
		case .LeftToRight:          from = .(bounds.X, bounds.Y); to = .(bounds.X + bounds.Width, bounds.Y);
		case .TopLeftToBottomRight: from = .(bounds.X, bounds.Y); to = .(bounds.X + bounds.Width, bounds.Y + bounds.Height);
		case .TopRightToBottomLeft: from = .(bounds.X + bounds.Width, bounds.Y); to = .(bounds.X, bounds.Y + bounds.Height);
		}

		let fill = scope VGLinearGradientFill(from, to);
		fill.AddStop(0, StartColor);
		fill.AddStop(1, EndColor);

		// Build a rect path and fill with the gradient.
		let pb = scope PathBuilder();
		pb.MoveTo(bounds.X, bounds.Y);
		pb.LineTo(bounds.X + bounds.Width, bounds.Y);
		pb.LineTo(bounds.X + bounds.Width, bounds.Y + bounds.Height);
		pb.LineTo(bounds.X, bounds.Y + bounds.Height);
		pb.Close();

		let path = pb.ToPath();
		defer delete path;
		ctx.VG.FillPath(path, fill);
	}
}
