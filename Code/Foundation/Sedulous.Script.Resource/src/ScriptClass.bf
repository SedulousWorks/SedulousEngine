using System;
using System.Collections;
using Sedulous.Core;

namespace Sedulous.Script.Resource;

/// The runtime product a component's Ref<ScriptClass> binds: the cooked record's content,
/// owned by the resource manager for as long as something references it.
class ScriptClass
{
	public String Language = new .() ~ delete _;
	public String ClassName = new .() ~ delete _;
	public String SourceName = new .() ~ delete _;
	public String Source = new .() ~ delete _;
	public List<ScriptPropertyDesc> Properties = new .() ~ DeleteContainerAndItems!(_);
	public List<String> Handlers = new .() ~ DeleteContainerAndItems!(_);
	public bool UsesCoroutines = false;
	/// "Script Mover": a stable label for the profiler, which keeps the pointer.
	public String ProfileName = new .() ~ delete _;

	/// A utility module: source with no behaviour class to instantiate.
	public bool IsModule => ClassName.IsEmpty;

	public bool HasHandler(StringView name)
	{
		for (let handler in Handlers)
		{
			if (handler == name)
				return true;
		}
		return false;
	}

	public ScriptPropertyDesc FindProperty(uint64 hash)
	{
		for (let property in Properties)
		{
			if (property.Hash == hash)
				return property;
		}
		return null;
	}

	public ScriptPropertyDesc FindProperty(StringView name) => FindProperty(ScriptPropertyNames.HashOf(name));

	/// Fills from the cooked record.
	public void From(ScriptClassSource source)
	{
		Language.Set(source.Language);
		ClassName.Set(source.ClassName);
		SourceName.Set(source.SourceName);
		Source.Set(source.Source);
		ClearAndDeleteItems!(Properties);
		for (let p in source.Properties)
		{
			let copy = new ScriptPropertyDesc();
			copy.Name.Set(p.Name);
			copy.Hash = p.Hash;
			copy.Type = p.Type;
			copy.AssetType.Set(p.AssetType);
			copy.Default = p.Default;
			if (p.Default.Text != null)
				copy.Default.Text = new String(p.Default.Text);
			copy.Description.Set(p.Description);
			Properties.Add(copy);
		}
		ClearAndDeleteItems!(Handlers);
		for (let h in source.Handlers)
			Handlers.Add(new String(h));
		UsesCoroutines = source.UsesCoroutines;
		ProfileName.Set("Script ");
		ProfileName.Append(ClassName.IsEmpty ? "(module)" : ClassName);
	}
}
