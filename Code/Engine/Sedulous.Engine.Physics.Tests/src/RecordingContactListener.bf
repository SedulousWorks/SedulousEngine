using System.Collections;
using Sedulous.Engine.Physics;

namespace Sedulous.Engine.Physics.Tests;

/// Records what the dispatch delivers.
///
/// The subsystem plays this role in a real run; a bare harness wires one in directly.
class RecordingContactListener : IContactListener
{
	public List<EntityContact> Contacts = new .() ~ delete _;

	public void OnContact(EntityContact contact)
	{
		Contacts.Add(contact);
	}
}
