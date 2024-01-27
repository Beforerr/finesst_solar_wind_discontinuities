preview:
   quarto preview

publish:
   quarto publish gh-pages --no-render --no-prompt

examples:
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_psp.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_stereo.yml'
   ipython notebooks/01_ids_example.ipynb 'notebooks/config_examples/examples_artemis.yml'

update: update-overleaf
   git add .; git commit -am "update"; git push

update-overleaf: sync-overleaf clean
   cd overleaf; git add .; git commit -am "update"; git push

sync-overleaf:
   rsync images/ overleaf/images/ -r
   rsync figures/ overleaf/figures/ -r
   rsync files/ overleaf/files/ -r

export-combined:
   -quarto render index.qmd --to latex
   mv _manuscript/index.tex index.tex
   awk '/\\begin\{document\}/ {flag=1; next} /\\end\{document\}/ {flag=0} flag' index.tex | awk '!/\\maketitle/' > overleaf/index.tex
   rm index.tex

export-cv:
   docx2pdf overleaf/files/Angelopoulos_2pgCV_January_2024.docx
   pdfcropmargins -v -s -u overleaf/files/Angelopoulos_2pgCV_January_2024.pdf -o overleaf/files/
   pdfcropmargins -v -s -u overleaf/files/cv/cv_Zijin_clean.pdf -o overleaf/files/cv

clean:
   find . -name '.DS_Store' -type f -delete

# Not used anymore

latex-export file:
   quarto render sections/{{file}}.qmd --to latex -M cite-method:natbib -M bibliography:files/references.bib -M filter:quarto -M filter:latex-environment
   awk '/\\begin\{document\}/ {flag=1; next} /\\end\{document\}/ {flag=0} flag' sections/{{file}}.tex > overleaf/sections/{{file}}.tex
   rm sections/{{file}}.tex

export:
   quarto pandoc sections/_01_science.qmd -o overleaf/sections/_01_science.tex -f markdown
   quarto pandoc sections/_01-04_demonstration.qmd -o overleaf/sections/_01-04_demonstration.tex -f markdown
   
   cp files/references.bib overleaf/files/

   quarto render sections/_01-04_demonstration.qmd --to latex -M cite-method:natbib -M bibliography:files/references.bib -M filter:quarto
   awk '/\\begin\{document\}/ {flag=1; next} /\\bibliography/ {flag=0} flag' sections/_01-04_demonstration.tex > overleaf/sections/_01-04_demonstration.tex
   rm sections/_01-04_demonstration.tex