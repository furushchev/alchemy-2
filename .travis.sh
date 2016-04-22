#!/bin/bash

set -e

function travis_time_start {
    set +x
    TRAVIS_START_TIME=$(date +%s%N)
    TRAVIS_TIME_ID=$(cat /dev/urandom | tr -dc 'a-z0-9' | fold -w 8 | head -n 1)
    TRAVIS_FOLD_NAME=$1
    echo -e "\e[0Ktraivs_fold:start:$TRAVIS_FOLD_NAME"
    echo -e "\e[0Ktraivs_time:start:$TRAVIS_TIME_ID"
    set -x
}
function travis_time_end {
    set +x
    _COLOR=${1:-32}
    TRAVIS_END_TIME=$(date +%s%N)
    TIME_ELAPSED_SECONDS=$(( ($TRAVIS_END_TIME - $TRAVIS_START_TIME)/1000000000 ))
    echo -e "traivs_time:end:$TRAVIS_TIME_ID:start=$TRAVIS_START_TIME,finish=$TRAVIS_END_TIME,duration=$(($TRAVIS_END_TIME - $TRAVIS_START_TIME))\n\e[0K"
    echo -e "traivs_fold:end:$TRAVIS_FOLD_NAME"
    echo -e "\e[0K\e[${_COLOR}mFunction $TRAVIS_FOLD_NAME takes $(( $TIME_ELAPSED_SECONDS / 60 )) min $(( $TIME_ELAPSED_SECONDS % 60 )) sec\e[0m"
    set -x
}

if [ ! -e /usr/bin/sudo ] ; then apt-get install -y sudo; fi

travis_time_start setup.apt-get_update
sudo apt-get update
travis_time_end

travis_time_start setup.apt-get_install
sudo apt-get install -qq -y git make g++ bison flex perl
travis_time_end

travis_time_start install
git clone https://github.com/pfi/mln-postagger $CI_SOURCE_PATH/test
travis_time_end

travis_time_start script.make
(cd $CI_SOURCE_PATH/src && make -j)
travis_time_end

travis_time_start script.test
export PATH=$CI_SOURCE_PATH/bin:$PATH
export TEST_PATH=$CI_SOURCE_PATH/test
export QUERY=Noun,Verb,Det,Prep,Adj
learnwts -d -i $TEST_PATH/pos.mln -o mid-out.mln -t $TEST_PATH/pos-train1.db,$TEST_PATH/pos-train2.db,$TEST_PATH/pos-train3.db -ne $QUERY -multipleDatabases 1>/dev/null
cat mid-out.mln
infer -i mid-out.mln -r result -e $TEST_PATH/pos-test.db -q $QUERY
cat result
travis_time_end
