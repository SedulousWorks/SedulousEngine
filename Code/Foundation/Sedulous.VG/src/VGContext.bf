using System;
using System.Collections;
using Sedulous.Core.Mathematics;
using Sedulous.ImageData;

namespace Sedulous.VG;

/// Main user-facing API for vector graphics drawing.
/// Produces batched geometry for rendering via VGBatch.
public class VGContext
{
	private VGBatch mBatch = new .() ~ delete _;

	// 1x1 white texture used for solid-color draws (shape/path/stroke).
	// Sits at Textures[0] so all shape vertices sample white → color passthrough.
	private OwnedImageData mWhiteTexture ~ delete _;

	// State stack
	private List<VGState> mStateStack = new .() ~ delete _;
	private VGState mCurrentState;

	// Independent stacks
	private List<RectangleF> mClipStack = new .() ~ delete _;
	private List<float> mOpacityStack = new .() ~ delete _;

	// Command tracking
	private VGBlendMode mCurrentBlendMode = .Normal;
	private int32 mCurrentTextureIndex = 0;  // 0 = white texture (solid draws)
	private int32 mCommandStartIndex = 0;

	// Default tessellation tolerance
	private float mTolerance = 0.05f;

	public this()
	{
		mCurrentState = .();
		mStateStack.Reserve(16);

		// Create 1x1 white texture for solid color drawing.
		uint8[4] whitePixel = .(255, 255, 255, 255);
		mWhiteTexture = new OwnedImageData(1, 1, .RGBA8, Span<uint8>(&whitePixel, 4));

		// Register as texture 0 in the batch.
		mBatch.Textures.Add(mWhiteTexture);
	}

	// === Output ===

	/// Get the current batch for rendering
	public VGBatch GetBatch()
	{
		FlushCurrentCommand();
		return mBatch;
	}

	/// Clear all content and reset state
	public void Clear()
	{
		mBatch.Clear();
		mStateStack.Clear();
		mClipStack.Clear();
		mOpacityStack.Clear();
		mCurrentState = .();
		mCurrentBlendMode = .Normal;
		mCurrentTextureIndex = 0;
		mCommandStartIndex = 0;

		// Re-add the white texture at index 0 for solid color drawing.
		mBatch.Textures.Add(mWhiteTexture);
	}

	/// Set the tessellation tolerance (lower = smoother curves, more vertices)
	public float Tolerance { get => mTolerance; set => mTolerance = value; }

	// === State Management ===

	/// Push current state onto the stack
	public void PushState()
	{
		mStateStack.Add(mCurrentState);
	}

	/// Pop state from the stack
	public void PopState()
	{
		if (mStateStack.Count > 0)
			mCurrentState = mStateStack.PopBack();
	}

	// === Transform ===

	/// Set the current transform matrix
	public void SetTransform(Matrix transform)
	{
		mCurrentState.Transform = transform;
	}

	/// Get the current transform matrix
	public Matrix GetTransform()
	{
		return mCurrentState.Transform;
	}

	/// Apply translation to current transform
	public void Translate(float x, float y)
	{
		mCurrentState.Transform = Matrix.CreateTranslation(x, y, 0) * mCurrentState.Transform;
	}

	/// Apply rotation to current transform (in radians)
	public void Rotate(float radians)
	{
		mCurrentState.Transform = Matrix.CreateRotationZ(radians) * mCurrentState.Transform;
	}

	/// Apply scale to current transform
	public void Scale(float sx, float sy)
	{
		mCurrentState.Transform = Matrix.CreateScale(sx, sy, 1) * mCurrentState.Transform;
	}

	/// Reset transform to identity
	public void ResetTransform()
	{
		mCurrentState.Transform = Matrix.Identity;
	}

	// === Clipping ===

	/// Push a scissor clip rectangle
	public void PushClipRect(RectangleF rect)
	{
		FlushCurrentCommand();
		mClipStack.Add(mCurrentState.ClipRect);

		let transformedRect = TransformRect(rect);
		if (mCurrentState.ClipRect.Width > 0 && mCurrentState.ClipRect.Height > 0)
			mCurrentState.ClipRect = RectangleF.Intersect(mCurrentState.ClipRect, transformedRect);
		else
			mCurrentState.ClipRect = transformedRect;
		mCurrentState.ClipMode = .Scissor;
	}

	/// Pop the current clip
	public void PopClip()
	{
		FlushCurrentCommand();
		if (mClipStack.Count > 0)
		{
			mCurrentState.ClipRect = mClipStack.PopBack();
			mCurrentState.ClipMode = (mCurrentState.ClipRect.Width > 0 && mCurrentState.ClipRect.Height > 0) ? .Scissor : .None;
		}
		else
		{
			mCurrentState.ClipRect = default;
			mCurrentState.ClipMode = .None;
		}
	}

	// === Opacity ===

	/// Push an opacity value (multiplies with current)
	public void PushOpacity(float opacity)
	{
		mOpacityStack.Add(mCurrentState.Opacity);
		mCurrentState.Opacity *= Math.Clamp(opacity, 0, 1);
	}

