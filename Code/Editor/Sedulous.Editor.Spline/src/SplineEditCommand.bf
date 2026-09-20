using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Spline;
using Sedulous.Engine.Spline;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Spline;

/// One undo step of the spline tool: the whole point table and the closed flag before and
/// after, re-applied to the entity's component by guid.
class SplineEditCommand : EditorCommand
{
	/// Borrowed.
	private Scene mScene;
	private Guid mEntity;
	private List<SplinePoint> mBefore = new .() ~ delete _;
	private bool mBeforeClosed;
	private List<SplinePoint> mAfter = new .() ~ delete _;
	private bool mAfterClosed;

	public this(Scene scene, Guid entity, Span<SplinePoint> before, bool beforeClosed, Span<SplinePoint> after, bool afterClosed)
	{
		mScene = scene;
		mEntity = entity;
		mBefore.AddRange(before);
		mBeforeClosed = beforeClosed;
		mAfter.AddRange(after);
		mAfterClosed = afterClosed;
	}

	public override bool Execute() => Apply(mAfter, mAfterClosed);
	public override void Undo() => Apply(mBefore, mBeforeClosed);
	public override StringView TypeId => "spline.edit";

	private bool Apply(List<SplinePoint> points, bool closed)
	{
		let manager = mScene.GetSystem<SplineComponentManager>();
		if (manager == null)
			return false;
		let component = manager.Get(mScene.FindEntity(mEntity));
		if ((component == null) || (component.Curve == null))
			return false;
		component.Curve.Points.Clear();
		component.Curve.Points.AddRange(points);
		component.Curve.Closed = closed;
		component.Curve.UpdateAutoHandles();
		component.Curve.RebuildArcLength();
		return true;
	}
}
