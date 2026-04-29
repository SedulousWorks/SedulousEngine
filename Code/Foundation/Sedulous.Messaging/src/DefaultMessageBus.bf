namespace Sedulous.Messaging;

/// Default concrete message bus. Inherits all behavior from MessageBus.
///
/// Usage:
///   let bus = new DefaultMessageBus();
///   let handle = bus.Subscribe<MyMessage>(new => OnMyMessage);
public class DefaultMessageBus : MessageBus
{
}
