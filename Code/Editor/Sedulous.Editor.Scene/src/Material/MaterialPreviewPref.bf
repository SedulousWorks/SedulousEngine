using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Editor.Scene;

/// One material's stored preview choice, keyed by the material asset's guid: a primitive
/// shape index, or a mesh asset that overrides it.
[Serializable(1)]
class MaterialPreviewPref
{
	public Guid Asset = .();
	public uint32 Shape = 0;
	public Guid Mesh = .();
}
