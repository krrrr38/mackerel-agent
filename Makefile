BIN = mackerel-agent
ARGS = "-conf=mackerel-agent.conf"
BUILD_OS_TARGETS = "linux darwin freebsd windows"

BUILD_LDFLAGS = "\
	  -X github.com/mackerelio/mackerel-agent/version.GITCOMMIT `git rev-parse --short HEAD` \
	  -X github.com/mackerelio/mackerel-agent/version.VERSION   `git describe --tags --abbrev=0 | sed 's/^v//' | sed 's/\+.*$$//'` "

all: clean test build

test: lint
	go test $(TESTFLAGS) ./...

build: deps
	go build -ldflags=$(BUILD_LDFLAGS) \
	-o build/$(BIN)

run: build
	./build/$(BIN) $(ARGS)

deps:
	go get -d -v -t ./...
	go get github.com/golang/lint/golint
	go get golang.org/x/tools/cmd/vet
	go get github.com/laher/goxc

LINT_RET = .golint.txt
lint: deps
	go vet ./...
	rm -f $(LINT_RET)
	for os in "$(BUILD_OS_TARGETS)"; do \
		if [ $$os != "windows" ]; then \
			GOOS=$$os golint ./... | tee -a $(LINT_RET); \
		fi \
	done
	test ! -s $(LINT_RET)

crossbuild: deps
	goxc -build-ldflags=$(BUILD_LDFLAGS) \
	    -os=$(BUILD_OS_TARGETS) -arch=386 -d . \
	    -resources-include='README*,mackerel-agent.conf' -n $(BIN)

clean:
	rm -f build/$(BIN)
	go clean

.PHONY: test build run deps clean lint crossbuild
