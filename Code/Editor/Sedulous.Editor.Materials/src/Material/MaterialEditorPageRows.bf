using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Shaders.Resource;
using Sedulous.Texture.Resource;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Materials;

/// The rows, laid out from the material's shader table in three sections: the material's (its
/// shader a reference, the built-in while there is none, the pipeline state), each property its
/// shader declares by its type, and each texture slot. A grid's commit is one undo step.
extension MaterialEditorPage
{
	private static readonly StringView[6] cBlendItems = .("Opaque", "Masked", "AlphaBlend", "Additive", "Multiply", "PremultipliedAlpha");
	private static readonly StringView[4] cDepthItems = .("Disabled", "ReadWrite", "ReadOnly", "WriteOnly");
	private static readonly StringView[3] cCullItems = .("None", "Back", "Front");
	private static readonly StringView[2] cBuiltIns = .("PBR", "Unlit");
	/// A number's parts, by their names in a group.
	private static readonly StringView[4] cParts = .("x", "y", "z", "w");

	/// The rows made again from the source, under their sections.
	private void BuildRows()
	{
		ClearSections(); // the grid lets go of the old rows before they go
		DeleteRows();
		mMaterialRows = new Sedulous.GUI.PropertyBag();
		mPropertyRows = new Sedulous.GUI.PropertyBag();
		mTextureRows = new Sedulous.GUI.PropertyBag();
		let asset = Edited;
		if (asset == null)
			return;
		let src = asset.Source;

		// The shader: a shader asset, or a built-in (PBR or Unlit) while it is on none.
		{
			let shader = mMaterialRows.Add("shader", .Reference);
			shader.DisplayName.Set("Shader");
			shader.Description.Set("A shader asset the material is drawn with; cleared, a built-in");
			shader.ReferenceType = typeof(ShaderResource);
			AddChoiceRow(mMaterialRows, "builtIn", "Built-in", cBuiltIns);
			AddChoiceRow(mMaterialRows, "blend", "Blend", cBlendItems);
			AddChoiceRow(mMaterialRows, "depth", "Depth", cDepthItems);
			AddChoiceRow(mMaterialRows, "cull", "Cull", cCullItems);
		}

		// Each value its shader declares, by its type.
		let path = scope String();
		for (int i = 0; (i < src.PropertyNames.Count) && (i < src.PropertyTypes.Count); i++)
		{
			let row = MaterialPropertyRow.For((MaterialPropertyType)src.PropertyTypes[i]);
			let name = src.PropertyNames[i];
			let rows = (row == .Texture) ? mTextureRows : mPropertyRows;
			PropertyInfo info = null;
			switch (row)
			{
			case .None:
				continue; // a sampler has no value to edit (the material system binds it)
			case .Number:
				info = rows.Add(name, .Float);
				// A shader asset's property declares its range; the standard PBR factors are 0..1
				// (the normal scale 0..2); any other float is unbounded.
				let ranged = ShaderRange(name, let min, let max);
				let zeroToOne = (name == "Metallic") || (name == "Roughness") || (name == "OcclusionStrength") || (name == "AlphaCutoff");
				if (ranged || zeroToOne || (name == "NormalScale"))
				{
					info.HasRange = true;
					info.Min = ranged ? min : 0.0;
					info.Max = ranged ? max : (zeroToOne ? 1.0 : 2.0);
					info.Hint.Set("slider"); // over its range, as the old page's were
				}
				info.Step = 0.01;
			case .Numbers2, .Numbers3, .Numbers4:
				let count = PartCount(row);
				info = rows.Add(name, .Group);
				info.Hint.AppendF("Float{}", count);
				for (int p < count)
				{
					path.Clear();
					JoinPropertyPath(name, cParts[p], path);
					rows.Add(path, .Float).Step = 0.01;
				}
			case .Integer:
				info = rows.Add(name, .Integer);
				if (ShaderRange(name, let lo, let hi))
				{
					info.HasRange = true;
					info.Min = lo;
					info.Max = hi;
				}
			case .Color:
				info = rows.Add(name, .Color);
			case .ColorWithIntensity:
				// A colour that may pass white: its colour as entered, its intensity in w (the
				// grid's HDR colour, as a field's parts are named).
				info = rows.Add(name, .Group);
				info.Hint.Set("ColorHdr");
				path.Clear();
				JoinPropertyPath(name, "color", path);
				rows.Add(path, .Color).ShowsAlpha = false;
				path.Clear();
				JoinPropertyPath(name, "intensity", path);
				let intensity = rows.Add(path, .Float);
				intensity.HasRange = true;
				intensity.Min = 0.0;
				intensity.Max = 1e6;
				intensity.Step = 0.05;
			case .Texture:
				// A texture or a render texture (a monitor's screen, a mirror): what makes a
				// Texture, asked of the builders.
				info = rows.Add(name, .Reference);
				info.ReferenceType = typeof(Texture);
			}
			if (info != null)
				PropertyNames.Prettify(name, info.DisplayName);
		}
		for (let rows in Sedulous.GUI.PropertyBag[3](mMaterialRows, mPropertyRows, mTextureRows))
		{
			rows.SetOnCommit(new [=this, =rows] (commit) =>
				{
					if (!commit.After.IsEmpty)
						Committed(rows, commit.Path, commit.After[0]);
				});
			// A gesture's previews shown live, as the old page's were: written to the source, the
			// preview material built again, no undo step until the commit.
			rows.SetOnPreview(new [=this, =rows] (path) =>
				{
					var value = rows.GetValue(path, 0);
					defer value.Dispose();
					mPreviewing = true;
					let reshow = mReshow;
					Committed(rows, path, value);
					mReshow = reshow; // the rows hold the preview already
					mPreviewing = false;
				});
			rows.SetOnCancel(new [=this] (path) => { CancelGesture(); });
			rows.PropertiesChanged(); // Add told the grid before the rows' names were set
		}
		ShowValues();
		AddSection("material", "Material", mMaterialRows);
		AddSection("properties", "Properties", mPropertyRows);
		AddSection("textures", "Textures", mTextureRows);
	}

