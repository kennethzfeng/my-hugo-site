help:
	@echo "Site Toolchain"
	@echo "make install - install all of dependencies"
	@echo "make serve - serve the hugo development site" 
	@echo "deploy - deploy to github" 

install:
	go get -v github.com/spf13/hugo

serve:
	hugo -w server

deploy:
	./deploy.sh

.PHONY: help install serve deploy
