# Peças isoladas da referência

- `404_nail.png`: prego normal, cabeça azul sólida.
- `404_screw.png`: parafuso normal, cabeça azul com rebaixo em cruz.

Extração assistida pela ferramenta integrada de imagem a partir da referência fornecida pelo usuário em 27/10/2026. A IA reinterpretou pixels e ampliou os elementos; estes arquivos não são recortes exatos nem estão na escala nativa 320x180. Ambos preservam o alpha gerado. A imagem de referência original e os assets existentes não foram alterados.

Prompts utilizados:
- Prego: isolar somente a cabeça azul sólida do prego no canto superior direito da placa direita, mantendo orientação, aparência pixel art e sombra; retirar placa e cenário e produzir PNG transparente.
- Parafuso: isolar somente a cabeça azul com cruz no canto inferior esquerdo da placa esquerda, mantendo orientação, aparência pixel art e sombra; retirar placa e cenário e produzir PNG transparente.

Integração: os slots normais usam `404_nail_sprite.tres` e `404_screw_sprite.tres`, recursos AtlasTexture que selecionam as regiões visíveis dos PNGs sem alterar os arquivos. O jogo exibe os sprites centralizados, em aproximadamente 18x18 pixels, com filtro nearest e proporção preservada. O prego torto usa `404_bent_nail_sprite.tres`. O parafuso enferrujado usa `404_rusty_screw_sprite.tres`. A marca de conclusão mantém seu indicador próprio.


## Prego torto

`404_bent_nail.png` foi criado com a ferramenta integrada de imagem usando o prego normal e a cena de referência como referências de estilo. Não é uma extração do prego enferrujado da referência. O AtlasTexture `404_bent_nail_sprite.tres` seleciona a área visível para exibição centralizada com nearest e proporção preservada.

Prompt: criar um único prego torto em pixel art com cabeça azul sólida inclinada, haste grossa dobrada em cotovelo e ponta visível; combinar com os sprites azuis e o cenário industrial, priorizando silhueta legível em 18x18 pixels, fundo transparente, sem placa, textos ou cenário. Cores sugeridas da AAP-64: azuis claros, azul metálico e sombra cinza.

## Parafuso enferrujado

`404_rusty_screw.png`: extração assistida por IA da cabeça marrom avermelhada com cruz no canto inferior direito da placa esquerda da referência. O resultado reinterpreta os pixels originais e tem fundo transparente. `404_rusty_screw_sprite.tres` seleciona a região visível, usada pelo slot RUSTY_SCREW.

Prompt: isolar somente o parafuso enferrujado no centro (447,367) da referência, preservando silhueta escalonada, cores terracota, rebaixo escuro em cruz, luz superior esquerda e sombra inferior direita; vista de cima, sem haste, placa, cenário ou outras peças; PNG transparente legível em 18x18 pixels.