	/// The three sections' rows let go; the grid let go of them first (ClearSections).
	private void DeleteRows()
	{
		DeleteAndNullify!(mMaterialRows);
		DeleteAndNullify!(mPropertyRows);
		DeleteAndNullify!(mTextureRows);
	}

	/// Each row's value from the source, where it differs; the preview bar's choices as they are.
	private void ShowValues()
	{
		let asset = Edited;
		if ((asset == null) || (mMaterialRows == null))
			return;
		let src = asset.Source;
		Show(mMaterialRows, "shader", Sedulous.GUI.Variant(GuidText(src.ShaderId, .. scope .())));
		Show(mMaterialRows, "builtIn", Sedulous.GUI.Variant((int64)((src.ShaderName == "unlit") ? 1 : 0)));
		if (let builtIn = mMaterialRows.FindInfo("builtIn"))
		{
			if (builtIn.Visible != src.ShaderId.IsNil)
			{
				builtIn.Visible = src.ShaderId.IsNil; // a built-in only while it is on no shader asset
				mMaterialRows.PropertiesChanged();
			}
		}
		Show(mMaterialRows, "blend", Sedulous.GUI.Variant((int64)src.BlendMode));
		Show(mMaterialRows, "depth", Sedulous.GUI.Variant((int64)src.DepthMode));
		Show(mMaterialRows, "cull", Sedulous.GUI.Variant((int64)src.CullMode));

		let path = scope String();
		for (int i = 0; (i < src.PropertyNames.Count) && (i < src.PropertyTypes.Count); i++)
		{
			let name = src.PropertyNames[i];
			let row = MaterialPropertyRow.For((MaterialPropertyType)src.PropertyTypes[i]);
			switch (row)
			{
			case .Number:
				Show(mPropertyRows, name, Sedulous.GUI.Variant((double)MaterialSourceEdit.ReadFloat(src, name)));
			case .Numbers2, .Numbers3, .Numbers4:
				let count = PartCount(row);
				float[4] parts = default;
				MaterialSourceEdit.ReadUniform(src, name, &parts[0], sizeof(float) * count);
				for (int p < count)
				{
					path.Clear();
					JoinPropertyPath(name, cParts[p], path);
					Show(mPropertyRows, path, Sedulous.GUI.Variant((double)parts[p]));
				}
			case .Integer:
				int32 integer = 0;
				MaterialSourceEdit.ReadUniform(src, name, &integer, sizeof(int32));
				Show(mPropertyRows, name, Sedulous.GUI.Variant((int64)integer));
			case .Color:
				let colour = MaterialSourceEdit.ReadFloat4(src, name);
				Show(mPropertyRows, name, Sedulous.GUI.Variant(Color(colour.X, colour.Y, colour.Z, colour.W)));
			case .ColorWithIntensity:
				let hdr = MaterialSourceEdit.ReadFloat4(src, name);
				path.Clear();
				JoinPropertyPath(name, "color", path);
				Show(mPropertyRows, path, Sedulous.GUI.Variant(Color(hdr.X, hdr.Y, hdr.Z, 1.0f)));
				path.Clear();
				JoinPropertyPath(name, "intensity", path);
				Show(mPropertyRows, path, Sedulous.GUI.Variant((double)hdr.W));
			case .Texture:
				Show(mTextureRows, name, Sedulous.GUI.Variant(GuidText(MaterialSourceEdit.TextureFor(src, name), .. scope .())));
			case .None:
			}
		}
		ShowPreviewChoices();
	}

