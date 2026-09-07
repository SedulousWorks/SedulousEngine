using System;

namespace Sedulous.RHI.Validation;

/// Where validation messages go.
typealias ValidationCallback = delegate void(ValidationSeverity severity, StringView message);
