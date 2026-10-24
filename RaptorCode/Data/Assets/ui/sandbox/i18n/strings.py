#!/usr/bin/env python3
# SPDX-License-Identifier: MIT
# Copyright (c) 2026-Present Robert Campbell
#
# Writes sandbox.strings.xml, the GUI sandbox's string table (E9e of
# Documentation/Specs/gui-lab-evolution.md), from the texts below: a foundation.i18n StringTable as
# its versioned payload reads through the XML serializer. The table is the source the sandbox
# loads; this script is how it is written, until the pipeline converts other formats (CSV).
# Run it after changing a text: python3 strings.py
import os
from xml.sax.saxutils import escape

# English, and Arabic (the right-to-left language: it joins its letters and uses every plural
# category). Language names are not keys: each shows in its own language.
LOCALES = [
    ("en", "one: n = 1", "ltr"),
    ("ar", "zero: n = 0; one: n = 1; two: n = 2; few: n % 100 = 3..10; many: n % 100 = 11..99", "rtl"),
]

TEXTS = {
    "lang.title": ("Language and direction", "اللغة والاتجاه"),
    "lang.lead": (
        "Every text on this page is a key in a string table, resolved through the GUI's localization. "
        "Choose a language and the page follows it; Arabic turns the whole GUI right to left.",
        "كل نص في هذه الصفحة مفتاح في جدول نصوص تترجمه الواجهة. "
        "اختر لغة فتتبعها الصفحة، والعربية تجعل الواجهة كلها من اليمين إلى اليسار."),
    "lang.choose": ("Language", "اللغة"),
    "lang.changed": ("Language: English", "اللغة: العربية"),
    "dir.title": ("Direction", "الاتجاه"),
    "dir.language": ("As the language", "حسب اللغة"),
    "dir.ltr": ("Left to right", "من اليسار إلى اليمين"),
    "dir.rtl": ("Right to left", "من اليمين إلى اليسار"),
    "form.title": ("A form", "نموذج"),
    "form.name": ("Name", "الاسم"),
    "form.name.hint": ("Your name", "اسمك"),
    "form.volume": ("Volume", "مستوى الصوت"),
    "form.music": ("Music", "الموسيقى"),
    "form.save": ("Save", "حفظ"),
    "form.cancel": ("Cancel", "إلغاء"),
    "files.title": ("Counting", "العدّ"),
    "files.more": ("More", "أكثر"),
    "files.fewer": ("Fewer", "أقل"),
    "mixed.title": ("Mixed directions", "اتجاهات مختلطة"),
    "mixed.lead": (
        "Arabic and Latin in one line, and a field to edit them in: the arrows move as the text shows.",
        "عربي ولاتيني في سطر واحد، وحقل لتحريرهما: تتحرك الأسهم كما يظهر النص."),
    # The lab's own widgets' labels (a message box's buttons, a field's context menu).
    "gui.ok": ("OK", "موافق"),
    "gui.cancel": ("Cancel", "إلغاء"),
    "gui.yes": ("Yes", "نعم"),
    "gui.no": ("No", "لا"),
    "gui.cut": ("Cut", "قص"),
    "gui.copy": ("Copy", "نسخ"),
    "gui.paste": ("Paste", "لصق"),
    "gui.select-all": ("Select all", "تحديد الكل"),
    # The game menu (the showcase, G6), its settings in Arabic the screen of E17a.
    "menu.welcome": ("Welcome back, {0}", "مرحبًا بعودتك يا {0}"),
    "menu.play": ("Play", "العب"),
    "menu.settings": ("Settings", "الإعدادات"),
    "menu.controls": ("Controls", "التحكم"),
    "menu.quit": ("Quit", "خروج"),
    "menu.back": ("Back", "رجوع"),
    "settings.volume": ("Volume", "الصوت"),
    "settings.music": ("Music", "الموسيقى"),
    "settings.name": ("Name", "الاسم"),
    "settings.on": ("On", "تشغيل"),
    "settings.off": ("Off", "إيقاف"),
    "controls.jump": ("Jump", "قفز"),
    "controls.dash": ("Dash", "اندفاع"),
    "controls.interact": ("Interact", "تفاعل"),
    "controls.map": ("Map", "الخريطة"),
    "controls.choose": ("Choose an action to change its key", "اختر إجراءً لتغيير مفتاحه"),
    "controls.press": ("Press a key...", "اضغط مفتاحًا..."),
    "controls.keep": ("A key or a pad button; Esc to keep ", "مفتاح أو زر في يد التحكم؛ Esc للإبقاء على "),
    "controls.swapped": ("Swapped with ", "تبادل مع "),
    "loading.loading": ("Loading...", "جارٍ التحميل..."),
    "loading.ready": ("Ready", "جاهز"),
    "hud.health": ("HEALTH", "الصحة"),
    "hud.score": ("SCORE", "النقاط"),
    "hud.objective": ("Gather the drifting lights", "اجمع الأضواء العائمة"),
    "hud.pause": ("Pause", "إيقاف مؤقت"),
    "pause.title": ("Paused", "متوقف مؤقتًا"),
    "pause.resume": ("Resume", "استئناف"),
    "pause.to-menu": ("Quit to menu", "العودة إلى القائمة"),
    "leave.title": ("Leave so soon?", "تغادر بهذه السرعة؟"),
    "leave.yes": ("Leave", "غادر"),
    "leave.no": ("Stay", "ابقَ"),
}

