# Mouse Tiler

<img align="left" style="margin-right: 20px" width="90" height="90" src="./assets/alpha_icon.png">

<pre>
KDE KWin Script for tiling windows.
Allows you to tile your windows with minimum effort by moving the mouse just a few pixels.
</pre>

* Compatible with KDE Plasma 6+ (compatibility with previous versions is unknown).

* Tested on Fedora 42 KDE running Wayland and X11 with Plasma version 6.5.2.

[![kde-store](https://img.shields.io/badge/KDE%20Store-download-blue?logo=KDE)](https://store.kde.org/p/2334027)


# Table of contents
<ul>
<li><a href="#features">Features</a>
    <ul>
        <li><a href="#features_released">Released so far</a></li>
        <li><a href="#features_planned">Planned for v1.0.0 (and beyond)</a></li>
    </ul>
</li>
<li><a href="#how">How it works</a></li>
<li><a href="#installation">Installation</a>
    <ul>
        <li><a href="#store">From KDE Store (Recommended)</a></li>
        <li><a href="#file">From File</a></li>
    </ul>
</li>
<li><a href="#setup">Recommended setup</a></li>
</li>
<li><a href="#system-settings">Changing system settings</a></li>
<li><a href="#remove-settings">Manually erasing settings</a></li>
<li><a href="#troubleshooting">Troubleshooting</a>
    <ul>
        <li><a href="#commandline">Command line</a></li>
    </ul>
</li>
<li><a href="#compatibility">Compatibility</a></li>
<li><a href="#getintouch">Get in touch</a></li>
</ul>

## <p id="features"></p>Features

### <p id="features_released"></p>Released so far

* Two mouse tiling modes - Grid and Overlay (use one or both)
* Manual text configuration of the modes
* Multi-monitor support
* v0.0.3 - Preview of where the tile will end up

![](./assets/popup_tiler.png)<br>
**Grid Tiler Default**

![](./assets/popup_tiler_all.png)<br>
**Grid Tiler All Layouts**

![](./assets/overlay_tiler.png)<br>
**Overlay Tiler**

### <p id="features_planned"></p>Planned for v1.0.0 (and beyond)

* GUI configuration
    * Default layout suggestions based on screen ratio (such as 16:9, 32:9, 4:3 - not sure which ones will be implemented yet)
* Define better default script colors - currently they are more or less just hex values I randomly typed towards blueish theme
* Use current theme colors instead (with option to use the default script colors - per user choice)
* Implement all the settings (and more) currently disabled in the configuration dialog

### Feature requests to investigate

* Option to enable automatic tiling
* Add additional titlebar button ? - System Settings > Colours & Themes > Window Decorations > ... > Configure Titlebar Buttons...
* Hide overlay/popup grid if mouse has not moved for X time

## <p id="how"></p>How it works

Use one of two mouse adapted tilers (or both). The Grid tiler lets you quickly place your window by moving the window a few pixels. The Overlay tiler is a classical full screen overlay that lets you place your window into one tile, or span multiple tiles. Define your own layouts or use some of the many predefined ones.

## <p id="installation"></p>Installation

### <p id="store"></p>From KDE Store (Recommended)

1) Open `System Settings` > `Window Management` > `KWin Scripts`.

2) Click the `Get New...` in upper right corner.<br>
![](./assets/get.png)<br>
3) Search for `Mouse Tiler` and click on it (step `1` applies only with small window size)<br>
![](./assets/search.png)<br>
4) Click `Install`<br>
![](./assets/download.png)<br>
5) Enable `Mouse Tiler`<br>
![](./assets/tick.png)<br>
6) Click `Apply`<br>
![](./assets/apply.png)<br>
7) Click the configure icon to change the settings to your liking<br>
![](./assets/configure.png)<br>

Please note that changing settings requires some additional steps to apply due to a KDE limitation - see `Changing settings` below for more information.

### <p id="file"></p>From File

You can download the `mousetiler.kwinscript` file and install it through **System Settings**.
1) Download the .kwinscript file.
2) Open `System Settings` > `Window Management` > `KWin Scripts`.
3) Click the `Install from File...` in upper right corner.<br>
![](./assets/install.png)<br>
4) Select the downloaded file and click `Open`
5) Enable `Mouse Tiler`<br>
![](./assets/tick.png)<br>
6) Click `Apply`<br>
![](./assets/apply.png)<br>
7) Click the configure icon to change the settings to your liking<br>
![](./assets/configure.png)<br>

Please note that changing settings requires some additional steps to apply due to a KDE limitation - see `Changing settings` below for more information.

## <p id="system-settings"></p>Changing system settings

### **`IMPORTANT`**

Due to a bug in KDE, changing user configuration requires reloading the script. (A reboot works too.)

To make setting changes effective, **reload the script as follows**:

1) In `System Settings` > `Window Management` > `KWin Scripts`, untick `Mouse Tiler`<br>
![](./assets/untick.png)<br>
2) Click `Apply`<br>
![](./assets/apply.png)<br>
3) Tick `Mouse Tiler`<br>
![](./assets/tick.png)<br>
4) Click `Apply`<br>
![](./assets/apply.png)<br>

### <p id="remove-settings"></p>Manually erasing settings

If there is ever need to manually erase user data (do not do this unless you are a developer or really need it).

The application/window data is stored in `~/.config/kde.org/kwin.conf` under the key `...`.

The system user settings data is stored in `~/.config/kwinrc` under `[Script-mousetiler]`.

## <p id="troubleshooting"></p>Troubleshooting

### <p id="commandline"></p>Command line

In case there are any issues (such as a crash - which should never happen but just in case), this is how to disable the script from command line (open a console with `Ctrl+Alt+F5`):

```
kwriteconfig6 --file kwinrc --group Plugins --key mousetilerEnabled false
qdbus org.kde.KWin /KWin reconfigure
```

If the mouse tiler configuration contains corrupted data, it can be manually deleted in the file: `~/.config/kde.org/kwin.conf` under key `TBD`.

## <p id="compatibility"></p>Compatibility ##

Compatible with:
* <a href="https://github.com/rxappdev/RememberWindowPositions">Remember Window Positions</a> - use the Mouse Tiler to move your windows into position, and restore them next time you start the application. Ultimate combo.

## <p id="getintouch"></p>Get in touch ##

Join the official discord channel https://discord.gg/Js6AYsnQQj to discuss, report bugs or find guides.