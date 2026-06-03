namespace SummonersLeague.Data;

/// Elemental type for monsters and abilities.
/// Five elements form a cycle, Dark and Light are a mutual pair.
///
/// Fire -> Earth -> Electric -> Water -> Wind -> Fire
/// Dark <-> Light (mutual weakness)
/// Neutral: no advantages or weaknesses
enum ElementType : uint8
{
	Fire,
	Water,
	Earth,
	Wind,
	Electric,
	Dark,
	Light,
	Neutral
}
