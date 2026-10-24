// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - the GUI driven from scripts (G1 of Specs/vg-and-gui-lab.md), with no UI-script layer: the
// widgets reach AngelScript and Luau through their reflection. Each language runs the same story
// against one native checker: build a small tree under `gui.root()`, set properties, add a class a
// sheet styles, listen to a click the dispatcher delivers; then the weak-handle rule: a destroyed
// element's handle answers isValid() false and any other use is the script's error, a destroy
// inside a click handler completes after it, a reused slot does not answer to the old handle, and
// a handle outliving its GUI reads as gone. Then bindings (G5): a script binds a label to a function
// of the GUI's data, a slider both ways to a data value, and a label to the slider, and each
// follows its source with no subscription.
#include <doctest/doctest.h>
#include "Core/Prelude.h"

import foundation.core;
import foundation.script;
import foundation.i18n; // a script's localized texts (E16)
import foundation.gui;
#ifdef OPTION_HAS_ANGELSCRIPT
import foundation.script.angelscript;
#endif
#ifdef OPTION_HAS_LUAU
import foundation.script.luau;
#endif

using namespace foundation::core;
using namespace foundation::script;
namespace gui = foundation::gui;

namespace
{
    struct Errors final : IScriptErrorHandler
    {
        int count = 0;
        String last;
        void OnError(const ScriptError& error) override
        {
            ++count;
            last = String(error.message);
        }
    };

    // A GUI for one script: its root, 400 x 300, installed as the script's `gui.root()`.
    struct GuiBed
    {
        RefPtr<gui::SceneRoot> root = MakeRef<gui::SceneRoot>(DefaultAllocator(), MakeRef<gui::GUIContext>(DefaultAllocator()));
        gui::GuiScriptBinding binding;
        Errors errors;
        RefPtr<IScriptContext> context;

        explicit GuiBed(IScriptManager& manager)
        {
            root->SetSize(Float2{400.0f, 300.0f});
            binding.root = root.Get();
            context = manager.CreateContext();
            context->SetErrorHandler(&errors);
            gui::InstallGuiScriptService(*context, binding);
        }
        ~GuiBed()
        {
            if (context)
                context->SetErrorHandler(nullptr);
        }

        [[nodiscard]] f64 Number(const char8_t* function)
        {
            Result<Variant> result = context->Call(function, Span<Variant>{});
            INFO(doctest::String(reinterpret_cast<const char*>(errors.last.CStr())));
            REQUIRE(result.HasValue());
            const f64* value = result.Value().TryGet<f64>();
            REQUIRE(value != nullptr);
            return *value;
        }
        void Run(const char8_t* function) { REQUIRE(context->Call(function, Span<Variant>{}).HasValue()); }
        // `function` must fail with the gone-handle error.
        void Refused(const char8_t* function)
        {
            INFO(reinterpret_cast<const char*>(function));
            const int before = errors.count;
            CHECK_FALSE(context->Call(function, Span<Variant>{}).HasValue());
            CHECK(errors.count > before);
            CHECK(errors.last.AsView().ContainsIgnoreCase(StringView(u8"the object is gone")));
        }
        void Click(Float2 at)
        {
            gui::EventDispatcher* dispatcher = root->GetEventDispatcher();
            dispatcher->InjectMouseDown(at, gui::MouseButton::Left);
            dispatcher->InjectMouseUp(at, gui::MouseButton::Left);
        }
        void Update() { root->GetContext().Update(Duration{}); }
    };

    [[nodiscard]] RefPtr<IScriptManager> Bound(RefPtr<IScriptManager> manager)
    {
        RegisterCoreTypes();
        gui::RegisterGuiScriptSurface();
        RegisterReflectedTypes(*manager);
        return manager;
    }

    // The native half of the story both languages tell. The script, once loaded, has built under
    // the root a Panel "panel" holding a Label "title" (text "Hunt") and, at the root, a Button
    // "go" (80 x 30 at the origin, text "Go", class "primary") listening for clicks.
    void CheckStory(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        gui::Node* panel = bed.root->GetChildAt(0);
        REQUIRE(panel != nullptr);
        CHECK(Cast<gui::Panel>(panel) != nullptr);
        gui::Label* title = Cast<gui::Label>(panel->GetChildAt(0));
        REQUIRE(title != nullptr);
        CHECK(title->GetText() == StringView(u8"Hunt"));
        CHECK(title->GetId() == StringView(u8"title"));
        gui::Button* go = Cast<gui::Button>(bed.root->GetChildAt(1));
        REQUIRE(go != nullptr);
        CHECK(go->GetText() == StringView(u8"Go"));
        CHECK(go->HasClass(u8"primary"));
        CHECK(go->GetSize().x == doctest::Approx(80.0f));
        CHECK(bed.Number(u8"foundTitle") == doctest::Approx(1.0)); // find by id, narrowed by Label.of

        // A sheet styles what the script classed; the script reads the styled value back.
        gui::StyleManager styles(gui::CSSParser::Parse(StringView(u8".primary { opacity: 0.5; }")));
        styles.ApplyTree(*bed.root);
        CHECK(go->GetAlpha() == doctest::Approx(0.5f));
        CHECK(bed.Number(u8"goOpacity") == doctest::Approx(0.5));

        // A click through the dispatcher reaches the script's handler.
        bed.Click(Float2{10.0f, 10.0f});
        CHECK(bed.Number(u8"clicks") == doctest::Approx(1.0));
    }

    // The weak-handle rule. The script holds `go` (above) and `bye`, a Button at (100, 0) whose
    // click handler destroys it and records whether it was still valid inside the handler.
    void CheckHandles(GuiBed& bed)
    {
        // A destroy inside a click handler completes after it: valid in the handler and until the
        // GUI's update ends.
        bed.Click(Float2{110.0f, 10.0f});
        CHECK(bed.Number(u8"byeValidInHandler") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"byeValid") == doctest::Approx(1.0));
        bed.Update();
        CHECK(bed.Number(u8"byeValid") == doctest::Approx(0.0));
        bed.Refused(u8"readBye");
        bed.Refused(u8"writeBye");
        bed.Refused(u8"callBye");

        // A slot freed and taken again does not answer to the old handle.
        bed.Run(u8"makeAndDestroyTemp");
        bed.Update();
        bed.Run(u8"makeAnother");
        CHECK(bed.Number(u8"tempValid") == doctest::Approx(0.0));
        CHECK(bed.Number(u8"anotherValid") == doctest::Approx(1.0));

        // A handle outliving its GUI reads as gone, never as freed memory.
        CHECK(bed.Number(u8"goValid") == doctest::Approx(1.0));
        gui::ClearGuiScriptService(*bed.context);
        bed.binding.root = nullptr;
        bed.root = RefPtr<gui::SceneRoot>{};
        CHECK(bed.Number(u8"goValid") == doctest::Approx(0.0));
        bed.Refused(u8"readGo");
    }
}

