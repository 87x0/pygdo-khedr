from __future__ import annotations

from gdo.base.GDO_Module import GDO_Module
from gdo.base.GDO import GDO
from gdo.base.GDT import GDT
from gdo.ui.GDT_Link import GDT_Link
from gdo.base.Application import Application

import os
import datetime

from typing import TYPE_CHECKING

if TYPE_CHECKING:
    from gdo.ui.GDT_Page import GDT_Page


class module_khedr(GDO_Module):

    def gdo_classes(self) -> list[type[GDO]]:
        return []

    async def gdo_install(self):
        pass

    def gdo_module_config(self) -> list[GDT]:
        return []

    def gdo_user_config(self) -> list[GDT]:
        return []

    def gdo_user_settings(self) -> list[GDT]:
        return []

    def gdo_init(self):
        pass

    def gdo_subscribe_events(self):
        Application.EVENTS.subscribe_times('new_message', self.on_new_message_log, 2_238_239_328)

    async def on_new_message_log(self, message):
        """Channel-tagged chat log for catch-up summaries (private dir, mode 600).
        One line per incoming message: <utc ts> #<channel_id|-> <user{server}> <displayname> >> <text>
        '#-' = private chat: never show those to anyone but that person."""
        try:
            channel = getattr(message, '_env_channel', None)
            user = getattr(message, '_env_reply_to', None) or message._env_user
            if user.get_server().get_name().lower() != 'telegram':
                return  # chat only: never log bash/web/tcp lines (e.g. $tcpauth carries a password)
            text = (message._message or '').replace('\r', ' ').replace('\n', ' / ')
            chan = f'#{channel.get_id()}' if channel else '#-'
            now = datetime.datetime.now(datetime.timezone.utc)
            folder = os.path.expanduser('~/data/chatlog')
            os.makedirs(folder, mode=0o700, exist_ok=True)
            path = os.path.join(folder, now.strftime('%Y-%m-%d') + '.log')
            fd = os.open(path, os.O_WRONLY | os.O_CREAT | os.O_APPEND, 0o600)
            with os.fdopen(fd, 'a', encoding='utf-8') as f:
                f.write(f"{now.strftime('%H:%M:%S')} {chan} {user.get_name_sid()} {user.get_displayname()} >> {text}\n")
        except Exception:
            pass

    def gdo_load_scripts(self, page: 'GDT_Page'):
        self.add_js('js/pygdo-khedr.js')
        self.add_css('css/pygdo-khedr.css')

    def gdo_init_sidebar(self, page: 'GDT_Page'):
        page._left_bar.add_field(GDT_Link().href(self.href('overview')).text('module_khedr'))
