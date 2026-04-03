using System;
using Sedulous.Core.Mathematics;

namespace Sedulous.VG;

/// Iterates over a Path, yielding PathSegment values
public struct PathIterator
{
	private Span<PathCommand> mCommands;
	private Span<Vector2> mPoints;
	private int mCommandIndex;
	private int mPointIndex;
	private Vector2 mCurrentPoint;
	private Vector2 mSubPathStart;

	public this(Span<PathCommand> commands, Span<Vector2> points)
	{
		mCommands = commands;
		mPoints = points;
		mCommandIndex = 0;
		mPointIndex = 0;
		mCurrentPoint = .Zero;
		mSubPathStart = .Zero;
	}

	/// Get the next segment. Returns false when iteration is complete.
	public bool GetNext(out PathSegment segment) mut
	{
		segment = default;

		if (mCommandIndex >= mCommands.Length)
			return false;

		let cmd = mCommands[mCommandIndex];
		segment.Command = cmd;
		segment.StartPoint = mCurrentPoint;

		switch (cmd)
		{
		case .MoveTo:
			segment.Points = mPoints.Slice(mPointIndex, 1);
			mCurrentPoint = mPoints[mPointIndex];
			mSubPathStart = mCurrentPoint;
			mPointIndex += 1;

		case .LineTo:
			segment.Points = mPoints.Slice(mPointIndex, 1);
			mCurrentPoint = mPoints[mPointIndex];
			mPointIndex += 1;

		case .QuadTo:
			segment.Points = mPoints.Slice(mPointIndex, 2);
			mCurrentPoint = mPoints[mPointIndex + 1];
			mPointIndex += 2;

		case .CubicTo:
			segment.Points = mPoints.Slice(mPointIndex, 3);
			mCurrentPoint = mPoints[mPointIndex + 2];
			mPointIndex += 3;

		case .Close:
			segment.Points = default;
			mCurrentPoint = mSubPathStart;
		}

		mCommandIndex++;
		return true;
	}
}
