GOPATH=$(shell pwd)
GOBIN=$(GOPATH)/bin

all: clean compile

compile:
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go get .
	@GOPATH=$(GOPATH) GOBIN=$(GOBIN) go build -buildmode=c-shared -o out_coralogix.so .

clean:
	@rm -rf out_coralogix.h src bin
