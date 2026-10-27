# Laboratório visual — terminal industrial corporativo

Abra `tests/design_system_preview.tscn` no Godot e execute com F6.

- Clique esquerdo: próxima tela.
- Segurar 0,8 s: tela anterior.
- Seis propostas: ativação/menu, linha de produção, registros, descarte, reboot e guia de componentes.
- Dados fictícios. Nenhum salvamento, placar, estado de robô ou navegação das cenas atuais é modificado.
- Os controles apenas alternam propostas; não iniciam partidas. O menu alterna a seleção automaticamente.

Tokens compartilhados: `scripts/ui/industrial_ui.gd`; `industrial_style.gd` apenas os reutiliza. Componentes desenhados com primitivas do Godot para avaliar o design antes da arte final.

Fonte Tiny5 sob SIL Open Font License 1.1, incluída em `res://fonts/OFL.txt`.
Fonte oficial: https://github.com/google/fonts/tree/main/ofl/tiny5
Download da família: https://fonts.googleapis.com/css2?family=Tiny5

Para gerar seis capturas: `godot --path . res://tests/design_system_preview.tscn -- --capture`.
As imagens são geradas em `tests/design_system/previews/`.

A interface principal já usa o layout simplificado e a AAP-64. Esta cena continua disponível como laboratório visual sem alterar dados do jogo.
