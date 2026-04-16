using System;
using Sedulous.Core.Mathematics;
using Sedulous.Drawing;
using Sedulous.ImageData;

namespace Sedulous.GUI;

/// How an image is scaled to fit its container.
public enum Stretch
{
	/// No scaling, original size.
	None,
	/// Scale to fill, may distort aspect ratio.
	Fill,
	/// Scale to fit while preserving aspect ratio (letterbox).
	Uniform,
	/// Scale to fill while preserving aspect ratio, may crop.
	UniformToFill
}

/// Controls which directions an image can be scaled.
public enum StretchDirection
{
	/// Scale up and down.
	Both,
	/// Only scale up (never smaller than source).
	UpOnly,
	/// Only scale down (never larger than source).
	DownOnly
}

/// Displays an image with stretch and alignment options.
public class Image : UIElement
{
	private IImageData mSource;
	private Stretch mStretch = .Uniform;
	private StretchDirection mStretchDirection = .Both;
	private Color mTint = .White;

	/// Creates a new Image.
	public this()
	{
	}

	/// Creates a new Image with the specified source.
	public this(IImageData source) : this()
	{
		mSource = source;
	}

	/// The image source to display.
	public IImageData Source
	{
		get => mSource;
		set
		{
			if (mSource != value)
			{
				mSource = value;
				InvalidateLayout();
			}
		}
	}

	/// How the image is stretched to fill the available space.
	public Stretch Stretch
	{
		get => mStretch;
		set
		{
			if (mStretch != value)
			{
				mStretch = value;
				InvalidateLayout();
			}
		}
	}

	/// Controls which directions the image can be scaled.
	public StretchDirection StretchDirection
	{
		get => mStretchDirection;
		set
		{
			if (mStretchDirection != value)
			{
				mStretchDirection = value;
				InvalidateLayout();
			}
		}
	}

	/// Tint color applied to the image.
	public Color Tint
	{
		get => mTint;
		set => mTint = value;
	}

	/// Measures the image based on source size and stretch mode.
	protected override DesiredSize MeasureOverride(SizeConstraints constraints)
	{
		if (mSource == null)
			return .Zero;

		let sourceWidth = (float)mSource.Width;
		let sourceHeight = (float)mSource.Height;

		if (sourceWidth <= 0 || sourceHeight <= 0)
			return .Zero;

		// For None stretch, just return source size
		if (mStretch == .None)
		{
			return .(sourceWidth, sourceHeight);
		}

		// For other stretch modes, calculate desired size based on constraints
		let maxWidth = constraints.MaxWidth;
		let maxHeight = constraints.MaxHeight;

		// If no constraints, return source size
		if (maxWidth == SizeConstraints.Infinity && maxHeight == SizeConstraints.Infinity)
		{
			return .(sourceWidth, sourceHeight);
		}

		switch (mStretch)
		{
		case .Fill:
			// Fill available space
			var width = maxWidth != SizeConstraints.Infinity ? maxWidth : sourceWidth;
			var height = maxHeight != SizeConstraints.Infinity ? maxHeight : sourceHeight;
			return .(width, height);

		case .Uniform:
			// Fit within bounds while preserving aspect ratio
			return CalculateUniformSize(sourceWidth, sourceHeight, maxWidth, maxHeight);

		case .UniformToFill:
			// Fill bounds while preserving aspect ratio (may exceed bounds)
			return CalculateUniformToFillSize(sourceWidth, sourceHeight, maxWidth, maxHeight);

		default:
			return .(sourceWidth, sourceHeight);
		}
	}

	/// Calculates Uniform stretch size (fit within bounds).
	private DesiredSize CalculateUniformSize(float sourceWidth, float sourceHeight, float maxWidth, float maxHeight)
	{
		if (maxWidth == SizeConstraints.Infinity && maxHeight == SizeConstraints.Infinity)
			return .(sourceWidth, sourceHeight);

		let sourceAspect = sourceWidth / sourceHeight;

		float width, height;
		if (maxWidth == SizeConstraints.Infinity)
		{
			// Only height constrained
			height = maxHeight;
			width = height * sourceAspect;
		}
		else if (maxHeight == SizeConstraints.Infinity)
		{
			// Only width constrained
			width = maxWidth;
			height = width / sourceAspect;
		}
		else
		{
			// Both constrained - fit within bounds
			let targetAspect = maxWidth / maxHeight;
			if (sourceAspect > targetAspect)
			{
				// Source is wider - width constrained
				width = maxWidth;
				height = width / sourceAspect;
			}
			else
			{
				// Source is taller - height constrained
				height = maxHeight;
				width = height * sourceAspect;
			}
		}

		// Apply stretch direction
		return ApplyStretchDirection(width, height, sourceWidth, sourceHeight);
	}

