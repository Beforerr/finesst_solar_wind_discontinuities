preview:
   quarto preview

publish:
   quarto publish gh-pages --no-render --no-prompt

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_psp.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'

export:
   quarto pandoc comps/_03_osdmp.qmd -o overleaf/sections/_03_osdmp.tex -f markdown
   quarto pandoc comps/_04_rrs.qmd -o overleaf/sections/_04_rrs.tex -f markdown
   quarto pandoc comps/_07_commitment.qmd -o overleaf/sections/_07_commitment.tex  -f markdown
   quarto pandoc comps/_08_mentoring.qmd -o overleaf/sections/_08_mentoring.tex  -f markdown
   quarto pandoc comps/_09_budget.qmd -o overleaf/sections/_09_budget.tex

   quarto pandoc comps/_01-04_demonstration.qmd -o overleaf/sections/_01-04_demonstration.tex -f markdown

   cp files/references.bib overleaf/files/

   quarto render comps/_01-04_demonstration.qmd --to latex -M cite-method:natbib -M bibliography:files/references.bib -M filter:quarto
   awk '/\\begin\{document\}/ {flag=1; next} /\\bibliography/ {flag=0} flag' comps/_01-04_demonstration.tex > overleaf/sections/_01-04_demonstration.tex
   rm comps/_01-04_demonstration.tex

   rsync images/ overleaf/images/ -r
   rsync figures/ overleaf/figures/ -r
   rsync files/ overleaf/files/ -r

clean:
   find . -name '.DS_Store' -type f -delete
