using System;
using System.Collections;
using Sedulous.Core;
using Sedulous.Core.Logging;
using Sedulous.Materials.Resource;
using Sedulous.Materials.Pipeline;
using Sedulous.Shaders;
using Sedulous.Shaders.Resource;
using Sedulous.Editor.Core;

namespace Sedulous.Editor.Scene;

/// The material's shader: a shader asset, or a built-in (PBR or Unlit) when it has none. A switch
/// is one undoable edit that re-lays the material by the new shader, keeping every value that
/// still fits; the page follows its shader asset when it recooks.
extension MaterialEditorPage
{
	/// The shader asset's cooked source (its property table), or null before it has cooked. The
	/// caller's to delete.
	private ShaderSource ReadShader(Guid shader)
	{
		if ((mContext.Project == null) || shader.IsNil)
			return null;
		let product = mContext.Project.CookedDb.GetInstance(shader);
		let object = (product != null) ? product.ReadObject() : null;
		let source = object as ShaderSource;
		if ((object != null) && (source == null))
			delete object;
		return source;
	}

	/// Moves the material onto a shader asset, or back to the built-in PBR (nil).
	private void SwitchShader(Guid shader)
	{
		if ((mAsset == null) || (shader == mAsset.Source.ShaderId))
			return;
		if (shader.IsNil)
		{
			SwitchToBuiltIn(false);
			return;
		}
		let table = ReadShader(shader);
		if (table == null)
		{
			mContext.Notify(.Warning, "That shader has not cooked yet - save it (or fix its errors), then pick it again");
			return;
		}
		defer delete table;
		ApplyEdit("Shader", new [=shader, =table](s) => MaterialShaderLayout.SetShader(s, shader, table));
	}

	private void SwitchToBuiltIn(bool unlit)
	{
		if (mAsset == null)
			return;
		let current = mAsset.Source;
		if (current.ShaderId.IsNil && ((current.ShaderName == "unlit") == unlit))
			return;
		ApplyEdit("Shader", new [=unlit](s) => MaterialShaderLayout.SetBuiltInShader(s, unlit));
	}

	/// Binds the material's shader asset (its resource registers it for the preview) and re-lays
	/// the material by its current table: on opening, and whenever it recooks.
	private void BindShader()
	{
		mShader.Forget();
		mShader = default;
		mShaderVersion = 0;
		ClearAndDeleteItems!(mShaderTable);
		if ((mAsset == null) || mAsset.Source.ShaderId.IsNil)
			return;
		let id = mAsset.Source.ShaderId;
		if (mContext.Resources != null)
		{
			mShader = mContext.Resources.Bind<ShaderResource>(id);
			mShader.Retain();
			mShaderVersion = (mShader.Get != null) ? mShader.Get.Version : 0;
		}
		let table = ReadShader(id);
		if (table == null)
		{
			GlobalLog(.Warning, "Editor: material '{}': its shader has not cooked - its rows are its own until it does", mTitle);
			return;
		}
		defer delete table;
		table.GetProperties(mShaderTable);
		// Not an edit: the material follows its shader, as the cook lays it out.
		let laid = scope MaterialSource();
		MaterialShaderLayout.LayOut(mAsset.Source, table, laid);
		MaterialShaderLayout.Assign(mAsset.Source, laid);
		mGridDirty = true;
	}

	/// The range the shader asset declares for `name`, when it declares one.
	private bool ShaderRange(StringView name, out float min, out float max)
	{
		min = 0.0f;
		max = 1.0f;
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
}
