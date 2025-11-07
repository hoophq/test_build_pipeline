VERSION ?= "0.0.1-alpha"
GITCOMMIT ?= $(shell git rev-parse HEAD)
DIST_FOLDER ?= ./dist

GOOS ?= linux
GOARCH ?= amd64

# compatible with uname -s
OS := $(shell echo "$(GOOS)" | awk '{print toupper(substr($$0, 1, 1)) tolower(substr($$0, 2))}')
SYMLINK_ARCH := $(if $(filter $(GOARCH),amd64),x86_64,$(if $(filter $(GOARCH),arm64),aarch64,$(ARCH)))
POSTREST_ARCH_SUFFIX := $(if $(filter $(GOARCH),amd64),linux-static-x64.tar.xz,$(if $(filter $(GOARCH),arm64),ubuntu-aarch64.tar.xz,$(ARCH)))

UNAME_S := $(shell uname -s)
UNAME_M := $(shell uname -m)
ifeq ($(UNAME_S),Darwin)
  ifeq ($(UNAME_M),x86_64)
    RUST_TARGET := x86_64-apple-darwin
  else ifeq ($(UNAME_M),arm64)
    RUST_TARGET := aarch64-apple-darwin
  endif
else ifeq ($(UNAME_S),Linux)
  ifeq ($(UNAME_M),x86_64)
    RUST_TARGET := x86_64-unknown-linux-gnu
  else ifeq ($(UNAME_M),aarch64)
    RUST_TARGET := aarch64-unknown-linux-gnu
  endif
endif

build-rust-darwin-all:
	GOOS=darwin GOARCH=amd64 $(MAKE) build-rust-single
	GOOS=darwin GOARCH=arm64 $(MAKE) build-rust-single

build-rust-linux-all:
	GOOS=linux GOARCH=amd64 $(MAKE) build-rust-single
	GOOS=linux GOARCH=arm64 $(MAKE) build-rust-single

# Build single Rust binary using GOOS/GOARCH variables
build-rust-single: build-clean-folder
	cd agentrs && cargo build --release --target ${RUST_TARGET} && \
	cp target/${RUST_TARGET}/release/agentrs ../dist/binaries/${GOOS}_${GOARCH}/hoop_rs

build-clean-folder:
	mkdir -p ${DIST_FOLDER}/binaries/${GOOS}_${GOARCH}
	
build-tar-files:
	mkdir -p ${DIST_FOLDER}/binaries/${GOOS}_${GOARCH}
	tar -czvf ${DIST_FOLDER}/binaries/hoop_${VERSION}_${OS}_${GOARCH}.tar.gz -C ${DIST_FOLDER}/binaries/${GOOS}_${GOARCH} .
	tar -czvf ${DIST_FOLDER}/binaries/hoop_${VERSION}_${OS}_${SYMLINK_ARCH}.tar.gz -C ${DIST_FOLDER}/binaries/${GOOS}_${GOARCH} .
	sha256sum ${DIST_FOLDER}/binaries/hoop_${VERSION}_${OS}_${GOARCH}.tar.gz > ${DIST_FOLDER}/binaries/hoop_${VERSION}_${OS}_${GOARCH}_checksum.txt
	sha256sum ${DIST_FOLDER}/binaries/hoop_${VERSION}_${OS}_${SYMLINK_ARCH}.tar.gz > ${DIST_FOLDER}/binaries/hoop_${VERSION}_${OS}_${SYMLINK_ARCH}_checksum.txt
	rm -rf ${DIST_FOLDER}/binaries/${GOOS}_${GOARCH}

build-go: build-clean-folder
	env CGO_ENABLED=0 GOOS=${GOOS} GOARCH=${GOARCH} go build -o ${DIST_FOLDER}/binaries/${GOOS}_${GOARCH}/ main.go

build-webapp:
	mkdir -p ${DIST_FOLDER}
	cd ./webapp && npm install && npm run release && cd ../
	tar -czf ${DIST_FOLDER}/webapp.tar.gz -C ./webapp/resources .

.PHONY: build-go build-webapp build-rust-darwin-all build-rust-linux-all build-rust-single build-clean-folder
