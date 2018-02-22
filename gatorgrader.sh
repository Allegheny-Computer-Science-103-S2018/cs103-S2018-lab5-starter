#!/bin/bash

# assume that gatorgrader.py exits correctly
GATORGRADER_EXIT=0

# assume that the human-readable answer is "No"
GATORGRADER_EXIT_HUMAN_PASS="No"

# determine if the exit code is always failing
determine_exit_code() {
  if [ "$1" -eq 1 ]; then
    GATORGRADER_EXIT=1
  else
    if [ "$2" ]; then
      echo "$2 was successful"
    fi
  fi
}

# determine a human-readable answer for status
determine_human_exit_code() {
  if [ "$1" -eq 1 ]; then
    GATORGRADER_EXIT_HUMAN_PASS="Yes"
  fi
}

# define colors that can improve terminal output
red=$'\e[1;31m'
grn=$'\e[1;32m'
yel=$'\e[1;33m'
blu=$'\e[1;34m'
mag=$'\e[1;35m'
cyn=$'\e[1;36m'
end=$'\e[0m'

# define the viable command-line arguments for gatorgrader.sh
OPTS=`getopt -o vsc: --long verbose,start,check,update,download -- "$@"`

# parsing did not work correctly, give an error
if [ $? != 0 ] ; then echo "gatorgrader.sh could not parse the options!" >&2 ; exit 1 ; fi

# set the command-line arguments for further analysis
eval set -- "$OPTS"

# set the default values for the variables that mirror arguments
VERBOSE=false
START=false
CHECK=false
DOWNLOAD=false
UPDATE=""

# set the variables based on the command-line arguments
# the --update parameter accepts an additional argument
while true; do
  case "$1" in
    -v | --verbose )  VERBOSE=true; shift ;;
    -s | --start )    START=true; shift ;;
    -c | --check )    CHECK=true; shift ;;
    -d | --download ) DOWNLOAD=true; shift ;;
    -u | --update )   UPDATE="$3"; shift; shift ;;
    -- ) shift; break ;;
    * ) break ;;
  esac
done

# VERBOSE: Display the values of the variables
if [ "$VERBOSE" = true ]; then
  echo VERBOSE=$VERBOSE
  echo START=$START
  echo CHECK=$CHECK
fi

# DOWNLOAD: Download the new code from a Git remote
if [ "$DOWNLOAD" = true ]; then
  printf "%s\n" "${red}Updating the provided source code...${end}"
  echo ""
  git pull download master
  echo ""
  printf "%s\n" "${red}...Finished updating the provided source code${end}"
  echo ""
fi

# UPDATE: Get ready for the download from a Git remote
if [ "$UPDATE" ]; then
  printf "%s\n" "${red}Getting ready to update the provided source code...${end}"
  echo ""
  git remote add download "$UPDATE"
  echo "Making a connection to $UPDATE"
  echo ""
  printf "%s\n" "${red}...Finished getting ready to update the provided source code${end}"
  echo ""
fi

# START: Initialize the git submodule and the check it out
if [ "$START" = true ]; then
  echo ""
  printf "%s\n" "${red}Getting ready to check the assignment with GatorGrader...${end}"
  echo ""
  echo "Starting to initialize the submodule..."
  git submodule update --init
  cd gatorgrader||exit
  git checkout master
  cd ..
  echo "... Finished Initializing the submodule"
  echo ""
  printf "%s\n" "${red}...Finished getting ready to check the assignment with GatorGrader${end}"
  echo ""
fi

# CHECK: Setup the python3 venv and then run the GatorGrader checks
if [ "$CHECK" = true ]; then
  # run all of the writing checks with mdl and proselint
  echo ""
  printf "%s\n" "${red}Checking the correctness of your technical writing!${end}"
  echo ""
  printf "%s\n" "${blu}Starting to run the mdl and proselint checks...${end}"
  echo ""
  mdl README.md
  determine_exit_code $? "mdl README.md"
  mdl writing/reflection.md
  determine_exit_code $? "mdl reflection.md"
  proselint writing/reflection.md
  determine_exit_code $? "proselint reflection.md"
  determine_exit_code $? "htmlhint src/www/index.html"
  htmlhint src/www/index.html
  echo ""
  printf "%s\n" "${blu}...Finished checking the correctness of your technical writing${end}"

  # run all of the checks with GatorGrader
  echo ""
  printf "%s\n" "${red}Checking the assignment with GatorGrader!${end}"
  echo ""
  printf "%s\n" "${blu}Starting to configure the GatorGrader environment ...${end}"
  # create the venv for local python3 package management
  python3 -m venv gatorgrader
  source "$PWD/gatorgrader/bin/activate"
  cd gatorgrader||exit
  echo ""
  # update pip and then install the requirements
  # NOTE: run with python3 -m due to long directory names and Linux kernel limitation
  python3 -m pip install -U pip
  python3 -m pip install -r requirements.txt
  python3 -m nltk.downloader punkt
  cd ../||exit
  echo ""
  printf "%s\n" "${blu}... Finished configuring the GatorGrader environment${end}"
  echo ""
  # run the gatorgrader.py program to run the checks
  printf "%s\n" "${blu}Starting to check with GatorGrader...${end}"
  # ADD ADDITIONAL CALLS TO BOTH gatorgrader.py and determine_exit_code HERE
  # --> GatorGrader CHECK: the existence of files in directories
  python3 gatorgrader/gatorgrader.py --directories writing . --checkfiles reflection.md README.md
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "<title>Share Your Travels</title>" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "<h1>Share Your Travels</h1>" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "<h3>Photograph Reviews</h3>" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "<b>" --fragmentcounts 5
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "<time>" --fragmentcounts 5
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "em em-" --fragmentcounts 5
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "<blockquote>" --fragmentcounts 5
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "css/site.css" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "css/emoji.css" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www \
                                     --checkfiles index.html --fragments "fonts.googleapis.com" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www/css \
                                     --checkfiles site.css --fragments "font-family: \"Montserrat\", sans;" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK:
  python3 gatorgrader/gatorgrader.py --nowelcome --directories src/www/css \
                                     --checkfiles site.css --fragments "font-family: \"Merriweather\", serif;" --fragmentcounts 1
  determine_exit_code $?
  # --> GatorGrader CHECK: the reflection contains at least 4 paragraphs with 3 sentences each
  python3 gatorgrader/gatorgrader.py --nowelcome --directories writing --checkfiles reflection.md --paragraphs 4
  determine_exit_code $?
  # --> GatorGrader CHECK: the repository contains at least five commits (update to current + 5)
  python3 gatorgrader/gatorgrader.py --nowelcome --commits 16
  determine_exit_code $?
  echo ""
  printf "%s\n" "${blu}... Finished checking with GatorGrader${end}"

  # return the exit value from running the commands
  determine_human_exit_code $GATORGRADER_EXIT
  echo ""
  printf "%s\n" "${red}Overall, are there any mistakes in the assignment? $GATORGRADER_EXIT_HUMAN_PASS ${end}"
  echo ""
  exit $GATORGRADER_EXIT
fi
