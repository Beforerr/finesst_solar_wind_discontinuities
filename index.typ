// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = [
  #line(start: (25%,0%), end: (75%,0%))
]

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): block.with(
    fill: luma(230), 
    width: 100%, 
    inset: 8pt, 
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.amount
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == "string" {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == "content" {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

#show figure: it => {
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match != none {
    let kind = kind_match.captures.at(0, default: "other")
    kind = upper(kind.first()) + kind.slice(1)
    // now we pull apart the callout and reassemble it with the crossref name and counter

    // when we cleanup pandoc's emitted code to avoid spaces this will have to change
    let old_callout = it.body.children.at(1).body.children.at(1)
    let old_title_block = old_callout.body.children.at(0)
    let old_title = old_title_block.body.body.children.at(2)

    // TODO use custom separator if available
    let new_title = if empty(old_title) {
      [#kind #it.counter.display()]
    } else {
      [#kind #it.counter.display(): #old_title]
    }

    let new_title_block = block_with_new_content(
      old_title_block, 
      block_with_new_content(
        old_title_block.body, 
        old_title_block.body.body.children.at(0) +
        old_title_block.body.body.children.at(1) +
        new_title))

    block_with_new_content(old_callout,
      new_title_block +
      old_callout.body.children.at(1))
  } else {
    it
  }
}

#show ref: it => locate(loc => {
  let target = query(it.target, loc).first()
  if it.at("supplement", default: none) == none {
    it
    return
  }

  let sup = it.supplement.text.matches(regex("^45127368-afa1-446a-820f-fc64c546b2c5%(.*)")).at(0, default: none)
  if sup != none {
    let parent_id = sup.captures.first()
    let parent_figure = query(label(parent_id), loc).first()
    let parent_location = parent_figure.location()

    let counters = numbering(
      parent_figure.at("numbering"), 
      ..parent_figure.at("counter").at(parent_location))
      
    let subcounter = numbering(
      target.at("numbering"),
      ..target.at("counter").at(target.location()))
    
    // NOTE there's a nonbreaking space in the block below
    link(target.location(), [#parent_figure.at("supplement") #counters#subcounter])
  } else {
    it
  }
})

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      block(
        inset: 1pt, 
        width: 100%, 
        block(fill: white, width: 100%, inset: 8pt, body)))
}



#let article(
  title: none,
  authors: none,
  date: none,
  abstract: none,
  cols: 1,
  margin: (x: 1.25in, y: 1.25in),
  paper: "us-letter",
  lang: "en",
  region: "US",
  font: (),
  fontsize: 11pt,
  sectionnumbering: none,
  toc: false,
  doc,
) = {
  set page(
    paper: paper,
    margin: margin,
    numbering: "1",
  )
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)

  if title != none {
    align(center)[#block(inset: 2em)[
      #text(weight: "bold", size: 1.5em)[#title]
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[Abstract] #h(1em) #abstract
    ]
  }

  if toc {
    block(above: 0em, below: 2em)[
    #outline(
      title: auto,
      depth: none
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}
#show: doc => article(
  title: [Solar wind discontinuities],
  authors: (
    ( name: [Zijin Zhang],
      affiliation: [University of California, Los Angeles],
      email: [zijin\@ucla.edu] ),
    ( name: [Anton V. Artemyev],
      affiliation: [University of California, Los Angeles],
      email: [aartemyev\@igpp.ucla.edu] ),
    ( name: [Vassilis Angelopoulos],
      affiliation: [University of California, Los Angeles],
      email: [] ),
    ( name: [Xiaofei Shi],
      affiliation: [University of California, Los Angeles],
      email: [] ),
    ( name: [Ivan Vasko],
      affiliation: [University of California, Berkeley],
      email: [] ),
    ),
  date: [2024-01-09],
  cols: 1,
  doc,
)


= Scientific/Technical/Management
<scientifictechnicalmanagement>
== Overview
<overview>
Parker Solar Probe \(PSP) is a NASA mission to study the Sun’s corona and inner heliosphere.

PSP timeline:

- 2018-08-12: Launch
- 2018-10-03: First Venus flyby
- 2018-11-05: First perihelion
- 2019-01-19: First aphehion
- …

#block[
]
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#box(width: 480.0pt, image("images/PSP_01_orbit.png"))
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
Parker Solar Probe orbits
],
  rect(stroke: none, width: 100%)[
]), 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#box(width: 1920.0pt, image("images/paste-1.png"))
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
Multiple satellites orbits
],
  rect(stroke: none, width: 100%)[
]), 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
)
#block[
]
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#box(width: 1041.0pt, image("https://www.nasa.gov/wp-content/uploads/2023/03/575573main_Juno20110727-3-43_full.jpg"))
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
Juno orbit
],
  rect(stroke: none, width: 100%)[
]), 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#box(width: 669.0pt, image("https://docs.poliastro.space/en/stable/_images/examples_Going_to_Jupiter_with_Python_using_Jupyter_and_poliastro_24_2.png"))
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
Juno orbit using `poliastro`
],
  rect(stroke: none, width: 100%)[
]), 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
)
#grid(
columns: (50.0%, 50.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
)
== Discontinuities observed by different spacecrafts
<discontinuities-observed-by-different-spacecrafts>
Juno, Parker Solar Probe, Wind and Stereo.

