#!/bin/bash
PSQL="psql --username=freecodecamp --dbname=number_guess -t --no-align -c"

INPUT_NAME() {
  echo "Enter your username:"
  read NAME
  n=${#NAME}

  if [[ ! $n -le 22 ]] || [[ ! $n -gt 0 ]]
  then
    INPUT_NAME
  else
    USERNAME=$(echo $($PSQL "SELECT username FROM players WHERE username='$NAME';") | sed 's/ //g')
    if [[ ! -z $USERNAME ]]
    then
      PLAYER_ID=$(echo $($PSQL "SELECT player_id FROM players WHERE username='$USERNAME';") | sed 's/ //g')
      USERNAME=$(echo $($PSQL "SELECT username FROM players WHERE player_id='$PLAYER_ID';") | sed 's/ //g')
      GAMES_PLAYED=$(echo $($PSQL "SELECT frequent_games FROM players WHERE player_id=$PLAYER_ID;") | sed 's/ //g')
      BEST_GAME=$(echo $($PSQL "SELECT MIN(best_game) FROM players LEFT JOIN games USING(player_id) WHERE player_id=$PLAYER_ID;") | sed 's/ //g')
      
      
      echo "Welcome back, $USERNAME! You have played $GAMES_PLAYED games, and your best game took $BEST_GAME guesses."
    else
      USERNAME=$NAME
      echo -e "\nWelcome, $USERNAME! It looks like this is your first time here."
    fi
    CORRECT_ANSWER=$(( $RANDOM % 1000 + 1 ))
    GUESS_COUNT=0
    INPUT_GUESS $USERNAME $CORRECT_ANSWER $GUESS_COUNT
  fi
}

INPUT_GUESS() {
  USERNAME=$1
  CORRECT_ANSWER=$2
  GUESS_COUNT=$3
  PLAYER_GUESS=$4

  if [[ -z $PLAYER_GUESS ]]
  then
    echo "Guess the secret number between 1 and 1000:"
    read PLAYER_GUESS
  else
    echo "That is not an integer, guess again:"
    read PLAYER_GUESS
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $PLAYER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USERNAME $CORRECT_ANSWER $GUESS_COUNT $PLAYER_GUESS
  else
    CHECK_ANSWER $USERNAME $CORRECT_ANSWER $GUESS_COUNT $PLAYER_GUESS
  fi
}

CHECK_ANSWER() {
  USERNAME=$1 
  CORRECT_ANSWER=$2 
  GUESS_COUNT=$3
  PLAYER_GUESS=$4

  if [[ $PLAYER_GUESS -gt $CORRECT_ANSWER ]]
  then
    echo "It's lower than that, guess again:"
    read PLAYER_GUESS
  elif [[ $PLAYER_GUESS -lt $CORRECT_ANSWER ]]
  then
    echo "It's higher than that, guess again:"
    read PLAYER_GUESS
  else
    GUESS_COUNT=$GUESS_COUNT
  fi

  GUESS_COUNT=$(( $GUESS_COUNT + 1 ))
  if [[ ! $PLAYER_GUESS =~ ^[0-9]+$ ]]
  then
    INPUT_GUESS $USERNAME $CORRECT_ANSWER $GUESS_COUNT $PLAYER_GUESS
  elif [[ $PLAYER_GUESS -lt $CORRECT_ANSWER ]] || [[ $PLAYER_GUESS -gt $CORRECT_ANSWER ]]
  then
    CHECK_ANSWER $USERNAME $CORRECT_ANSWER $GUESS_COUNT $PLAYER_GUESS
  elif [[ $PLAYER_GUESS -eq $CORRECT_ANSWER ]]
  then

    SAVE_PLAYER $USERNAME $GUESS_COUNT
    NUMBER_OF_GUESSES=$GUESS_COUNT
    SECRET_NUMBER=$CORRECT_ANSWER
    echo "You guessed it in $NUMBER_OF_GUESSES tries. The secret number was $SECRET_NUMBER. Nice job!"
  fi

}

SAVE_PLAYER() {
  USERNAME=$1 
  GUESS_COUNT=$2

  CHECK_NAME=$($PSQL "SELECT username FROM players WHERE username='$USERNAME';")
  if [[ -z $CHECK_NAME ]]
  then
    INSERT_NEW_PLAYER=$($PSQL "INSERT INTO players(username, frequent_games) VALUES('$USERNAME',1);")
  else
    GET_GAMES_PLAYED=$(( $($PSQL "SELECT frequent_games FROM players WHERE username='$USERNAME';") + 1))
    UPDATE_EXIST_PLAYER=$($PSQL "UPDATE players SET frequent_games=$GET_GAMES_PLAYED WHERE username='$USERNAME';")
  fi
  SAVE_GAME $USERNAME $GUESS_COUNT
}

SAVE_GAME() {
  USERNAME=$1 
  NUMBER_OF_GUESSES=$2

  PLAYER_ID=$($PSQL "SELECT player_id FROM players WHERE username='$USERNAME';")
  INSERT_GAME=$($PSQL "INSERT INTO games(player_id, best_game) VALUES($PLAYER_ID, $NUMBER_OF_GUESSES);")
  USERNAME=$($PSQL "SELECT username FROM players WHERE player_id=$PLAYER_ID;")
}


INPUT_NAME