# Plural entries: each locale's forms by category.
PLURALS = {
    "files.count": (
        {"one": "{0} file", "other": "{0} files"},
        {"zero": "لا توجد ملفات", "one": "ملف واحد", "two": "ملفان", "few": "{0} ملفات", "many": "{0} ملفًا", "other": "{0} ملف"},
    ),
}

CATEGORIES = ["zero", "one", "two", "few", "many", "other"]


def type_id(namespace, name):
    """The type's stable id, as RTTI computes it: FNV-1a over "<namespace>::<name>"."""
    h = 0xCBF29CE484222325
    for b in (namespace + "::" + name).encode():
        h = ((h ^ b) * 0x100000001B3) & 0xFFFFFFFFFFFFFFFF
    return h


def string(name, value, indent):
    return f'{indent}<string name="{name}">{escape(value)}</string>\n' if value else f'{indent}<string name="{name}"/>\n'


def main():
    out = ["<root>\n"]
    out.append('\t<array name="dataVersions" count="1">\n')
    out.append(f'\t\t<u64 name="type">{type_id("rtti::foundation::i18n", "StringTable")}</u64>\n')
    out.append('\t\t<u32 name="version">1</u32>\n')
    out.append("\t</array>\n")
    out.append(f'\t<array name="locales" count="{len(LOCALES)}">\n')
    for locale, rule, direction in LOCALES:
        out.append("\t\t<object>\n")
        out.append(string("id", locale, "\t\t\t"))
        out.append(f'\t\t\t<bool name="hasRule">{"true" if rule else "false"}</bool>\n')
        out.append(string("rule", rule, "\t\t\t"))
        out.append(string("direction", direction, "\t\t\t"))
        out.append("\t\t</object>\n")
    out.append("\t</array>\n")
    entries = [(key, False, texts) for key, texts in TEXTS.items()] + [(key, True, forms) for key, forms in PLURALS.items()]
    out.append(f'\t<array name="entries" count="{len(entries)}">\n')
    for key, plural, cells in entries:
        out.append("\t\t<object>\n")
        out.append(string("key", key, "\t\t\t"))
        out.append(f'\t\t\t<bool name="plural">{"true" if plural else "false"}</bool>\n')
        out.append(f'\t\t\t<array name="cells" count="{len(LOCALES)}">\n')
        for cell in cells:
            out.append("\t\t\t\t<object>\n")
            forms = cell if plural else {}
            present = bool(cell) and not plural
            mask = sum(1 << i for i, c in enumerate(CATEGORIES) if c in forms)
            out.append(f'\t\t\t\t\t<bool name="present">{"true" if present else "false"}</bool>\n')
            out.append(string("text", cell if present else "", "\t\t\t\t\t"))
            out.append(f'\t\t\t\t\t<u8 name="forms">{mask}</u8>\n')
            for category in CATEGORIES:
                out.append(string(category, forms.get(category, ""), "\t\t\t\t\t"))
            out.append("\t\t\t\t</object>\n")
        out.append("\t\t\t</array>\n")
        out.append("\t\t</object>\n")
    out.append("\t</array>\n")
    out.append("</root>\n")
    path = os.path.join(os.path.dirname(os.path.abspath(__file__)), "sandbox.strings.xml")
    with open(path, "w", encoding="utf-8") as f:
        f.write("".join(out))
    print("wrote", path)


if __name__ == "__main__":
    main()
