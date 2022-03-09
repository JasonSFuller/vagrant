#!/bin/bash

ssh centos8a -l jsmith -i id_rsa_jsmith echo 'LOGIN:  jsmith login successful'
ssh centos8a -l jdoe -i id_ed25519_jdoe echo 'LOGIN:  jdoe login successful'
ssh centos8a -l root -i id_ed25519_jdoe echo 'LOGIN:  I am root!'

echo -e "\nDONE!\n"
