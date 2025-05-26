#!/bin/sh
"C:\Program Files\Git\usr\bin\openssl.exe" genrsa -out privateKey.pem 4096
"C:\Program Files\Git\usr\bin\openssl.exe" rsa -in privateKey.pem -pubout -out publicKey.pem