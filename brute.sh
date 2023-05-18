x=0
while [ "$x" -lt 3 ]
do
    h=$( openssl rand 16 -hex )
    echo "$x"
    echo "$h"
    echo "// $h\npragma solidity ^0.8.18;" > ./src/Comment.sol
    forge build
    x=$( cat ./out/SelfDestructMeta.sol/SelfDestructMeta.json | grep -o '5bff' | wc -l )
done
say "done"