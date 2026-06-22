#!/bin/bash

set -a

CONFIGURATION_DIRECTORY="${HOME}/.config/"
CONFIGURATION_FILE="${CONFIGURATION_DIRECTORY}git_profiles.conf.bash"
PROFILES_DIRECTORY="${CONFIGURATION_DIRECTORY}git_profiles/"

clean(){
 set +a && exit $1
}

write_Configuration_File(){
 echo '#!/bin/bash' > "$CONFIGURATION_FILE"
 echo 'set -a' >> "$CONFIGURATION_FILE"
 echo "PROFILES_DIRECTORY='${PROFILES_DIRECTORY}'" >> "$CONFIGURATION_FILE"
 echo "set +a" >> "$CONFIGURATION_FILE"
 mkdir -p "$PROFILES_DIRECTORY"
}

GIT_NAME=""
GIT_EMAIL=""
GIT_PGP=""

write_Git_Profile_File(){
 GIT_PROFILE_FILE="${PROFILES_DIRECTORY}${GIT_PROFILE}.profile.bash"
 echo '#!/bin/bash' > "$GIT_PROFILE_FILE"
 echo 'set -a' >> "$GIT_PROFILE_FILE"
 echo "GIT_NAME='${GIT_NAME}'" >> "$GIT_PROFILE_FILE"
 echo "GIT_EMAIL='${GIT_EMAIL}'" >> "$GIT_PROFILE_FILE"
 echo "GIT_PGP='${GIT_PGP}'" >> "$GIT_PROFILE_FILE"
 echo 'set +a' >> "$GIT_PROFILE_FILE"
 chmod +x "$GIT_PROFILE_FILE"
}

USER_INPUT=""

read_Integer(){
 read -n 1 USER_INPUT
}

read_String(){
 read -r USER_INPUT
}

set_GIT_NAME(){
  echo "INSERT GIT user.name:"
  read_String
  GIT_NAME="$USER_INPUT" 
}

set_GIT_EMAIL(){
  echo "INSERT GIT user.email:"
  read_String
  GIT_EMAIL="$USER_INPUT"
}

set_GIT_PGP(){
 gpg --list-keys --keyid-format=long
 echo "SPECIFY A KEYID FOR THE KEY YOU WILL USE:"
 read_String
 GIT_PGP="$USER_INPUT"
}

main_Menu(){
 echo "CHOOSE AN OPTION"
 echo "0)CHANGE PROFILES DIRECTORY"
 echo "1)ADD A PROFILE"
 echo "2)MODIFY A PROFILE"
 echo "3)DELETE A PROFILE"
 echo "4)INIT GIT FOR CURRENT DIRECTORY (INIRIALIZE ONLY: MUST DO ANY SERVER CONNECTION AFTER)"
 echo "5)OVERWRITE FOR CURRENT DIRECTORY/REPOSITORY"
 echo "6)LIST PROFILES"
 echo "7)EXIT"
 read_Integer
 echo ""
 case "$USER_INPUT" in
 "0")
  echo "INSERT NEw PROFILES DIRECTORY (ABSOLUTE ADDRESS WITH A '/' AT THE END)"
  read_String
  PROFILES_DIRECTORY="$USER_INPUT"
  write_Configuration_File
 ;;
 "1")
  echo "INSERT NAME FOR PROFILE FILE(DO NOT INCLUDE FILE EXTENSION):"
  read_String
  GIT_PROFILE="$USER_INPUT"
  set_GIT_NAME
  set_GIT_EMAIL
  set_GIT_PGP
  echo "WRITING FILE"
  write_Git_Profile_File
 ;;
 "2")
  echo "WHAT PROFILE ARE YOU MODIFYING:"
  read_String
  GIT_PROFILE="$USER_INPUT"
  GIT_PROFILE_FILE="${PROFILES_DIRECTORY}${USER_INPUT}.profile.bash"
  if [[ ! -f "$GIT_PROFILE_FILE" ]] then
   echo "THE '${USER_INPUT}' PROFILE DOES NOT EXIST"
   return
  fi
  . "$GIT_PROFILE_FILE"
  echo "WHICH PART DO YOU WANT TO EDIT:"
  echo "GIT_NAME"
  echo "GIT_EMAIL"
  echo "GIT_PGP"
  read_String
  set_${USER_INPUT}
  write_Git_Profile_File
  ;;

 "3")
  echo "INSERT THE NAME OF THE PROFILE:"
  read_String
  rm "${PROFILES_DIRECTORY}${USER_INPUT}.profile.bash"
 ;;

 "4")
  echo "ENTER THE NAME OF THE PROFILE:"
  read_String
  GIT_PROFILE_FILE="${PROFILES_DIRECTORY}${USER_INPUT}.profile.bash"
  if [[ ! -f "$GIT_PROFILE_FILE" ]] then
   echo "THE '${USER_INPUT}' PROFILE DOES NOT EXIST"
   return
  fi
  . "$GIT_PROFILE_FILE"
  git init
  git config user.name "$GIT_NAME"
  git config user.email "$GIT_EMAIL"
  git config --unset gpg.format
  git config user.signingkey "$GIT_PGP"
  ;;

  "5")
  echo "ENTER THE NAME OF THE PROFILE:"
  read_String
  GIT_PROFILE_FILE="${PROFILES_DIRECTORY}${USER_INPUT}.profile.bash"
 
  if [[ ! -f "$GIT_PROFILE_FILE" ]] then
   echo "THE '${USER_INPUT}' PROFILE DOES NOT EXIST"
   return
  fi
  . "$GIT_PROFILE_FILE"
  git config user.name "$GIT_NAME"
  git config user.email "$GIT_EMAIL"
  git config --unset gpg.format
  git config user.signingkey "$GIT_PGP"
  ;;
 "6")
  HOME_DIR="$(pwd)"
  cd "$PROFILES_DIRECTORY"
  mapfile -t profiles < <(find . -maxdepth 1 -type f -name "*.profile.bash" | tr -d '\r')
  for profile in "${profiles[@]}"; do
   profile="${profile#./}"
   echo "${profile%.profile.bash}"
  done
  cd "$HOME_DIR"
  ;;
 "7")
  clean 0
 ;;
 *)
  echo "INVALID OPTION"
 ;;
 esac
}

if [[ ! -f "$CONFIGURATION_FILE" ]] then
 mkdir -p "$CONFIGURATION_DIRECTORY" || (echo "FAILED TO CREATE DIRECTORY: ${CONFIGURATION_DIRECTORY}";clean 1)
 touch "$CONFIGURATION_FILE" || (echo "FAILED TO CREATE FILE: ${CONFIGURATION_FILE}";clean 2)
 chmod +x "$CONFIGURATION_FILE" || (echo "FAILED TO SET CONFIGURATION SCRIPT TO EXECUTABLE";clean 3)
 write_Configuration_File
fi

. "$CONFIGURATION_FILE"
while : 
 do 
  main_Menu
done
