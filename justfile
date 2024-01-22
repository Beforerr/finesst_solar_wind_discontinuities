preview:
   quarto preview

publish:
   quarto publish gh-pages --no-render --no-prompt

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_psp.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'

update: clean sync
   cd overleaf; git commit -am "update"; git push

export-all:
   quarto render _proposal.qmd --to latex -M cite-method:natbib -M bibliography:files/references.bib -M filter:quarto

latex-export file:
   quarto render sections/{{file}}.qmd --to latex -M cite-method:natbib -M bibliography:files/references.bib -M filter:quarto -M filter:latex-environment
   awk '/\\begin\{document\}/ {flag=1; next} /\\bibliography/ {flag=0} flag' sections/{{file}}.tex > overleaf/sections/{{file}}.tex
   rm sections/{{file}}.tex

export:
   quarto pandoc sections/_01_science.qmd -o overleaf/sections/_01_science.tex -f markdown
   quarto pandoc sections/_03_osdmp.qmd -o overleaf/sections/_03_osdmp.tex -f markdown
   quarto pandoc sections/_04_rrs.qmd -o overleaf/sections/_04_rrs.tex -f markdown
   quarto pandoc sections/_07_commitment.qmd -o overleaf/sections/_07_commitment.tex  -f markdown
   quarto pandoc sections/_08_mentoring.qmd -o overleaf/sections/_08_mentoring.tex  -f markdown
   quarto pandoc sections/_09_budget.qmd -o overleaf/sections/_09_budget.tex

   quarto pandoc sections/_01-04_demonstration.qmd -o overleaf/sections/_01-04_demonstration.tex -f markdown


   cp files/references.bib overleaf/files/

   quarto render sections/_01-04_demonstration.qmd --to latex -M cite-method:natbib -M bibliography:files/references.bib -M filter:quarto
   awk '/\\begin\{document\}/ {flag=1; next} /\\bibliography/ {flag=0} flag' sections/_01-04_demonstration.tex > overleaf/sections/_01-04_demonstration.tex
   rm sections/_01-04_demonstration.tex

sync:
   rsync images/ overleaf/images/ -r
   rsync figures/ overleaf/figures/ -r
   rsync files/ overleaf/files/ -r

clean:
   find . -name '.DS_Store' -type f -delete
