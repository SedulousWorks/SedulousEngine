using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The grid half: the shader line, the preview shape and mesh rows, the pipeline presets,
/// then one row per declared property: a slider or a float for scalars, a colour for
/// float4s, a picker for textures.
extension MaterialEditorPage
{
	private static readonly StringView[6] cBlendItems = .("Opaque", "Masked", "AlphaBlend", "Additive", "Multiply", "PremultipliedAlpha");
	private static readonly StringView[4] cDepthItems = .("Disabled", "ReadWrite", "ReadOnly", "WriteOnly");
	private static readonly StringView[3] cCullItems = .("None", "Back", "Front");

	private void RebuildGrid()
	{
		mGrid.Clear();
		ClearAndDeleteItems!(mRefreshers);
		if (mAsset == null)
			return;
		let src = mAsset.Source;

		let shaderShown = src.ShaderName.IsEmpty ? "(shader asset)" : StringView(src.ShaderName);
		mGrid.AddProperty(new StringEditor("Shader", shaderShown, null, "Material"));

		let shape = new EnumEditor("Shape", (int32)mPreviewShape, MaterialPreviewShapes.Names, new (index) =>
			{
				mPreviewShape = (uint32)Math.Max(0, index);
				mPreviewMeshGuid = Guid(); // a shape pick overrides an asset mesh
				ApplyPreviewMesh();
				SavePreviewPref();
			}, "Preview");
		mGrid.AddProperty(shape);

		let meshRow = new ResourceRefEditor("Mesh", PreviewMeshName(), "Preview");
		meshRow.OnPick = new [=this, =meshRow]() =>
			{
				let ctx = Ctx;
				if ((ctx == null) || (mContext.Project == null))
					return;
				let dialog = new AssetPickerDialog(mContext, scope StringView[]("StaticMeshAsset", "SkinnedMeshAsset"));
				dialog.OnPicked = new [=this, =meshRow](picked) =>
					{
						mPreviewMeshGuid = picked; // nil (Clear) = back to the primitive
						ApplyPreviewMesh();
						SavePreviewPref();
						meshRow.SetValueText(PreviewMeshName());
					};
				dialog.Show(ctx);
			};
		mGrid.AddProperty(meshRow);

		AddPipelineEnumRow("Blend", cBlendItems, new (s) => (int32)s.BlendMode, new (s, v) => s.BlendMode = (BlendMode)v);
		AddPipelineEnumRow("Depth", cDepthItems, new (s) => (int32)s.DepthMode, new (s, v) => s.DepthMode = (DepthMode)v);
		AddPipelineEnumRow("Cull", cCullItems, new (s) => (int32)s.CullMode, new (s, v) => s.CullMode = (CullModeConfig)v);

		for (int i < src.PropertyNames.Count)
		{
			let type = (i < src.PropertyTypes.Count) ? (MaterialPropertyType)src.PropertyTypes[i] : MaterialPropertyType.Float;
			// A copy: the grid outlives rebuilds of the source's arrays.
			let name = Own(new String(src.PropertyNames[i]));
			switch (type)
			{
			case .Float: AddFloatRow(name);
			case .Float4: AddColorRow(name);
			case .Texture2D, .TextureCube: AddTextureRow(name);
			default:
			}
		}
	}

	private StringView PreviewMeshName()
	{
		if (mPreviewMeshGuid.IsNil)
			return "(primitive)";
		if (mContext.Project != null)
		{
			if (let inst = mContext.Project.SourceDb.GetInstance(mPreviewMeshGuid))
				return inst.Name;
		}
		return "(missing)";
	}

	private void AddPipelineEnumRow(StringView label, Span<StringView> items,
		delegate int32(MaterialSource) read, delegate void(MaterialSource, int32) write)
	{
		Own(read);
		Own(write);
		let key = Own(new String(label));
		let editor = new EnumEditor(label, read(mAsset.Source), items, new [=this, =key, =write](index) =>
			{
				ApplyEdit(key, new [=write, =index](s) => write(s, index));
			}, "Material");
		AddEditor(editor, new [=this, =editor, =read]() =>
			{
				if (mAsset != null)
					editor.SetValue(read(mAsset.Source));
			});
	}

	private void AddFloatRow(String name)
	{
		let zeroToOne = (name == "Metallic") || (name == "Roughness") || (name == "OcclusionStrength") || (name == "AlphaCutoff");
		let zeroToTwo = name == "NormalScale";
		let label = PropertyNames.Prettify(name, .. scope .());
		if (zeroToOne || zeroToTwo)
		{
			let editor = new RangeEditor(name, ReadFloat(name), 0.0f, zeroToTwo ? 2.0f : 1.0f, 0.01f, new [=this, =name](v) =>
				{
					ApplyEdit(name, new [=name, =v](s) => MaterialSourceEdit.WriteFloat(s, name, v));
				}, "Properties");
			editor.SetDisplayName(label);
			AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(ReadFloat(name)));
			return;
		}
		let editor = new FloatEditor(name, ReadFloat(name), 0.0, 1e9, 0.01, 3, new [=this, =name](v) =>
			{
				let f = (float)v;
				ApplyEdit(name, new [=name, =f](s) => MaterialSourceEdit.WriteFloat(s, name, f));
			}, "Properties");
		editor.SetDisplayName(label);
		AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(ReadFloat(name)));
	}

	private void AddColorRow(String name)
	{
		let editor = new ColorEditor(name, ReadColor(name), new [=this, =name](c) =>
			{
				let v = Float4(c.R, c.G, c.B, c.A);
				ApplyEdit(name, new [=name, =v](s) => MaterialSourceEdit.WriteFloat4(s, name, v));
			}, "Properties");
		editor.SetDisplayName(PropertyNames.Prettify(name, .. scope .()));
		AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(ReadColor(name)));
	}

	private void AddTextureRow(String slot)
	{
		let editor = new ResourceRefEditor(slot, AssetNameFor(MaterialSourceEdit.TextureFor(mAsset.Source, slot)), "Textures");
		editor.SetDisplayName(PropertyNames.Prettify(slot, .. scope .()));
		editor.OnPick = new [=this, =slot]() =>
			{
				let ctx = Ctx;
				if ((ctx == null) || (mContext.Project == null))
					return;
				let dialog = new AssetPickerDialog(mContext, scope StringView[]("TextureAsset"));
				dialog.OnPicked = new [=this, =slot](picked) =>
					{
						ApplyEdit(slot, new [=slot, =picked](s) => MaterialSourceEdit.SetTexture(s, slot, picked));
					};
				dialog.Show(ctx);
			};
		AddEditor(editor, new [=this, =editor, =slot]() =>
			{
				if (mAsset != null)
					editor.SetValueText(AssetNameFor(MaterialSourceEdit.TextureFor(mAsset.Source, slot)));
			});
	}

	private float ReadFloat(StringView name) => (mAsset != null) ? MaterialSourceEdit.ReadFloat(mAsset.Source, name) : 0.0f;

	private Color ReadColor(StringView name)
	{
		let v = (mAsset != null) ? MaterialSourceEdit.ReadFloat4(mAsset.Source, name) : Float4(1, 1, 1, 1);
		return .(v.X, v.Y, v.Z, v.W);
	}
}
