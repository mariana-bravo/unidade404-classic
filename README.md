# Unidade 404: Futuro Não Encontrado

Jogo arcade 2D de precisão em pixel art, desenvolvido para a Game Jam da Semana Acadêmica de Ciência da Computação da Universidade Federal Fluminense (UFF).

A fábrica nunca para. Humanos erram e têm justificativas. Robôs não têm esse privilégio: um erro de montagem ou o fim do tempo, e a unidade é desligada. Você controla um desses robôs e precisa escolher ferramentas, instalar e remover peças usando apenas o botão esquerdo do mouse.

## Equipe

- Mariana Bravo
- Alysson Lucas
- João Victor Freitas

## Como executar

### Versão para Windows

1. Extraia todo o conteúdo do ZIP, se o jogo estiver compactado.
2. Abra `Unidade404.exe` com um duplo clique.
3. No menu, selecione **JOGAR** para começar ou **SAIR** para encerrar.

A versão exportada é para **Windows de 64 bits** e não exige instalação do Godot.

### Pelo projeto-fonte

1. Instale o [Godot 4.7.2, edição padrão](https://godotengine.org/).
2. No gerenciador de projetos, escolha **Importar** e selecione `project.godot`.
3. Aguarde a importação dos recursos e pressione **F5** para executar o jogo.

A cena inicial é `scenes/menu.tscn`.

## Controles

Todo o jogo usa apenas o **botão esquerdo do mouse**, sem mirar ou mover o cursor para selecionar elementos.

| Tela | Ação |
| --- | --- |
| Menu | Clique para mudar a opção; segure para confirmar. Soltar antes cancela a confirmação. |
| Introdução | Clique para completar o texto; clique novamente para avançar. |
| Pergunta de calibração | Um clique escolhe SIM; dois cliques rápidos escolhem NÃO. |
| Tutorial | Clique para avançar; segure para voltar uma tela. Na última tela, clique para iniciar a produção. |
| Placar | Segure para voltar ao menu. |
| Game over | Após a espera inicial, clique para jogar novamente. Sem interação, o jogo volta ao menu. |

### Durante a montagem

Selecione a ferramenta antes de trabalhar em cada encaixe:

- **Um clique:** seleciona o martelo.
- **Dois cliques rápidos:** selecionam a chave de fenda.

Depois da seleção, execute a ação correspondente:

| Encaixe | Ação |
| --- | --- |
| Prego normal | Dê um clique para fixá-lo. |
| Parafuso normal | Segure para aparafusar. |
| Prego defeituoso | Dê dois cliques rápidos para removê-lo. Aguarde a reposição e dê um clique para fixar o prego novo. |
| Parafuso enferrujado | Dê um clique curto e depois segure para removê-lo. Aguarde a reposição e segure novamente para aparafusar o novo. |

Após uma reposição no mesmo encaixe, a ferramenta continua selecionada. Soltar o botão antes de concluir uma ação de segurar cancela o progresso dessa etapa.

## Partida e placar

- Trabalhe nos encaixes da esquerda para a direita.
- Concluir encaixes concede pontos e recupera tempo; concluir peças também concede pontos e aumenta a dificuldade ao longo da partida.
- Escolher a ferramenta errada, executar uma ação incorreta ou deixar o tempo acabar encerra a vida da unidade.
- Cada nova unidade recebe nome, número de série e uma cor sorteada entre as seis cores da paleta, sem repetir a cor da unidade anterior.
- A cor acompanha o nome na introdução, na HUD, na ativação, no game over e no placar.
- Após o game over, a apresentação da nova unidade dura 4,2 segundos, incluindo 3 segundos de leitura após a animação.
- O placar local mantém os três melhores resultados, com nome, cor, pontuação e tempo de vida. A ordenação prioriza a pontuação e, em caso de empate, o maior tempo de vida.

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

As cenas de teste antigas foram removidas. A calibração permanece como tutorial acessível pelo fluxo normal do jogo.

## Créditos dos recursos

| Recurso | Autor | Licença / referência |
| --- | --- | --- |
| Fonte [Tiny5](https://github.com/Gissio/font_tiny5) | The Tiny5 Project Authors | SIL Open Font License 1.1; [licença incluída](fonts/OFL.txt). |
| [Interface Sounds](https://kenney.nl/assets/interface-sounds) | Kenney | CC0; [licença incluída](audio/licenses/interface_CC0.txt). |
| [Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0; [licença incluída](audio/licenses/impact_CC0.txt). |
| [Electric screwdriver #1](https://bigsoundbank.com/electric-screwdriver-1-s1572.html) | Joseph SARDIN — BigSoundBank | CC0, conforme os créditos incluídos; trecho editado para o som da parafusadeira. |
| [Paleta AAP-64](https://lospec.com/palette-list/aap-64) | Adigun A. Polack | Referência de cores; arquivo em `art/palettes/aap-64.gpl`. |
| Música de fundo, arquivo `retro-bgm-chan-vs-robbot_vs-534622.mp3` | [Retoro BGM Chan](https://pixabay.com/pt/users/retro-bgm-chan-55246343/) | Disponibilizada no Pixabay; referência: Pixabay Content License. |

**Crédito da música:** Música de Retoro BGM Chan, disponibilizada no [Pixabay](https://pixabay.com/). Identificador da faixa no crédito fornecido pela equipe: **534622**.

O texto completo da licença da plataforma está nos [Termos do Pixabay, seções 5 e 6](https://pixabay.com/service/terms/), com um [resumo oficial](https://pixabay.com/service/license-summary/). A licença permite o uso e a adaptação em projetos comerciais ou não comerciais, sujeitos às restrições dos termos, e proíbe a venda ou distribuição da música isoladamente. A atribuição é opcional; o projeto mantém o crédito ao autor. Este resumo não substitui os termos oficiais. Referências consultadas em 27/10/2026.

A Tiny5 também está disponível no [repositório do Google Fonts](https://github.com/google/fonts/tree/main/ofl/tiny5).

Os efeitos de **Interface Sounds** são usados na inicialização, no desligamento, nos cliques, na seleção de ferramentas, nas confirmações, nos alertas e na preparação de ações. Os efeitos de **Impact Sounds** são usados nas ações de martelar e remover peças. As licenças CC0 incluídas são da versão **1.0**.

O som da parafusadeira usa um trecho editado da gravação de Joseph SARDIN, com ajuste de volume e fades. O mapeamento dos efeitos sonoros originais e locais está em [audio/CREDITS.md](audio/CREDITS.md).

O arquivo da música está em `audio/retro-bgm-chan-vs-robbot_vs-534622.mp3`. Além das condições resumidas acima, os termos do Pixabay permitem copiar o conteúdo e proíbem alegar autoria ou direitos exclusivos sobre ele. Outras restrições e possíveis direitos de terceiros constam dos termos oficiais.

### Artes e recursos adicionais

Os arquivos locais das artes em `art/Background`, `art/Conveyor Belt`, `art/Parts` e `art/HUD`, além do ícone `art/unidade-404.ico`, não documentam autoria, licenças ou links de origem. Esses créditos ainda precisam ser completados pela equipe.

As imagens em `art/Robot` permanecem no projeto, mas não são usadas como retratos na HUD. A [Pixelify Sans](https://github.com/google/fonts/tree/main/ofl/pixelifysans) é de autoria de **The Pixelify Sans Project Authors** e também permanece disponível, sob SIL OFL 1.1 ([licença](fonts/PixelifySans-OFL.txt)), mas a fonte ativa é a Tiny5.

As licenças dos recursos de terceiros são independentes: a licença CC0 dos efeitos sonoros não abrange a música nem as artes. O contexto educacional do projeto não define, por si só, uma licença para o código ou para os demais recursos.
