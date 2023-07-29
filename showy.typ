
/*
 * ShowyBox - A package for Typst
 * Pablo González Calderón and Showybox Contributors (c) 2023
 *
 * Main Contributors:
 * - Jonas Neugebauer (<https://github.com/jneug>)
 *
 * showy.typ -- The package's main file containing the
 * public and (more) useful functions
 *
 * This file is under the MIT license. For more
 * information see LICENSE on the package's main folder.
 */

#let showy-defaults = (
  frame: (
    upper-color: black,
    lower-color: white,
    border-color: black,
    footer-color: luma(220),
    inset: (x:1em, y:.65em),
    radius: 5pt,
    width: 1pt,
    dash: "solid"
  ),
  title-style: (
    color: white,
    weight: "bold",
    align: left
  ),
  body-style: (
    color: black,
    align: left
  ),
  footer-style: (
    color: luma(85),
    weight: "regular",
    align: left
  ),
  sep: (
    width: 1pt,
    dash: "solid",
    gutter: 0.65em
  ),
  shadow: (
    offset: 3pt,
    color: luma(200)
  ),
)

/*
 * Function: showy-inset()
 *
 * Description: Helper function to get inset in a specific direction
 *
 * Parameters:
 * + direction
 * + value
 */
#let showy-inset( direction, value ) = {
  direction = repr(direction)   // allows use of alignment values
  if type(value) == "dictionary" {
    if direction in value {
      value.at(direction)
    } else if direction in ("left", "right") and "x" in value {
      value.x
    } else if direction in ("top", "bottom") and "y" in value {
      value.y
    } else {
      0pt
    }
  } else if value == none {
    0pt
  } else {
    value
  }
}
/*
 * Function: showy-line()
 *
 * Description: Creates a modified `#line()` function
 * to draw a separator line with start and end points
 * adjusted to insets.
 *
 * Parameters:
 * + frame: The dictionary with frame settings
 */
#let showy-line( frame ) = {
  let inset = frame.at("lower-inset", default: frame.at("inset", default: showy-defaults.frame.inset))
  let inset = (
    left: showy-inset(left, inset),
    right: showy-inset(right, inset)
  )
  let (start, end) = (0%, 0%)

  // For relative insets the original width needs to be calculated
  if type(inset.left) == "ratio" and type(inset.right) == "ratio" {
    let full = 100% / (1 - float(inset.right) - float(inset.left))
    start = -inset.left * full
    end = full + start
  } else if type(inset.left) == "ratio" {
    let full = (100% + inset.right) / (1 - float(inset.left))
    (start, end) = (-inset.left * full, 100% + inset.right)
  } else if type(inset.right) == "ratio" {
    let full = (100% + inset.left) / (1 - float(inset.right))
    (start, end) = (-inset.left, full - inset.left)
  } else {
    (start, end) = (-inset.left, 100% + inset.right)
  }

  line.with(
    start: (start, 0%),
    end: (end, 0%)
  )
}
/*
 * Function: showy-stroke()
 *
 * Description: Creates a stroke ot set of strokes
 * to use as borders.
 *
 * Parameters:
 * + frame: The dictionary with frame settings
 */
#let showy-stroke( frame, ..overrides ) = {
  let (paint, dash, width) = (
    frame.at("border-color", default: showy-defaults.frame.border-color),
    frame.at("dash", default: showy-defaults.frame.dash),
    frame.at("width", default: showy-defaults.frame.width)
  )

  let strokes = (:)
  if type(width) != "dictionary" { // Set all borders at once
    for side in ("top", "bottom", "left", "right") {
      strokes.insert(side, (paint: paint, dash: dash, thickness: width))
    }
  } else { // Set each border individually
    for pair in width {
      strokes.insert(
        pair.first(), // key
        (paint: paint, dash: dash, thickness: pair.last())
      )
    }
  }
  for pair in overrides.named() {
    strokes.insert(
      pair.first(),
      (paint: paint, dash: dash, thickness: pair.last())
    )
  }
  return strokes
}

