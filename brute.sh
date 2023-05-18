while [ "$( cat ./out/SelfDestructMeta.sol/SelfDestructMeta.json | grep -o "5bff" | wc -l )" < "3" ]
do
    echo "// $( openssl rand 8 -hex )\npragma solidity ^0.8.18;" > src/Comment.sol
done