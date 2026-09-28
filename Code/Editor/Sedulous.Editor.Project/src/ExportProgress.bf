using System;

namespace Sedulous.Editor.Core;

/// A step's name and the fraction of the whole export done.
typealias ExportProgress = delegate void(StringView step, float fraction);
