using Sedulous.Core;

namespace Sedulous.Render;

/// The size a view's scene draws at when it is not the viewport's own, and which part of that
/// image the viewport shows: all of it, or for a Crop fit the slice that fills the viewport.
/// Unset (nought) draws at the viewport's size.
struct SceneSize
{
	public uint32 Width = 0;
	public uint32 Height = 0;
	/// The shown part of the scene image, as fractions of it.
	public float SourceX = 0.0f;
	public float SourceY = 0.0f;
	public float SourceWidth = 1.0f;
	public float SourceHeight = 1.0f;

	public this() {}

	public this(uint32 width, uint32 height)
	{
		Width = width;
		Height = height;
	}

	public bool IsSet => (Width > 0) && (Height > 0);

	/// A fit of a `width` x `height` scene into a region: the scene size, and the slice of it
	/// the fit shows (the whole image, but for Crop).
	public static SceneSize FromFit(ContentFit fit)
	{
		var size = SceneSize((uint32)fit.ContentSize.X, (uint32)fit.ContentSize.Y);
		if ((fit.ContentSize.X > 0.0f) && (fit.ContentSize.Y > 0.0f))
		{
			let source = fit.SrcRect();
			size.SourceX = source.X / fit.ContentSize.X;
			size.SourceY = source.Y / fit.ContentSize.Y;
			size.SourceWidth = source.Width / fit.ContentSize.X;
			size.SourceHeight = source.Height / fit.ContentSize.Y;
		}
		return size;
	}
}
