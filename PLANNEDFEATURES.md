# Short version:
Sadly new features are now based on donations. I will still implement bugfixes and do bringups for upcoming versions of KDE Plasma.

Vote below to decide which feature will be implemented next.

# Long version:
I spent exactly 5 months (from 11th September 2025 when I started working on the first prototype of Mouse Tiler for myself until 11th February 2026 when I write this). I have been working full time most of this time, usually minimum 8 hours a day (maximum over 30 hour non-stop sessions), including several weekends (Saturdays and Sundays), and even during Christmas.

During that time, I have received under $500 in donations which does not even cover rent for a single month.

Salary in Sweden (in my field) per hour is $60-$100 depending on experience and such. We pay around 30% for self-employment / employer fee, and around 30% for taxes. So a $100 donation/salary ends up being around $50 after all fees and taxes (sadly we need to pay taxes/fees on donations).

My rent is $700 a month + utilities (electricity, internet, etc) + food + other costs.
Lets say $15 a day for food just for me (I also got a 4 year old son) is another $450.
Probably minimum $1200 a month. That means I need to earn $2400 a month minimum just to cover my own basic costs.

Which means I'm minimum $11500 behind on bills during the time I've invested into Mouse Tiler and Remember Window Positions.

From now on, I will use a donation system (prices might change in the future) to implement new features.

## What I'm doing next
I will spend a few months working on my games before going back to a regular employment. I will from time to time fix bugs, and if donations ever take off, implement new features for Mouse Tiler or Remember Window Positions.

## How implementation works
For each feature - even if it's just a minor 5 line change, I need to do most (if not all) of the following:
- Test locally in developer mode
- Test so script works correctly after a reboot (close everyhing I do and restart computer)
- Test on my wife's computer if it is anything that could affect multi-monitor users (most features)
- For Mouse Tiler, make sure both Overlay and Popup Grid modes work correctly
- Update settings UI so it reflects the changes or includes new configuration options
- Consider what other features the change affects and test them or make them compatible
- Release it on github
- Release it on KDE store
- Possibly create a demo animation, video, and reddit post

# Current donation amount: $0
You can donate anywhere, github, buy me a coffee or patreon (see links on the right).

## How voting works

The highest rated feature is the one currently being donated towards (so get your votes in).
On Friday or Saturday each week, I will update the current donation amount, and once the amount reaches the required amount for top voted item, I will start working on that item when time permits.

## Size and donation goals:
```
S = half day    - $250
M = 1 day       - $490
L = 2 days      - $970
XL = 3-5 days   - $1900
XXL = 6-10 days - $3700
```

## Current vote results (click to place your vote)

[![poll](https://wakatime.com/polls/0e8054f0-e168-4f00-b31b-ed6c17bd51af.png)](https://wakatime.com/polls/0e8054f0-e168-4f00-b31b-ed6c17bd51af)

## Features you can vote on (detailed description)

### 1. S - Mouse Tiler: Custom size split tile (such as 70% / 30%)
Make it possible to use custom size for split tile (SPECIAL_SPLIT_HORIZONTAL and SPECIAL_SPLIT_VERTICAL).

Example SPECIAL_SPLIT_HORIZONTAL left side 70% right side 30%.

### 2. S - Mouse Tiler: Setting to display mouse tiler in portrait mode
In settings, have an option to invert width/height on portrait monitors (off by default)

### 3. S - Mouse Tiler: Add maximize horizontally / vertically special tiles
Tile would only fill screen width or height keep other dimention (use the system option to maximize horizontally/vertically)

### 4. S - Mouse Tiler: Add option to auto-tile when dropping to a virtual desktop
Add a new "Drop action" option in Vritual Desktop Manager settings

### 5. S - Mouse Tiler: Add support for adding labels to each tile
Add possibility to use a custom label for each tile

### 6. S - Mouse Tiler: Add setting to move add virtual desktop to end of the first row (right aligned)
Visual change to have the "drop zone" right aligned

### 7. S - Mouse Tiler: Disable auto-tiling fully
Minimize system resource usage for low end users that are running bare minimum hardware

### 8. S - Remember Window Positions: Do not restore user moved windows
Prevent restoration of windows that user moves before the restoration process finishes

### 9. M - Mouse Tiler: Keyboard tiling shortcuts
Add shortcuts and possibility to move already tiled windows. Example Ctrl+Meta+Num 4 to move window left in the layout it was tiled. (Maybe have left, right, up, down and empty keybindings that people can assign themselves). Alternative use the "overlay" mode layout for the moving options, no matter if you use Popup Grid or Overlay.

### 10. M - Mouse Tiler: Add a toolbar to the UI (things like Cancel Move, Close, Keep Above, Maximize)
Add a customizable toolbar that can be placed on left | top | right side of the tiler that gives access to common actions

### 11. M - Mouse Tiler: Enable auto-tiling per screen, virtual desktop, activity
Have all windows auto-tile on specific screens/desktop instead for a global on/off switch

### 12. M - Mouse Tiler: Add support for decimal and fractional values for x, y, width, height and anchor values on the website
Allow using values such as 66.67 or 2/3 in the online editor

### 13. M - Mouse Tiler: Add per tile modifiers (keep above, fullscreen, center, etc)
Add per tile modifiers so you can both tile and perform special operation at once.

Example: center in tile, fullscreen, keep above, keep below, close

Also add text hint of what a tile does (like C for center F for fullscreen A for keep above B for keep below X for close)

### 14. L - Mouse Tiler: Per screen layout configuration
For advanced users who want to have different tiling options per screen

### 15. L - Mouse Tiler: Add support for auto-tiling on Activities
Add support for activities when using auto-tiling

### 16. L - Mouse Tiler: Update default layouts (including grids) to use decimal values and fractions
Currently the tiles use integer values to make sure there are no gaps (as few gaps as possible). 

Probably make it a setting so old users do not have to redo their manual layouts. This would allow for more precise divisions of screeen estate.

### 17. XL - Mouse Tiler: Add support for editing multiple layouts at once on the website
Copy the whole list of layouts from settings and be able to re-arrange them and edit them 1 by 1 then export them back to settings once done

### 18. XL - Mouse Tiler: Add support for editing auto-tiler layouts on the website
Add support for editing auto-tiler sequences in the online editor

### 19. XL - Mouse Tiler: Snap adjacent tiles / resize together
Resize adjacent windows together, add boundaries so you resize until you reach a new boundary, resize windows below if the edge matches current resized edge

### 20. XL - Remember Window Positions: Restore window properties after crash (take periodic snapshots)
Take snapshots of currently open windows in case of a crash.

See: https://github.com/rxappdev/RememberWindowPositions/issues/12

### 21. XL - Remember Window Positions: Current saved window editor (delete currently saved settings for app/window)
Add an editor (list of currently saved apps and their windows) when pressing Ctrl+Meta+W. Add ability to delete individual window data, app data or whole data for all saved apps.

## Thank you!
The future of the upcoming features is in your hands. Thanks to everyone who has supported me until now - I really apreciate it. You have kept me motivated to keep going (was planning to stop back in December 2025, but kept going until February 2026 instead).