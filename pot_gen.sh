#!/bin/bash
# SPDX-FileCopyrightText: None
# SPDX-License-Identifier: CC0-1.0

xgettext --from-code=UTF-8 \
    --add-comments=TRANSLATORS: \
    --keyword=i18n:1 \
    --keyword=i18nc:1c,2 \
    --keyword=i18np:1,2 \
    --keyword=i18ncp:1c,2,3 \
    -o po/piki.pot $(find . -name '*.cpp' -o -name '*.h' -o -name '*.qml')