namespace
{
    // The binding story (G5) both languages tell. Before the script loads, the GUI's data holds
    // score 3 and volume 0.5. The script builds, under the root: a Label bound to "Score: " and the
    // score text (bind, a function reading gui.getText), a Slider bound both ways to volume
    // (bindData), and a Label bound to the slider's value (a function reading slider.value), and
    // offers setScore(n), which writes the data through gui.set.
    void CheckBindings(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        gui::Label* score = Cast<gui::Label>(bed.root->GetChildAt(0));
        gui::Slider* slider = Cast<gui::Slider>(bed.root->GetChildAt(1));
        gui::Label* volume = Cast<gui::Label>(bed.root->GetChildAt(2));
        REQUIRE((score != nullptr && slider != nullptr && volume != nullptr));
        CHECK(score->GetText() == StringView(u8"Score: 3"));
        CHECK(slider->GetValue() == doctest::Approx(0.5f));
        CHECK(volume->GetText() == StringView(u8"0.5"));
        CHECK(bed.Number(u8"bound") == doctest::Approx(1.0)); // every bind call answered true
        // A handle held in a variable narrowed, and reached a Variant sink as the same element.
        CHECK(gui::Node::FromHandle(bed.root->GetContext().GetData().Get(StringView(u8"picked"))) == slider);

        // The game changes the data: the script's binding follows on the GUI's frame.
        bed.root->GetContext().GetData().Set(StringView(u8"score"), Variant::From<i32>(4));
        bed.Update();
        CHECK(score->GetText() == StringView(u8"Score: 4"));

        // The user drags the slider: the data and the label reading the slider follow.
        slider->SetValue(0.75f);
        bed.Update();
        CHECK(volume->GetText() == StringView(u8"0.75"));
        const Variant written = bed.root->GetContext().GetData().Get(StringView(u8"volume"));
        REQUIRE(written.TryGet<f64>() != nullptr); // a range's value is an f64
        CHECK(*written.TryGet<f64>() == doctest::Approx(0.75));

        // The script writes the data.
        bed.Run(u8"setNine");
        bed.Update();
        CHECK(score->GetText() == StringView(u8"Score: 9"));
        CHECK(bed.errors.count == 0);
    }

    void SeedBindingData(GuiBed& bed)
    {
        bed.root->GetContext().GetData().Set(StringView(u8"score"), Variant::From<i32>(3));
        bed.root->GetContext().GetData().Set(StringView(u8"volume"), Variant::From<f64>(0.5));
    }
}

namespace
{
    // The command story (G7) both languages tell. The script defines "music" (label "Music"),
    // handles it on the root by toggling its checked state, binds a CheckBox and F5 to it, and offers
    // switchOff() (disables it) and runIt() (runs it, returning 1 when a handler ran).
    void CheckCommands(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        gui::CheckBox* box = Cast<gui::CheckBox>(bed.root->GetChildAt(0));
        REQUIRE(box != nullptr);
        const gui::Command* music = bed.root->GetContext().GetCommands().Find(StringView(u8"music"));
        REQUIRE(music != nullptr);
        CHECK(music->GetLabel() == StringView(u8"Music"));
        bed.Update();
        CHECK(box->IsEnabled());
        CHECK(bed.Number(u8"runIt") == doctest::Approx(1.0)); // the script's handler toggles it
        bed.Update();
        CHECK(box->IsChecked());
        // The script bound F5 to it.
        bed.root->GetEventDispatcher()->InjectKeyDown(static_cast<u32>(gui::KeyCode::F5));
        bed.Update();
        CHECK_FALSE(box->IsChecked());
        bed.Run(u8"switchOff");
        bed.Update();
        CHECK_FALSE(box->IsEnabled());
        CHECK(bed.root->GetContext().GetCommands().Find(StringView(u8"music"))->GetDisabledReason() == StringView(u8"No sound device"));
        CHECK(bed.Number(u8"runIt") == doctest::Approx(0.0)); // disabled: nothing runs
        CHECK(bed.errors.count == 0);
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript defines, handles and runs commands")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool CommandHandler();\n"
        u8"bool toggleMusic() { gui::setCommandChecked(\"music\", !gui::isCommandChecked(\"music\")); return false; }\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  gui::defineCommand(\"music\", \"Music\");\n"
        u8"  root.onCommand(\"music\", CommandHandler(toggleMusic));\n"
        u8"  Node@ box = root.add(\"CheckBox\");\n"
        u8"  box.command = \"music\";\n"
        u8"  gui::bindKey(\"f5\", \"music\", \"\");\n"
        u8"}\n"
        u8"void switchOff() { gui::setCommandEnabled(\"music\", false); gui::setCommandDisabledReason(\"music\", \"No sound device\"); }\n"
        u8"double runIt() { return gui::runCommand(\"music\") ? 1 : 0; }\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckCommands(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau defines, handles and runs commands")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local root = gui.root()\n"
        u8"gui.defineCommand(\"music\", \"Music\")\n"
        u8"root:onCommand(\"music\", function() gui.setCommandChecked(\"music\", not gui.isCommandChecked(\"music\")); return false end)\n"
        u8"local box = root:add(\"CheckBox\")\n"
        u8"box.command = \"music\"\n"
        u8"gui.bindKey(\"f5\", \"music\", \"\")\n"
        u8"function switchOff() gui.setCommandEnabled(\"music\", false); gui.setCommandDisabledReason(\"music\", \"No sound device\") end\n"
        u8"function runIt() return gui.runCommand(\"music\") and 1 or 0 end\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckCommands(bed);
}
#endif

