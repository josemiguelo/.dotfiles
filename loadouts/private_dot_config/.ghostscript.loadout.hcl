# ghostscript: ImageMagick shells out to `gs` to rasterize PDFs, which snacks.nvim's image preview needs.

program "ghostscript" {
  install_via = [brew, omarchy]
}
