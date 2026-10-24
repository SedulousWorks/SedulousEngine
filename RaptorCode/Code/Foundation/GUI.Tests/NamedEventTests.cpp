// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - named events (K4 of Specs/gui-lab-evolution-3.md): an event a library names for itself (a
// gamekit screen's `screenenter`), sent to a node with a detail, heard by name and by no other.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

TEST_CASE("named events: heard by their name only, with their detail; a token removes the listener")
{
    auto node = core::MakeRef<UIWidget>(core::DefaultAllocator());
    core::String heard;
    int others = 0;
    const core::u32 token = node->AddNamedListener(core::StringView(u8"screenenter"), [&heard](const Event& e)
                                                   { heard = core::String(static_cast<const NamedEvent&>(e).Detail); });
    (void)node->AddNamedListener(core::StringView(u8"screenleave"), [&others](const Event&) { ++others; });
    node->SendNamedEvent(core::StringView(u8"screenenter"), core::StringView(u8"title"));
    CHECK(heard == core::StringView(u8"title"));
    CHECK(others == 0);
    CHECK(node->RemoveEventListener(token));
    node->SendNamedEvent(core::StringView(u8"screenenter"), core::StringView(u8"again"));
    CHECK(heard == core::StringView(u8"title"));
}
