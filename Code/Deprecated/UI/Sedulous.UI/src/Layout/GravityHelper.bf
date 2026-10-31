using Sedulous.Core;

namespace Sedulous.UI;

/// Applies Gravity flags to place a child inside a container.
static class GravityHelper
{
	/// Places a child's MARGIN BOX of (boxWidth, boxHeight) inside a container of
	/// (containerWidth, containerHeight), answering that margin box.
	///
	/// View.Layout insets to the border box afterwards, so this needs no margin of its own: a
	/// margin aware form would land on the same border box anyway.
	public static Rectangle Apply(Gravity gravity, float containerWidth, float containerHeight,
		float boxWidth, float boxHeight)
	{
		float x = 0.0f, y = 0.0f, width = 0.0f, height = 0.0f;

		if (gravity.HasFlag(.FillH))
		{
			x = 0.0f;
			width = containerWidth;
		}
		else if (gravity.HasFlag(.Right))
		{
			x = containerWidth - boxWidth;
			width = boxWidth;
		}
		else if (gravity.HasFlag(.CenterH))
		{
			x = (containerWidth - boxWidth) * 0.5f;
			width = boxWidth;
		}
		else
		{
			// Left, or nothing said.
			x = 0.0f;
			width = boxWidth;
		}

		if (gravity.HasFlag(.FillV))
		{
			y = 0.0f;
			height = containerHeight;
		}
		else if (gravity.HasFlag(.Bottom))
		{
			y = containerHeight - boxHeight;
			height = boxHeight;
		}
		else if (gravity.HasFlag(.CenterV))
		{
			y = (containerHeight - boxHeight) * 0.5f;
			height = boxHeight;
		}
		else
		{
			// Top, or nothing said.
			y = 0.0f;
			height = boxHeight;
		}

		return .(x, y, Max(0.0f, width), Max(0.0f, height));
	}
}
