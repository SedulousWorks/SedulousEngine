namespace Sedulous.Mcp;

/// What a resource provider made of a uri.
///
/// NotMine is distinct from Failed on purpose: the server tries each provider in turn, and
/// only a provider that CLAIMS the uri gets to fail it.
enum ResourceReadOutcome : uint8
{
	case NotMine;
	case Ok;
	case Failed;
}
