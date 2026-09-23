using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Scene;
using Sedulous.Editor.Core;
using Sedulous.Engine.Vegetation;

namespace Sedulous.Editor.Vegetation;

/// One prop stroke as one undo step: the layer's whole instance list before and after.
///
/// Whole rather than incremental because props are FEW, a few hundred at most over a
/// terrain, and the manager re-buckets on a content hash either way, so a diff would buy
/// nothing and would have to describe an erase as well as a place.
///
/// The component is re-resolved on every write, the manager's pool being free to move, and
/// a layer that has gone leaves a no op behind.
class ScatterStrokeCommand : EditorCommand
{
	/// BORROWED: the page owns the scene.
	private Scene mScene;
	private EntityHandle mOwner;
	private uint32 mLayer;
	private List<Float4x4> mBefore = new .() ~ delete _;
	private List<Float4x4> mAfter = new .() ~ delete _;

	public this(Scene scene, EntityHandle owner, uint32 layer, Span<Float4x4> before,
		Span<Float4x4> after)
	{
		mScene = scene;
		mOwner = owner;
		mLayer = layer;
		mBefore.AddRange(before);
		mAfter.AddRange(after);
	}

	public override bool Execute() => Write(mAfter);
	public override void Undo() => Write(mBefore);
	public override StringView TypeId => "vegetation.scatter.stroke";

	private bool Write(List<Float4x4> instances)
	{
		let manager = (mScene != null) ? mScene.GetSystem<TerrainVegetationComponentManager>() : null;
		let component = (manager != null) ? manager.Get(mOwner) : null;
		if ((component == null) || (component.Layers == null)
			|| ((int)mLayer >= component.Layers.Count))
			return false;

		let target = component.Layers[(int)mLayer].Instances;
		target.Clear();
		target.AddRange(instances);
		return true;
	}
}