#block[
]
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#image("https://agupubs.onlinelibrary.wiley.com/cms/asset/8e244339-32cf-4703-9101-c1d9b4a3fa7c/jgra57047-fig-0002-m.jpg")
],
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
  rect(stroke: none, width: 100%)[
A RD detected by PSP at 0.126~AU from #cite(<liu2022>)
],
  rect(stroke: none, width: 100%)[
]), 
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#box(width: 1115.0pt, image("images/paste-2.png"))
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
A RD detected by Juno
],
  rect(stroke: none, width: 100%)[
]), 
],
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#image("https://agupubs.onlinelibrary.wiley.com/cms/asset/837d691e-c062-4bde-95ec-8b3e7b095dfe/jgra21804-fig-0003.png")
],
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
  rect(stroke: none, width: 100%)[
A RD detected by Stereos at 1 AU from #cite(<malaspina2012>)
],
  rect(stroke: none, width: 100%)[
]), 
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
  rect(stroke: none, width: 100%)[
#figure([
],
  rect(stroke: none, width: 100%)[
#image("https://agupubs.onlinelibrary.wiley.com/cms/asset/0be15a8d-39e0-4617-8018-239f22962bea/jgra54962-fig-0001-m.jpg")
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
], caption: figure.caption(
],
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
position: bottom, 
],
  rect(stroke: none, width: 100%)[
[
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
A RD detected by ARTEMIS at 1 AU from #cite(<artemyev2019>)
],
  rect(stroke: none, width: 100%)[
]), 
],
  rect(stroke: none, width: 100%)[
kind: "quarto-float-fig", 
],
  rect(stroke: none, width: 100%)[
supplement: "Figure", 
],
)
#grid(
columns: (25.0%, 25.0%, 25.0%, 25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[
)
],
  rect(stroke: none, width: 100%)[
],
  rect(stroke: none, width: 100%)[


],
)
#grid(
columns: (25.0%), gutter: 1em, rows: 1,
  rect(stroke: none, width: 100%)[
Rotational discontinuities \(RDs) detected by PSP, Juno, Stereo and near-Earth satellite.

],
)
== Occurrence rate of discontinuities
<occurrence-rate-of-discontinuities>
#box(width: 481.3645484949833pt, image("https://raw.githubusercontent.com/Beforerr/ids_finder/1b9830d558470d730a3adbb6667b9b2ca66a6425/notebooks/figures/ocr/ocr_time_cleaned.png"))

== Model validation
<model-validation>
== Solar wind properties
<solar-wind-properties>
#figure([
#box(width: 481.3645484949833pt, image("https://beforerr.github.io/ids_finder/figures/thickness/thickness_mn_dist.png"))
], caption: figure.caption(
position: bottom, 
[
Current sheet thickness
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


= References
<references>
- #link("https://parkersolarprobe.jhuapl.edu/The-Mission/index.php")[Parker Solar Probe: The Mission]

= Open Science and Data Management Plan \(OSDMP)
<open-science-and-data-management-plan-osdmp>
= Biographical Sketches/Curriculum Vitae \(CVs)
<biographical-sketchescurriculum-vitae-cvs>
== Zijin’s CV
<zijins-cv>
== Anton’s CV
<antons-cv>
= Table of Personnel and Work Effort
<table-of-personnel-and-work-effort>
= Current and Pending Support
<current-and-pending-support>
= Statements of Commitment and Letters of Support, Feasibility and Endorsement
<statements-of-commitment-and-letters-of-support-feasibility-and-endorsement>
= Budget
<budget>
== Budget Narrative \(Budget Justification)
<budget-narrative-budget-justification>
== Budget Details
<budget-details>



#bibliography("files/references.bib")

