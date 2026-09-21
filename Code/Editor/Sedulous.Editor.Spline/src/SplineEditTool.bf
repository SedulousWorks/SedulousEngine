using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Shell;
using Sedulous.Render;
using Sedulous.Spline;
using Sedulous.Engine.Spline;
using Sedulous.Editor.Core;
using Sedulous.Editor.ViewportTools;

namespace Sedulous.Editor.Spline;

/// The spline viewport tool, available while a selected entity carries a spline: drag a
/// point or, on the selected point, a tangent handle (Shift breaks the pair), Ctrl-click a
/// segment to insert, Ctrl-click off a curve with no segment to place a point, Delete or X
/// over a point to remove. Every edit is one command holding the whole point table. The scene, commands and selection are BORROWED from the host.
class SplineEditTool : IViewportTool
{
	/// Screen constant pick radius per unit of distance.
	private const float cPickScale = 0.02f;

	private Scene mScene;
	private EditorCommandStack mCommands;
	private Selection<Guid> mSelection;
	private Guid mEntity = .();
	private Float4x4 mWorld = Float4x4.Identity();
	private int32 mHoverPoint = -1;
	private bool mDragging = false;
	private int32 mDragPoint = -1;
	/// -1 the point itself, 0 the in handle, 1 the out handle.
	private int32 mDragHandle = -1;
	private int32 mSelectedPoint = -1;
	private int32 mHoverHandle = -1;
	private Float3 mDragPlaneOrigin = .Zero;
	private Float3 mDragPlaneNormal = .(0, 0, 1);
	private bool mHasInsertPreview = false;
	private float mInsertT = 0.0f;
	private Float3 mInsertLocal = .Zero;
	/// Ctrl over an empty curve: the next point's spot.
	private bool mHasPlacePreview = false;
	private Float3 mPlaceLocal = .Zero;
	private List<SplinePoint> mSnapshotPoints = new .() ~ delete _;
	private bool mSnapshotClosed = false;

	public this(in ViewportToolHostContext context)
	{
		mScene = context.Scene;
		mCommands = context.Commands;
		mSelection = context.EntitySelection;
	}

	public StringView Id => "spline.edit";
	public StringView DisplayName => "Spline";
	public bool IsAvailable => TargetComponent() != null;
	public StringView StatusText => "drag point/handle (Shift: break pair) | Ctrl+click segment: insert | Del/X: remove";
	public int32 HoverPoint => mHoverPoint;
	public int32 SelectedPoint => mSelectedPoint;
	public bool IsDragging => mDragging;
	public bool HasInsertPreview => mHasInsertPreview;
	/// Ctrl over a curve with no segment: a click appends here.
	public bool HasPlacePreview => mHasPlacePreview;

	public void OnActivate() {}
	public void OnDeactivate() => EndDrag(true);

