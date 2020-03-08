#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ ! -z "$1" ]
then
    WF="$1"
else
    WF="$DIR"
fi

source $DIR/markenda-core.sh "$WF"

# dmenu_normal="$DIR/pmenu -p Markenda>"
# dmenu_nop="$DIR/pmenu"
dmenu_normal="vis-menu -i -l $(expr $(tput lines) - 1) -p Markenda>"
dmenu_nop="vis-menu -i -l $(expr $(tput lines) - 1)"
EDITOR="nvim "
BROWSER="lynx "


function confirm {
    echo -e "No\nYes" | $dmenu_nop -p "Are you sure?> "
}

function select_week_rofi {
    week="$(gcal --blocks=12 -K | sed '/^\s*$/d' | $dmenu_nop -p 'Select week> ' | awk '{ if($NF < 54) print $NF}')"
    if [ ! -z "$week" ]
    then 
        echo "Week $week:"
        gcal -Cx"$week"w -f $AGENDA
    else 
        echo "Wrong selection"
    fi
}

function start {
    generate_agendafile &
    MENU=$'View TODOS\nView Notes\nCalendar\nAgenda: Show Upcoming\nAgenda: Current Week\nAgenda: Select Week\nAgenda: Current Month\nAgenda: Current Year\nEXIT'
    OPT="$(echo -e "$MENU" | $dmenu_normal)"    
    INFILE=false
}

function menu_todos {
    TODOS="$(find $WF/TODOS | grep '.md')"
    NAMES="$(echo "$TODOS" | sed "s|$WF/TODOS/||")"
    empty=$'\n'
    
    if [ -z "$1" ] && [ "$INFILE" == false ]
    then
        SEL="$(echo -e "BACK\nCreate TODO\nOpen All TODOS HTML\n-----\n$NAMES" | $dmenu_normal)"
    fi
    case "$SEL" in
    "BACK")
        OPT="start"
        ;;
    "Create TODO")
        name="$(echo "" | $dmenu_nop -p "TODO name> ")"
        new_todo_file "$name"
        OPT="View TODOS"
        ;;
    "Open All TODOS HTML")
        cat $(find "$WF/TODOS" | grep '.md' | sort) | pandoc --toc --self-contained --from=gfm --to=html --css=pandoc.css -o "$WF/todos.html"
        $BROWSER"$WF/todos.html" && 
        # cat $(find "$WF/TODOS" | grep '.md' | sort) > "$WF/todos.md"
        # $BROWSER"$WF/todos.md" && 
        OPT="View TODOS"
       ;;
    *)  
        MENU=$'BACK\nOpen HTML\nAdd TODO item\nAdd Schedule\nEdit file\nDelete file\n-----\n'
        TODO="$(cat "$WF/TODOS/$SEL")"
        LINE="$(echo "$MENU$TODO" | $dmenu_normal)"
        INFILE=true
        case "$LINE" in
        "BACK")
            OPT="View TODOS"
            INFILE=false
           ;;
        "Add TODO item")
            MSG="$(echo "" | $dmenu_nop -p "Item contents> ")"
            new_todo_item "$WF/TODOS/$SEL" "$MSG"
            OPT="View TODOS" #"$SEL"
            ;;
        "Add Schedule")
            MSG="$(echo "$TODO" | $dmenu_nop -p "Select Line> ")"
            if [ -z "$MSG" ]
            then
                OPT="View TODOS"
               break
            else
                TAG="$(echo -e "TODO\nEVENT\nDEADLINE\n" | $dmenu_nop -p "Select or write TAG> ")"
                SCHEDULE="$(echo "" | $dmenu_nop -p "Type Date (yyyy-mm-dd[-hh:mm])> ")"
                schedule_item "$WF/TODOS/$SEL" "$MSG" "$SCHEDULE" "$TAG"
                OPT="View TODOS" #"$SEL"
            fi
            ;;
        "Open HTML")
            pandoc -i "$WF/TODOS/$SEL" --toc --self-contained --from=gfm --css=pandoc.css -o "$WF/TODOS/${SEL:0:-3}.html"
            $BROWSER"$WF/TODOS/${SEL:0:-3}.html" && 
            # $BROWSER"$WF/TODOS/${SEL}" && 
            OPT="View TODOS"
           ;;
        "Edit file")
            $EDITOR "$WF/TODOS/$SEL"
            OPT="View TODOS"
            ;;
        "Delete file")
            ans="$(confirm)"
            if [ "$ans" == "Yes" ]
            then
                rm "$WF/TODOS/$SEL"
            fi
            OPT="View TODOS"
           ;;
        *)
            toggle_todo_item "$WF/TODOS/$SEL" "$LINE"
            OPT="View TODOS" #"$SEL"
            ;;
        esac
        ;;
    esac
}

