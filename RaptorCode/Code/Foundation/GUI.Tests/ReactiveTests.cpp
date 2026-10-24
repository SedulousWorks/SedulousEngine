// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the reactive layer (G5 of Specs/vg-and-gui-lab.md): properties that record their readers,
// computed values that recompute lazily, and effects that rerun when what they read changes,
// batched on a scheduler; no manual subscriptions.
#include <doctest/doctest.h>
#include "Core/Prelude.h"
import foundation.core;
import foundation.gui;

using namespace foundation::gui;
namespace core = foundation::core;

TEST_CASE("reactive: an effect reruns when a property it read changes, and not otherwise")
{
    Property<int> score{1};
    Property<int> other{0};
    int seen = 0;
    Effect effect([&] { seen = score.Get(); });
    CHECK(seen == 1);
    CHECK(effect.RunCount() == 1u);

    score.Set(5);
    CHECK(seen == 5);
    CHECK(effect.RunCount() == 2u);
    score.Set(5); // the same value: nothing to do
    other.Set(3); // never read
    CHECK(effect.RunCount() == 2u);
}

TEST_CASE("reactive: dependencies are found again on every run")
{
    Property<bool> useA{true};
    Property<int> a{1};
    Property<int> b{2};
    int seen = 0;
    Effect effect([&] { seen = useA.Get() ? a.Get() : b.Get(); });
    CHECK(seen == 1);
    b.Set(20); // not read on this branch
    CHECK(effect.RunCount() == 1u);

    useA.Set(false);
    CHECK(seen == 20);
    a.Set(10); // no longer read
    CHECK(effect.RunCount() == 2u);
    b.Set(30);
    CHECK(seen == 30);
}

TEST_CASE("reactive: a computed value recomputes lazily, once per change")
{
    Property<int> price{3};
    Property<int> count{2};
    int evaluations = 0;
    Computed<int> total([&] {
        ++evaluations;
        return price.Get() * count.Get();
    });
    CHECK(evaluations == 0); // nothing read it yet
    CHECK(total.Get() == 6);
    CHECK(total.Get() == 6);
    CHECK(evaluations == 1);

    price.Set(4);
    count.Set(3);
    CHECK(total.IsStale());
    CHECK(evaluations == 1); // not until read
    CHECK(total.Get() == 12);
    CHECK(evaluations == 2);

    // An effect reading the computed reruns through it.
    int shown = 0;
    Effect effect([&] { shown = total.Get(); });
    count.Set(1);
    CHECK(shown == 4);
}

TEST_CASE("reactive: a scheduler batches changes into one run per effect")
{
    EffectScheduler scheduler;
    Property<int> a{0};
    Property<int> b{0};
    int runs = 0;
    Effect effect([&] { (void)(a.Get() + b.Get()); ++runs; }, [&] { return &scheduler; });
    CHECK(runs == 1); // the first run is at creation

    a.Set(1);
    b.Set(2);
    a.Set(3);
    CHECK(runs == 1);
    CHECK(scheduler.HasPending());
    CHECK(scheduler.Flush() == 1u);
    CHECK(runs == 2);
    CHECK_FALSE(scheduler.HasPending());
}

TEST_CASE("reactive: an effect destroyed while queued is not run, and teardown unlinks both ways")
{
    EffectScheduler scheduler;
    Property<int> a{0};
    {
        auto effect = core::MakeUnique<Effect>(core::DefaultAllocator(), [&] { (void)a.Get(); },
                                               [&] { return &scheduler; });
        CHECK(a.Changed().ObserverCount() == 1u);
        a.Set(1);
        CHECK(scheduler.HasPending());
    }
    CHECK_FALSE(scheduler.HasPending());
    CHECK(a.Changed().ObserverCount() == 0u);
    CHECK(scheduler.Flush() == 0u);

    // A source destroyed first leaves the effect with no dangling source.
    auto source = core::MakeUnique<Property<int>>(core::DefaultAllocator(), 7);
    int seen = 0;
    Effect effect([&] { seen = source ? source->Get() : -1; });
    CHECK(effect.SourceCount() == 1u);
    source.Reset();
    CHECK(effect.SourceCount() == 0u);
}

TEST_CASE("reactive: an effect that keeps changing what it reads is cut off")
{
    EffectScheduler scheduler;
    Property<int> a{0};
    Effect effect([&] { a.Set(a.Get() + 1); }, [&] { return &scheduler; });
    (void)scheduler.Flush();
    CHECK(effect.RunCount() <= 18u); // a few rounds, not forever
}

TEST_CASE("reactive: an untracked read records nothing")
{
    Property<int> a{1};
    int runs = 0;
    Effect effect([&] { (void)Untracked([&] { return a.Get(); }); ++runs; });
    a.Set(2);
    CHECK(runs == 1);
}

TEST_CASE("reactive: an effect that changes what it read reruns after itself, never inside itself")
{
    // No scheduler: the effect would otherwise run again inside its own run, recursing.
    Property<int> a{0};
    int depth = 0, deepest = 0;
    Effect settles([&] {
        ++depth;
        deepest = core::Max(deepest, depth);
        if (a.Get() < 3)
            a.Set(a.Peek() + 1);
        --depth;
    });
    CHECK(a.Peek() == 3);
    CHECK(deepest == 1);
    CHECK(settles.RunCount() == 4u); // 0, 1, 2, 3

    // One that never settles is cut off, still flat.
    Property<int> b{0};
    deepest = 0;
    Effect runaway([&] {
        ++depth;
        deepest = core::Max(deepest, depth);
        b.Set(b.Get() + 1);
        --depth;
    });
    CHECK(deepest == 1);
    CHECK(runaway.RunCount() <= 16u);
}
