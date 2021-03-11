#!/bin/bash

echo "Update system"
sudo apt update
sudo apt upgrade -y
sudo apt autoremove -y
sudo apt clean

echo "Update snapshots"
sudo snap refresh

echo "Done!"
