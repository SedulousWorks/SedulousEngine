using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Image;
using Sedulous.VG;

namespace Sedulous.VG.Tests;

/// The batch a context fills and a renderer walks, and the clip stack that writes into it.
class BatchTests
{
	private static Path Rect(float x, float y, float w, float h)
	{
		let builder = scope PathBuilder();
		builder.MoveTo(x, y);
		builder.LineTo(x + w, y);
		builder.LineTo(x + w, y + h);
		builder.LineTo(x, y + h);
		builder.Close();
		return builder.ToPath();
	}

	/// All three parts must be present. Geometry with no command is never submitted, and a
	/// command with no geometry draws nothing.
	[Test]
	public static void ABatchIsEmptyUntilItHasAllThreeParts()
	{
		let batch = scope VGBatch();
		Test.Assert(batch.IsEmpty);

		batch.Vertices.Add(VGVertex.Solid(.(0, 0), .Red));
		Test.Assert(batch.IsEmpty, "vertices alone are not a draw");

		batch.Indices.Add(0);
		Test.Assert(batch.IsEmpty, "nor geometry with no command");

		batch.Commands.Add(.());
		Test.Assert(!batch.IsEmpty);
	}

	[Test]
	public static void ACommandResolvesItsOwnTexture()
	{
		let batch = scope VGBatch();
		let white = scope OwnedImageData(1, 1, .RGBA8, .(), .Linear);
		batch.Textures.Add(white);

		var withTexture = VGCommand();
		withTexture.TextureIndex = 0;
		batch.Commands.Add(withTexture);

		var untextured = VGCommand();
		batch.Commands.Add(untextured);

		var outOfRange = VGCommand();
		outOfRange.TextureIndex = 7;
		batch.Commands.Add(outOfRange);

		Test.Assert(batch.GetTextureForCommand(0) == white);
		Test.Assert(batch.GetTextureForCommand(1) == null, "negative means none");
		Test.Assert(batch.GetTextureForCommand(2) == null, "and so does out of range");
	}

	/// Clearing empties the TEXTURE LIST too, so the caller re-adds the white fallback at
	/// index zero rather than inheriting a stale list.
	[Test]
	public static void ClearingEmptiesTheTextureListAsWell()
	{
		let batch = scope VGBatch();
		let image = scope OwnedImageData(1, 1, .RGBA8, .(), .Linear);

		batch.Vertices.Add(VGVertex.Solid(.(0, 0), .Red));
		batch.Indices.Add(0);
		batch.Commands.Add(.());
		batch.Textures.Add(image);
		batch.EvictedTextures.Add(image);

		batch.Clear();

		Test.Assert(batch.IsEmpty);
		Test.Assert(batch.Textures.IsEmpty);
		Test.Assert(batch.EvictedTextures.IsEmpty);
	}

	/// A command's defaults are the ordinary case: direct fill, no clip, normal blend, no
	/// texture.
	[Test]
	public static void ACommandDefaultsToAnOrdinaryDraw()
	{
		let command = VGCommand();
		Test.Assert(command.TextureIndex == -1);
		Test.Assert(command.ClipMode == .None);
		Test.Assert(command.BlendMode == .Normal);
		Test.Assert(command.DrawMode == .Default);
		Test.Assert(command.FillPhase == .Direct);
		Test.Assert(command.FillRule == .NonZero);
		Test.Assert(command.GradientSpread == .Pad);
		Test.Assert(command.StencilRef == 0);
	}

	// ---- clip stack ----

	/// A push emits stencil geometry and takes the next stencil value, so nesting depth is
	/// the value a draw tests against.
	[Test]
	public static void PushingAClipEmitsStencilGeometry()
	{
		let clips = scope ClipPathManager();
		let batch = scope VGBatch();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		Test.Assert(clips.CurrentStencilRef == 0);
		Test.Assert(clips.Depth == 0);

		clips.PushClipPath(path, .NonZero, batch);

		Test.Assert(clips.Depth == 1);
		Test.Assert(clips.CurrentStencilRef == 1);
		Test.Assert(batch.Commands.Count == 1);
		Test.Assert(batch.Commands[0].ClipMode == .Stencil);
		Test.Assert(batch.Commands[0].StencilRef == 1);
		Test.Assert(batch.Commands[0].IndexCount > 0);
	}

	/// A clip is tessellated WITHOUT antialiasing: it is a hard test, and a fringe of
	/// partial coverage would write stencil for pixels only partly inside.
	[Test]
	public static void AClipIsNotAntiAliased()
	{
		let clips = scope ClipPathManager();
		let batch = scope VGBatch();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		clips.PushClipPath(path, .NonZero, batch);

		Test.Assert(batch.Vertices.Count == 4, "the corners only, with no fringe ring");
		for (let vertex in batch.Vertices)
			Test.Assert(vertex.Coverage == 1.0f);
	}

	[Test]
	public static void NestingRaisesTheStencilValueAndPoppingRestoresIt()
	{
		let clips = scope ClipPathManager();
		let batch = scope VGBatch();
		let outer = Rect(0, 0, 20, 20);
		defer delete outer;
		let inner = Rect(5, 5, 10, 10);
		defer delete inner;

		clips.PushClipPath(outer, .NonZero, batch);
		clips.PushClipPath(inner, .NonZero, batch);

		Test.Assert(clips.Depth == 2);
		Test.Assert(clips.CurrentStencilRef == 2);
		Test.Assert(batch.Commands[1].StencilRef == 2);

		clips.PopClip();
		Test.Assert(clips.Depth == 1);
		Test.Assert(clips.CurrentStencilRef == 1);

		clips.PopClip();
		Test.Assert(clips.Depth == 0);
		Test.Assert(clips.CurrentStencilRef == 0);
	}

	/// An unbalanced pop resets to no clip rather than going negative, which would make
	/// every following draw test against a value nothing ever wrote.
	[Test]
	public static void AnUnbalancedPopResetsToNoClip()
	{
		let clips = scope ClipPathManager();
		clips.PopClip();
		Test.Assert(clips.CurrentStencilRef == 0);
		Test.Assert(clips.Depth == 0);
	}

	/// A clip path that tessellates to nothing still counts as pushed, so its pop balances.
	[Test]
	public static void AnEmptyClipStillCountsAsPushed()
	{
		let clips = scope ClipPathManager();
		let batch = scope VGBatch();
		let empty = scope Path();

		clips.PushClipPath(empty, .NonZero, batch);

		Test.Assert(clips.Depth == 1, "the stack is balanced");
		Test.Assert(batch.Commands.IsEmpty, "but there is nothing to draw");
	}

	[Test]
	public static void ClearingTheStackResetsIt()
	{
		let clips = scope ClipPathManager();
		let batch = scope VGBatch();
		let path = Rect(0, 0, 10, 10);
		defer delete path;

		clips.PushClipPath(path, .NonZero, batch);
		clips.PushClipPath(path, .NonZero, batch);
		clips.Clear();

		Test.Assert(clips.Depth == 0);
		Test.Assert(clips.CurrentStencilRef == 0);
	}
}
