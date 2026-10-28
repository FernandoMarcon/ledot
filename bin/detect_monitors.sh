#!/bin/bash

hyprctl monitors|grep "^Monitor"|cut -f2 -d$' '
