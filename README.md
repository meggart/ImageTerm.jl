ANSIImage.jl
============

Julia functions to plot colorful maps in the terminal

# Requirements

You should use a terminal emulator that supports 256 colors, for example iTerm for MacOSX or Konsole on Ubuntu.

# Usage

    ansiimage(x,optional arguments...)

here x is a 2d array. The following optional arguments are currently supported:

    col=heatscale/diffscale/bluescale/redscale/greenscale/greyscale

picks the colorbar.

    missval=1.0e32

defines which values are marked as missing and will get a special missval color.

    hd=true/false

determines the resolution (1 pixel per line for false, 2 pixels per line for true).
