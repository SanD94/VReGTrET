init_font <- function() {
    options(repr.plot.width=8, repr.plot.height=6, repr.plot.res = 300)
    options(bitmapType = 'cairo')
    library(showtext)
    font_add_google("Lato", "lato")
    font_add_google(name = "Roboto", family = "roboto")
    showtext_opts(dpi = 300)
    showtext_auto()

    cli_alert_success("Fonts are loaded while configuring repr for 300dpi")
}