namespace
{
    // A script capturing keys (E12): the next key's name lands in the data as `captured`, and a
    // key bound from it runs its command.
    void CheckCapture(GuiBed& bed)
    {
        gui::EventDispatcher& d = *bed.root->GetEventDispatcher();
        bed.Run(u8"listen");
        CHECK(d.IsCapturingKey());
        d.InjectKeyDown(static_cast<u32>(gui::KeyCode::Q), gui::KeyModCtrl);
        bed.Update();
        CHECK(bed.root->GetContext().GetData().Get(u8"captured").Get<String>() == StringView(u8"ctrl-q"));
        CHECK(bed.Number(u8"jumps") == doctest::Approx(0.0));
        d.InjectKeyDown(static_cast<u32>(gui::KeyCode::Q), gui::KeyModCtrl); // now bound to jump
        bed.Update();
        CHECK(bed.Number(u8"jumps") == doctest::Approx(1.0));
        bed.Run(u8"listen");
        d.InjectKeyDown(static_cast<u32>(gui::KeyCode::Escape), 0); // cancelled: empty
        bed.Update();
        CHECK(bed.root->GetContext().GetData().Get(u8"captured").Get<String>().IsEmpty());
        CHECK(bed.errors.count == 0);
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript captures the next key, names it and binds it")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool CommandHandler();\n"
        u8"double count = 0;\n"
        u8"bool jump() { count += 1; return false; }\n"
        u8"void onKey(const string &in keys) {\n"
        u8"  gui::set(\"captured\", keys);\n"
        u8"  if (keys != \"\") gui::bindKey(keys, \"jump\", \"\");\n"
        u8"  gui::set(\"shown\", gui::keyText(keys));\n"
        u8"}\n"
        u8"void main() { gui::root().onCommand(\"jump\", CommandHandler(jump)); }\n"
        u8"void listen() { gui::captureKey(KeyHandler(onKey)); }\n"
        u8"double jumps() { return count; }\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckCapture(bed);
    bed.Run(u8"listen");
    bed.root->GetEventDispatcher()->InjectKeyDown(static_cast<u32>(gui::KeyCode::Keypad5), 0);
    CHECK(bed.root->GetContext().GetData().Get(u8"shown").Get<String>() == StringView(u8"Numpad 5"));
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau captures the next key, names it and binds it")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local count = 0\n"
        u8"gui.root():onCommand(\"jump\", function() count = count + 1; return false end)\n"
        u8"function listen()\n"
        u8"  gui.captureKey(function(keys)\n"
        u8"    gui.set(\"captured\", keys)\n"
        u8"    if keys ~= \"\" then gui.bindKey(keys, \"jump\", \"\") end\n"
        u8"  end)\n"
        u8"end\n"
        u8"function jumps() return count end\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckCapture(bed);
}
#endif

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript binds widgets to data and to each other")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    SeedBindingData(bed);
    const Status loaded = bed.context->Load(
        u8"funcdef string TextExpression();\n"
        u8"funcdef double NumberExpression();\n"
        u8"Slider@ slider;\n"
        u8"double allBound = 0;\n"
        u8"string scoreText() { return \"Score: \" + gui::getText(\"score\"); }\n"
        u8"double sliderValue() { return slider.value; }\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  Label@ score = Label::of(root.add(\"Label\"));\n"
        u8"  @slider = Slider::of(root.add(\"Slider\"));\n"
        u8"  Label@ volume = Label::of(root.add(\"Label\"));\n"
        u8"  bool a = score.bind(\"text\", TextExpression(scoreText));\n"
        u8"  bool b = slider.bindData(\"value\", \"volume\");\n"
        u8"  bool c = volume.bind(\"text\", NumberExpression(sliderValue));\n"
        u8"  allBound = (a && b && c) ? 1 : 0;\n"
        u8"  Node@ held = root.childAt(1);\n"
        u8"  Slider@ narrowed = Slider::of(held);\n" // a handle in a variable narrows as it is
        u8"  gui::set(\"picked\", @narrowed);\n"      // and an explicit handle reaches a Variant sink
        u8"}\n"
        u8"double bound() { return allBound; }\n"
        u8"void setNine() { gui::set(\"score\", 9); }\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckBindings(bed);
}
#endif // OPTION_HAS_ANGELSCRIPT

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau binds widgets to data and to each other")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    SeedBindingData(bed);
    const Status loaded = bed.context->Load(
        u8"local root = gui.root()\n"
        u8"local score = Label.of(root:add(\"Label\"))\n"
        u8"local slider = Slider.of(root:add(\"Slider\"))\n"
        u8"local volume = Label.of(root:add(\"Label\"))\n"
        u8"local a = score:bind(\"text\", function() return \"Score: \" .. gui.getText(\"score\") end)\n"
        u8"local b = slider:bindData(\"value\", \"volume\")\n"
        u8"local c = volume:bind(\"text\", function() return slider.value end)\n"
        u8"local allBound = (a and b and c) and 1 or 0\n"
        u8"local held = root:childAt(1)\n"
        u8"gui.set(\"picked\", Slider.of(held))\n"
        u8"function bound() return allBound end\n"
        u8"function setNine() gui.set(\"score\", 9) end\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckBindings(bed);
}
#endif // OPTION_HAS_LUAU

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript builds, styles and clicks the GUI's widgets, and holds them weakly")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"double clickCount = 0;\n"
        u8"double byeInHandler = -1;\n"
        u8"Button@ go;\n"
        u8"Button@ bye;\n"
        u8"Node@ temp;\n"
        u8"Node@ another;\n"
        u8"void onGo() { clickCount += 1; }\n"
        u8"void onBye() { bye.destroy(); byeInHandler = bye.isValid() ? 1 : 0; }\n"
        u8"double clicks() { return clickCount; }\n"
        u8"double byeValidInHandler() { return byeInHandler; }\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  Node@ panel = root.add(\"Panel\");\n"
        u8"  Label@ title = Label::of(panel.add(\"Label\"));\n"
        u8"  title.text = \"Hunt\";\n"
        u8"  title.id = \"title\";\n"
        u8"  @go = Button::of(root.add(\"Button\"));\n"
        u8"  go.text = \"Go\";\n"
        u8"  go.addClass(\"primary\");\n"
        u8"  go.width = 80; go.height = 30;\n"
        u8"  go.on(\"click\", Action(onGo));\n"
        u8"  @bye = Button::of(root.add(\"Button\"));\n"
        u8"  bye.x = 100; bye.width = 80; bye.height = 30;\n"
        u8"  bye.on(\"click\", Action(onBye));\n"
        u8"}\n"
        u8"double foundTitle() { Label@ t = Label::of(gui::root().find(\"title\")); return t !is null && t.text == \"Hunt\" ? 1 : 0; }\n"
        u8"double goOpacity() { return go.opacity; }\n"
        u8"double byeValid() { return bye.isValid() ? 1 : 0; }\n"
        u8"string readBye() { return bye.text; }\n"
        u8"void writeBye() { bye.text = \"x\"; }\n"
        u8"void callBye() { bye.addClass(\"x\"); }\n"
        u8"void makeAndDestroyTemp() { @temp = gui::root().add(\"Label\"); temp.destroy(); }\n"
        u8"void makeAnother() { @another = gui::root().add(\"Label\"); }\n"
        u8"double tempValid() { return temp.isValid() ? 1 : 0; }\n"
        u8"double anotherValid() { return another.isValid() ? 1 : 0; }\n"
        u8"double goValid() { return go.isValid() ? 1 : 0; }\n"
        u8"string readGo() { return go.text; }\n",
        u8"main");
    REQUIRE(loaded.IsOk());
    CheckStory(bed);
    CheckHandles(bed);
}
#endif // OPTION_HAS_ANGELSCRIPT

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau builds, styles and clicks the GUI's widgets, and holds them weakly")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local clickCount = 0\n"
        u8"local byeInHandler = -1\n"
        u8"local root = gui.root()\n"
        u8"local panel = root:add(\"Panel\")\n"
        u8"local title = Label.of(panel:add(\"Label\"))\n"
        u8"title.text = \"Hunt\"\n"
        u8"title.id = \"title\"\n"
        u8"local go = Button.of(root:add(\"Button\"))\n"
        u8"go.text = \"Go\"\n"
        u8"go:addClass(\"primary\")\n"
        u8"go.width = 80\n"
        u8"go.height = 30\n"
        u8"go:on(\"click\", function() clickCount = clickCount + 1 end)\n"
        u8"local bye = Button.of(root:add(\"Button\"))\n"
        u8"bye.x = 100\n"
        u8"bye.width = 80\n"
        u8"bye.height = 30\n"
        u8"bye:on(\"click\", function() bye:destroy(); byeInHandler = bye:isValid() and 1 or 0 end)\n"
        u8"local temp, another\n"
        u8"function clicks() return clickCount end\n"
        u8"function byeValidInHandler() return byeInHandler end\n"
        u8"function foundTitle() local t = Label.of(gui.root():find(\"title\")); return (t ~= nil and t.text == \"Hunt\") and 1 or 0 end\n"
        u8"function goOpacity() return go.opacity end\n"
        u8"function byeValid() return bye:isValid() and 1 or 0 end\n"
        u8"function readBye() return bye.text end\n"
        u8"function writeBye() bye.text = \"x\" end\n"
        u8"function callBye() bye:addClass(\"x\") end\n"
        u8"function makeAndDestroyTemp() temp = gui.root():add(\"Label\"); temp:destroy() end\n"
        u8"function makeAnother() another = gui.root():add(\"Label\") end\n"
        u8"function tempValid() return temp:isValid() and 1 or 0 end\n"
        u8"function anotherValid() return another:isValid() and 1 or 0 end\n"
        u8"function goValid() return go:isValid() and 1 or 0 end\n"
        u8"function readGo() return go.text end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckStory(bed);
    CheckHandles(bed);
}
#endif // OPTION_HAS_LUAU

