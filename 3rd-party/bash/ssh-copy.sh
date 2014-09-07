#!/bin/sh

SSH="${HOME}/.ssh"

if [ ! -f "${SSH}/identity.pub" ]
then
    PASSPHRASE=
    read -p "Enter ssh passphrase for ${HOSTNAME}:" PASSPHRASE
    ssh-keygen -t rsa1 -N "$PASSPHRASE" -f "${SSH}/identity"
    ssh-keygen -t rsa  -N "$PASSPHRASE" -f "${SSH}/id_rsa"
    ssh-keygen -t dsa  -N "$PASSPHRASE" -f "${SSH}/id_dsa"
    chmod -f go-w "${SSH}" "${SSH}/authorized_keys*"
fi

cd "${SSH}" && \
tar -c id*.pub | \
ssh $* 'tar -x
    SSH="${HOME}/.ssh"
    if [ ! -f "${SSH}/identity.pub" ]
    then
        PASSPHRASE=
        read -p "Enter ssh passphrase for ${HOSTNAME}:" PASSPHRASE
        ssh-keygen -t rsa1 -N "$PASSPHRASE" -f "${SSH}/identity"
        ssh-keygen -t rsa  -N "$PASSPHRASE" -f "${SSH}/id_rsa"
        ssh-keygen -t dsa  -N "$PASSPHRASE" -f "${SSH}/id_dsa"
    fi
    cat identity.pub          >>"${SSH}/authorized_keys"
    cat id_dsa.pub id_rsa.pub >>"${SSH}/authorized_keys2"
    chmod -f go-w "${SSH}" "${SSH}/authorized_keys*"
    rm -f identity.pub id_dsa.pub id_rsa.pub
'
