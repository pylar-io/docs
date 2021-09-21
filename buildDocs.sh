#!/usr/bin/env bash

# Install node_modules, if not already installed
if [ ! -r ./node_modules ]; then
    docker run --rm --volume "$PWD:/src" -w "/src" capsulecorplab/asciidoctor-extended:asciidocsy-nodejs 'npm i'
fi

# Install m30pm/node_modules, if not already installed
if [ ! -r ./m30pm/node_modules ]; then
    docker run --rm --volume "$PWD:/src" -w "/src" capsulecorplab/asciidoctor-extended:asciidocsy-nodejs 'cd m30pm && npm ci'
fi

# Make dist/ directory, if none exists
if [ ! -r ./dist ]; then
    mkdir dist/
fi

# Build the unified model
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app node:14 node m30pm/buildUnifiedModel.js

# copy dist/architecture.yaml to dist/architecture.yml
cp dist/architecture.yaml dist/architecture.yml

# generate architecture.adoc from liquid template
docker run --rm -v "$PWD":/usr/src/app -w /usr/src/app node:14 node m30pm/generateDoc.js --unifiedModel=dist/architecture.yaml --template=templates/architecture.adoc.liquid --out=dist/architecture.adoc

# generate pdf-theme.yml from liquid template
docker run --rm -v "$PWD:/src" -w "/src" capsulecorplab/asciidoctor-extended:liquidoc 'bundle exec liquidoc -d dist/architecture.yml -t templates/pdf-theme.yml.liquid -o dist/pdf-theme.yml'

# generate index.html
docker run --rm -v "$PWD:/src" -w "/src" asciidoctor/docker-asciidoctor asciidoctor dist/architecture.adoc -r asciidoctor-diagram -o dist/index.html

# generate pylar-architecture.pdf
docker run --rm -v "$PWD:/src" -w "/src" asciidoctor/docker-asciidoctor asciidoctor dist/architecture.adoc -o dist/pylar-architecture.pdf -r asciidoctor-pdf -r asciidoctor-diagram -b pdf -a pdf-theme=dist/pdf-theme.yml