namespace
{
    // The native half of the event story: a press on the button reaches the script with its data;
    // the handler takes it, so the root's handler never hears it; a second press counts two.
    void CheckEvents(GuiBed& bed)
    {
        gui::EventDispatcher* dispatcher = bed.root->GetEventDispatcher();
        dispatcher->InjectMouseDown(Float2{30.0f, 15.0f}, gui::MouseButton::Left); // the button is at (20, 10)
        dispatcher->InjectMouseUp(Float2{30.0f, 15.0f}, gui::MouseButton::Left);
        CHECK(bed.Number(u8"lastX") == doctest::Approx(30.0));
        CHECK(bed.Number(u8"lastLocalX") == doctest::Approx(10.0));
        CHECK(bed.Number(u8"lastCount") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"rootSaw") == doctest::Approx(0.0));
        dispatcher->InjectMouseDown(Float2{30.0f, 15.0f}, gui::MouseButton::Left);
        CHECK(bed.Number(u8"lastCount") == doctest::Approx(2.0));
        dispatcher->InjectMouseUp(Float2{30.0f, 15.0f}, gui::MouseButton::Left);
        dispatcher->InjectMouseDown(Float2{300.0f, 200.0f}, gui::MouseButton::Left); // off the button
        CHECK(bed.Number(u8"rootSaw") == doctest::Approx(1.0));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: an AngelScript handler reads the event and takes it")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"double x = -1; double localX = -1; double count = 0; double saw = 0;\n"
        u8"bool onDown(GuiEvent e) { x = e.x; localX = e.localX; count = e.clickCount; return true; }\n"
        u8"bool onRoot(GuiEvent e) { saw += 1; return false; }\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  Node@ button = root.add(\"Button\");\n"
        u8"  button.x = 20; button.y = 10; button.width = 80; button.height = 30;\n"
        u8"  button.on(\"mousedown\", EventHandler(onDown));\n"
        u8"  root.on(\"mousedown\", EventHandler(onRoot));\n"
        u8"}\n"
        u8"double lastX() { return x; }\n"
        u8"double lastLocalX() { return localX; }\n"
        u8"double lastCount() { return count; }\n"
        u8"double rootSaw() { return saw; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckEvents(bed);
}
#endif // OPTION_HAS_ANGELSCRIPT

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: a Luau handler reads the event and takes it")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local x, localX, count, saw = -1, -1, 0, 0\n"
        u8"local root = gui.root()\n"
        u8"local button = root:add(\"Button\")\n"
        u8"button.x = 20; button.y = 10; button.width = 80; button.height = 30\n"
        u8"button:on(\"mousedown\", function(e) x = e.x; localX = e.localX; count = e.clickCount; return true end)\n"
        u8"root:on(\"mousedown\", function(e) saw = saw + 1; return false end)\n"
        u8"function lastX() return x end\n"
        u8"function lastLocalX() return localX end\n"
        u8"function lastCount() return count end\n"
        u8"function rootSaw() return saw end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckEvents(bed);
}
#endif // OPTION_HAS_LUAU

namespace
{
    // Two fingers spread from 100 apart to 200 over the pad, then turned a quarter (E17c).
    void CheckGestures(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        (void)bed.root->UpdateLayout();
        gui::EventDispatcher& d = *bed.root->GetEventDispatcher();
        d.InjectTouchDown(1u, Float2{150.0f, 200.0f});
        d.InjectTouchDown(2u, Float2{250.0f, 200.0f});
        d.InjectTouchMove(1u, Float2{100.0f, 200.0f});
        d.InjectTouchMove(2u, Float2{300.0f, 200.0f});
        CHECK(bed.Number(u8"lastScale") == doctest::Approx(2.0));
        d.InjectTouchMove(1u, Float2{200.0f, 100.0f});
        d.InjectTouchMove(2u, Float2{200.0f, 300.0f});
        CHECK(bed.Number(u8"lastRotation") == doctest::Approx(1.5708).epsilon(0.01));
        d.InjectTouchUp(2u, Float2{200.0f, 300.0f});
        d.InjectTouchUp(1u, Float2{200.0f, 100.0f});
        CHECK(bed.Number(u8"started") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"ended") == doctest::Approx(1.0));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: an AngelScript handler takes a node's gestures, declared by its touch-action")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"double scale = 0; double rotation = 0; double startCount = 0; double endCount = 0;\n"
        u8"bool onStart(GuiEvent e) { startCount += 1; return true; }\n"
        u8"bool onChange(GuiEvent e) { scale = e.scale; rotation = e.rotation; return true; }\n"
        u8"bool onEnd(GuiEvent e) { endCount += 1; return true; }\n"
        u8"void main() {\n"
        u8"  Node@ pad = gui::root().add(\"Panel\");\n"
        u8"  pad.x = 50; pad.y = 50; pad.width = 300; pad.height = 300;\n"
        u8"  pad.touchAction = \"pan-x pan-y\";\n"
        u8"  pad.on(\"gesturestart\", EventHandler(onStart));\n"
        u8"  pad.on(\"gesturechange\", EventHandler(onChange));\n"
        u8"  pad.on(\"gestureend\", EventHandler(onEnd));\n"
        u8"}\n"
        u8"double lastScale() { return scale; }\n"
        u8"double lastRotation() { return rotation; }\n"
        u8"double started() { return startCount; }\n"
        u8"double ended() { return endCount; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckGestures(bed);
}
#endif // OPTION_HAS_ANGELSCRIPT

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: a Luau handler takes a node's gestures, declared by its touch-action")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local scale, rotation, startCount, endCount = 0, 0, 0, 0\n"
        u8"local pad = gui.root():add(\"Panel\")\n"
        u8"pad.x = 50; pad.y = 50; pad.width = 300; pad.height = 300\n"
        u8"pad.touchAction = \"none\"\n"
        u8"pad:on(\"gesturestart\", function(e) startCount = startCount + 1; return true end)\n"
        u8"pad:on(\"gesturechange\", function(e) scale = e.scale; rotation = e.rotation; return true end)\n"
        u8"pad:on(\"gestureend\", function(e) endCount = endCount + 1; return true end)\n"
        u8"function lastScale() return scale end\n"
        u8"function lastRotation() return rotation end\n"
        u8"function started() return startCount end\n"
        u8"function ended() return endCount end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckGestures(bed);
}
#endif // OPTION_HAS_LUAU

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: an AngelScript source and targets drag and drop, a dragquery handler taking a drop")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"double dropped = 0; double right = 0; double asked = 0; double ended = 0;\n"
        u8"bool onDrop(GuiEvent e) { dropped += 1; if (e.dragType == \"color\" && e.text == \"red\" && e.effect == \"move\") right += 1; return true; }\n"
        u8"bool onQuery(GuiEvent e) { asked += 1; return e.dragType == \"color\"; }\n"
        u8"bool onEnd(GuiEvent e) { if (e.effect == \"move\") ended += 1; return false; }\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  UIWidget@ swatch = UIWidget::of(root.add(\"Panel\"));\n"
        u8"  swatch.x = 10; swatch.y = 10; swatch.width = 60; swatch.height = 30;\n"
        u8"  swatch.dragType = \"color\"; swatch.dragValue = \"red\";\n"
        u8"  swatch.on(\"dragend\", EventHandler(onEnd));\n"
        u8"  Node@ canvas = root.add(\"Panel\");\n"
        u8"  canvas.x = 200; canvas.y = 10; canvas.width = 100; canvas.height = 100;\n"
        u8"  canvas.dropTypes = \"color\";\n"
        u8"  canvas.on(\"drop\", EventHandler(onDrop));\n"
        u8"  Node@ easel = root.add(\"Panel\");\n"
        u8"  easel.x = 200; easel.y = 150; easel.width = 100; easel.height = 100;\n"
        u8"  easel.on(\"dragquery\", EventHandler(onQuery));\n"
        u8"  easel.on(\"drop\", EventHandler(onDrop));\n"
        u8"}\n"
        u8"double droppedCount() { return dropped; }\n"
        u8"double rightCount() { return right; }\n"
        u8"double askedCount() { return asked; }\n"
        u8"double endedCount() { return ended; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    (void)bed.root->UpdateLayout();
    gui::EventDispatcher* d = bed.root->GetEventDispatcher();
    const auto dragTo = [&](Float2 to)
    {
        d->InjectMouseDown(Float2{20.0f, 20.0f}, gui::MouseButton::Left);
        d->InjectMouseMove(Float2{40.0f, 20.0f});
        d->InjectMouseMove(to);
        d->InjectMouseUp(to, gui::MouseButton::Left);
    };
    dragTo(Float2{250.0f, 50.0f}); // onto the canvas (drop-types)
    CHECK(bed.Number(u8"droppedCount") == doctest::Approx(1.0));
    CHECK(bed.Number(u8"rightCount") == doctest::Approx(1.0));
    CHECK(bed.Number(u8"endedCount") == doctest::Approx(1.0));
    dragTo(Float2{250.0f, 200.0f}); // onto the easel, which a dragquery handler takes
    CHECK(bed.Number(u8"askedCount") >= 1.0);
    CHECK(bed.Number(u8"droppedCount") == doctest::Approx(2.0));
}
#endif // OPTION_HAS_ANGELSCRIPT

