# The design of a better player experience for minesweeper
## The game
Minesweeper as a game is widely known and has lots of variants. In this context, the following variant is considered (which is implemented in KDE's KMines and MS Windows Minesweeper programs):

* A quadratic grid is made up of cells, which can either be open or closed.
* Each cell either contains one mine or the number of mines in the 8 cells around of it (which can be open or closed).
* At a closed cell, the player can either put a flag there as an indication of a mine, or they can open the cell. This action constitutes one move in the game.
* The game has no time limit, and the player is scored on the length of the game - the faster, the better.
* The player loses the game when he opens a cell with a mine. So the player has only one life in the game.
* The player wins the game when he opens all cells without mines and correctly flags all mined cells.
* There is never a mine on the first cell opened by the player (not guaranteed by KMines).
* Only a limited, but known number of mines are hidden on the grid.

## Unsolvability as the issue
After several moves, the player might arrive at a configuration of the grid (game state), in which they feel that they cannot decide logically on a safe next move. This situation can have several root causes as listed below.

### Wrong assumptions
The player may have wrongly flagged cells, e.g. as a guess - the cell shows a flag, but there is no mine in that cell. This way, the number of available flags and the number of mines on the grid differ. This situation can prevent the progress later in the game, as the player is using wrong assumptions about mined cells.

### Bounded Rationality
The evaluation of the available information (e.g. numbers, already flagged cells etc.) is obviously a subjective one and some game states may seem unsolvable to one player but not to another. Effectively processing all available information is a prerequisite for solvability. If a player overlooks key information, or if a solution is too complex to think of, a game may seem unsolvable (even if it is not).

### Missing Information
Even if the player perfectly uses all available information and are right in their assumptions, the available information might still be too little for a logical deduction, thereby creating a game state that is ambiguous. In order to advance, the player then has to resort to guessing which cell could be safe or could be a mine. Here is an example of such a situation in KMines:

<img src="./docs/screenshot_incomplete_info.png" alt="Screenshot of KMines">

All three root causes of unsolvability are somewhat frustrating, because Minesweeper is a logic game and hence, the player should be able to solve it based on logic and the given information alone.  
Also, if the player has to guess and the player's guess is wrong, the game is lost, which is very frustrating, especially for larger grids. The player invested tens of minutes to arrive at a certain game state, and then loses the game, so all his work so far is also lost.

## Possible solutions
There are several options to avoid the issues described above:

1. The program (the programmed logic) could create only solvable grids. I have not seen any implementation and I am not sure this is actually feasible, as the player can open the grid cells in any order, so the available information to him depends on this order, which cannot be foreseen by the program (You could point to https://www.chiark.greenend.org.uk/~sgtatham/puzzles/js/mines.html, which claims to be always solvable by deduction alone. In my tests, there were instances that I could not solve this way.) Even with the guarantee of solvable grids, the issues of wrong assumptions and limited rationality still persist, so guessing is still required. Just because a game is solvable in principle does not mean that the player can actually solve it.
1. The program could grant the player more than one life, so that wrong guesses will not immediately lead to losing the game. Drawback: the player still needs to guess and the number of necessary, but wrong guesses might exceed the available lives, leading again to losing.
2. The program could offer the player to play the same grid again, so that they can reuse their knowledge gained in the lost game (KMines offers this option). Drawback: the player still has to guess and lose first and has to repeat the game, which might be frustrating, too.
3. In an ambiguous situation, the program could guarantee that each guess is safe by shuffling around the mines in the grid in accordance with the information revealed so far. For this approach, the program also needs to recognize ambiguous situations and also needs to move mines to new cells. Drawbacks: mines tend to cluster in the remaining closed cells and the player is still required to guess. Example implementation: https://pwmarcz.pl/kaboom/ 
1. In an ambiguous situation, the player can actively request more information from the program itself (e.g. a hint). Then the program shows the player a closed, but safe cell.  Additionally, the program proactively checks the game state for consistency and solvability after each move by the player and tells the player about a wrongly flagged cell. 
It can then open additional cells so that the game state is always solvable logically, and it can notify the player about inconsistencies in their last move. These two options eliminate both the need for guessing and also fix the three issue (wrong assumptions, bounded rationality, missing information). However, this approach makes it necessary for the program to understand whether a given configuration is ambiguous or not (by solving it).

The only alternative without guessing is the last one, so I'll have a closer look at that. Please leave me a message on Github, if you see other options.

## Solution design
### Logic changes
The aforementioned consistency checks for game states are limited to flagged cells. As soon as the player makes a move and flags a cell, the program automatically checks whether this newly set flag fits to the available information on the grid, i.e. already placed flags and the numbers in the open cells around it. This check is simple: the program just looks at every open cell in the direct vicinity of the flagged cell and counts the flagged cells around it - if the number of flags is higher than the number in the cell, the program will actively mark the newly flagged cell with a different color to indicate an inconsistency and to give the player the chance to reconsider.

If the player feels the need for additional information, they can request a hint from the program. The player can choose a special menu item "Hint" in the "Game" menu or they can press a button in the ribbon above the grid. The program then opens one, random safe cell adjacent to an already opened cell. As the program knows exactly where the mines are, it can easily select a safe cell on demand.

The key change to the program is the solvability check and the associated automated actions, which in combination are supposed to ensure that the game is always solvable for the player. Solvability of Minesweeper is not a new idea - there are a number of available solvers for Minesweeper, e.g. [a probabilistic one](https://mrgris.com/projects/minesweepr/), or a [deterministic one](https://www.gecode.org/doc-latest/reference/classMineSweeper.html). The problem with these kinds of solvers is that they solve the whole game, i.e. they try to place all mines. [This computational task is exponentially hard](https://arxiv.org/abs/1204.4659).
Also, intermediary grid configurations allow for a large number of potential solutions, so the desired solution is not uniquely identifiable. So these approaches are not helpful for guaranteeing a better player experience.

The solution design suggested here does not try to solve the whole game, but only solve the current game state in order to determine, if the next move is deterministic or probabilistic, i.e. if the player needs to guess or not. The program does not need to shuffle mines around, it just opens additional cells.

I would like to demonstrate the logic with an example. Let's take the screenshot from above: the areas enclosed in red contain the cells that the program would need to look at for solvability. The areas only cover a small part of the grid, so the problem remains computationally tractable.

<img src="./docs/screenshot_solving_region.png" alt="Area of cells that are checked for solvability">

The following steps happen automatically after every move of the player:

1. The program determines all cells for which there is any information available - those are the cells within the red boundary (candidate cells). 
1. The program then tries to solve the game state for the candidate cells. The solver uses the total number of mines only as an upper limit, but it does not need to place them all. The solver calculates all solutions for the candidate cells; it does not include the player's already placed flags as constraints, as they might not be consistent with the available information. The solver only uses the information on the grid also available to the player (no private information from the game engine itself). The following cases can be distinguished:
  * The solver finds no solution: this means that the candidate cells display inconsistent data. In this case, the game must be aborted. Nobody can win a game with an inconsistent game state - this situation should never arise, if the program works correctly.
  * The solver finds exactly one solution: this is the best case - no need for further processing.
  * The solver finds more than one solution: this is the most likely case, as the placement of the mines on the candidate cells usually exhibits a high degree of symmetry, i.e. the mines can be placed in many different ways. The game logic now needs to determine, if there are invariants in all possible solutions. Are there cells, that are always empty (or mined) in all possible solutions? 
     * If so, this is the good case - these cells constitute solutions that the player must also be able to determine logically, thus the grid is solvable. 
     * If not, then this is the bad case - there is no logically deductible solution, because there is too little available information in the grid. In this case, the program will then automatically open one random, safe, unflagged cell adjacent to an already open or flagged cell. After opening this cell, the program needs to re-execute the steps starting from #1 again (just like after a regular move by a player), because there is no guarantee that the newly opened cell makes the candidate cells solvable. The program might need a couple of iterations until a solvable game state is reached.
     
The solver runs described above yield another insightful piece of information, namely whether the solver's idea of mine locations matches with the player's idea (indicated by the flagged cells). The solver helps to answer the question whether the information available to the player is sufficient to explain the flags set by the player. The following cases can be distinguished:

1. The solver identifies cells that always carry mines,  but the player has not flagged them (yet). This case is harmless, as the player will probably place the needed flags in a future move (as soon as they process all available information).
2. The solver identifies cells that never carry mines,  but the player has flagged them in past moves. This case is problematic, as it proves that the player's reasoning is either incomplete or illogical. As a consequence, the player might run out of flags in a later stage of the game. The program should give a corresponding hint to the player.
3. The solver identifies cells that sometimes carry mines,  but the player has flagged them in past moves. This is less problematic - the status of these cells will become clearer in the course of the game, and then they'll fall into case #1 or #2. No immediate action required by the program here.

### UI changes - TODO

Here the UI, if the player requested a hint. The hint consists of a coloured cell on the grid, which is safe to be opened.
<img src="./docs/screenshot_hint.png" alt="Player information: hint is displayed in red">


## Implementation
Checking whether a given area of the grid has a unique solution is a constraint satisfaction problem, and we can use [Gecode](https://www.gecode.org/doc-latest/reference/index.html) to model and solve such problems. There is already an example program available for Minesweeper in the Gecode software package.

The implementation is ongoing. The KDE KMines game will act as the graphical front-end. The source code is available in the [KDE git repo](https://invent.kde.org/games/kmines). As the standard Linux distributions neither feature the latest KDE Framework version nor the latest Qt libraries, I need to pick a commit version, that fits to the KDE packages installed on my computer. As I am using openSUSE Leap 15.3, I'll go back to version v20.07.80 of KMines.


