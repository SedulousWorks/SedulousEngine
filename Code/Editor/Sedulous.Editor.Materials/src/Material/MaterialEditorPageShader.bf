using System;
using Sedulous.Materials; // BuiltinShading, MaterialPresets
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Materials.Resource;
using Sedulous.Materials.Pipeline;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Materials;

/// The material's shader: a shader asset, or a built-in (PBR, Unlit or Phong) when it has none. A switch
/// is one undoable edit that re-lays the material by the new shader, keeping every value that
/// still fits; the page follows its shader asset when it recooks.
extension MaterialEditorPage
{
	/// The shader asset's cooked source (its property table), or null before it has cooked. The
	/// caller's to delete.
	private ShaderSource ReadShader(Guid shader)
	{
		if ((Context.Project == null) || shader.IsNil)
			return null;
		let product = Context.Project.CookedDb.GetInstance(shader);
		let object = (product != null) ? product.ReadObject() : null;
		let source = object as ShaderSource;
		if ((object != null) && (source == null))
			delete object;
		return source;
	}

	/// Moves the material onto a shader asset, or back to the built-in PBR (nil).
	private void SwitchShader(Guid shader)
	{
		let asset = Edited;
		if ((asset == null) || (shader == asset.Source.ShaderId))
			return;
		if (shader.IsNil)
		{
			SwitchToBuiltIn(.Pbr);
			return;
		}
		let table = ReadShader(shader);
		if (table == null)
		{
			Context.Notify(.Warning, "That shader has not cooked yet: save it (or fix its errors), then pick it again");
			return; // the row shows the shader it still has
		}
		defer delete table;
		ApplyEdit("Shader", scope [&] (s) => { MaterialShaderLayout.SetShader(s, shader, table); });
	}

	private void SwitchToBuiltIn(BuiltinShading shading)
	{
		let asset = Edited;
		if (asset == null)
			return;
		let current = asset.Source;
		if (current.ShaderId.IsNil && (current.ShaderName == MaterialPresets.BuiltinShadingOf(shading).ShaderName))
			return;
		ApplyEdit("Shader", scope [&] (s) => { MaterialShaderLayout.SetBuiltInShader(s, shading); });
	}

	/// Binds the material's shader asset (its resource registers it for the preview) and re-lays
	/// the material by its current table: on opening, and whenever it recooks. Not an edit: the
	/// material follows its shader, as the cook lays it out.
	private void BindShader()
	{
		mShader.Forget();
		mShader = default;
		mShaderVersion = 0;
		ClearAndDeleteItems!(mShaderTable);
		let asset = Edited;
		if ((asset == null) || asset.Source.ShaderId.IsNil)
			return;
		let id = asset.Source.ShaderId;
		if (Context.Resources != null)
		{
			mShader = Context.Resources.Bind<ShaderResource>(id);
			mShader.Retain();
			mShaderVersion = (mShader.Get != null) ? mShader.Get.Version : 0;
		}
		mRowsDirty = true;
		let table = ReadShader(id);
		if (table == null)
		{
			GlobalLog(.Warning, "Editor: material '{}': its shader has not cooked, its rows are its own until it does", Title);
			return;
		}
		defer delete table;
		table.GetProperties(mShaderTable);
		let laid = scope MaterialSource();
		MaterialShaderLayout.LayOut(asset.Source, table, laid);
		MaterialShaderLayout.Assign(asset.Source, laid);
	}
}
