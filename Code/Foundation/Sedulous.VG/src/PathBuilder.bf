using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.VG;

/// Builds a path, one command at a time.
///
/// Every drawing command IMPLIES a MoveTo when none has been issued: a line drawn before
/// the pen has been placed starts at the origin rather than being dropped, because dropping
/// it produces a shape that is silently missing an edge.
class PathBuilder
{
	private List<PathCommand> mCommands = new .() ~ delete _;
	private List<Float2> mPoints = new .() ~ delete _;
	private Float2 mCurrentPoint = .Zero;
	private Float2 mSubPathStart = .Zero;
	private bool mHasMoveTo = false;

	public void MoveTo(float x, float y)
	{
		mCommands.Add(.MoveTo);
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
		mSubPathStart = mCurrentPoint;
		mHasMoveTo = true;
	}

	public void MoveTo(Float2 point) => MoveTo(point.X, point.Y);

	public void LineTo(float x, float y)
	{
		EnsureMoveTo();
		mCommands.Add(.LineTo);
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
	}

	public void LineTo(Float2 point) => LineTo(point.X, point.Y);

	public void QuadTo(float cx, float cy, float x, float y)
	{
		EnsureMoveTo();
		mCommands.Add(.QuadTo);
		mPoints.Add(.(cx, cy));
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
	}

	public void QuadTo(Float2 control, Float2 end) => QuadTo(control.X, control.Y, end.X, end.Y);

	public void CubicTo(float c1x, float c1y, float c2x, float c2y, float x, float y)
	{
		EnsureMoveTo();
		mCommands.Add(.CubicTo);
		mPoints.Add(.(c1x, c1y));
		mPoints.Add(.(c2x, c2y));
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
	}

	public void CubicTo(Float2 control1, Float2 control2, Float2 end)
		=> CubicTo(control1.X, control1.Y, control2.X, control2.Y, end.X, end.Y);

	/// An SVG endpoint arc, stored as the cubics that approximate it.
	///
	/// Converted HERE rather than kept as an arc command, so everything downstream only
	/// ever sees lines and beziers: one fewer case in the tessellator, the hit test, and
	/// the length walk each.
	public void ArcTo(float rx, float ry, float xAxisRotation, bool largeArc, bool sweep,
		float x, float y)
	{
		EnsureMoveTo();
		let to = Float2(x, y);

		let cubicPoints = scope List<Float2>();
		CurveUtils.ArcToCubics(mCurrentPoint, rx, ry, xAxisRotation, largeArc, sweep, to,
			cubicPoints);

		// Three points per cubic: two controls and an end.
		for (int i = 0; (i + 2) < cubicPoints.Count; i += 3)
		{
			mCommands.Add(.CubicTo);
			mPoints.Add(cubicPoints[i]);
			mPoints.Add(cubicPoints[i + 1]);
			mPoints.Add(cubicPoints[i + 2]);
		}

		// Set from the ARGUMENT rather than from the last emitted point, so an arc that
		// produced nothing still leaves the pen where the caller said.
		mCurrentPoint = to;
	}

	public void ArcTo(float rx, float ry, float xAxisRotation, bool largeArc, bool sweep, Float2 to)
		=> ArcTo(rx, ry, xAxisRotation, largeArc, sweep, to.X, to.Y);

	/// Closes the current subpath. Does NOTHING before the first MoveTo: there is no
	/// subpath to close, and emitting one would leave a command the iterator cannot place.
	public void Close()
	{
		if (!mHasMoveTo)
			return;

		mCommands.Add(.Close);
		mCurrentPoint = mSubPathStart;
	}

	/// THE CALLER OWNS what comes back, and the builder is unchanged: it can go on being
	/// used, which is what lets one builder emit a family of related paths.
	public Path ToPath() => new .(mCommands, mPoints);

	public void Clear()
	{
		mCommands.Clear();
		mPoints.Clear();
		mCurrentPoint = .Zero;
		mSubPathStart = .Zero;
		mHasMoveTo = false;
	}

	public Float2 CurrentPoint => mCurrentPoint;
	public int CommandCount => mCommands.Count;

	private void EnsureMoveTo()
	{
		if (!mHasMoveTo)
			MoveTo(0.0f, 0.0f);
	}
}
