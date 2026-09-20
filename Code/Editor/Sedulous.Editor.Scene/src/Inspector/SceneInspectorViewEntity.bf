using System;
using Sedulous.Core;
using Sedulous.UI.Toolkit;

namespace Sedulous.Editor.Scene;

/// The entity's own rows: name and active, then the local transform as position, Euler
/// degrees and scale.
extension SceneInspectorView
{
	private void BuildEntitySection(Guid id)
	{
		let edit = mEdit;
		let name = new StringEditor("Name", edit.Scene.GetEntityName(edit.Resolve(id)),
			new [=edit, =id](v) => { edit.RenameEntity(id, v); }, "Entity");
		AddEditor(name, new [=edit, =id, =name]() => { name.SetValue(edit.Scene.GetEntityName(edit.Resolve(id))); });

		let active = new BoolEditor("Active", edit.Scene.IsActive(edit.Resolve(id)),
			new [=edit, =id](v) => { edit.SetEntityActive(id, v); }, "Entity");
		AddEditor(active, new [=edit, =id, =active]() => { active.SetValue(edit.Scene.IsActive(edit.Resolve(id))); });
	}

	private void BuildTransformSection(Guid id)
	{
		let edit = mEdit;
		let category = "Transform";
		let t = edit.Scene.GetLocalTransform(edit.Resolve(id));

		let position = new Float3Editor("Position", t.Position, -100000.0f, 100000.0f, 0.1f,
			new [=edit, =id](v) =>
			{
				var current = edit.Scene.GetLocalTransform(edit.Resolve(id));
				current.Position = v;
				edit.SetLocalTransform(id, current);
			}, category);
		AddEditor(position, new [=edit, =id, =position]() =>
		{
			position.SetValue(edit.Scene.GetLocalTransform(edit.Resolve(id)).Position);
		});

		let rotation = new Float3Editor("Rotation", EulerDegrees(t.Rotation), -360.0f, 360.0f, 1.0f,
			new [=edit, =id](v) =>
			{
				var current = edit.Scene.GetLocalTransform(edit.Resolve(id));
				current.Rotation = FromYawPitchRoll(DegreesToRadians(v.Y), DegreesToRadians(v.X),
					DegreesToRadians(v.Z));
				edit.SetLocalTransform(id, current);
			}, category);
		AddEditor(rotation, new [=edit, =id, =rotation]() =>
		{
			rotation.SetValue(EulerDegrees(edit.Scene.GetLocalTransform(edit.Resolve(id)).Rotation));
		});

		let scale = new Float3Editor("Scale", t.Scale, -100000.0f, 100000.0f, 0.1f,
			new [=edit, =id](v) =>
			{
				var current = edit.Scene.GetLocalTransform(edit.Resolve(id));
				current.Scale = v;
				edit.SetLocalTransform(id, current);
			}, category);
		AddEditor(scale, new [=edit, =id, =scale]() =>
		{
			scale.SetValue(edit.Scene.GetLocalTransform(edit.Resolve(id)).Scale);
		});
	}

	/// Pitch, yaw, roll as degrees on X, Y, Z.
	public static Float3 EulerDegrees(Quaternion q)
	{
		float yaw = ?, pitch = ?, roll = ?;
		ToYawPitchRoll(q, out yaw, out pitch, out roll);
		return .(RadiansToDegrees(pitch), RadiansToDegrees(yaw), RadiansToDegrees(roll));
	}
}
