# Unidade 404: Futuro Não Encontrado

**[Read in English](README.md)**

Jogo arcade 2D de precisão em pixel art, **vencedor da Game Jam da XXII Semana Acadêmica de Ciência da Computação da Universidade Federal Fluminense (UFF)**.

## Descrição

A fábrica nunca para. Humanos erram e têm justificativas. Robôs não têm esse privilégio: um erro de montagem ou o fim do tempo, e a unidade é desligada. Você é um desses robôs e precisa escolher ferramentas, instalar e remover peças o mais rápido possível antes que o substituam.

O fim é certo, mas a diversão é garantida!

## Sobre a competição

O tema da Game Jam foi **“Apenas um input”**, uma limitação tanto para o desenvolvimento quanto para a jogabilidade. Este jogo utiliza apenas o **botão esquerdo do mouse (LMB)**.

A competição contou com dez equipes de desenvolvedores alunos da UFF. Os jogos foram avaliados por votação aberta durante o evento, sob a supervisão do organizador e docente da UFF [@JoaoVitorSantiagoNogueira](https://github.com/JoaoVitorSantiagoNogueira).

| Critério | Colocação |
| --- | --- |
| Adesão ao tema | 1º lugar |
| Criatividade | 2º lugar |
| Polimento | 3º lugar |
| Diversão | 4º lugar |
| **Média final** | **1º lugar** |

## Equipe

| Integrante | Papel | Contribuições |
| --- | --- | --- |
| Mariana Bravo ([@mariana-bravo](https://github.com/mariana-bravo)) | Game Designer e Líder Criativa | Desenvolveu o conceito e a direção criativa do jogo, implementou funcionalidades e orientou a equipe de desenvolvimento. |
| João Victor Freitas ([@joaov-freitas](https://github.com/joaov-freitas)) | Desenvolvedor Principal e Responsável pela Integração | Liderou a programação e integrou as funcionalidades ao jogo. |
| Alysson Lucas ([@AlyssonLucasVFSoares](https://github.com/AlyssonLucasVFSoares)) | Artista Pixel Art e Responsável pelos Recursos Visuais e de Áudio | Criou a pixel art e os recursos visuais originais; cuidou da seleção, preparação e integração de fontes e áudios. |

## Acesso ao jogo

Baixe a versão para Windows em [Releases no GitHub](https://github.com/mariana-bravo/unidade-404-game/releases).

### Executar pelo projeto-fonte

1. Instale o [Godot 4.7.2 ou mais recente, edição padrão](https://godotengine.org/).
2. No gerenciador de projetos, selecione **Importar** e abra `project.godot`.
3. No Godot, abra **Projeto → Exportar**.
4. Use a configuração existente **Windows Desktop** ou adicione-a, se necessário.
5. Instale os modelos de exportação correspondentes, caso solicitado.
6. Clique em **Exportar Projeto** e escolha a pasta de destino.

O destino configurado é Windows x86_64. O ícone do executável está em `art/unidade-404.ico`.

## Controles

O jogo usa apenas o **botão esquerdo do mouse**, sem necessidade de mirar.

| Tela | Ação |
| --- | --- |
| Menu | Clique para mudar a opção; segure para confirmar. |
| Introdução | Clique para completar o texto; clique novamente para avançar. |
| Pergunta de calibração | Um clique escolhe SIM; dois cliques rápidos escolhem NÃO. |
| Tutorial | Clique para avançar; segure para voltar uma tela. Na última tela, clique para iniciar a produção. |
| Placar | Segure para voltar ao menu. |
| Game over | Após a espera inicial, clique para jogar novamente. Sem interação, o jogo volta ao menu. |

Antes de cada encaixe, selecione a ferramenta: **um clique seleciona o martelo** e **dois cliques rápidos selecionam a chave de fenda**.

| Peça | Ação após selecionar a ferramenta |
| --- | --- |
| Prego normal | Dê um clique para fixá-lo. |
| Parafuso normal | Segure para aparafusar. |
| Prego defeituoso | Dê dois cliques rápidos para removê-lo. Aguarde a reposição e dê um clique para fixar o prego novo. |
| Parafuso enferrujado | Dê um clique curto e depois segure para removê-lo. Aguarde a reposição e segure novamente para aparafusar o novo. |

Trabalhe da esquerda para a direita. Após uma reposição no mesmo encaixe, a ferramenta continua selecionada. Ações incorretas ou o fim do tempo desligam a unidade.

## Tecnologia

- **Engine:** Godot 4.7, validado com Godot 4.7.2.
- **Linguagem:** GDScript.
- **Renderizador:** GL Compatibility.
- **Resolução interna:** 320 × 180, com escala inteira; tamanho de janela configurado em 1280 × 720.
- **Plataforma de exportação:** Windows x86_64.
- **Fonte da interface:** Tiny5.

## Organização do projeto

- `scenes/`: menu, introdução, calibração, partida, esteira, braço auxiliar, HUD, desligamento e placar.
- `scripts/`: lógica de interação, geração de peças e nomes, tempo, pontuação e apresentação.
- `scripts/autoload/`: configurações, estado da unidade e persistência do placar.
- `art/`: imagens, paleta e ícone do executável.
- `audio/`: música, efeitos sonoros e créditos.
- `fonts/`: fontes e suas licenças.
- `docs/`: documentação de design.

## Créditos dos recursos

| Recurso | Autor | Licença / referência |
| --- | --- | --- |
| [Tiny5](https://github.com/Gissio/font_tiny5) | The Tiny5 Project Authors | SIL Open Font License 1.1; [licença incluída](fonts/OFL.txt). |
| [Interface Sounds](https://kenney.nl/assets/interface-sounds) | Kenney | CC0; [licença incluída](audio/licenses/interface_CC0.txt). |
| [Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0; [licença incluída](audio/licenses/impact_CC0.txt). |
| [Electric screwdriver #1](https://bigsoundbank.com/electric-screwdriver-1-s1572.html) | Joseph SARDIN — BigSoundBank | CC0; trecho editado em `audio/sfx/screwdriver_loop.wav`. |
| [Paleta AAP-64](https://lospec.com/palette-list/aap-64) | Adigun A. Polack | Referência de cores; arquivo local: `art/palettes/aap-64.gpl`. |
| [Música de fundo](https://pixabay.com/pt/users/retro-bgm-chan-55246343/) | Retoro BGM Chan | Pixabay Content License; identificador da faixa no crédito enviado: 534622. |

Os efeitos de **Interface Sounds** são usados na inicialização, no desligamento, nos cliques, na seleção de ferramentas, nas confirmações, nos alertas e na preparação de ações. Os efeitos de **Impact Sounds** são usados nas ações de martelar e remover pregos. O **loop da parafusadeira do BigSoundBank também é reutilizado ao segurar para confirmar no menu e ao segurar para sair do placar**. O mapeamento dos arquivos originais e os detalhes da edição estão em [audio/CREDITS.md](audio/CREDITS.md).

**Crédito da música:** Música de Retoro BGM Chan, disponibilizada no [Pixabay](https://pixabay.com/). Consulte os [termos completos do Pixabay, seções 5 e 6](https://pixabay.com/service/terms/) e o [resumo oficial da licença](https://pixabay.com/service/license-summary/).

### Artes originais

As artes em `art/Background`, `art/Conveyor Belt`, `art/Parts` e `art/HUD`, além de `art/unidade-404.ico`, foram criadas pelo integrante **Alysson Lucas**. A seleção ou preparação de fontes e áudios de terceiros não transfere sua autoria à equipe; seus criadores mantêm os direitos previstos nas respectivas licenças.

## Licença e autoria

Os materiais originais da equipe estão sob a [Licença de Uso Pessoal e Educacional Não Comercial do Unidade 404](LICENSE.txt). É permitido jogar, estudar e fazer modificações locais para fins pessoais ou educacionais, sem finalidade comercial ou ganho financeiro. Redistribuição ou republicação exige autorização prévia e por escrito, ressalvados os direitos previstos nos termos do GitHub ou na legislação aplicável. Preserve a autoria e os créditos originais.

Este é um **projeto de código disponível sob licença própria não comercial**, e não um projeto open source sob GPL ou MIT. Recursos de terceiros mantêm suas próprias licenças. As condições completas estão em `LICENSE.txt`.

### Aviso de autoria e condições de uso

**© 2026 Mariana Bravo, João Victor Freitas e Alysson Lucas. Os direitos sobre o trabalho original da equipe são reservados, exceto pelas permissões expressas abaixo.**

*Unidade 404: Futuro Não Encontrado* é um jogo de autoria desta equipe. O jogo e o código, as artes e os demais materiais originais da equipe são disponibilizados para uso pessoal, educacional e não comercial. A exploração comercial — incluindo a venda do jogo, a monetização de versões redistribuídas ou a incorporação de materiais originais da equipe em um produto comercial — exige autorização prévia e por escrito da equipe.

Não é permitido atribuir a si a autoria do jogo ou do trabalho da equipe, publicá-lo sob outra autoria, nem remover ou deturpar os créditos originais. Toda redistribuição autorizada pela equipe deve preservar os avisos de autoria, os créditos e as licenças aplicáveis. O acesso público ao repositório não concede, por si só, direitos de exploração comercial; os direitos de visualização e criação de forks previstos nos termos do GitHub permanecem inalterados.

Este aviso se aplica somente aos direitos pertencentes à equipe. Godot, fontes, áudios, paletas e outros recursos externos continuam sujeitos às suas próprias licenças; este aviso não restringe permissões concedidas por essas licenças. Também não revoga direitos já concedidos por qualquer licença aplicável.

O jogo é fornecido **“no estado em que se encontra”**, sem garantias, na medida permitida pela legislação aplicável. Para uso comercial, republicação ou permissões além das descritas acima, entre em contato com a equipe pelos perfis do GitHub indicados neste README.
