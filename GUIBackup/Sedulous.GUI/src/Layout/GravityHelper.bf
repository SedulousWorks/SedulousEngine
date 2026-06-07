namespace Sedulous.GUI;

using System;
using Sedulous.Core.Mathematics;

/// Applies Gravity flags to position a child within a container.
public static class GravityHelper
{
	/// Apply gravity to position a child of (childW, childH) inside a
	/// container of (containerW, containerH) with the given margin.
	/// Returns the (x, y, w, h) of the child.
	public static RectangleF Apply(Gravity gravity, float containerW, float containerH,
		float childW, float childH, Thickness margin)
	{
		float x, y, w, h;

		let availW = containerW - margin.Left - margin.Right;
		let availH = containerH - margin.Top - margin.Bottom;

		// Horizontal
		if (gravity.HasFlag(.FillH))
		{
			x = margin.Left;
			w = availW;
		}
		else if (gravity.HasFlag(.Right))
		{
			x = containerW - margin.Right - childW;
			w = childW;
		}
		else if (gravity.HasFlag(.CenterH))
		{
			x = margin.Left + (availW - childW) * 0.5f;
			w = childW;
		}
		else // Left or None
		{
			x = margin.Left;
			w = childW;
		}

		// Vertical
		if (gravity.HasFlag(.FillV))
		{
			y = margin.Top;
			h = availH;
		}
		else if (gravity.HasFlag(.Bottom))
		{
			y = containerH - margin.Bottom - childH;
			h = childH;
		}
		else if (gravity.HasFlag(.CenterV))
		{
			y = margin.Top + (availH - childH) * 0.5f;
			h = childH;
		}
		else // Top or None
		{
			y = margin.Top;
			h = childH;
		}

		return .(x, y, Math.Max(0, w), Math.Max(0, h));
	}
}
