# A Fórmula Secreta — port JS → Godot (versão 3)

Descompacte **por cima da pasta raiz do projeto** (`godot-formula-secreta-1`). Os arquivos substituem os de mesmo caminho.
A máquina de estados (`scripts/State Machine/`) não foi alterada.

## O que já vem pronto
- **project.godot**: os 6 autoloads registrados (SaveManager, MusicManager, GameManager, DialogueManager, GameOver, PauseMenu) e a intro como cena inicial (F5).
- **level_1.tscn** montado com as posições do `map_1.json` do JS:
  - jogador no spawn do JS (32, 1024);
  - 2 guardas (patrulha vertical, alcance 64);
  - 4 pedras;
  - 8 fogos normais e 18 fogos surpresa (invisíveis até você chegar perto);
  - 3 gatilhos de fala (dialogo0/1/2, com os textos do JS);
  - 3 NPCs fugitivos.
- **map_1.tscn**: nova camada "Objetos" com as 36 peças das carroças (com colisão), que faltavam no mapa do Godot.
- **npc_fugitivo.png** + `npc_fugitive.tscn` (anda com animação nas 4 direções e não colide com o jogador, como no JS).

## Teclas
WASD/setas andam · E pega pedra · segure F para mirar e solte para jogar · Esc pausa · Enter/Espaço/clique avança o diálogo.
(E, F e Esc são criadas por código, não precisa mexer no Input Map.)

## Pode apagar
`scenes/hazards/fire.tscn`, `scenes/characters/player_2.gd`, `player2.tscn`, `scenes/levels/*.tmp`.

## Observação sobre o mapa
O mapa do Godot é diferente do `map_1.json` do JS: falta chão em vários pontos e algumas paredes mudaram (parece ter vindo do `untitled.tmx`, mais antigo). Não mexi nisso; só acrescentei as carroças. Se quiser o mapa idêntico ao do JS, eu gero as camadas de chão e parede a partir do JSON.
