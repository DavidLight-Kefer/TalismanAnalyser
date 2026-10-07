# Talisman Analyser

A Mod for MHWilds to analyse your Appraised Talismans and find Duplicates, Obsoletes, Contradictions.

Full mod description on [Nexusmods](https://www.nexusmods.com/monsterhunterwilds/mods/4472).

## Developing

First, create a `.env` file (that you don't push) containing the following for the scripts to work properly:

```
WILDS_DIR="<path_to_your_mh_wilds_install_folder>"
```

The Lua script `compiler.lua` is used by `archive.sh` and `update.sh` to combine all the Lua files of the project into a single final file.

The update scripts (`update.sh`, `update.ps1`) automatically create and update the mod file in your game folder (`talisman_analyser_dev.lua`) so it's easier to test things.
If you're feeling fancy you can probably even tell your code editor of choice to run it whenever you save.


## Publishing

The archive scripts (`archive.sh`, `archive.ps1`) allow you to generate a `talisman_analyser.zip` for Nexus automatically, including `screenshot.png` and `modinfo.ini` from the `nexus` directory. Use it like:

```
./archive.sh <version>
```

With `<version>` being whatever you like: `1.0.1`, `0.4-alpha`, etc... the script doesn't check it in any way, you can do what you want. The `talisman_analyser.zip` will be generated in a new `artefacts` folder.

It will also shrink the `screenshot.png` should [Magick](https://imagemagick.org/magick) be installed when exporting the `talisman_analyser.zip` to not be comically large for how small it will end up being in Fluffy Mod Manager.
