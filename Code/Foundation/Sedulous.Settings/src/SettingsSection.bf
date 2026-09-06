using System;
using Sedulous.Core.Serialization;

namespace Sedulous.Settings;

/// One live section: the object, and the qualified type name it is stored under.
///
/// The name is kept rather than derived on demand because it is what the file records and
/// what a later load resolves the type by. The store owns the object.
class SettingsSection
{
	public String TypeName = new .() ~ delete _;
	public ISerializable Object ~ delete _;
}
