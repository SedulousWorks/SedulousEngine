namespace Sedulous.Physics;

enum ContactKind : uint8
{
	case Begin;
	case End;
	case TriggerEnter;
	case TriggerExit;
}
