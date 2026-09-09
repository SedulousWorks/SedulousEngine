namespace Sedulous.Net.Manager;

/// The role a networked run starts in. None is single player: no socket is opened at all.
enum NetworkRole
{
	None,
	Server,
	Client
}
