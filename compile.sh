#!/bin/bash

rgbasm -L -o main.o main.asm
rgblink -o main.gb main.o
rgbfix -v -p 0xFF --color-only main.gb