	public bool Update(in ViewportToolInput input)
	{
		mHoverPoint = -1;
		mHasInsertPreview = false;
		mHasPlacePreview = false;
		Guid entity = .();
		let component = TargetComponent(ref entity);
		if ((component == null) || (mScene == null))
		{
			EndDrag(true);
			return false;
		}
		mEntity = entity;
		mWorld = mScene.GetWorldMatrix(mScene.FindEntity(mEntity));
		let curve = component.Curve;
		if (!input.PointerValid)
		{
			EndDrag(true);
			return mDragging;
		}

		mHoverHandle = -1;
		var bestDistance = float.MaxValue;
		if ((mSelectedPoint >= 0) && (mSelectedPoint < curve.Points.Count))
		{
			let selected = curve.Points[mSelectedPoint];
			Float3[2] ends = .(TransformPoint(selected.Position + selected.InHandle, mWorld), TransformPoint(selected.Position + selected.OutHandle, mWorld));
			for (int32 h < 2)
			{
				float along = 0.0f;
				let d = RayPointDistance(input.Ray, ends[h], ref along);
				if ((d < along * cPickScale) && (d < bestDistance))
				{
					bestDistance = d;
					mHoverHandle = h;
				}
			}
		}
		if (mHoverHandle < 0)
		{
			for (int32 i < (int32)curve.Points.Count)
			{
				let world = TransformPoint(curve.Points[i].Position, mWorld);
				float along = 0.0f;
				let d = RayPointDistance(input.Ray, world, ref along);
				if ((d < along * cPickScale) && (d < bestDistance))
				{
					bestDistance = d;
					mHoverPoint = i;
				}
			}
		}
		if (input.Ctrl && (mHoverPoint < 0) && (curve.SegmentCount > 0))
			FindRayClosest(curve, input.Ray);
		// Place preview: a curve with no segment yet (a component added bare, or cut down to
		// one point) takes its points from Ctrl-clicks, on the camera-facing plane through the
		// entity (through its last point once it has one), so a spline can be built from
		// nothing.
		if (input.Ctrl && (mHoverPoint < 0) && (curve.SegmentCount == 0) && !mDragging)
		{
			let through = curve.Points.IsEmpty
				? TransformPoint(.Zero, mWorld)
				: TransformPoint(curve.Points[curve.Points.Count - 1].Position, mWorld);
			let normal = input.CameraForward * -1.0f;
			let denominator = Dot(input.Ray.Direction, normal);
			if (Math.Abs(denominator) > 0.0001f)
			{
				let t = Dot(through - input.Ray.Origin, normal) / denominator;
				if (t > 0.0f)
				{
					let world = input.Ray.Origin + input.Ray.Direction * t;
					mPlaceLocal = TransformPoint(world, Inverse(mWorld));
					mHasPlacePreview = true;
				}
			}
		}

		if (mDragging)
		{
			if (input.EditingLocked || !input.LeftDown)
			{
				EndDrag(!input.EditingLocked);
				return true;
			}
			let denominator = Dot(input.Ray.Direction, mDragPlaneNormal);
			if ((Math.Abs(denominator) > 0.0001f) && (mDragPoint < curve.Points.Count))
			{
				let t = Dot(mDragPlaneOrigin - input.Ray.Origin, mDragPlaneNormal) / denominator;
				if (t > 0.0f)
				{
					let world = input.Ray.Origin + input.Ray.Direction * t;
					let local = TransformPoint(world, Inverse(mWorld));
					var point = curve.Points[mDragPoint];
					if (mDragHandle < 0)
						point.Position = local;
					else
					{
						if (point.Mode == .Auto)
							point.Mode = .Smooth;
						if (input.Shift)
							point.Mode = .Broken;
						let dragged = local - point.Position;
						var other = (mDragHandle == 0) ? point.OutHandle : point.InHandle;
						if (point.Mode == .Smooth)
						{
							let draggedLength = Length(dragged);
							if (draggedLength > 0.0001f)
								other = dragged * (-Length(other) / draggedLength);
						}
						if (mDragHandle == 0)
						{
							point.InHandle = dragged;
							point.OutHandle = other;
						}
						else
						{
							point.OutHandle = dragged;
							point.InHandle = other;
						}
					}
					curve.Points[mDragPoint] = point;
					curve.UpdateAutoHandles();
					curve.RebuildArcLength();
				}
			}
			return true;
		}

		if (input.EditingLocked)
			return mHoverPoint >= 0;

		if ((mHoverPoint >= 0) && (input.Keyboard != null)
			&& (input.Keyboard.IsKeyPressed(.Delete) || input.Keyboard.IsKeyPressed(.X))
			&& (curve.Points.Count > 2))
		{
			BeginSnapshot(curve);
			curve.Points.RemoveAt(mHoverPoint);
			curve.UpdateAutoHandles();
			curve.RebuildArcLength();
			CommitSnapshot(curve);
			mHoverPoint = -1;
			mSelectedPoint = -1;
			return true;
		}

		if (input.LeftPressed && input.PointerOver)
		{
			if ((mHoverHandle >= 0) && (mSelectedPoint >= 0))
			{
				let selected = curve.Points[mSelectedPoint];
				BeginSnapshot(curve);
				mDragging = true;
				mDragPoint = mSelectedPoint;
				mDragHandle = mHoverHandle;
				mDragPlaneOrigin = TransformPoint(selected.Position + ((mHoverHandle == 0) ? selected.InHandle : selected.OutHandle), mWorld);
				mDragPlaneNormal = input.CameraForward * -1.0f;
				return true;
			}
			if (mHoverPoint >= 0)
			{
				BeginSnapshot(curve);
				mDragging = true;
				mDragPoint = mHoverPoint;
				mDragHandle = -1;
				mSelectedPoint = mHoverPoint;
				mDragPlaneOrigin = TransformPoint(curve.Points[mDragPoint].Position, mWorld);
				mDragPlaneNormal = input.CameraForward * -1.0f;
				return true;
			}
			if (input.Ctrl && mHasPlacePreview)
			{
				// Append (one undo step each): the first two clicks make the curve a curve,
				// after which Ctrl-click inserts on the segment under the pointer.
				BeginSnapshot(curve);
				curve.Points.Add(SplinePoint(mPlaceLocal));
				curve.UpdateAutoHandles();
				curve.RebuildArcLength();
				CommitSnapshot(curve);
				mSelectedPoint = (int32)curve.Points.Count - 1;
				mHasPlacePreview = false;
				return true;
			}
			if (input.Ctrl && mHasInsertPreview)
			{
				BeginSnapshot(curve);
				var point = SplinePoint();
				point.Position = mInsertLocal;
				let after = (int)mInsertT + 1;
				curve.Points.Insert(Math.Min(after, curve.Points.Count), point);
				curve.UpdateAutoHandles();
				curve.RebuildArcLength();
				CommitSnapshot(curve);
				return true;
			}
		}
		return mHoverPoint >= 0;
	}

