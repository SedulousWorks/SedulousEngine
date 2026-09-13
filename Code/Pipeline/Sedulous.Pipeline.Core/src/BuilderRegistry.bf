using System;
using System.Collections;

namespace Sedulous.Pipeline.Core;

/// Asset type to builder routing for the cook driver.
///
/// A module registers its builders here and the executable assembles the set, which is the same
/// shape the resource factories and the editor's page creators use.
class BuilderRegistry
{
	/// OWNED: registering hands the builder over.
	private List<IAssetBuilder> mBuilders = new .() ~ DeleteContainerAndItems!(_);

	/// Takes ownership of the builder.
	public void Register(IAssetBuilder builder)
	{
		if (builder != null)
			mBuilders.Add(builder);
	}

	public IAssetBuilder Find(Type assetType)
	{
		for (let builder in mBuilders)
		{
			if (builder.AssetType == assetType)
				return builder;
		}
		return null;
	}

	/// By type NAME, which is what a cooked envelope stores rather than a type pointer.
	public IAssetBuilder FindByTypeName(StringView typeName)
	{
		let name = scope String();
		for (let builder in mBuilders)
		{
			let type = builder.AssetType;
			if (type == null)
				continue;
			name.Clear();
			type.GetFullName(name);
			if (name == typeName)
				return builder;
		}
		return null;
	}

	public int Count => mBuilders.Count;

	/// Every registered builder, in registration order. The registration tripwires audit the
	/// whole set through this, asking things like whether every product type is a registered
	/// serializable.
	public void ForEach(delegate void(IAssetBuilder) action)
	{
		for (let builder in mBuilders)
			action(builder);
	}
}
