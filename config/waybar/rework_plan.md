# Waybar Rework Plan - Modern Island Layout

This plan reworks the Waybar configuration to fix the "square corners" rendering bug and improve the overall aesthetic using a modern "island" (pill) design.

## Objective
- Eliminate the intermittent "square corners" bug by moving the background and rounding from the main window to module containers.
- Enhance the visual layout while maintaining the existing Gruvbox Material color scheme.
- Clean up the configuration files for better maintainability.

## Proposed Changes

### 1. `config.jsonc`
- Remove the fixed `width` to allow the "islands" to size themselves naturally (or keep a max-width approach).
- Add `margin-top`, `margin-left`, and `margin-right` to create a "floating" effect.
- Refine module formatting for `pulseaudio`, `battery`, and `clock`.
- Add spacing between modules.

### 2. `style.css`
- **Transparent Main Window**: Set `window#waybar` background to `transparent`.
- **Island Containers**: Apply the Gruvbox background (`@bg0`), borders, and `border-radius` to `.modules-left`, `.modules-center`, and `.modules-right`.
- **Module Styling**: 
    - Improve padding and margins for all modules.
    - Style `#workspaces` buttons with better active/inactive states.
    - Add subtle hover effects for interactive modules like `pulseaudio`.
- **Stability**: Keep `transition: none` on critical layout-shifting elements to ensure a flicker-free experience.

## Verification Plan
1. Apply the new `config.jsonc`.
2. Apply the new `style.css`.
3. Reload Waybar using `pkill -USR2 waybar`.
4. Verify that corners remain rounded during:
    - Cursor hover over modules.
    - Workspace switching.
    - Volume/Battery updates.
5. Check for any "wallpaper gaps" or alignment issues.