	public void Draw(DebugDraw drawList)
	{
		let component = TargetComponent();
		if (component == null)
			return;
		let curve = component.Curve;
		let curveColor = Color(0.35f, 0.85f, 1.0f, 1.0f);
		let pointColor = Color(1.0f, 0.85f, 0.2f, 1.0f);
		let hoverColor = Color(1.0f, 0.4f, 0.2f, 1.0f);
		let segments = curve.SegmentCount;
		if (segments > 0)
		{
			let steps = segments * SplineCurve.SamplesPerSegment;
			var previous = TransformPoint(curve.Evaluate(0.0f), mWorld);
			for (uint32 i = 1; i <= steps; i++)
			{
				let t = curve.MaxT * (float)i / (float)steps;
				let position = TransformPoint(curve.Evaluate(t), mWorld);
				drawList.DrawLine(previous, position, curveColor);
				previous = position;
			}
		}
		for (int32 i < (int32)curve.Points.Count)
		{
			let world = TransformPoint(curve.Points[i].Position, mWorld);
			let hovered = i == mHoverPoint;
			drawList.DrawWireSphere(world, hovered ? 0.14f : 0.1f, hovered ? hoverColor : pointColor);
		}
		if ((mSelectedPoint >= 0) && (mSelectedPoint < curve.Points.Count))
		{
			let selected = curve.Points[mSelectedPoint];
			let anchor = TransformPoint(selected.Position, mWorld);
			let handleColor = Color(0.75f, 0.6f, 1.0f, 1.0f);
			Float3[2] ends = .(TransformPoint(selected.Position + selected.InHandle, mWorld), TransformPoint(selected.Position + selected.OutHandle, mWorld));
			for (int32 h < 2)
			{
				drawList.DrawLine(anchor, ends[h], handleColor);
				drawList.DrawWireSphere(ends[h], (mHoverHandle == h) ? 0.09f : 0.06f, (mHoverHandle == h) ? hoverColor : handleColor, 10);
			}
		}
		if (mHasInsertPreview)
			drawList.DrawWireSphere(TransformPoint(mInsertLocal, mWorld), 0.08f, .(0.4f, 1.0f, 0.4f, 1.0f));
		if (mHasPlacePreview)
			drawList.DrawWireSphere(TransformPoint(mPlaceLocal, mWorld), 0.08f, .(0.6f, 1.0f, 0.6f, 1.0f));
	}

	/// The first selected entity carrying a spline, and its guid.
	private SplineComponent* TargetComponent(ref Guid outEntity)
	{
		if ((mScene == null) || (mSelection == null) || mSelection.IsEmpty)
			return null;
		let manager = mScene.GetSystem<SplineComponentManager>();
		if (manager == null)
			return null;
		for (let id in mSelection.Items)
		{
			if (let component = manager.Get(mScene.FindEntity(id)))
			{
				outEntity = id;
				return component;
			}
		}
		return null;
	}

	private SplineComponent* TargetComponent()
	{
		Guid ignored = .();
		return TargetComponent(ref ignored);
	}

	private static float RayPointDistance(in ViewportRay ray, Float3 point, ref float outAlong)
	{
		let toPoint = point - ray.Origin;
		outAlong = Math.Max(Dot(toPoint, ray.Direction), 0.0f);
		return Length(toPoint - ray.Direction * outAlong);
	}

	/// The closest sampled curve point under the ray, the insert preview.
	private void FindRayClosest(SplineCurve curve, in ViewportRay ray)
	{
		let steps = curve.SegmentCount * SplineCurve.SamplesPerSegment;
		var bestDistance = float.MaxValue;
		for (uint32 i = 0; i <= steps; i++)
		{
			let t = curve.MaxT * (float)i / (float)steps;
			let world = TransformPoint(curve.Evaluate(t), mWorld);
			float along = 0.0f;
			let d = RayPointDistance(ray, world, ref along);
			if ((d < along * cPickScale) && (d < bestDistance))
			{
				bestDistance = d;
				mInsertT = t;
				mInsertLocal = curve.Evaluate(t);
				mHasInsertPreview = true;
			}
		}
	}

	private void BeginSnapshot(SplineCurve curve)
	{
		mSnapshotPoints.Clear();
		mSnapshotPoints.AddRange(curve.Points);
		mSnapshotClosed = curve.Closed;
	}

	private void CommitSnapshot(SplineCurve curve)
	{
		if (mCommands == null)
			return;
		mCommands.Execute(new SplineEditCommand(mScene, mEntity, mSnapshotPoints, mSnapshotClosed, curve.Points, curve.Closed));
	}

	/// Closes a drag out: committed as one step, or reverted to the snapshot.
	private void EndDrag(bool commit)
	{
		if (!mDragging)
			return;
		mDragging = false;
		let component = TargetComponent();
		if (component == null)
			return;
		if (commit)
			CommitSnapshot(component.Curve);
		else
		{
			component.Curve.Points.Clear();
			component.Curve.Points.AddRange(mSnapshotPoints);
			component.Curve.Closed = mSnapshotClosed;
			component.Curve.UpdateAutoHandles();
			component.Curve.RebuildArcLength();
		}
	}
}
