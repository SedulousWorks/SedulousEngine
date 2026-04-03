using System;
using System.Collections;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Mutable builder for constructing Path objects
public class PathBuilder
{
	private List<PathCommand> mCommands = new .() ~ delete _;
	private List<Vector2> mPoints = new .() ~ delete _;
	private Vector2 mCurrentPoint;
	private Vector2 mSubPathStart;
	private bool mHasMoveTo;

	/// Move the pen to a new position, starting a new sub-path
	public void MoveTo(float x, float y)
	{
		mCommands.Add(.MoveTo);
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
		mSubPathStart = mCurrentPoint;
		mHasMoveTo = true;
	}

	/// Move the pen to a new position
	public void MoveTo(Vector2 point)
	{
		MoveTo(point.X, point.Y);
	}

	/// Draw a straight line to the given point
	public void LineTo(float x, float y)
	{
		EnsureMoveTo();
		mCommands.Add(.LineTo);
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
	}

	/// Draw a straight line to the given point
	public void LineTo(Vector2 point)
	{
		LineTo(point.X, point.Y);
	}

	/// Draw a quadratic Bezier curve
	public void QuadTo(float cx, float cy, float x, float y)
	{
		EnsureMoveTo();
		mCommands.Add(.QuadTo);
		mPoints.Add(.(cx, cy));
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
	}

	/// Draw a quadratic Bezier curve
	public void QuadTo(Vector2 control, Vector2 end)
	{
		QuadTo(control.X, control.Y, end.X, end.Y);
	}

	/// Draw a cubic Bezier curve
	public void CubicTo(float c1x, float c1y, float c2x, float c2y, float x, float y)
	{
		EnsureMoveTo();
		mCommands.Add(.CubicTo);
		mPoints.Add(.(c1x, c1y));
		mPoints.Add(.(c2x, c2y));
		mPoints.Add(.(x, y));
		mCurrentPoint = .(x, y);
	}

	/// Draw a cubic Bezier curve
	public void CubicTo(Vector2 control1, Vector2 control2, Vector2 end)
	{
		CubicTo(control1.X, control1.Y, control2.X, control2.Y, end.X, end.Y);
	}

	/// Draw an SVG-style endpoint arc
	public void ArcTo(float rx, float ry, float xAxisRotation, bool largeArc, bool sweep, float x, float y)
	{
		EnsureMoveTo();
		let to = Vector2(x, y);
		let cubicPoints = scope List<Vector2>();
		CurveUtils.ArcToCubics(mCurrentPoint, rx, ry, xAxisRotation, largeArc, sweep, to, cubicPoints);

		// Each 3 points = one cubic segment (cp1, cp2, endpoint)
		for (int i = 0; i + 2 < cubicPoints.Count; i += 3)
		{
			mCommands.Add(.CubicTo);
			mPoints.Add(cubicPoints[i]);
			mPoints.Add(cubicPoints[i + 1]);
			mPoints.Add(cubicPoints[i + 2]);
		}

		mCurrentPoint = to;
	}

	/// Draw an SVG-style endpoint arc
	public void ArcTo(float rx, float ry, float xAxisRotation, bool largeArc, bool sweep, Vector2 to)
	{
		ArcTo(rx, ry, xAxisRotation, largeArc, sweep, to.X, to.Y);
	}

	/// Close the current sub-path
	public void Close()
	{
		if (mHasMoveTo)
		{
			mCommands.Add(.Close);
			mCurrentPoint = mSubPathStart;
		}
	}

	/// Build an immutable Path from the current state
	public Path ToPath()
	{
		let commands = new List<PathCommand>();
		commands.AddRange(mCommands);
		let points = new List<Vector2>();
		points.AddRange(mPoints);
		return new Path(commands, points);
	}

	/// Reset the builder for reuse
	public void Clear()
	{
		mCommands.Clear();
		mPoints.Clear();
		mCurrentPoint = .Zero;
		mSubPathStart = .Zero;
		mHasMoveTo = false;
	}

	/// Current pen position
	public Vector2 CurrentPoint => mCurrentPoint;

	/// Number of commands added so far
	public int CommandCount => mCommands.Count;

	private void EnsureMoveTo()
	{
		if (!mHasMoveTo)
		{
			MoveTo(0, 0);
		}
	}
}
