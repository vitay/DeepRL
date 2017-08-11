all: html pdf

pdf: DeepRL.md
	pandoc -sSN -F pandoc-crossref --toc --bibliography=/home/vitay/Articles/biblio/ReinforcementLearning.bib \
		--csl=apalike.csl -V fontsize=11pt -V roboto:sfdefault -V geometry:margin=1in \
		-V documentclass=report -V linestretch=1.3 DeepRL.md -o DeepRL.tex
	rubber --pdf DeepRL.tex
	rubber --clean DeepRL.tex

html: DeepRL.md
	pandoc -sSN -F pandoc-crossref --template=default.html5 --mathjax="/usr/share/mathjax/MathJax.js?config=TeX-AMS-MML_HTMLorMML" \
		--toc --listings --css=github.css --bibliography=/home/vitay/Articles/biblio/ReinforcementLearning.bib \
		--csl=apalike.csl DeepRL.md -o DeepRL.html

export: DeepRL.md
	pandoc -sSN -F pandoc-crossref --template=default.html5 --mathjax="https://cdnjs.cloudflare.com/ajax/libs/mathjax/2.7.1/MathJax.js?config=TeX-AMS-MML_HTMLorMML" \
		--toc --listings --css=github.css --bibliography=/home/vitay/Articles/biblio/ReinforcementLearning.bib \
		--csl=apalike.csl DeepRL.md -o index.html

