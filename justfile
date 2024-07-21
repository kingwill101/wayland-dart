gen:
    dart --enable-asserts bin/scanner.dart scan --format=true --prefix=wl --pkg=client --protocols=protocols.yaml --clean=true

    
shared:
    gcc -shared -o libsocket_operations.so -fPIC src/socket.c
