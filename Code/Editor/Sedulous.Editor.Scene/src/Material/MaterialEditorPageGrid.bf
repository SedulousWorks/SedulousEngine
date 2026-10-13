using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.UI.Toolkit;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Scene;

/// The grid half: the shader (an asset, or a built-in), the preview shape and mesh rows, the
/// pipeline presets, then one row per declared property: a slider or a float for scalars, a
/// row of its size for each vector and int, a colour for declared colours, a picker for
/// textures.
extension MaterialEditorPage
{
	private static readonly StringView[6] cBlendItems = .("Opaque", "Masked", "AlphaBlend", "Additive", "Multiply", "PremultipliedAlpha");
	private static readonly StringView[4] cDepthItems = .("Disabled", "ReadWrite", "ReadOnly", "WriteOnly");
	private static readonly StringView[3] cCullItems = .("None", "Back", "Front");
	private static readonly StringView[2] cBuiltIns = .("PBR", "Unlit");

	private void RebuildGrid()
	{
		mGrid.Clear();
		ClearAndDeleteItems!(mRefreshers);
		if (mAsset == null)
			return;
		let src = mAsset.Source;

		// The shader: a shader asset, or nil for a built-in (PBR or Unlit, picked below).
		let shader = new ResourceRefEditor("Shader", AssetNameFor(src.ShaderId), "Material", scope StringView[]("ShaderAsset"));
		shader.EmptyText.Set("(built-in)");
		shader.BindAsset(mContext, new [=this]() => (mAsset != null) ? mAsset.Source.ShaderId : Guid(),
			new [=this](picked) => SwitchShader(picked));
		AddEditor(shader, new [=shader]() => { shader.Refresh(); });
		if (src.ShaderId.IsNil)
		{
			let builtIn = new EnumEditor("Built-in", (src.ShaderName == "unlit") ? 1 : 0, cBuiltIns,
				new [=this](index) => SwitchToBuiltIn(index == 1), "Material");
			AddEditor(builtIn, new [=this, =builtIn]() =>
				{
					if (mAsset != null)
						builtIn.SetValue((mAsset.Source.ShaderName == "unlit") ? 1 : 0);
				});
		}

		let shape = new EnumEditor("Shape", (int32)mPreviewShape, MaterialPreviewShapes.Names, new (index) =>
			{
				mPreviewShape = (uint32)Math.Max(0, index);
				mPreviewMeshGuid = Guid(); // a shape pick overrides an asset mesh
				ApplyPreviewMesh();
				SavePreviewPref();
			}, "Preview");
		mGrid.AddProperty(shape);

		let meshRow = new ResourceRefEditor("Mesh", PreviewMeshName(), "Preview", scope StringView[]("StaticMeshAsset", "SkinnedMeshAsset"));
		meshRow.EmptyText.Set(PreviewMeshName());
		meshRow.BindAsset(mContext, new [=this]() => mPreviewMeshGuid, new [=this](picked) =>
			{
				mPreviewMeshGuid = picked; // nil (Clear) = back to the primitive
				ApplyPreviewMesh();
				SavePreviewPref();
			});
		AddEditor(meshRow, new [=this, =meshRow]() =>
			{
				meshRow.EmptyText.Set(PreviewMeshName());
				meshRow.Refresh();
			});

		AddPipelineEnumRow("Blend", cBlendItems, new (s) => (int32)s.BlendMode, new (s, v) => s.BlendMode = (BlendMode)v);
		AddPipelineEnumRow("Depth", cDepthItems, new (s) => (int32)s.DepthMode, new (s, v) => s.DepthMode = (DepthMode)v);
		AddPipelineEnumRow("Cull", cCullItems, new (s) => (int32)s.CullMode, new (s, v) => s.CullMode = (CullModeConfig)v);

		for (int i < src.PropertyNames.Count)
		{
			let type = (i < src.PropertyTypes.Count) ? (MaterialPropertyType)src.PropertyTypes[i] : MaterialPropertyType.Float;
			// A copy: the grid outlives rebuilds of the source's arrays.
			let name = Own(new String(src.PropertyNames[i]));
			switch (MaterialPropertyRow.For(type))
			{
			case .Number: AddFloatRow(name);
			case .Numbers2: AddFloat2Row(name);
			case .Numbers3: AddFloat3Row(name);
			case .Numbers4: AddFloat4Row(name);
			case .Integer: AddIntRow(name);
			case .Color: AddColorRow(name, false);
			case .ColorWithIntensity: AddColorRow(name, true);
			case .Texture: AddTextureRow(name);
			case .None:
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
		// The standard PBR factors are all 0..1; a shader asset's property declares its own range.
		let ranged = ShaderRange(name, var min, var max);
		let zeroToOne = (name == "Metallic") || (name == "Roughness") || (name == "OcclusionStrength") || (name == "AlphaCutoff");
		let zeroToTwo = name == "NormalScale";
		if (!ranged && zeroToTwo)
			max = 2.0f;
		let label = PropertyNames.Prettify(name, .. scope .());
		if (ranged || zeroToOne || zeroToTwo)
		{
			let editor = new RangeEditor(name, ReadFloat(name), min, max, 0.01f, new [=this, =name](v) =>
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

	private void AddFloat2Row(String name)
	{
		let editor = new Float2Editor(name, Read<Float2>(name), -100000.0f, 100000.0f, 0.01f, new [=this, =name](v) =>
			{
				ApplyEdit(name, new [=name, =v](s) => { var value = v; MaterialSourceEdit.WriteUniform(s, name, &value, sizeof(Float2)); });
			}, "Properties");
		editor.SetDisplayName(PropertyNames.Prettify(name, .. scope .()));
		AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(Read<Float2>(name)));
	}

	private void AddFloat3Row(String name)
	{
		let editor = new Float3Editor(name, Read<Float3>(name), -100000.0f, 100000.0f, 0.01f, new [=this, =name](v) =>
			{
				ApplyEdit(name, new [=name, =v](s) => { var value = v; MaterialSourceEdit.WriteUniform(s, name, &value, sizeof(Float3)); });
			}, "Properties");
		editor.SetDisplayName(PropertyNames.Prettify(name, .. scope .()));
		AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(Read<Float3>(name)));
	}

	/// An int as the shader reads it; a shader asset's int may declare its range.
	private void AddIntRow(String name)
	{
		var min = (int64)int32.MinValue;
		var max = (int64)int32.MaxValue;
		if (ShaderRange(name, let lo, let hi))
		{
			min = (int64)lo;
			max = (int64)hi;
		}
		let editor = new IntEditor(name, Read<int32>(name), min, max, new [=this, =name](v) =>
			{
				var value = (int32)v;
				ApplyEdit(name, new [=name, =value](s) => { var stored = value; MaterialSourceEdit.WriteUniform(s, name, &stored, sizeof(int32)); });
			}, "Properties");
		editor.SetDisplayName(PropertyNames.Prettify(name, .. scope .()));
		AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(Read<int32>(name)));
	}

	/// Plain numbers: only a declared colour property gets a colour picker.
	private void AddFloat4Row(String name)
	{
		let editor = new Float4Editor(name, ReadFloat4(name), -100000.0f, 100000.0f, 0.01f, new [=this, =name](v) =>
			{
				ApplyEdit(name, new [=name, =v](s) => MaterialSourceEdit.WriteFloat4(s, name, v));
			}, "Properties");
		editor.SetDisplayName(PropertyNames.Prettify(name, .. scope .()));
		AddEditor(editor, new [=this, =editor, =name]() => editor.SetValue(ReadFloat4(name)));
	}

	/// The colour as entered (sRGB, what the picker shows). A ColorHdr keeps its intensity in
	/// w, edited on its own row, so the picker's alpha is not it.
	private void AddColorRow(String name, bool hdr)
	{
		let editor = new ColorEditor(name, ReadColor(name, hdr), new [=this, =name, =hdr](c) =>
			{
				let v = Float4(c.R, c.G, c.B, hdr ? ReadFloat4(name).W : c.A);
				ApplyEdit(name, new [=name, =v](s) => MaterialSourceEdit.WriteFloat4(s, name, v));
			}, "Properties");
		editor.SetDisplayName(PropertyNames.Prettify(name, .. scope .()));
		AddEditor(editor, new [=this, =editor, =name, =hdr]() => editor.SetValue(ReadColor(name, hdr)));
		if (!hdr)
			return;

		let intensityName = Own(new String(name)..Append("Intensity"));
		let intensity = new FloatEditor(intensityName, ReadFloat4(name).W, 0.0, 1e6, 0.05, 3, new [=this, =name](i) =>
			{
				var v = ReadFloat4(name);
				v.W = (float)i;
				ApplyEdit(name, new [=name, =v](s) => MaterialSourceEdit.WriteFloat4(s, name, v));
			}, "Properties");
		intensity.SetDisplayName(PropertyNames.Prettify(intensityName, .. scope .()));
		AddEditor(intensity, new [=this, =intensity, =name]() => intensity.SetValue(ReadFloat4(name).W));
	}

	private void AddTextureRow(String slot)
	{
		// A render texture samples like any texture (a monitor's screen, a mirror).
		let editor = new ResourceRefEditor(slot, AssetNameFor(MaterialSourceEdit.TextureFor(mAsset.Source, slot)), "Textures",
			scope StringView[]("TextureAsset", "RenderTextureAsset"));
		editor.SetDisplayName(PropertyNames.Prettify(slot, .. scope .()));
		editor.BindAsset(mContext, new [=this, =slot]() => (mAsset != null) ? MaterialSourceEdit.TextureFor(mAsset.Source, slot) : Guid(),
			new [=this, =slot](picked) => { ApplyEdit(slot, new [=slot, =picked](s) => MaterialSourceEdit.SetTexture(s, slot, picked)); });
		AddEditor(editor, new [=editor]() => { editor.Refresh(); });
	}

	/// A uniform read as `T`, zero when the source lacks it.
	private T Read<T>(StringView name) where T : struct
	{
		var value = default(T);
		if (mAsset != null)
			MaterialSourceEdit.ReadUniform(mAsset.Source, name, &value, sizeof(T));
		return value;
	}

	private float ReadFloat(StringView name) => (mAsset != null) ? MaterialSourceEdit.ReadFloat(mAsset.Source, name) : 0.0f;

	private Float4 ReadFloat4(StringView name) => (mAsset != null) ? MaterialSourceEdit.ReadFloat4(mAsset.Source, name) : Float4(1, 1, 1, 1);

	private Color ReadColor(StringView name, bool hdr)
	{
		let v = ReadFloat4(name);
		return .(v.X, v.Y, v.Z, hdr ? 1.0f : v.W);
	}
}
