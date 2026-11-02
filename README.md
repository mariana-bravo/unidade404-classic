# Unidade 404: Futuro Não Encontrado

**[Leia em português brasileiro](readme_pt.md)**

A 2D precision arcade game in pixel art, **winner of the Game Jam at UFF's 22nd Computer Science Academic Week**, at Universidade Federal Fluminense, Brazil.

## About the game

The factory never stops. Humans make mistakes and have excuses. Robots do not have that privilege: one assembly mistake or a depleted timer, and the unit is shut down. You are one of those robots. Choose tools, install and remove parts as quickly as possible before you are replaced.

The end is certain, but the fun is guaranteed!

## The competition

The Game Jam theme was **“Only one input”**, a constraint on both development and gameplay. This game uses only the **left mouse button (LMB)**.

Ten teams of UFF student developers participated. The games were evaluated through an open vote during the event, supervised by organizer and UFF faculty member [@JoaoVitorSantiagoNogueira](https://github.com/JoaoVitorSantiagoNogueira)

| Category | Placement |
| --- | --- |
| Theme adherence | 1st |
| Creativity | 2nd |
| Polish | 3rd |
| Fun | 4th |
| **Overall average** | **1st** |

## Team

| Member | Role | Contributions |
| --- | --- | --- |
| Mariana Bravo ([@mariana-bravo](https://github.com/mariana-bravo)) | Game Designer & Creative Lead | Developed the game concept and creative direction, implemented features, and guided the development team. |
| João Victor Freitas ([@joaov-freitas](https://github.com/joaov-freitas)) | Lead Developer & Integration Lead | Led programming and integrated the features into the playable game. |
| Alysson Lucas ([@AlyssonLucasVFSoares](https://github.com/AlyssonLucasVFSoares)) | Pixel Artist & Visual and Audio Asset Lead | Created the original pixel art and visual assets; handled font and audio selection, preparation, and integration.|

## Play the game

Download the Windows build from [GitHub Releases](https://github.com/mariana-bravo/unidade-404-game/releases).

### Run from source

1. Install [Godot 4.7.2 or newer, standard edition](https://godotengine.org/).
2. In the project manager, select **Import** and open `project.godot`.
3. Open **Project → Export** in Godot.
4. Use the existing **Windows Desktop** preset, or add it if needed.
5. Install the matching export templates if prompted.
6. Select **Export Project** and choose the output folder.

The configured target is Windows x86_64. The executable icon is `art/unidade-404.ico`.

## Controls

The game uses only the **left mouse button**, with no aiming required.

| Screen | Action |
| --- | --- |
| Menu | Click to change the selected option; hold to confirm. |
| Introduction | Click to complete the text; click again to advance. |
| Calibration question | One click selects YES; two quick clicks select NO. |
| Tutorial | Click to advance; hold to return to the previous page. Click on the final page to begin production. |
| Leaderboard | Hold to return to the menu. |
| Game over | After the initial wait, click to play again. Without input, the game returns to the menu. |

Select a tool before working on each slot: **one click selects the hammer** and **two quick clicks select the screwdriver**.

| Part | Action after tool selection |
| --- | --- |
| Normal nail | Click to drive it in. |
| Normal screw | Hold to tighten it. |
| Defective nail | Double-click to remove it. Wait for the replacement, then click to drive in the new nail. |
| Rusty screw | Click briefly, then hold to remove it. Wait for the replacement, then hold again to tighten the new screw. |

Work from left to right. The tool stays selected after a replacement within the same slot. Incorrect actions or running out of time shut down the unit.

## Technology

- **Engine:** Godot 4.7, validated with Godot 4.7.2.
- **Language:** GDScript.
- **Renderer:** GL Compatibility.
- **Internal resolution:** 320 × 180, with integer scaling; configured window size of 1280 × 720.
- **Export platform:** Windows x86_64.
- **Interface font:** Tiny5.

## Project structure

- `scenes/`: menu, introduction, calibration, gameplay, conveyor, helper arm, HUD, shutdown, and leaderboard.
- `scripts/`: interaction logic, part and name generation, time, scoring, and presentation.
- `scripts/autoload/`: settings, robot state, and leaderboard persistence.
- `art/`: images, palette, and executable icon.
- `audio/`: music, sound effects, and credits.
- `fonts/`: fonts and their licenses.
- `docs/`: design documentation.

## Asset credits

| Resource | Author | License / reference |
| --- | --- | --- |
| [Tiny5](https://github.com/Gissio/font_tiny5) | The Tiny5 Project Authors | SIL Open Font License 1.1; [included license](fonts/OFL.txt). |
| [Interface Sounds](https://kenney.nl/assets/interface-sounds) | Kenney | CC0; [included license](audio/licenses/interface_CC0.txt). |
| [Impact Sounds](https://kenney.nl/assets/impact-sounds) | Kenney | CC0; [included license](audio/licenses/impact_CC0.txt). |
| [Electric screwdriver #1](https://bigsoundbank.com/electric-screwdriver-1-s1572.html) | Joseph SARDIN — BigSoundBank | CC0; an edited excerpt is used in `audio/sfx/screwdriver_loop.wav`. |
| [AAP-64 palette](https://lospec.com/palette-list/aap-64) | Adigun A. Polack | Color reference; local file: `art/palettes/aap-64.gpl`. |
| [Background music](https://pixabay.com/pt/users/retro-bgm-chan-55246343/) | Retoro BGM Chan | Pixabay Content License; track ID supplied in the attribution: 534622. |

**Interface Sounds** provides startup, shutdown, click, tool-selection, confirmation, warning, and action-preparation effects. **Impact Sounds** provides the hammering and nail-removal effects. The **BigSoundBank screwdriver loop is also reused when holding to confirm in the menu and when holding to leave the leaderboard**. The source-file mapping and editing details are documented in [audio/CREDITS.md](audio/CREDITS.md).

**Music attribution:** Music by Retoro BGM Chan from [Pixabay](https://pixabay.com/). See the [full Pixabay terms, sections 5 and 6](https://pixabay.com/service/terms/) and the [official license summary](https://pixabay.com/service/license-summary/).

### Original art

The artwork in `art/Background`, `art/Conveyor Belt`, `art/Parts`, and `art/HUD`, along with `art/unidade-404.ico`, was created by team member **Alysson Lucas**. Selecting or preparing third-party fonts and audio does not transfer their authorship to the team; their creators retain the rights described in their respective licenses.

## License and ownership

The Team's original materials are licensed under the [Unidade 404 Personal and Educational Non-Commercial License](LICENSE.txt). Personal play, study, and local educational modifications are permitted without commercial purpose or financial gain. Redistribution or republication requires prior written permission, except for rights provided by GitHub's terms or applicable law. Keep the original authorship and credits.

This is a **source-available project under a custom non-commercial license**, not a GPL- or MIT-licensed open-source project. Third-party assets retain their own licenses. The full terms are in `LICENSE.txt`.

### Ownership and usage disclaimer

**© 2026 Mariana Bravo, João Victor Freitas, and Alysson Lucas. Rights to the team's original work are reserved except as expressly permitted below.**

*Unidade 404: Futuro Não Encontrado* is a game authored by this team. The game and the team's original code, artwork, and other original materials are made available for personal, educational, and non-commercial use. Commercial exploitation—including selling the game, monetizing redistributed builds, or incorporating the team's original materials into a commercial product—requires prior written permission from the team.

You must not claim the game or the team's work as your own, publish it under another authorship, or remove or misrepresent the original credits. Any redistribution authorized by the team must retain the authorship notices, credits, and applicable license notices. Public access to this repository does not by itself grant commercial rights; viewing and forking rights provided by GitHub's terms remain unaffected.

This notice applies only to rights held by the team. Godot, third-party fonts, audio, palettes, and other external resources remain governed by their own licenses; this notice does not restrict permissions granted by those licenses. It does not revoke rights already granted under any applicable license.

The game is provided **“as is”**, without warranties, to the extent permitted by applicable law. For commercial use, republication, or permissions beyond those stated above, contact the team through the GitHub profiles listed in this README.