namespace
{
    // Motion from a script (E14): the script has put a Label "box" first under the root, tweening
    // its x to 100 over a second (a callback at the end), playing a sequence that moves its y to 50
    // over a second, waits half a second and calls back, and a Slider second, springing its value
    // to 0.4. `finishedCount` counts the callbacks; `keptDone` reads the kept tween.
    void CheckMotion(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        gui::Node* box = bed.root->GetChildAt(0);
        gui::Slider* slider = Cast<gui::Slider>(bed.root->GetChildAt(1));
        REQUIRE(box != nullptr);
        REQUIRE(slider != nullptr);
        const auto advance = [&](double seconds) { bed.root->GetContext().Update(Duration::FromSeconds(seconds)); };
        advance(0.5);
        CHECK(box->GetPosition().x == doctest::Approx(50.0f));
        CHECK(box->GetPosition().y == doctest::Approx(25.0f));
        CHECK(bed.Number(u8"keptDone") == doctest::Approx(0.0));
        advance(0.5);
        CHECK(box->GetPosition().x == doctest::Approx(100.0f));
        CHECK(box->GetPosition().y == doctest::Approx(50.0f));
        CHECK(bed.Number(u8"finishedCount") == doctest::Approx(1.0)); // the tween's
        CHECK(bed.Number(u8"keptDone") == doctest::Approx(1.0));
        advance(0.5);
        CHECK(bed.Number(u8"finishedCount") == doctest::Approx(2.0)); // and the sequence's call
        for (int i = 0; i < 300; ++i)
            advance(1.0 / 60.0);
        CHECK(slider->GetValue() == doctest::Approx(0.4).epsilon(0.01));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript tweens, springs and plays a sequence (E14)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef void Done();\n"
        u8"int finished = 0;\n"
        u8"void tick() { finished++; }\n"
        u8"Tween@ kept;\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  Node@ box = root.add(\"Label\");\n"
        u8"  @kept = box.tween(\"x\", \"100\", 1.0, \"linear\").onFinished(Done(tick));\n"
        u8"  box.play(TweenSequence().add(box.createTween(\"y\", \"50\", 1.0, \"linear\")).wait(0.5).call(Done(tick)));\n"
        u8"  Node@ slider = root.add(\"Slider\");\n"
        u8"  slider.springTo(\"value\", \"0.4\", 400, 40, 1);\n"
        u8"}\n"
        u8"double finishedCount() { return finished; }\n"
        u8"double keptDone() { return kept.isDone() ? 1 : 0; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckMotion(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau tweens, springs and plays a sequence (E14)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local finished = 0\n"
        u8"local root = gui.root()\n"
        u8"local box = root:add(\"Label\")\n"
        u8"local kept = box:tween(\"x\", \"100\", 1.0, \"linear\"):onFinished(function() finished = finished + 1 end)\n"
        u8"box:play(TweenSequence.new():add(box:createTween(\"y\", \"50\", 1.0, \"linear\")):wait(0.5)"
        u8":call(function() finished = finished + 1 end))\n"
        u8"local slider = root:add(\"Slider\")\n"
        u8"slider:springTo(\"value\", \"0.4\", 400, 40, 1)\n"
        u8"function finishedCount() return finished end\n"
        u8"function keptDone() return kept:isDone() and 1 or 0 end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckMotion(bed);
}
#endif

namespace
{
    // Leaving (K0): the script has put a Button "card" (class "card") under the root, listening for
    // `transitionend` (`heardOpacity` is 1 once it heard the opacity's, `heardElapsed` its seconds),
    // and offers `goAway()`, which makes it leave, and `leaving()`, which reads whether it is.
    void CheckLeaving(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        REQUIRE(bed.root->ChildCount() == 1);
        gui::StyleManager styles(gui::CSSParser::Parse(
            StringView(u8".card { opacity: 1; transition: opacity 0.5s linear; } .card:leaving { opacity: 0; }")));
        const auto frame = [&](double seconds)
        {
            bed.root->GetContext().Update(Duration::FromSeconds(seconds));
            styles.ApplyTree(*bed.root);
        };
        frame(0.0);
        bed.Run(u8"goAway");
        CHECK(bed.Number(u8"leaving") == doctest::Approx(1.0));
        frame(0.0);
        frame(0.25);
        CHECK(bed.root->ChildCount() == 1);
        CHECK(bed.Number(u8"heardOpacity") == doctest::Approx(0.0));
        frame(0.25);
        CHECK(bed.Number(u8"heardOpacity") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"heardElapsed") == doctest::Approx(0.5));
        CHECK(bed.root->ChildCount() == 0);
        CHECK(bed.errors.count == 0);
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript makes a node leave and hears its transition end (K0)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"double heard = 0; double elapsed = 0;\n"
        u8"Button@ card;\n"
        u8"bool onEnd(GuiEvent e) { if (e.text == \"opacity\") { heard = 1; elapsed = e.elapsed; } return false; }\n"
        u8"void main() {\n"
        u8"  @card = Button::of(gui::root().add(\"Button\"));\n"
        u8"  card.addClass(\"card\");\n"
        u8"  card.on(\"transitionend\", EventHandler(onEnd));\n"
        u8"}\n"
        u8"void goAway() { card.leave(); }\n"
        u8"double leaving() { return card.isLeaving() ? 1 : 0; }\n"
        u8"double heardOpacity() { return heard; }\n"
        u8"double heardElapsed() { return elapsed; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckLeaving(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau makes a node leave and hears its transition end (K0)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local heard, elapsed = 0, 0\n"
        u8"local card = Button.of(gui.root():add(\"Button\"))\n"
        u8"card:addClass(\"card\")\n"
        u8"card:on(\"transitionend\", function(e) if e.text == \"opacity\" then heard = 1; elapsed = e.elapsed end return false end)\n"
        u8"function goAway() card:leave() end\n"
        u8"function leaving() return card:isLeaving() and 1 or 0 end\n"
        u8"function heardOpacity() return heard end\n"
        u8"function heardElapsed() return elapsed end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckLeaving(bed);
}
#endif

namespace
{
    // A data value tweened (K3): the script tweens `score` (0 at first) to 10 over a second and
    // offers `done()`, whether its tween ended.
    void CheckDataTween(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        const auto advance = [&](double seconds) { bed.root->GetContext().Update(Duration::FromSeconds(seconds)); };
        advance(0.5);
        const Variant half = bed.root->GetContext().GetData().Get(StringView(u8"score"));
        REQUIRE(half.TryGet<i32>() != nullptr);
        CHECK(*half.TryGet<i32>() == 5);
        CHECK(bed.Number(u8"done") == doctest::Approx(0.0));
        advance(0.5);
        CHECK(*bed.root->GetContext().GetData().Get(StringView(u8"score")).TryGet<i32>() == 10);
        CHECK(bed.Number(u8"done") == doctest::Approx(1.0));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript tweens a data value (K3)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    bed.root->GetContext().GetData().Set(StringView(u8"score"), Variant::From<i32>(0));
    const Status loaded = bed.context->Load(
        u8"Tween@ counting;\n"
        u8"void main() { @counting = gui::tween(\"score\", 10, 1.0, \"linear\"); }\n"
        u8"double done() { return counting.isDone() ? 1 : 0; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckDataTween(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau tweens a data value (K3)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    bed.root->GetContext().GetData().Set(StringView(u8"score"), Variant::From<i32>(0));
    const Status loaded = bed.context->Load(
        u8"local counting = gui.tween(\"score\", 10, 1.0, \"linear\")\n"
        u8"function done() return counting:isDone() and 1 or 0 end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckDataTween(bed);
}
#endif

namespace
{
    // The input kind (K2b): the script offers `isPad()` from gui.inputKind(), and counts the
    // root's `inputkind` events in `changes()`.
    void CheckInputKind(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        CHECK(bed.Number(u8"isPad") == doctest::Approx(0.0));
        bed.root->GetEventDispatcher()->SetInputKind(gui::InputKind::Pad);
        CHECK(bed.Number(u8"isPad") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"changes") == doctest::Approx(1.0));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript reads the input kind and hears it change (K2b)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"double heard = 0;\n"
        u8"bool onKind(GuiEvent e) { heard += 1; return false; }\n"
        u8"void main() { gui::root().on(\"inputkind\", EventHandler(onKind)); }\n"
        u8"double isPad() { return gui::inputKind() == \"pad\" ? 1 : 0; }\n"
        u8"double changes() { return heard; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckInputKind(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau reads the input kind and hears it change (K2b)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local heard = 0\n"
        u8"gui.root():on(\"inputkind\", function(e) heard = heard + 1; return false end)\n"
        u8"function isPad() return gui.inputKind() == \"pad\" and 1 or 0 end\n"
        u8"function changes() return heard end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckInputKind(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau hears an event a library names, with its detail (K4)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local heard = \"\"\n"
        u8"gui.root():on(\"screenenter\", function(e) heard = e.type .. \":\" .. e.text; return false end)\n"
        u8"function heardIt() return heard == \"screenenter:title\" and 1 or 0 end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    bed.root->SendNamedEvent(StringView(u8"screenleave"), StringView(u8"title"));
    CHECK(bed.Number(u8"heardIt") == doctest::Approx(0.0));
    bed.root->SendNamedEvent(StringView(u8"screenenter"), StringView(u8"title"));
    CHECK(bed.Number(u8"heardIt") == doctest::Approx(1.0));
}
#endif

namespace
{
    // Listener tokens (E16): the script put a Button 80 x 30 at the origin, listening for clicks
    // twice: `once` stops itself from inside, `always` stays until `stopAlways` turns it off.
    void CheckOff(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        (void)bed.root->UpdateLayout();
        bed.Click(Float2{10.0f, 10.0f});
        CHECK(bed.Number(u8"onceCount") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"alwaysCount") == doctest::Approx(1.0));
        bed.Click(Float2{10.0f, 10.0f});
        CHECK(bed.Number(u8"onceCount") == doctest::Approx(1.0)); // it stopped itself
        CHECK(bed.Number(u8"alwaysCount") == doctest::Approx(2.0));
        CHECK(bed.Number(u8"stopAlways") == doctest::Approx(1.0)); // off said it was there
        bed.Click(Float2{10.0f, 10.0f});
        CHECK(bed.Number(u8"alwaysCount") == doctest::Approx(2.0));
        CHECK(bed.Number(u8"stopAlways") == doctest::Approx(0.0)); // and now it is not
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript turns listeners off, from inside one too (E16)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"int onces = 0; int alwayses = 0; int onceToken = 0; int alwaysToken = 0;\n"
        u8"bool once(GuiEvent e) { onces++; gui::root().childAt(0).off(onceToken); return false; }\n"
        u8"bool always(GuiEvent e) { alwayses++; return false; }\n"
        u8"void main() {\n"
        u8"  Node@ button = gui::root().add(\"Button\");\n"
        u8"  button.width = 80; button.height = 30;\n"
        u8"  onceToken = button.on(\"click\", EventHandler(once));\n"
        u8"  alwaysToken = button.on(\"click\", EventHandler(always));\n"
        u8"}\n"
        u8"double onceCount() { return onces; }\n"
        u8"double alwaysCount() { return alwayses; }\n"
        u8"double stopAlways() { return gui::root().childAt(0).off(alwaysToken) ? 1 : 0; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckOff(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau turns listeners off, from inside one too (E16)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local onces, alwayses = 0, 0\n"
        u8"local button = gui.root():add(\"Button\")\n"
        u8"button.width = 80; button.height = 30\n"
        u8"local onceToken\n"
        u8"onceToken = button:on(\"click\", function() onces = onces + 1; button:off(onceToken); return false end)\n"
        u8"local alwaysToken = button:on(\"click\", function() alwayses = alwayses + 1; return false end)\n"
        u8"function onceCount() return onces end\n"
        u8"function alwaysCount() return alwayses end\n"
        u8"function stopAlways() return button:off(alwaysToken) and 1 or 0 end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckOff(bed);
}
#endif

namespace
{
    // Windows, menus and popups from a script (E16): under the root, a Window opened in place
    // (listened to for `close`), a Menu with one item "open" (its `activate` listened to), a Button
    // and a Panel; `openMenu` opens the menu at (20, 20), `openPanel` the panel as the button's
    // popup (an open auto popup closes another, so one at a time).
    template <typename T>
    T* FindIn(gui::Node& node)
    {
        if (T* found = Cast<T>(&node))
            return found;
        for (usize i = 0; i < node.ChildCount(); ++i)
            if (T* found = FindIn<T>(*node.GetChildAt(i)))
                return found;
        return nullptr;
    }

    void CheckOverlays(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        (void)bed.root->UpdateLayout();
        gui::EventDispatcher& d = *bed.root->GetEventDispatcher();
        // Held: closing removes the script's window from the page, its only other owner.
        const RefPtr<gui::Window> window(FindIn<gui::Window>(*bed.root));
        gui::Menu* menu = FindIn<gui::Menu>(*bed.root);
        gui::Panel* panel = FindIn<gui::Panel>(*bed.root);
        REQUIRE(window.Get() != nullptr);
        REQUIRE(menu != nullptr);
        REQUIRE(panel != nullptr);
        CHECK(window->IsOpen());
        CHECK(window->GetTitle() == StringView(u8"Settings"));

        bed.Run(u8"openMenu");
        CHECK(menu->IsOpen());
        (void)bed.root->UpdateLayout();
        gui::Node* item = menu->GetChildAt(0);
        REQUIRE(item != nullptr);
        bed.Click(item->ConvertToWorldSpace(Float2{item->GetSize().x * 0.5f, item->GetSize().y * 0.5f}));
        CHECK(bed.Number(u8"pickedOpen") == doctest::Approx(1.0));
        CHECK_FALSE(menu->IsOpen());
        // Closed, the script's menu went back where it waits (nothing else keeps it), unseen there,
        // and opens again.
        CHECK(menu->GetParent() != nullptr);
        CHECK_FALSE(menu->IsDisplayed());
        bed.Run(u8"openMenu");
        CHECK(menu->IsOpen());
        (void)d.InjectKeyDown(static_cast<u32>(gui::KeyCode::Escape));
        CHECK_FALSE(menu->IsOpen());

        bed.Run(u8"openPanel");
        CHECK(d.IsPopupOpen(*panel));
        bed.Run(u8"closePanel");
        CHECK_FALSE(d.IsPopupOpen(*panel));
        CHECK(panel->GetParent() == bed.root.Get()); // back where it stood
        bed.Run(u8"openPanel");
        CHECK(d.IsPopupOpen(*panel));
        bed.Run(u8"closePanel");

        bed.Run(u8"closeWindow");
        CHECK_FALSE(window->IsOpen());
        CHECK(bed.Number(u8"closeCount") == doctest::Approx(1.0));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript opens windows, menus and popups of its own (E16)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"int closes = 0; bool picked = false;\n"
        u8"bool onClose(GuiEvent e) { closes++; return false; }\n"
        u8"bool onActivate(GuiEvent e) { picked = e.id == \"open\"; return true; }\n"
        u8"Node@ win; Node@ panel; Node@ menu; Node@ anchor;\n"
        u8"void main() {\n"
        u8"  Node@ root = gui::root();\n"
        u8"  @win = root.add(\"Window\"); win.width = 200; win.height = 150;\n"
        u8"  Window::of(win).title = \"Settings\";\n"
        u8"  win.on(\"close\", EventHandler(onClose));\n"
        u8"  Window::of(win).open();\n"
        u8"  @menu = root.add(\"Menu\");\n"
        u8"  Node@ item = menu.add(\"MenuItem\");\n"
        u8"  MenuItem::of(item).text = \"Open\";\n"
        u8"  UIWidget::of(item).id = \"open\";\n"
        u8"  menu.on(\"activate\", EventHandler(onActivate));\n"
        u8"  @anchor = root.add(\"Button\"); anchor.width = 80; anchor.height = 30;\n"
        u8"  @panel = root.add(\"Panel\"); panel.width = 100; panel.height = 60;\n"
        u8"}\n"
        u8"void openMenu() { Menu::of(menu).openAt(20, 20); }\n"
        u8"void openPanel() { anchor.popup(panel); }\n"
        u8"void closeWindow() { Window::of(win).close(); }\n"
        u8"void closePanel() { panel.closePopup(); }\n"
        u8"double closeCount() { return closes; }\n"
        u8"double pickedOpen() { return picked ? 1 : 0; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckOverlays(bed);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau opens windows, menus and popups of its own (E16)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    const Status loaded = bed.context->Load(
        u8"local closes, picked = 0, false\n"
        u8"local root = gui.root()\n"
        u8"local win = root:add(\"Window\"); win.width = 200; win.height = 150\n"
        u8"Window.of(win).title = \"Settings\"\n"
        u8"win:on(\"close\", function() closes = closes + 1; return false end)\n"
        u8"Window.of(win):open()\n"
        u8"local menu = root:add(\"Menu\")\n"
        u8"local item = menu:add(\"MenuItem\")\n"
        u8"MenuItem.of(item).text = \"Open\"\n"
        u8"UIWidget.of(item).id = \"open\"\n"
        u8"menu:on(\"activate\", function(e) picked = e.id == \"open\"; return true end)\n"
        u8"local anchor = root:add(\"Button\"); anchor.width = 80; anchor.height = 30\n"
        u8"local panel = root:add(\"Panel\"); panel.width = 100; panel.height = 60\n"
        u8"function openMenu() Menu.of(menu):openAt(20, 20) end\n"
        u8"function openPanel() anchor:popup(panel) end\n"
        u8"function closeWindow() Window.of(win):close() end\n"
        u8"function closePanel() panel:closePopup() end\n"
        u8"function closeCount() return closes end\n"
        u8"function pickedOpen() return picked and 1 or 0 end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckOverlays(bed);
}
#endif

namespace
{
    // A script's list model and localized texts (E16): the script made a ListModel of three rows,
    // shown by a ListView it put first under the root, and keeps `edit` to change it; the GUI's
    // localization has `title` and the plural `lives`.
    struct Texts
    {
        foundation::i18n::StringTable table;
        foundation::i18n::Localization loc;
        Texts()
        {
            REQUIRE(table.Set(StringView(u8"title"), StringView(u8"en"), StringView(u8"Settings")));
            REQUIRE(table.SetPluralRule(StringView(u8"en"), StringView(u8"one: n = 1")));
            REQUIRE(table.SetPlural(StringView(u8"lives"), StringView(u8"en"), foundation::i18n::PluralCategory::One, StringView(u8"{0} life")));
            REQUIRE(table.SetPlural(StringView(u8"lives"), StringView(u8"en"), foundation::i18n::PluralCategory::Other, StringView(u8"{0} lives")));
            loc.AddTable(&table);
            loc.SetLanguage(StringView(u8"en"));
        }
    };

    void CheckModelAndTexts(GuiBed& bed)
    {
        REQUIRE(bed.errors.count == 0);
        gui::ListView* list = Cast<gui::ListView>(bed.root->GetChildAt(0));
        REQUIRE(list != nullptr);
        CHECK(list->GetModel()->RowCount() == 3u);
        bed.Run(u8"edit"); // insert at 1, remove the last, rename the first
        CHECK(list->GetModel()->RowCount() == 3u);
        CHECK(bed.Number(u8"firstIsAlpha") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"secondIsNew") == doctest::Approx(1.0));
        CHECK(bed.Number(u8"textsRight") == doctest::Approx(1.0));
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript fills a list model and reads localized texts (E16)")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    Texts texts;
    bed.root->GetContext().SetLocalization(&texts.loc);
    const Status loaded = bed.context->Load(
        u8"ListModel@ model;\n"
        u8"void main() {\n"
        u8"  @model = ListModel();\n"
        u8"  model.add(\"one\"); model.add(\"two\"); model.add(\"three\");\n"
        u8"  ListView::of(gui::root().add(\"ListView\")).setModel(model);\n"
        u8"}\n"
        u8"void edit() { model.insert(1, \"new\"); model.remove(model.count() - 1); model.set(0, \"alpha\"); }\n"
        u8"double firstIsAlpha() { return model.get(0) == \"alpha\" ? 1 : 0; }\n"
        u8"double secondIsNew() { return model.get(1) == \"new\" ? 1 : 0; }\n"
        u8"double textsRight() { return gui::tr(\"title\") == \"Settings\" && gui::trCount(\"lives\", 3) == \"3 lives\" &&\n"
        u8"  gui::trCount(\"lives\", 1) == \"1 life\" && gui::tr(\"missing\") == \"missing\" && gui::language() == \"en\" ? 1 : 0; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckModelAndTexts(bed);
    bed.root->GetContext().SetLocalization(nullptr);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau fills a list model and reads localized texts (E16)")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    Texts texts;
    bed.root->GetContext().SetLocalization(&texts.loc);
    const Status loaded = bed.context->Load(
        u8"local model = ListModel.new()\n"
        u8"model:add(\"one\"); model:add(\"two\"); model:add(\"three\")\n"
        u8"ListView.of(gui.root():add(\"ListView\")):setModel(model)\n"
        u8"function edit() model:insert(1, \"new\"); model:remove(model:count() - 1); model:set(0, \"alpha\") end\n"
        u8"function firstIsAlpha() return model:get(0) == \"alpha\" and 1 or 0 end\n"
        u8"function secondIsNew() return model:get(1) == \"new\" and 1 or 0 end\n"
        u8"function textsRight() return (gui.tr(\"title\") == \"Settings\" and gui.trCount(\"lives\", 3) == \"3 lives\" and\n"
        u8"  gui.trCount(\"lives\", 1) == \"1 life\" and gui.tr(\"missing\") == \"missing\" and gui.language() == \"en\") and 1 or 0 end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckModelAndTexts(bed);
    bed.root->GetContext().SetLocalization(nullptr);
}
#endif

namespace
{
    // Toasts from a script (T7 of round three): the script found the host the bed placed, filled in
    // a request (a title, a message, success, staying, the class `pop`, an action "reveal") and
    // posted it, posted a widget's toast, and listens for `activate` on the host, writing the
    // pressed action's id to the data as `pressed`.
    void CheckToasts(GuiBed& bed, gui::ToastHost& host)
    {
        INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
        REQUIRE(bed.errors.count == 0);
        REQUIRE(host.ShownCount() == 2);
        CHECK(bed.Number(u8"shown") == doctest::Approx(2.0));
        gui::ToastCard* card = Cast<gui::ToastCard>(host.GetChildAt(0));
        REQUIRE(card != nullptr);
        REQUIRE(card->GetTitlePart() != nullptr);
        CHECK(card->GetTitlePart()->GetText() == StringView(u8"Exported"));
        CHECK(card->GetMessagePart()->GetText() == StringView(u8"Town is in Dist/Town."));
        CHECK(card->HasClass(StringView(u8"success")));
        CHECK(card->HasClass(StringView(u8"pop")));
        CHECK(card->GetRemaining() < 0.0f); // duration 0: until closed
        REQUIRE(card->ActionCount() == 1);
        CHECK(card->ActionAt(0).GetText() == StringView(u8"Reveal"));
        gui::ToastCard* widget = Cast<gui::ToastCard>(host.GetChildAt(1));
        REQUIRE(widget != nullptr);
        CHECK(Cast<gui::Label>(widget->GetContent()) != nullptr);
        CHECK(widget->GetAnnouncement() == StringView(u8"From a widget"));

        (void)card->ActionAt(0).HandleActivate();
        CHECK(bed.root->GetContext().GetData().Get(u8"pressed").Get<String>() == StringView(u8"reveal"));
        CHECK(host.ShownCount() == 1);
        CHECK(bed.errors.count == 0);
    }
}

#ifdef OPTION_HAS_ANGELSCRIPT
TEST_CASE("gui-script: AngelScript fills in a toast request and posts it, and hears its action")
{
    RefPtr<IScriptManager> manager = Bound(angelscript::CreateScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    RefPtr<gui::ToastHost> host = MakeRef<gui::ToastHost>(DefaultAllocator());
    bed.root->AddChild(host.Get());
    const Status loaded = bed.context->Load(
        u8"funcdef bool EventHandler(GuiEvent e);\n"
        u8"bool onAction(GuiEvent e) { gui::set(\"pressed\", e.id); return true; }\n"
        u8"void main() {\n"
        u8"  ToastHost@ host = ToastHost::nearest(gui::root());\n"
        u8"  ToastRequest r;\n"
        u8"  r.title = \"Exported\";\n"
        u8"  r.message = \"Town is in Dist/Town.\";\n"
        u8"  r.severity = ToastSeverity::Success;\n"
        u8"  r.duration = 0;\n"
        u8"  r.classes = \"pop\";\n"
        u8"  r.addAction(\"reveal\", \"Reveal\", \"\");\n"
        u8"  host.post(r);\n"
        u8"  host.on(\"activate\", EventHandler(onAction));\n"
        u8"  Node@ label = gui::root().add(\"Label\");\n"
        u8"  ToastRequest w;\n"
        u8"  w.announcement = \"From a widget\";\n"
        u8"  host.postContent(w, label);\n"
        u8"}\n"
        u8"double shown() { return ToastHost::nearest(gui::root()).shownCount; }\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckToasts(bed, *host);
}
#endif

#ifdef OPTION_HAS_LUAU
TEST_CASE("gui-script: Luau fills in a toast request and posts it, and hears its action")
{
    RefPtr<IScriptManager> manager = Bound(CreateLuauScriptManager(DefaultAllocator()));
    GuiBed bed(*manager);
    RefPtr<gui::ToastHost> host = MakeRef<gui::ToastHost>(DefaultAllocator());
    bed.root->AddChild(host.Get());
    const Status loaded = bed.context->Load(
        u8"local host = ToastHost.nearest(gui.root())\n"
        u8"local r = ToastRequest.new()\n"
        u8"r.title = \"Exported\"\n"
        u8"r.message = \"Town is in Dist/Town.\"\n"
        u8"r.severity = ToastSeverity.Success\n"
        u8"r.duration = 0\n"
        u8"r.classes = \"pop\"\n"
        u8"r:addAction(\"reveal\", \"Reveal\", \"\")\n"
        u8"host:post(r)\n"
        u8"host:on(\"activate\", function(e) gui.set(\"pressed\", e.id); return true end)\n"
        u8"local label = gui.root():add(\"Label\")\n"
        u8"local w = ToastRequest.new()\n"
        u8"w.announcement = \"From a widget\"\n"
        u8"host:postContent(w, label)\n"
        u8"function shown() return host.shownCount end\n",
        u8"main");
    INFO(doctest::String(reinterpret_cast<const char*>(bed.errors.last.CStr())));
    REQUIRE(loaded.IsOk());
    CheckToasts(bed, *host);
}
#endif