	/// Pop the current opacity
	public void PopOpacity()
	{
		if (mOpacityStack.Count > 0)
			mCurrentState.Opacity = mOpacityStack.PopBack();
		else
			mCurrentState.Opacity = 1.0f;
	}

	/// Get the current opacity
	public float Opacity => mCurrentState.Opacity;

	// === Blend Mode ===

	/// Set the blend mode for subsequent draws
	public void SetBlendMode(VGBlendMode mode)
	{
		if (mode != mCurrentBlendMode)
		{
			FlushCurrentCommand();
			mCurrentBlendMode = mode;
		}
	}

	// === Path Drawing ===

	/// Fill a path with a solid color
	public void FillPath(Path path, Color color, FillRule fillRule = .EvenOdd, bool antiAlias = true)
	{
		SetupForSolidDraw();
		let startVertex = mBatch.Vertices.Count;
		let scaledTolerance = GetScaledTolerance();
		FillTessellator.Tessellate(path, fillRule, ApplyOpacity(color), antiAlias, mBatch.Vertices, mBatch.Indices, scaledTolerance);
		TransformVertices(startVertex);
	}

	/// Fill a path with a fill style
	public void FillPath(Path path, IVGFill fill, FillRule fillRule = .EvenOdd, bool antiAlias = true)
	{
		SetupForSolidDraw();
		let startVertex = mBatch.Vertices.Count;
		let scaledTolerance = GetScaledTolerance();
		FillTessellator.TessellateWithFill(path, fillRule, fill, antiAlias, mBatch.Vertices, mBatch.Indices, scaledTolerance);
		ApplyOpacityToVertices(startVertex);
		TransformVertices(startVertex);
	}

	/// Stroke a path with a solid color
	public void StrokePath(Path path, Color color, StrokeStyle style, Span<float> dashPattern = default, bool antiAlias = true)
	{
		SetupForSolidDraw();
		// Flatten path to polylines
		let scaledTolerance = GetScaledTolerance();
		let subPaths = scope List<FlattenedSubPath>();
		PathFlattener.Flatten(path, scaledTolerance, subPaths);
		defer { for (let sp in subPaths) delete sp; }

		let startVertex = mBatch.Vertices.Count;
		let opColor = ApplyOpacity(color);

		for (let subPath in subPaths)
		{
			if (subPath.Points.Count < 2)
				continue;
			StrokeTessellator.Tessellate(subPath.Points, subPath.IsClosed, style, dashPattern, antiAlias, opColor, mBatch.Vertices, mBatch.Indices);
		}

		TransformVertices(startVertex);
	}

	// === Convenience: Filled Shapes ===

