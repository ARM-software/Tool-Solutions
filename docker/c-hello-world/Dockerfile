FROM alpine AS builder
RUN apk add build-base
WORKDIR /home
COPY hello.c .
RUN gcc "-DARCH=\"`uname -a`\"" hello.c -o hello
 

FROM alpine
WORKDIR /home
COPY --from=builder /home/hello .
ENTRYPOINT ["./hello"]
