#!/usr/bin/env bash

if [ -z "$1" ]
  then
    echo "No argument supplied"
        exit 1
fi

echo $@ > /tmp/arguments

/hive/bin/miner stop

RIG_CONF="/hive-config/rig.conf"
WALLET_CONF="/hive-config/wallet.conf"
CCMINER_CONFIG_FILE="/hive/ccminer/pools.conf"


. $RIG_CONF
. $WALLET_CONF

sed -i '/CCMINER/d'  $WALLET_CONF
echo -e "\n"  >>   $WALLET_CONF

echo CCMINER_FORK=\"$1\" >>  $WALLET_CONF
echo -e $CCMINERCONF  | swap_ccminer.py $3 $5  >>   $WALLET_CONF

sleep 2

/hive/bin/miner start

echo conf chenged, miner started

sleep 3
