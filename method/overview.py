from gdo.base.GDT import GDT
from gdo.base.Method import Method
from gdo.ui.GDT_Card import GDT_Card
from gdo.ui.GDT_Link import GDT_Link
from gdo.ui.GDT_Panel import GDT_Panel


class overview(Method):
    """$khedr: Khedr introduces himself, built only from GDTs so it renders in HTML, CLI and chat."""

    SECTIONS = ('who', 'team', 'does', 'talk', 'rules')

    @classmethod
    def gdo_trigger(cls) -> str:
        return 'khedr'

    def gdo_execute(self) -> GDT:
        card = GDT_Card().title('khedr_intro_title')
        card.get_header().add_field(GDT_Panel().text('khedr_intro_tagline'))
        for key in self.SECTIONS:
            card.get_content().add_field(
                GDT_Panel().title(f'khedr_intro_{key}_title').text(f'khedr_intro_{key}_text'))
        card.get_footer().add_fields(
            GDT_Link().href('https://codegeex.dev/').text('khedr_intro_link_site'),
            GDT_Link().href('https://github.com/87x0').text('khedr_intro_link_github'),
        )
        return card
