#!/bin/sh



pfile="./passwd"
PASSWD=$(cat "$pfile")

#Displays account of the user
disp_account(){
echo "Your Wallet is:"
./geth --testnet --fast -exec "eth.accounts" attach 
}


#Check geth location
ETH=$(which geth)  
check_geth() {
    STATUS=""
    if [ -z $ETH ] && [ ! "$(ps -A | grep ether*)" ];  
    then
        STATUS="You need to install Ethereum CLI based on GoLang, or run Ethereum Wallet App"
    else 
        STATUS="OK"
    fi
    echo $STATUS
}

#Run ETHER server
run_server() {
    # execute eth and redirect all output to /dev/null
    if ! $ETH --testnet --exec 'console.log("OK")' attach 2&>/dev/null  
    then
        # run eth webserver 
        $ETH --testnet --ws --fast 2&> /tmp/wallet-server.log & 
        # get server process PID
        PID=`jobs -p`
        echo $1
        # until webserver is not created look for it
        until grep -q 'WebSocket endpoint opened:' /tmp/wallet-server.log
        do
            sleep 3
        done
        # save the URL of server for future requests
        URL=`grep 'WebSocket endpoint opened:'  /tmp/wallet-server.log | sed 's/^.*WebSocket endpoint opened: //'`
        echo $URL,$PID
    fi
}


#Unlock user account and send certain number of 'ether' 
send(){
SENDER=$1
RECEIVER=$2
AMOUNT=$3
./geth --exec "personal.unlockAccount('$1', '$PASSWD')" attach > /dev/null
TRANSACTION=`./geth --testnet --fast -exec "eth.sendTransaction({from: '$SENDER', to: '$RECEIVER', value: web3.toWei('$AMOUNT', 'ether')})" attach`
echo $TRANSACTION
}

#Help
help () {
    printf "Script: "$0" provides the possibility to send ether from one account to another\n"
}


cli_main(){

if [ ! -z $1 ] && [ $1 = "-h" ];
    then
        help
        exit
fi

STATUS=$(check_geth)
    if [[ $STATUS != *"OK" ]] || $([ ! -z $1 ] );
    then
        echo $STATUS
        exit 
fi

#Start server if Ethereum app is not running
if [ ! "$(ps -A | grep ether*)" ];
	then
	    SERVER=$(run_server)
	fi


while true
do
	printf "Please enter the account of SENDER:\n"
	read SENDER
	
	printf "Please enter the account of RECEIVER:\n"
        read RECEIVER

	printf "Please enter the AMOUNT of ethers:\n"
        read AMOUNT

	TRANSACTION="$(send $SENDER $RECEIVER $AMOUNT)"
	echo "Transaction code is:"
	echo $TRANSACTION
	
	printf "Do you want make another transaction? (Y/N).\n"
	read ANS
	if [ $ANS != "Y" ];
        then
            exit
	fi

done

} 


cli_main $*