	/// Fill a rectangle
	public void FillRect(RectangleF rect, Color color)
	{
		let pb = scope PathBuilder();
		pb.MoveTo(rect.X, rect.Y);
		pb.LineTo(rect.X + rect.Width, rect.Y);
		pb.LineTo(rect.X + rect.Width, rect.Y + rect.Height);
		pb.LineTo(rect.X, rect.Y + rect.Height);
		pb.Close();

		let path = pb.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// Fill a rounded rectangle with uniform radius
	public void FillRoundedRect(RectangleF rect, float radius, Color color)
	{
		FillRoundedRect(rect, CornerRadii(radius), color);
	}

	/// Fill a rounded rectangle with per-corner radii
	public void FillRoundedRect(RectangleF rect, CornerRadii radii, Color color)
	{
		if (radii.IsZero)
		{
			FillRect(rect, color);
			return;
		}

		let pb = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, pb);
		let path = pb.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// Fill a circle
	public void FillCircle(Vector2 center, float radius, Color color)
	{
		let pb = scope PathBuilder();
		ShapeBuilder.BuildCircle(center, radius, pb);
		let path = pb.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// Fill an ellipse
	public void FillEllipse(Vector2 center, float rx, float ry, Color color)
	{
		let pb = scope PathBuilder();
		ShapeBuilder.BuildEllipse(center, rx, ry, pb);
		let path = pb.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// Fill a regular polygon
	public void FillRegularPolygon(Vector2 center, float radius, int sides, Color color)
	{
		let pb = scope PathBuilder();
		ShapeBuilder.BuildRegularPolygon(center, radius, sides, pb);
		let path = pb.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	/// Fill a star shape
	public void FillStar(Vector2 center, float outerRadius, float innerRadius, int points, Color color)
	{
		let pb = scope PathBuilder();
		ShapeBuilder.BuildStar(center, outerRadius, innerRadius, points, pb);
		let path = pb.ToPath();
		defer delete path;
		FillPath(path, color);
	}

	// === Convenience: Stroked Shapes ===

	/// Stroke a rectangle
	public void StrokeRect(RectangleF rect, Color color, float width = 1.0f)
	{
		let pb = scope PathBuilder();
		pb.MoveTo(rect.X, rect.Y);
		pb.LineTo(rect.X + rect.Width, rect.Y);
		pb.LineTo(rect.X + rect.Width, rect.Y + rect.Height);
		pb.LineTo(rect.X, rect.Y + rect.Height);
		pb.Close();

		let path = pb.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	/// Stroke a rounded rectangle with uniform radius
	public void StrokeRoundedRect(RectangleF rect, float radius, Color color, float width = 1.0f)
	{
		StrokeRoundedRect(rect, CornerRadii(radius), color, width);
	}

	/// Stroke a rounded rectangle with per-corner radii
	public void StrokeRoundedRect(RectangleF rect, CornerRadii radii, Color color, float width = 1.0f)
	{
		let pb = scope PathBuilder();
		ShapeBuilder.BuildRoundedRect(rect, radii, pb);
		let path = pb.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	/// Stroke a circle
	public void StrokeCircle(Vector2 center, float radius, Color color, float width = 1.0f)
	{
		let pb = scope PathBuilder();
		ShapeBuilder.BuildCircle(center, radius, pb);
		let path = pb.ToPath();
		defer delete path;
		StrokePath(path, color, .(width));
	}

	// === Texture state (used by text/image paths — currently only solid) ===

	/// Look up a texture in the batch or append it. Returns the index.
	/// Index 0 is reserved for the 1x1 white texture used by solid draws.
	private int32 GetOrAddTexture(IImageData tex)
	{
		if (tex == null) return 0;
		for (int i = 0; i < mBatch.Textures.Count; i++)
		{
			if (mBatch.Textures[i] === tex)
				return (int32)i;
		}
		mBatch.Textures.Add(tex);
		return (int32)(mBatch.Textures.Count - 1);
	}

	/// Ensure the current command state uses the solid (white) texture.
	/// Flushes the current command if a texture switch is needed.
	private void SetupForSolidDraw()
	{
		if (mCurrentTextureIndex != 0)
		{
			FlushCurrentCommand();
			mCurrentTextureIndex = 0;
		}
	}

	/// Ensure the current command state uses the given texture index.
	/// Flushes the current command if a texture switch is needed.
	private void SetupForTextureDraw(int32 textureIndex)
	{
		if (mCurrentTextureIndex != textureIndex)
		{
			FlushCurrentCommand();
			mCurrentTextureIndex = textureIndex;
		}
	}

	// === Internal Helpers ===

	private void FlushCurrentCommand()
	{
		let indexCount = (int32)mBatch.Indices.Count - mCommandStartIndex;
		if (indexCount > 0)
		{
			var cmd = VGCommand();
			cmd.StartIndex = mCommandStartIndex;
			cmd.IndexCount = indexCount;
			cmd.TextureIndex = mCurrentTextureIndex;
			cmd.ClipRect = mCurrentState.ClipRect;
			cmd.BlendMode = mCurrentBlendMode;
			cmd.ClipMode = mCurrentState.ClipMode;
			cmd.StencilRef = mCurrentState.StencilRef;

			mBatch.Commands.Add(cmd);
			mCommandStartIndex = (int32)mBatch.Indices.Count;
		}
	}

	/// Compute tolerance adjusted for current transform scale.
	/// When a path is scaled up, we need a tighter tolerance to maintain smoothness.
	private float GetScaledTolerance()
	{
		if (mCurrentState.Transform == Matrix.Identity)
			return mTolerance;

		// Extract approximate uniform scale from the transform matrix
		let sx = Vector2(mCurrentState.Transform.M11, mCurrentState.Transform.M12).Length();
		let sy = Vector2(mCurrentState.Transform.M21, mCurrentState.Transform.M22).Length();
		let scale = Math.Max(sx, sy);

		if (scale > 0.0001f)
			return mTolerance / scale;
		return mTolerance;
	}

	private Vector2 TransformPoint(Vector2 point)
	{
		if (mCurrentState.Transform == Matrix.Identity)
			return point;
		return Vector2.Transform(point, mCurrentState.Transform);
	}

	private void TransformVertices(int startVertex)
	{
		if (mCurrentState.Transform == Matrix.Identity)
			return;

		for (int i = startVertex; i < mBatch.Vertices.Count; i++)
		{
			var vertex = ref mBatch.Vertices[i];
			vertex.Position = Vector2.Transform(vertex.Position, mCurrentState.Transform);
		}
	}

	private Color ApplyOpacity(Color color)
	{
		if (mCurrentState.Opacity >= 1.0f)
			return color;
		return Color(color.R, color.G, color.B, (uint8)(color.A * mCurrentState.Opacity));
	}

	private void ApplyOpacityToVertices(int startVertex)
	{
		if (mCurrentState.Opacity >= 1.0f)
			return;

		for (int i = startVertex; i < mBatch.Vertices.Count; i++)
		{
			var vertex = ref mBatch.Vertices[i];
			vertex.Color = ApplyOpacity(vertex.Color);
		}
	}

	private RectangleF TransformRect(RectangleF rect)
	{
		if (mCurrentState.Transform == Matrix.Identity)
			return rect;

		let topLeft = TransformPoint(.(rect.X, rect.Y));
		let bottomRight = TransformPoint(.(rect.X + rect.Width, rect.Y + rect.Height));
		return .(topLeft.X, topLeft.Y, bottomRight.X - topLeft.X, bottomRight.Y - topLeft.Y);
	}
}
