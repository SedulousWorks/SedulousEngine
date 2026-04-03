using System;
using Sedulous.OpenDDL;

namespace Sedulous.Serialization.OpenDDL;

/// Custom DataDescription that keeps object and array structures for serialization.
class SerializableDataDescription : DataDescription
{
	/// Creates custom structure types for serialization.
	public override Structure CreateStructure(StringView identifier)
	{
		// Keep "Obj_" structures for objects
		if (identifier == "Obj_")
			return new Structure(StructureTypes.MakeFourCC("Obj_"));

		// Keep "Arr_" structures for arrays
		if (identifier == "Arr_")
			return new Structure(StructureTypes.MakeFourCC("Arr_"));

		return base.CreateStructure(identifier);
	}
}
