// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :message_box partition, what is left of it after slice S15: a standard button's label
// translated where the GUI's tables have it, through Node::BindTranslation (S19, the script
// surface). The rest is Code/Foundation/Sedulous.GUI/src/Widgets/MessageBox.bf (MessageBox, whose
// AddStandard sets the English label alone until then).

export namespace foundation::gui
{
    class MessageBox : public Window
    {
    private:
        // A standard button: its label translated (gui.ok, ...) where the GUI's tables have it,
        // else English. AddStandard's lines that MessageBox.bf leaves out:
        void AddStandard(Result result)
        {
            static constexpr core::StringView kKeys[] = {u8"gui.ok", u8"gui.cancel", u8"gui.yes", u8"gui.no"};
            // ...
            (void)button.BindTranslation(core::StringView(u8"text"), kKeys[i], {}, {}, {}, kEnglish[i]);
        }
    };
}
