#!/usr/bin/env bash
iverilog -o SimpleCore-tests SimpleTests.v SimpleMCU.v SimpleCore.v
echo "### Sleeping a few seconds in case you wanna CTRL+C ###"
sleep 5
vvp SimpleCore-tests
