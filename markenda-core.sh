#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -z "$1" ]
then
    WF="$1"
else
    WF="$DIR"
fi

AGENDA="$WF/agenda.gcal"
ICAL="$WF/cal.ics"


function show_upcoming {
    echo "Upcoming (up to 30 days): "
    gcal -cxdl@t30 -f $AGENDA
} 

function current_week {
    echo "Current week: "
    gcal -cxW -f $AGENDA
}

function current_month {
    echo "Current month: "
    gcal -cxM -f $AGENDA
}

function current_year {
    echo "Current year: "
    gcal -cxY -f $AGENDA
}

function rest_week {
    echo "Rest of the week: "
    gcal -cxW+ -f $AGENDA
}

function rest_month {
    echo "Rest of the month: "
    gcal -cxM+ -f $AGENDA
}

function rest_year {
    echo "Rest of the year: "
    gcal -cxY+ -f $AGENDA
}

function new_note {
    NAME="$1"
    Y="$(date +%Y)"
    M="$(date +%m)"
    D="$(date +%d)"
    TIME="$(date +%H:%M)"
    mkdir -p "$WF/NOTES/$Y$M$D"
    touch "$WF/NOTES/$Y$M$D/$NAME".md
    echo "***" >> "$WF/NOTES/$Y$M$D/$NAME".md
    echo "<!-- NOTE -->" >> "$WF/NOTES/$Y$M$D/$NAME".md
    echo "NOTE: $NAME" >> "$WF/NOTES/$Y$M$D/$NAME".md
    echo "[CREATED]: $Y-$M-$D-$TIME" >> "$WF/NOTES/$Y$M$D/$NAME".md
    echo "***" >> "$WF/NOTES/$Y$M$D/$NAME".md
}

function new_todo_file {
    NAME="$1"
    Y="$(date +%Y)"
    M="$(date +%m)"
    D="$(date +%d)"
    TIME="$(date +%H:%M)"
    mkdir -p "$WF/TODOS/$Y$M$D"
    touch "$WF/TODOS/$Y$M$D/$NAME".md
    echo "<!-- TODO -->" >> "$WF/TODOS/$Y$M$D/$NAME".md
    echo "TODO: $NAME" >> "$WF/TODOS/$Y$M$D/$NAME".md
    echo "[CREATED]: $Y-$M-$D-$TIME" >> "$WF/TODOS/$Y$M$D/$NAME".md
}

function schedule_item {
    FILE="$1"
    LINE="$2"
    SCHEDULE="$3"
    TAG="$4"

    FOUND=false
    ISSCHEDULED=false
    # Verify it does not have been scheduled already
    while IFS= read -r line || [ -n "$line" ]
    do
        if [ "$line" == "$LINE" ]  
        then 
            FOUND=true
            break
        fi            
    done < "$FILE"
    # if not schedueled, write schedule
    empty=$'\\\n'
    if [ "$FOUND" == false ]
    then
        echo -e "\n$LINE" >> "$FILE"
    fi
    LINE="$(echo "$LINE" | sed 's/^\s*.*\[/\\\[/g' | sed 's/^\s*.*\]/\\\]/g' | sed 's/^\s*.*\*/\\\*/g')"
    NEWLINE="$LINE$empty\[$TAG\]\: $SCHEDULE"
    echo "$LINE"
    echo "$NEWLINE"
    sed -i "$FILE" -e "0,/$LINE/ s/$LINE/$NEWLINE/"
}

function new_todo_item {
    FILE="$1"
    MSG="$2"
    empty=$'\n'
    echo "$empty* [ ]" "$MSG" >> $FILE
}

function toggle_todo_item {
    FILE="$1"
    LINE="$2"
    ISOFF="$(echo "$LINE" | grep "\[ \]")"
    if [ ! -z "$ISOFF" ]
    then
        # Too many escaped characters!!
        NEWLINE="$(echo "$LINE" | sed 's/^\s*.*\[ \]/\\\[x\\\]/g')"
        LINE="$(echo "$LINE" | sed 's/^\s*.*\[ \]/\\\[ \\\]/g')"
        sed -i "$FILE" -e "s/$LINE$/$NEWLINE/"
    else
        NEWLINE="$(echo "$LINE" | sed 's/^\s*.*\[x\]/\\\[ \\\]/g')"
        LINE="$(echo "$LINE" | sed 's/^\s*.*\[x\]/\\\[x\\\]/g')"
        sed -i "$FILE" -e "s/$LINE$/$NEWLINE/"
    fi
}

function ical_entry {
    sum=$1
    des=$2
    dateS=$3
    timeS="$(echo $4 | sed 's/://')"
    loc="Earth"
    if [ -z "$timeS" ]
    then
        ENTRY="\nBEGIN:VEVENT\nLOCATION:"$loc"\nSUMMARY:"$sum"\nDESCRIPTION:"$des"\nDTSTART;TZID=$(date +%Z):"$dateS"\nUID:$(date +%s-$RANDOM)\nEND:VEVENT\n"
    else
        ENTRY="\nBEGIN:VEVENT\nLOCATION:"$loc"\nSUMMARY:"$sum"\nDESCRIPTION:"$des"\nDTSTART;TZID=$(date +%Z):"$dateS"T"$timeS"00\nUID:$(date +%s-$RANDOM)\nEND:VEVENT\n"
    fi
    echo -e "$ENTRY"
}

function generate_agendafile {
    echo "" > "$AGENDA"NEW
    echo "BEGIN:VCALENDAR" > "$ICAL"
    mkdir -p "$WF/TODOS"
    mkdir -p "$WF/NOTES"
    MDS="$(find $WF | grep '.md')"

    for md in $MDS
    do
        prev_line=""
        NAME="$(echo $md | sed "s|$WF/||")"
        while IFS= read -r line || [ -n "$line" ]
        do
            SCHEDULE="$(echo "$line" | grep "\[.*\]:" | cut -d' ' -f 2 | sed 's/-//g')"
            DATE="${SCHEDULE:0:8}"
            TIME="${SCHEDULE:8}"
            echo "$line" >> $HOME/l.log
            if [ ! -z $TIME ] ; 
            then 
                TIME=" $TIME"
            fi
            TAG="$(echo "$line" | grep "\[.*\]:" | cut -d' ' -f 1 | sed 's/\[\|\]\|://g')"
            if [ ! -z "$SCHEDULE" ] && [ "$line" != "$prev_line" ] && [ ! "$NAME" == "todos.md" ] && [ ! "$NAME" == "notes.md" ]
            then
                echo "; $NAME" >> "$AGENDA"NEW
                echo "$DATE" "[$TAG$TIME]" "$prev_line" >> "$AGENDA"NEW
                ical_entry "[${TAG}] ${prev_line}" "File: $WF/$NAME" "$DATE" "$TIME" >> $ICAL
            fi

            prev_line=$line
        done < $md
    done
    mv "$AGENDA"NEW "$AGENDA"
    echo "END:VCALENDAR" >> "$ICAL"

}
