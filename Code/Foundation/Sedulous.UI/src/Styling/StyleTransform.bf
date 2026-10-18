using System;
using Sedulous.Core;

namespace Sedulous.UI;

/// A sheet's `transform`: a move (dp), a turn (degrees, clockwise) and a scale, about the
/// view's transform origin. It composes with the view's own Transform field: moves and turns
/// add, scales multiply. Its parts apply as translate, rotate, then scale, whatever order the
/// sheet writes them in.
struct StyleTransform
{
	public Float2 Translate = .(0.0f, 0.0f);
	public float RotateDegrees = 0.0f;
	public Float2 Scale = .(1.0f, 1.0f);

	public this() {}

	public bool IsIdentity => (Translate.X == 0.0f) && (Translate.Y == 0.0f) && (RotateDegrees == 0.0f)
		&& (Scale.X == 1.0f) && (Scale.Y == 1.0f);

	[Commutable]
	public static bool operator==(StyleTransform a, StyleTransform b) =>
		(a.Translate == b.Translate) && (a.RotateDegrees == b.RotateDegrees) && (a.Scale == b.Scale);
}