/*
 * Function: showybox()
 *
 * Description: Creates a showybox
 *
 * Parameters:
 * - frame:
 *   + upper-color: Color used as background color where the title goes
 *   + lower-color: Color used as background color where the body goes
 *   + border-color: Color used for the showybox's border
 *   + radius: Showybox's radius
 *   + width: Border width of the showybox
 *   + dash: Showybox's border style
 * - title-style:
 *   + color: Text color
 *   + weight: Text weight
 *   + align: Text align
 * - body-styles:
 *   + color: Text color
 *   + align: Text align
 * - sep:
 *   + width: Separator's width
 *   + dash: Separator's style (as a 'line' dash style)
 */
 #let showybox(
  // See at the top for default values
  frame: showy-defaults.frame,
  title-style: showy-defaults.title-style,
  body-style: showy-defaults.body-style,
  footer-style: showy-defaults.footer-style,
  sep: showy-defaults.sep,
  shadow: none,

  width: 100%,
  breakable: false,
  // align: none, // collides with align-function

  title: "",
  footer: "",

  ..body
) = {
  /*
   *  Alignment wrapper
   */
  let alignprops = (:)
  for prop in ("spacing", "above", "blow") {
    if prop in body.named() {
      alignprops.insert(prop, body.named().at(prop))
    }
  }
  let alignwrap( content ) = block(
    ..alignprops,
    width: 100%,
    if "align" in body.named() and body.named().align != none {
      align(body.named().align, content)
    } else {
      content
    }
  )

  /*
   * Optionally create a wrapper
   * function to add a shadow.
   */
  let shadowwrap = (sbox) => sbox
  if shadow != none {
    let offset = shadow.at("offset", default: showy-defaults.shadow.offset)
    if type(offset) != "dictionary" {
      shadow.offset = (x: offset, y: offset)
    }
    shadowwrap = (sbox) => block(
      breakable: breakable,
      radius: frame.at("radius", default: showy-defaults.frame.radius),
      fill:   shadow.at("color", default: showy-defaults.shadow.color),
      outset: (
        top: -shadow.offset.y,
        left: -shadow.offset.x,
        right: shadow.offset.x,
        bottom: shadow.offset.y
      ),
      sbox
    )
  }
  let showyblock = block(
    width: width,
    fill: frame.at("lower-color", default: showy-defaults.frame.lower-color),
    radius: frame.at("radius", default: showy-defaults.frame.radius),
    inset: 0pt,
    breakable: breakable,
    stroke: showy-stroke(frame)
  )[
    /*
     * Title of the showybox. We'll check if it is
     * empty. If so, skip its drawing and only put
     * the body
     */
    #if title != "" {
      block(
        inset: if "upper-inset" in frame {
          frame.upper-inset
        } else {
          frame.at("inset", default: showy-defaults.frame.inset)
        },
        width: 100%,
        spacing: 0pt,
        fill: frame.at("upper-color", default: showy-defaults.frame.upper-color),
        stroke: showy-stroke(frame, bottom:1pt),
        radius: (top: frame.at("radius", default: showy-defaults.frame.radius)))[
          #align(
            title-style.at("align", default: showy-defaults.title-style.align),
            text(
              title-style.at("color", default: showy-defaults.title-style.color),
              weight: title-style.at("weight", default: showy-defaults.title-style.weight),
              title
            )
          )
      ]
    }

    /*
     * Body of the showybox
     */
    #block(
      width: 100%,
      spacing: 0pt,
      inset:  if "lower-inset" in frame {
        frame.lower-inset
      } else {
        frame.at("inset", default:(x:1em, y:0.65em))
      },
      align(
        body-style.at("align", default: showy-defaults.body-style.align),
        text(
          body-style.at("color", default: showy-defaults.body-style.color),
          body.pos()
            .map(block.with(spacing:0pt))
            .join(block(spacing: sep.at("gutter", default: showy-defaults.sep.gutter),
              align(left, // Avoid alignment errors
                showy-line(frame)(
                  stroke: (
                    paint: frame.at("border-color", default: showy-defaults.frame.border-color),
                    dash: sep.at("dash", default: showy-defaults.sep.dash),
                    thickness: sep.at("width", default: showy-defaults.sep.width)
                  )
                )
              ))
            )
        )
      )
    )

    #if footer != "" {
      block(
        inset: if "footer-inset" in frame {
          frame.upper-inset
        } else {
          frame.at("inset", default:showy-defaults.frame.inset)
        },
        width: 100%,
        spacing: 0pt,
        fill: frame.at("footer-color", default: showy-defaults.frame.footer-color),
        stroke: showy-stroke(frame, top:1pt),
        radius: (bottom: frame.at("radius", default: showy-defaults.frame.radius))
      )[
          #align(
            footer-style.at("align", default: showy-defaults.footer-style.align),
            text(
              footer-style.at("color", default: showy-defaults.footer-style.color),
              weight: footer-style.at("weight", default: showy-defaults.footer-style.weight),
              footer
            )
          )
      ]
    }
  ]

  alignwrap(
    shadowwrap(showyblock)
  )
}
