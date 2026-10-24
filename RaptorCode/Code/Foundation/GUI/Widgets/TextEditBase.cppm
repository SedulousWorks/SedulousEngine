// SPDX-License-Identifier: MIT
// Copyright (c) 2026-Present Robert Campbell

// GUI - :text_edit_base partition, what is left of it after slice S16: the context menu's labels
// translated where the GUI's tables have them, through Node::BindTranslation (S19, the script
// surface). The rest is Code/Foundation/Sedulous.GUI/src/Widgets/TextEditBase.bf (TextEditBase,
// whose OnContextMenu sets the English labels alone until then; TextField, TextArea, NumberField
// with SpinButton, EditableLabel, and ColorPicker with ColorSwatch and ColorPickerArea, are in their
// own files there).

export namespace foundation::gui
{
    class TextEditBase : public UIWidget
    {
    protected:
        // Cut, copy, paste and select all: each item's label translated (gui.cut, ...) where the
        // GUI's tables have it, else English. OnContextMenu's lines that TextEditBase.bf leaves out
        // (its AddEditItem adds the item and its English label):
        void OnContextMenu(const MouseEvent& event) override
        {
            // ...
                TextEditBase* self = this;
                // Each label translated (gui.cut, ...) where the GUI's tables have it, else English.
                const auto add = [&](const char8_t* label, const char8_t* key, TextEditCommand command)
                {
                    MenuItem* item = m_contextMenu->AddItem(core::StringView(label), [self, command] { self->RunEdit(command); });
                    (void)item->BindTranslation(core::StringView(u8"text"), core::StringView(key), {}, {}, {}, core::StringView(label));
                    m_contextItems.PushBack(item);
                };
                add(u8"Cut", u8"gui.cut", TextEditCommand::Cut);
                add(u8"Copy", u8"gui.copy", TextEditCommand::Copy);
                add(u8"Paste", u8"gui.paste", TextEditCommand::Paste);
                m_contextMenu->AddSeparator();
                add(u8"Select all", u8"gui.select-all", TextEditCommand::SelectAll);
            // ...
        }
    };
}
