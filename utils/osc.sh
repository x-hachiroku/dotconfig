#!/bin/bash
printf "\033]52;c;%s\007" "$(base64 -w 0)"
