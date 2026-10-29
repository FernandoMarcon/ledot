# Ranger's kitty image method can't draw through tmux, so inside tmux turn
# image previews off and let scope.sh render images as chafa text art.
# Runs after rc.conf is sourced, so it overrides `set preview_images true`.
import os

import ranger.api

HOOK_INIT_OLD = ranger.api.hook_init


def hook_init(fm):
    if os.environ.get('TMUX'):
        fm.settings.preview_images = False
    return HOOK_INIT_OLD(fm)


ranger.api.hook_init = hook_init
