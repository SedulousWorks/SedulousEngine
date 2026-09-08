using System;
using Sedulous.Core;

namespace Sedulous.VG;

/// Walks a path's parallel command and point streams together.
///
/// A STRUCT, so iterating costs no allocation: a tessellator walks a path several times per
/// frame and a heap iterator per walk would be pure overhead.
struct PathIterator
{
	private Span<PathCommand> mCommands = default;
	private Span<Float2> mPoints = default;
	private int mCommandIndex = 0;
	private int mPointIndex = 0;
	private Float2 mCurrentPoint = .Zero;
	private Float2 mSubPathStart = .Zero;

	public this() {}

	public this(Span<PathCommand> commands, Span<Float2> points)
	{
		mCommands = commands;
		mPoints = points;
	}

	/// The next segment, or false once the path is walked.
	public bool GetNext(out PathSegment segment) mut
	{
		segment = .();

		if (mCommandIndex >= mCommands.Length)
			return false;

		let command = mCommands[mCommandIndex];
		segment.Command = command;
		segment.StartPoint = mCurrentPoint;

		switch (command)
		{
		case .MoveTo:
			segment.Points = mPoints.Slice(mPointIndex, 1);
			mCurrentPoint = mPoints[mPointIndex];
			// Remembered so a Close knows where to go back to.
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
			// No points of its own: the pen returns to where the subpath started.
			segment.Points = default;
			mCurrentPoint = mSubPathStart;
		}

		mCommandIndex++;
		return true;
	}
}