function menu_notes {
    NOTES="$(find $WF/NOTES | grep '.md')"
    NAMES="$(echo "$NOTES" | sed "s|$WF/NOTES/||")"
    empty=$'\n'
    if [ -z "$1" ] && [ "$INFILE" == false ]
    then
        SEL="$(echo -e "BACK\nCreate Note\nOpen All Notes HTML\n-----\n$NAMES" | $dmenu_normal)"
    fi
    case "$SEL" in
    "BACK")
        OPT="start"
        ;;
    "Create Note")
        name="$(echo "" | $dmenu_nop -p "Note name> ")"
        new_note "$name"
        OPT="View Notes"
        ;;
    "Open All Notes HTML")
        cat $(find $WF/NOTES | grep '.md' | sort) | pandoc --toc --self-contained --from=gfm --css=pandoc.css -o "$WF/notes.html"
        $BROWSER"$WF/notes.html" && 
        # cat $(find "$WF/NOTES" | grep '.md' | sort) > "$WF/notes.md"
        # $BROWSER"$WF/notes.md" && 
        OPT="View Notes"

        ;;
    *)  
        MENU=$'BACK\nAdd Schedule\nOpen HTML\nEdit file\nDelete file\n-----\n'
        NOTE="$(cat "$WF/NOTES/$SEL")"
        LINE="$(echo "$MENU$NOTE" | $dmenu_normal)"
        INFILE=true
        case "$LINE" in
        "BACK")
            OPT="View Notes"
            INFILE=false
            ;;
        "Add Schedule")
            MSG="$(echo "$NOTE" | $dmenu_nop -p "Select Line> ")"
            if [ -z "$MSG" ]
            then
                OPT="View Notes"

                break
            else
                TAG="$(echo -e "NOTE\nEVENT\nDEADLINE\n" | $dmenu_nop -p "Select or write TAG> ")"
                SCHEDULE="$(echo "" | $dmenu_nop -p "Type Date (yyyy-mm-dd[-hh:mm])> ")"
                schedule_item "$WF/NOTES/$SEL" "$MSG" "$SCHEDULE" "$TAG"
                OPT="View Notes" #"$SEL"
            fi
            ;;
        "Open HTML")
            pandoc -i "$WF/NOTES/$SEL" --toc --self-contained --from=gfm --css=pandoc.css -o "$WF/NOTES/${SEL:0:-3}.html"
            $BROWSER"$WF/NOTES/${SEL:0:-3}.html" && 
            # $BROWSER"$WF/NOTES/${SEL}" && 
            OPT="View Notes"

            ;;
        "Edit file")
            $EDITOR "$WF/NOTES/$SEL"
            OPT="View Notes"
            ;;
        "Delete file")
            ans="$(confirm)"
            if [ "$ans" == "Yes" ]
            then
                rm "$WF/NOTES/$SEL"
            fi
            OPT="View Notes"

            ;;
        *)
            toggle_todo_item "$WF/NOTES/$SEL" "$LINE"
            OPT="View Notes" #"$SEL"
            ;;
        esac
        ;;
    esac
}


start
empty=$'\n'
if [ ! -z "$OPT" ]
then
    while true
    do
        WEEK=""
        case "$OPT" in
        "start")
            start
            ;;
        "EXIT")
            clear
            exit 0
            ;;
        "View TODOS")
            menu_todos
            ;;
        "View Notes")
            menu_notes
            ;;
        "Calendar")
            OPT="$(nice gcal --blocks=4 | tail -n +3 | sed '/^$/d')"
            ;;
        "Agenda: Show Upcoming")
            OPT="$(show_upcoming)"
            ;;
        "Agenda: Current Week")
            OPT="$(current_week)"
            ;;
        "Agenda: Select Week")
            OPT="$(select_week_rofi)" 
            if [ "$WEEK" == "Wrong selection" ]
            then
                TMP=$(echo "BACK" | $dmenu_nop -p "WRONG SELECTION")
            fi
            ;;
        "Agenda: Current Month")
            OPT="$(current_month)"
            ;;
        "Agenda: Current Year")
            OPT="$(current_year)"
            ;;
        *)
            LINE="$(echo "BACK$empty$OPT" | $dmenu_normal)"
            if [ ! -z "$LINE" ] && [ ! "$LINE" == "BACK" ]
            then
                DATE="$(echo "$LINE" | cut -d: -f 1 | cut -d, -f 2)"
                MSG="$(echo "$LINE" | cut -d: -f 2-)"
                DATE="$(echo "$DATE" | sed 's/<\|>/ /g' | sed 's/st\|th\|rd\|nd//')"
                DATE="$(date -d "$DATE" +%Y%m%d)"
                prev_line=""
                while IFS= read -r line || [ -n "$line" ]
                do
                    if [ "$line" == "$DATE$MSG" ] && [ "$line" != "$prev_line" ]
                    then
                        todo="$(echo ${prev_line:2} | grep 'TODOS')"
                        if [ ! -z "$todo" ]
                        then    
                            NAME="$(echo "${prev_line:2}" | sed "s|TODOS/||")"
                            menu_todos "$NAME"
                        else
                            NAME="$(echo "${prev_line:2}" | sed "s|NOTES/||")"
                            menu_notes "$NAME"
                        fi
                    fi
                    prev_line=$line
                done < "$AGENDA"
            elif [ "$LINE" == "BACK" ]
            then
                OPT="start"
            fi
            ;;
        esac
    done
fi  
