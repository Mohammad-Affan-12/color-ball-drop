# Localization

Godot CSV translations ship for core controls/HUD in English, Spanish, Brazilian Portuguese, French, German and Indonesian. Device language is automatic; Settings → Privacy & data choices → Language overrides it. English is the fallback. Brand and level names are retained. This is localization infrastructure and an initial translation pass, not a claim that every puzzle, accessibility message or legal text is translated.

Keep English message IDs stable. Translate a format string before substituting values, preserving `%d`, `%02d`, `%s`, newlines, symbols and whitespace. New static Control captions auto-translate; strings composed before assignment need `tr()` on each message. `resources/i18n/ui.csv` is the editable source; Godot imports `.translation` resources. Run `tools/extract_localization.gd` to regenerate the review inventory from actual scripts. Never silently translate or modify level solution geometry.

Before broadening each listing locale, a native speaker must review tutorial hints, all five chapters, plural forms, privacy text, overflow at 540×960, and diacritics. Arabic/Hindi/CJK are not advertised as supported yet: ship suitable font subsets and validate shaping/RTL layouts first. Re-test pseudolocalization/long German labels. The game remains playable with English fallback worldwide.
