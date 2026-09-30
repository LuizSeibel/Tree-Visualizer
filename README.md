# AVL Tree Visualizer

An interactive AVL tree visualizer built with Lua and LÖVE. Insert, delete, and search for values while following each step of the operation, including balance checks and rotations.

**Play online:** [Tree Visualizer](https://luizseibel.github.io/Tree-Visualizer/)

## Controls

Type a number in the field at the top left, then choose an operation. The field accepts digits, `-`, and `.`; use `Backspace` to erase characters.

| Action | Keyboard | Mouse |
| --- | --- | --- |
| Insert the value | `Enter` | Click **Insert** |
| Delete the value | `Delete` | Click **Delete** |
| Search for the value | `F` | Click **Search** |
| Advance one step in manual mode | `Space` | Click **Next step** |
| Switch between manual and automatic mode | `A` | Click the **Automatic** toggle |

An operation shows its first step immediately. In manual mode, advance through the remaining steps with `Space` or **Next step**. In automatic mode, steps advance about every 0.9 seconds. Finish the current operation before starting another one.

If you are playing in a browser, click the game area first so it receives keyboard input.

## Run locally

Install [LÖVE](https://love2d.org/) and run this command from the project directory:

```bash
love .
```

## What the visualization shows

Nodes display their height (`h`) and balance factor (`b`). Colors highlight the node being visited, inserted, deleted, checked for balance, or rotated. A message above the tree describes the current step.
