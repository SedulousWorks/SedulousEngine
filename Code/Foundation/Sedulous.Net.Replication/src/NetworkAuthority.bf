using Sedulous.Core;

namespace Sedulous.Net.Replication;

/// Who owns an entity's replicated state.
///
/// Server authoritative is the DEFAULT, because it is the anti cheat position: a client that
/// can assert its own state can assert anything. Per entity Client authority is the escape
/// hatch for host migration and client owned avatars.
[Scriptable(.AllPublic)]
enum NetworkAuthority : uint8
{
	Server,
	Client
}
