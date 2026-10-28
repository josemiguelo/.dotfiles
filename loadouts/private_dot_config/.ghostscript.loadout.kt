// ghostscript: ImageMagick shells out to `gs` to rasterize PDFs, which snacks.nvim's image preview needs.
package loadouts

import loadout.dsl.*

val ghostscript = program(name = "ghostscript") {
    installVia(
        brew,
        omarchy,
    )
}