	/// Calculates UniformToFill stretch size (fill bounds, may crop).
	private DesiredSize CalculateUniformToFillSize(float sourceWidth, float sourceHeight, float maxWidth, float maxHeight)
	{
		if (maxWidth == SizeConstraints.Infinity && maxHeight == SizeConstraints.Infinity)
			return .(sourceWidth, sourceHeight);

		let sourceAspect = sourceWidth / sourceHeight;

		float width, height;
		if (maxWidth == SizeConstraints.Infinity)
		{
			height = maxHeight;
			width = height * sourceAspect;
		}
		else if (maxHeight == SizeConstraints.Infinity)
		{
			width = maxWidth;
			height = width / sourceAspect;
		}
		else
		{
			// Both constrained - fill bounds (may exceed one dimension)
			let targetAspect = maxWidth / maxHeight;
			if (sourceAspect > targetAspect)
			{
				// Source is wider - height fills
				height = maxHeight;
				width = height * sourceAspect;
			}
			else
			{
				// Source is taller - width fills
				width = maxWidth;
				height = width / sourceAspect;
			}
		}

		// Apply stretch direction
		return ApplyStretchDirection(width, height, sourceWidth, sourceHeight);
	}

	/// Applies stretch direction constraints.
	private DesiredSize ApplyStretchDirection(float width, float height, float sourceWidth, float sourceHeight)
	{
		switch (mStretchDirection)
		{
		case .UpOnly:
			// Never smaller than source
			return .(Math.Max(width, sourceWidth), Math.Max(height, sourceHeight));
		case .DownOnly:
			// Never larger than source
			return .(Math.Min(width, sourceWidth), Math.Min(height, sourceHeight));
		default:
			return .(width, height);
		}
	}

	/// Renders the image.
	protected override void RenderOverride(DrawContext ctx)
	{
		if (mSource == null)
			return;

		let sourceWidth = (float)mSource.Width;
		let sourceHeight = (float)mSource.Height;

		if (sourceWidth <= 0 || sourceHeight <= 0)
			return;

		let bounds = ArrangedBounds;
		RectangleF destRect;

		switch (mStretch)
		{
		case .None:
			// Center at original size
			let x = bounds.X + (bounds.Width - sourceWidth) / 2;
			let y = bounds.Y + (bounds.Height - sourceHeight) / 2;
			destRect = .(x, y, sourceWidth, sourceHeight);

		case .Fill:
			// Fill the entire bounds
			destRect = bounds;

		case .Uniform:
			// Fit within bounds, centered
			destRect = CalculateUniformDestRect(sourceWidth, sourceHeight, bounds);

		case .UniformToFill:
			// Fill bounds while preserving aspect (some content may be clipped)
			destRect = CalculateUniformToFillDestRect(sourceWidth, sourceHeight, bounds);
		}

		// Apply stretch direction
		destRect = ApplyStretchDirectionToDestRect(destRect, sourceWidth, sourceHeight, bounds);

		// UniformToFill can overflow bounds - clip to container
		let needsClip = mStretch == .UniformToFill &&
			(destRect.Width > bounds.Width || destRect.Height > bounds.Height);

		if (needsClip)
			ctx.PushClipRect(bounds);

		ctx.DrawImage(mSource, destRect, .(0, 0, sourceWidth, sourceHeight), mTint);

		if (needsClip)
			ctx.PopClip();
	}

	/// Calculates destination rect for Uniform stretch.
	private RectangleF CalculateUniformDestRect(float sourceWidth, float sourceHeight, RectangleF bounds)
	{
		let sourceAspect = sourceWidth / sourceHeight;
		let targetAspect = bounds.Width / bounds.Height;

		float width, height;
		if (sourceAspect > targetAspect)
		{
			// Source is wider
			width = bounds.Width;
			height = width / sourceAspect;
		}
		else
		{
			// Source is taller
			height = bounds.Height;
			width = height * sourceAspect;
		}

		let x = bounds.X + (bounds.Width - width) / 2;
		let y = bounds.Y + (bounds.Height - height) / 2;
		return .(x, y, width, height);
	}

	/// Calculates destination rect for UniformToFill stretch.
	private RectangleF CalculateUniformToFillDestRect(float sourceWidth, float sourceHeight, RectangleF bounds)
	{
		let sourceAspect = sourceWidth / sourceHeight;
		let targetAspect = bounds.Width / bounds.Height;

		float width, height;
		if (sourceAspect > targetAspect)
		{
			// Source is wider - height fills
			height = bounds.Height;
			width = height * sourceAspect;
		}
		else
		{
			// Source is taller - width fills
			width = bounds.Width;
			height = width / sourceAspect;
		}

		let x = bounds.X + (bounds.Width - width) / 2;
		let y = bounds.Y + (bounds.Height - height) / 2;
		return .(x, y, width, height);
	}

	/// Applies stretch direction to destination rect.
	private RectangleF ApplyStretchDirectionToDestRect(RectangleF destRect, float sourceWidth, float sourceHeight, RectangleF bounds)
	{
		switch (mStretchDirection)
		{
		case .UpOnly:
			// Don't shrink below source size
			if (destRect.Width < sourceWidth || destRect.Height < sourceHeight)
			{
				let x = bounds.X + (bounds.Width - sourceWidth) / 2;
				let y = bounds.Y + (bounds.Height - sourceHeight) / 2;
				return .(x, y, sourceWidth, sourceHeight);
			}
			return destRect;

		case .DownOnly:
			// Don't grow above source size
			if (destRect.Width > sourceWidth || destRect.Height > sourceHeight)
			{
				let x = bounds.X + (bounds.Width - sourceWidth) / 2;
				let y = bounds.Y + (bounds.Height - sourceHeight) / 2;
				return .(x, y, sourceWidth, sourceHeight);
			}
			return destRect;

		default:
			return destRect;
		}
	}
}
