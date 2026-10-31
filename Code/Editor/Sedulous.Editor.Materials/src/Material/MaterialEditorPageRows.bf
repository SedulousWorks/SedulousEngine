using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Materials;
using Sedulous.Materials.Resource;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.Texture.Resource;
using Sedulous.GUI;
using Sedulous.Editor.App;

namespace Sedulous.Editor.Materials;

/// The rows, laid out from the material's shader table in three sections: the material's (its
/// shader a reference, the built-in while there is none, the pipeline state), each property its
/// shader declares by its type, and each texture slot; then a section per effect group the
/// material carries. A grid's commit is one undo step.
extension MaterialEditorPage
{
	private static readonly StringView[6] cBlendItems = .("Opaque", "Masked", "AlphaBlend", "Additive", "Multiply", "PremultipliedAlpha");
	private static readonly StringView[4] cDepthItems = .("Disabled", "ReadWrite", "ReadOnly", "WriteOnly");
	private static readonly StringView[3] cCullItems = .("None", "Back", "Front");
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

		// The shader: a shader asset, or a built-in (PBR, Unlit or Phong) while it is on none.
		{
			let shader = mMaterialRows.Add("shader", .Reference);
			shader.DisplayName.Set("Shader");
			shader.Description.Set("A shader asset the material is drawn with; cleared, a built-in");
			shader.ReferenceType = typeof(ShaderResource);
			// The built-ins by their labels, in BuiltinShading's order.
			StringView[MaterialPresets.cBuiltinShadingCount] builtIns = default;
			for (int i < builtIns.Count)
				builtIns[i] = MaterialPresets.BuiltinShadings[i].Label;
			AddChoiceRow(mMaterialRows, "builtIn", "Built-in", builtIns);
			AddChoiceRow(mMaterialRows, "blend", "Blend", cBlendItems);
			AddChoiceRow(mMaterialRows, "depth", "Depth", cDepthItems);
			AddChoiceRow(mMaterialRows, "cull", "Cull", cCullItems);
		}

		// Each value its shader declares, by its type.
		for (int i = 0; (i < src.PropertyNames.Count) && (i < src.PropertyTypes.Count); i++)
		{
			let row = MaterialPropertyRow.For((MaterialPropertyType)src.PropertyTypes[i]);
			let name = src.PropertyNames[i];
			if (row == .None)
				continue; // a sampler has no value to edit (the material system binds it)
			if (row == .Texture)
			{
				// A texture or a render texture (a monitor's screen, a mirror): what makes a
				// Texture, asked of the builders.
				let slot = mTextureRows.Add(name, .Reference);
				slot.ReferenceType = typeof(Texture);
				PropertyNames.Prettify(name, slot.DisplayName);
				continue;
			}
			// A shader asset's property declares its range.
			ShaderProperty declared = null;
			for (let property in mShaderTable)
			{
				if (property.Name == name)
					declared = property;
			}
			AddValueRow(mPropertyRows, name, row, declared);
			let info = mPropertyRows.FindInfo(name);
			if (info == null)
				continue;
			// The standard PBR factors are 0..1 (the normal scale 0..2); any other float a shader
			// gives no range is unbounded.
			let zeroToOne = (name == "Metallic") || (name == "Roughness") || (name == "OcclusionStrength") || (name == "AlphaCutoff");
			if ((row == .Number) && !info.HasRange && (zeroToOne || (name == "NormalScale")))
			{
				info.HasRange = true;
				info.Min = 0.0;
				info.Max = zeroToOne ? 1.0 : 2.0;
				info.Hint.Set("slider"); // over its range, as the old page's were
			}
			PropertyNames.Prettify(name, info.DisplayName);
		}

