# Testes

Execute a partir da raiz do projeto, com Godot 4 no PATH:

```sh
godot --headless --path . res://tests/input_regression_test.tscn
godot --headless --path . res://tests/game_integration_test.tscn
godot --headless --path . res://tests/continuous_time_test.tscn
godot --headless --path . res://tests/scoreboard_test.tscn
godot --headless --path . res://tests/input_feedback_test.tscn
```

Os testes automatizados encerram com código 1 se houver falha. Os testes de input avançam o relógio manualmente para verificar os limites sem depender da velocidade do computador. O teste integrado usa a cena real e aguarda as animações da esteira e a substituição.

Para verificar também o cursor e capturar o HUD, execute com renderização:

```sh
godot --path . res://tests/game_integration_test.tscn -- --capture
```

A captura temporária é salva em `tests/hud_preview.png`. O teste existente `run_manager_test.tscn` imprime 22 conferências do modelo de tempo e oferece controles manuais; `visor_hud_test.tscn` permite inspecionar o HUD isoladamente.

O relógio normal drena também na entrada/saída da esteira e na substituição. A recompensa é T_MIN × margem + duração da substituição (slots defeituosos) + saída/entrada da esteira (último slot). O teto permanece em 10 segundos; o treino isolado mantém seu comportamento sem morte.

O placar usa `user://scoreboard.dat`, binário little-endian com assinatura U404, versão u16 e até três registros. Cada registro contém comprimento UTF-8 u16, nome, pontuação u32 e tempo float64. A gravação usa `.tmp` e preserva o último arquivo válido em `.bak`. Os testes de placar e integração usam nomes exclusivos em `user://` e removem apenas seus próprios arquivos. O teste de falha de escrita emite um aviso esperado.

O teste de feedback verifica indicadores, atraso de 0,10 s do anel, streams de áudio, loop do motor, cancelamento, preparo, conclusão, alerta e game over. O modo `--capture` do teste integrado mostra o anel durante uma remoção. Os testes aguardam um ciclo de liberação do servidor de áudio antes de encerrar.

No Windows, para exercitar áudio real sem abrir janela: `godot --headless --audio-driver WASAPI --path . res://tests/input_feedback_test.tscn`. O driver Dummy do modo headless pode emitir avisos de playbacks ainda pendentes ao encerrar rapidamente; a validação de áudio deve usar o driver real ou execução gráfica.
