namespace Sedulous.Script;

/// One emitted callable: a method, a constructor, or a field's get or set.
typealias ScriptThunk = function void(ref ScriptCallFrame frame);