		// Each effect group the material carries (Wind), a section of its own: its rows from the
		// effect's table, as a custom shader's properties are, with the table's ranges when the
		// page has the shader system serving it; else the group's own layout, unbounded.
		for (let group in src.Effects)
		{
			let rows = new Sedulous.GUI.PropertyBag();
			let table = (mEffectSystem != null) ? mEffectSystem.FindEffect(group.Name) : null;
			for (int i = 0; (i < group.PropertyNames.Count) && (i < group.PropertyTypes.Count); i++)
			{
				let name = group.PropertyNames[i];
				let row = MaterialPropertyRow.For((MaterialPropertyType)group.PropertyTypes[i]);
				if ((row == .None) || (row == .Texture))
					continue; // an effect takes uniforms only
				AddValueRow(rows, name, row, (table != null) ? table.FindProperty(name) : null);
				if (let info = rows.FindInfo(name))
					PropertyNames.Prettify(name, info.DisplayName);
			}
			mEffectRows.Add(rows);
			mEffectRowNames.Add(new String(group.Name));
		}
		let bags = scope List<Sedulous.GUI.PropertyBag>();
		bags.Add(mMaterialRows);
		bags.Add(mPropertyRows);
		bags.Add(mTextureRows);
		bags.AddRange(mEffectRows);
		for (let rows in bags)
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
		// After the shader's own: an effect's values are the material's, not its shader's.
		for (int g < mEffectRows.Count)
			AddSection(scope String()..AppendF("effect-{}", mEffectRowNames[g]), mEffectRowNames[g], mEffectRows[g]);
	}

	/// The sections' rows let go; the grid let go of them first (ClearSections).
	private void DeleteRows()
	{
		DeleteAndNullify!(mMaterialRows);
		DeleteAndNullify!(mPropertyRows);
		DeleteAndNullify!(mTextureRows);
		ClearAndDeleteItems!(mEffectRows);
		ClearAndDeleteItems!(mEffectRowNames);
	}

	/// A value's row by its type, at `path` of `rows`: one way for the shader's properties and an
	/// effect group's parameters. `declared` (the shader's or the effect's) gives its range.
	private static void AddValueRow(Sedulous.GUI.PropertyBag rows, StringView path, MaterialPropertyRow row, ShaderProperty declared)
	{
		let ranged = (declared != null) && declared.HasRange;
		let part = scope String();
		switch (row)
		{
		case .Number:
			let info = rows.Add(path, .Float);
			if (ranged)
			{
				info.HasRange = true;
				info.Min = declared.RangeMin;
				info.Max = declared.RangeMax;
				info.Hint.Set("slider"); // over its range, as the old page's were
			}
			info.Step = 0.01;
		case .Numbers2, .Numbers3, .Numbers4:
			let count = PartCount(row);
			let group = rows.Add(path, .Group);
			group.Hint.AppendF("Float{}", count);
			for (int p < count)
			{
				part.Clear();
				JoinPropertyPath(path, cParts[p], part);
				rows.Add(part, .Float).Step = 0.01;
			}
		case .Integer:
			let integer = rows.Add(path, .Integer);
			if (ranged)
			{
				integer.HasRange = true;
				integer.Min = declared.RangeMin;
				integer.Max = declared.RangeMax;
			}
		case .Color:
			rows.Add(path, .Color);
		case .ColorWithIntensity:
			// A colour that may pass white: its colour as entered, its intensity in w (the
			// grid's HDR colour, as a field's parts are named).
			let hdr = rows.Add(path, .Group);
			hdr.Hint.Set("ColorHdr");
			JoinPropertyPath(path, "color", part);
			rows.Add(part, .Color).ShowsAlpha = false;
			part.Clear();
			JoinPropertyPath(path, "intensity", part);
			let intensity = rows.Add(part, .Float);
			intensity.HasRange = true;
			intensity.Min = 0.0;
			intensity.Max = 1e6;
			intensity.Step = 0.05;
		default:
			// a texture's row is a slot (BuildRows); a sampler has none
		}
	}

	/// Each row's value from the source, where it differs; the preview bar's choices as they are.
	private void ShowValues()
	{
		let asset = Edited;
		if ((asset == null) || (mMaterialRows == null))
			return;
		let src = asset.Source;
		Show(mMaterialRows, "shader", Sedulous.GUI.Variant(GuidText(src.ShaderId, .. scope .())));
		let builtin = MaterialPresets.FindBuiltinShadingByShader(src.ShaderName);
		Show(mMaterialRows, "builtIn", Sedulous.GUI.Variant((int64)(builtin.HasValue ? (int)builtin.Value.Shading : 0)));
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

		for (int i = 0; (i < src.PropertyNames.Count) && (i < src.PropertyTypes.Count); i++)
		{
			let name = src.PropertyNames[i];
			let row = MaterialPropertyRow.For((MaterialPropertyType)src.PropertyTypes[i]);
			if (row == .Texture)
				Show(mTextureRows, name, Sedulous.GUI.Variant(GuidText(MaterialSourceEdit.TextureFor(src, name), .. scope .())));
			else
				ShowValue(src, mPropertyRows, name, name, row);
		}
		// Each effect group's values, addressed as `Effect.Property`.
		let qualified = scope String();
		for (int g < mEffectRows.Count)
		{
			for (let group in src.Effects)
			{
				if (group.Name != mEffectRowNames[g])
					continue;
				for (int i = 0; (i < group.PropertyNames.Count) && (i < group.PropertyTypes.Count); i++)
				{
					let name = group.PropertyNames[i];
					qualified..Clear().AppendF("{}.{}", group.Name, name);
					ShowValue(src, mEffectRows[g], name, qualified, MaterialPropertyRow.For((MaterialPropertyType)group.PropertyTypes[i]));
				}
			}
		}
		ShowPreviewChoices();
	}

	/// The value `name` addresses (`Metallic`, `Wind.Strength`) shown in row `path` of `rows`, by
	/// its type.
	private static void ShowValue(MaterialSource src, Sedulous.GUI.PropertyBag rows, StringView path, StringView name, MaterialPropertyRow row)
	{
		let part = scope String();
		switch (row)
		{
		case .Number:
			Show(rows, path, Sedulous.GUI.Variant((double)MaterialSourceEdit.ReadFloat(src, name)));
		case .Numbers2, .Numbers3, .Numbers4:
			let count = PartCount(row);
			float[4] parts = default;
			MaterialSourceEdit.ReadUniform(src, name, &parts[0], sizeof(float) * count);
			for (int p < count)
			{
				part.Clear();
				JoinPropertyPath(path, cParts[p], part);
				Show(rows, part, Sedulous.GUI.Variant((double)parts[p]));
			}
		case .Integer:
			int32 integer = 0;
			MaterialSourceEdit.ReadUniform(src, name, &integer, sizeof(int32));
			Show(rows, path, Sedulous.GUI.Variant((int64)integer));
		case .Color:
			let colour = MaterialSourceEdit.ReadFloat4(src, name);
			Show(rows, path, Sedulous.GUI.Variant(Color(colour.X, colour.Y, colour.Z, colour.W)));
		case .ColorWithIntensity:
			let hdr = MaterialSourceEdit.ReadFloat4(src, name);
			JoinPropertyPath(path, "color", part);
			Show(rows, part, Sedulous.GUI.Variant(Color(hdr.X, hdr.Y, hdr.Z, 1.0f)));
			part.Clear();
			JoinPropertyPath(path, "intensity", part);
			Show(rows, part, Sedulous.GUI.Variant((double)hdr.W));
		default:
		}
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
			case "builtIn":
				if ((index >= 0) && (index < MaterialPresets.cBuiltinShadingCount))
					SwitchToBuiltIn((BuiltinShading)index);
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
		// A value, or one part of it ("Tint.x", "Emissive.intensity").
		let parent = ParentPropertyPath(path);
		let name = parent.IsEmpty ? path : parent;
		let part = (name.Length == path.Length) ? StringView() : path.Substring(name.Length + 1);
		let src = asset.Source;
		if (rows === mPropertyRows)
		{
			var row = MaterialPropertyRow.None;
			for (int i = 0; (i < src.PropertyNames.Count) && (i < src.PropertyTypes.Count); i++)
			{
				if (src.PropertyNames[i] == name)
					row = MaterialPropertyRow.For((MaterialPropertyType)src.PropertyTypes[i]);
			}
			CommitValue(name, part, row, value);
			return;
		}
		// An effect group's parameter, written as `Effect.Property` into the group's values.
		for (int g < mEffectRows.Count)
		{
			if (rows !== mEffectRows[g])
				continue;
			for (let group in src.Effects)
			{
				if (group.Name != mEffectRowNames[g])
					continue;
				for (int i = 0; (i < group.PropertyNames.Count) && (i < group.PropertyTypes.Count); i++)
				{
					if (group.PropertyNames[i] != name)
						continue;
					let qualified = scope String()..AppendF("{}.{}", group.Name, name);
					CommitValue(qualified, part, MaterialPropertyRow.For((MaterialPropertyType)group.PropertyTypes[i]), value);
					return;
				}
			}
			return;
		}
	}

	/// An edit of the value `name` addresses (`Metallic`, `Wind.Strength`), or of its `part`, one
	/// undo step merged per value.
	private void CommitValue(StringView name, StringView part, MaterialPropertyRow row, Sedulous.GUI.Variant value)
	{
		let asset = Edited;
		if (asset == null)
			return;
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