	/// A grid's commit of `value` to row `path` of `rows`, one undo step (a shader switched,
	/// re-laid by its table).
	private void Committed(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		let asset = Edited;
		if (asset == null)
			return;
		mReshow = true; // what the edit did, or did not, shown
		if (rows === mMaterialRows)
		{
			let index = value.AsInt;
			switch (path)
			{
			case "shader": SwitchShader(GuidOf(value.AsString));
			case "builtIn": SwitchToBuiltIn(index == 1);
			case "blend": ApplyEdit("blend", scope [&] (s) => { s.BlendMode = (BlendMode)index; });
			case "depth": ApplyEdit("depth", scope [&] (s) => { s.DepthMode = (DepthMode)index; });
			case "cull": ApplyEdit("cull", scope [&] (s) => { s.CullMode = (CullModeConfig)index; });
			}
			return;
		}
		if (rows === mTextureRows)
		{
			// Pick, drop and clear are one write: nil removes the slot's binding.
			let picked = GuidOf(value.AsString);
			ApplyEdit(path, scope [&] (s) => { MaterialSourceEdit.SetTexture(s, path, picked); });
			return;
		}
		// A property, or one part of it ("Tint.x", "Emissive.intensity").
		let parent = ParentPropertyPath(path);
		let name = parent.IsEmpty ? path : parent;
		let part = (name.Length == path.Length) ? StringView() : path.Substring(name.Length + 1);
		var row = MaterialPropertyRow.None;
		for (int i = 0; (i < asset.Source.PropertyNames.Count) && (i < asset.Source.PropertyTypes.Count); i++)
		{
			if (asset.Source.PropertyNames[i] == name)
				row = MaterialPropertyRow.For((MaterialPropertyType)asset.Source.PropertyTypes[i]);
		}
		switch (row)
		{
		case .Number:
			let number = (float)value.AsFloat;
			ApplyEdit(name, scope [&] (s) => { MaterialSourceEdit.WriteFloat(s, name, number); });
		case .Integer:
			var integer = (int32)value.AsInt;
			ApplyEdit(name, scope [&] (s) => { MaterialSourceEdit.WriteUniform(s, name, &integer, sizeof(int32)); });
		case .Numbers2, .Numbers3, .Numbers4:
			let count = PartCount(row);
			let index = PartIndex(part);
			if ((index >= 0) && (index < count))
			{
				float[4] parts = default;
				MaterialSourceEdit.ReadUniform(asset.Source, name, &parts[0], sizeof(float) * count);
				parts[index] = (float)value.AsFloat;
				ApplyEdit(name, scope [&] (s) => { MaterialSourceEdit.WriteUniform(s, name, &parts[0], sizeof(float) * count); });
			}
		case .Color:
			let colour = value.AsColor;
			ApplyEdit(name, scope [&] (s) => { MaterialSourceEdit.WriteFloat4(s, name, .(colour.R, colour.G, colour.B, colour.A)); });
		case .ColorWithIntensity:
			var hdr = MaterialSourceEdit.ReadFloat4(asset.Source, name);
			if (part == "color")
			{
				let picked = value.AsColor;
				hdr = .(picked.R, picked.G, picked.B, hdr.W);
			}
			else if (part == "intensity")
				hdr.W = (float)value.AsFloat;
			ApplyEdit(name, scope [&] (s) => { MaterialSourceEdit.WriteFloat4(s, name, hdr); });
		default:
		}
	}

	/// The range the shader asset declares for `name`, when it declares one.
	private bool ShaderRange(StringView name, out double min, out double max)
	{
		min = 0.0;
		max = 1.0;
		for (let property in mShaderTable)
		{
			if ((property.Name == name) && property.HasRange)
			{
				min = property.RangeMin;
				max = property.RangeMax;
				return true;
			}
		}
		return false;
	}

	// `value` shown in row `path` of `rows` where it differs.
	private static void Show(Sedulous.GUI.PropertyBag rows, StringView path, Sedulous.GUI.Variant value)
	{
		if (rows.FindInfo(path) == null)
			return;
		var now = rows.GetValue(path, 0);
		defer now.Dispose();
		if ((now.Kind != value.Kind) || (now.Compare(value) != 0))
			rows.SetValue(path, 0, value);
	}

	// An enum row named `label`, its choices `items` by their index.
	private static void AddChoiceRow(Sedulous.GUI.PropertyBag rows, StringView path, StringView label, Span<StringView> items)
	{
		let info = rows.Add(path, .Enum);
		info.DisplayName.Set(label);
		for (int i < items.Length)
			info.AddChoice(items[i], i);
	}

	private static int PartCount(MaterialPropertyRow row) => (row == .Numbers2) ? 2 : ((row == .Numbers3) ? 3 : 4);

	// A number's part by its name in a group (x, y, z, w); -1 when it is none.
	private static int PartIndex(StringView part)
	{
		for (int i < cParts.Count)
		{
			if (part == cParts[i])
				return i;
		}
		return -1;
	}

	// A reference row's text: the guid, empty for none.
	private static void GuidText(Guid id, String outText)
	{
		if (!id.IsNil)
			id.ToString(outText);
	}

	private static Guid GuidOf(StringView text)
	{
		var trimmed = text;
		trimmed.Trim();
		if (!trimmed.IsEmpty && (Guid.Parse(trimmed) case .Ok(let id)))
			return id;
		return .();
	}
}
