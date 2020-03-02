#!/bin/bash

source /home/omar/Workspace/markenda/markenda-core.sh

dmenu_normal="rofi -dmenu -p Markenda -scroll-method 1"
dmenu_nop="rofi -dmenu -scroll-method 1"

function confirm {
    echo -e "No\nYes" | $dmenu_nop -p "Are you sure?"
}

function select_week_rofi {
    WEEK="$(gcal --blocks=12 -K | sed '/^\s*$/d' | $dmenu_nop -p 'Select week' | awk '{ if($NF < 54) print $NF}')"
    if [ ! -z "$WEEK" ]
    then 
        echo "Week $WEEK:"
        gcal -Cx"$WEEK"w -f $AGENDA
    else 
        echo "Wrong selection"
    fi
}

function start {
    generate_agendafile
    MENU=$'View TODOS\nView Notes\nCalendar\nAgenda: Show Upcoming\nAgenda: Current Week\nAgenda: Select Week\nAgenda: Current Month\nAgenda: Current Year\nEXIT'
    SEL="$(echo -e "$MENU" | $dmenu_normal)"

    case "$SEL" in
    "View TODOS")
        menu_todos
        ;;
    "View Notes")
        menu_notes
        ;;
    "Calendar")
        nice gcal --blocks=4 | tail -n +3 | sed '/^$/d'
        ;;
    "Agenda: Show Upcoming")
        show_upcoming
        ;;
    "Agenda: Current Week")
        current_week
        ;;
    "Agenda: Select Week")
        week="$(select_week_rofi)" 
        if [ "$week" == "Wrong selection" ]
        then
            TMP=$(echo "BACK" | $dmenu_nop -p "WRONG SELECTION")
        else
            echo "$week"
        fi
        ;;
    "Agenda: Current Month")
        current_month
        ;;
    "Agenda: Current Year")
        current_year
        ;;
    *)
        echo "EXIT"
        ;;
    esac
}

function menu_todos {
    TODOS="$(find $WF/TODOS | grep '.md')"
    NAMES="$(echo "$TODOS" | sed "s|$WF/TODOS/||")"
    empty=$'\n'
    if [ -z "$1" ]
    then
        SEL="$(echo -e "BACK\nCreate TODO\nOpen All TODOS HTML\n-----\n$NAMES" | $dmenu_normal)"
    else   
        SEL=$1
    fi
    case "$SEL" in
    "BACK")
    
        ;;
    "Create TODO")
        name="$($dmenu_nop -p "TODO name")"
        new_todo_file "$name"
        menu_todos
        ;;
    "Open All TODOS HTML")
        cat $(find $WF/TODOS | grep '.md') | pandoc --toc --self-contained --from=gfm --css=pandoc.css -o "$WF/todos.html"
        $TERM "lynx $WF/todos.html" && 
        menu_notes
        ;;
    *)  
        MENU=$'BACK\nOpen HTML\nAdd TODO item\nAdd Schedule\nEdit file\nDelete file\n-----\n'
        TODO="$(cat "$WF/TODOS/$SEL")"
        LINE="$(echo "$MENU$TODO" | $dmenu_normal)"
        case "$LINE" in
        "BACK")
            menu_todos
            ;;
        "Add TODO item")
            MSG="$($dmenu_nop -p "Item contents")"
            new_todo_item "$WF/TODOS/$SEL" "$MSG"
            menu_todos "$SEL"
            ;;
        "Add Schedule")
            MSG="$(echo "$TODO" | $dmenu_nop -p "Select Line")"
            if [ -z "$MSG" ]
            then
                menu_todos
                break
            else
                TAG="$(echo -e "TODO\nEVENT\nDEADLINE\n" | $dmenu_nop -p "Select or write TAG")"
                SCHEDULE="$($dmenu_nop -p "Type Date (yyyy-mm-dd[-hh:mm])")"
                schedule_item "$WF/TODOS/$SEL" "$MSG" "$SCHEDULE" "$TAG"
                menu_todos "$SEL"
            fi
            ;;
        "Open HTML")
            $TERM "pandoc --toc --self-contained -i "$WF/TODOS/$SEL" --from=gfm --to=html --css=pandoc.css | lynx -stdin"  && 
            menu_todos
            ;;
        "Edit file")
            $EDITOR "$WF/TODOS/$SEL"
            echo "EXIT"
            ;;
        "Delete file")
            ans="$(confirm)"
            if [ "$ans" == "Yes" ]
            then
                rm "$WF/TODOS/$SEL"
            fi
            menu_todos
            ;;
        *)
            toggle_todo_item "$WF/TODOS/$SEL" "$LINE"
            menu_todos "$SEL"
            ;;
        esac
        ;;
    esac
}

function menu_notes {
    NOTES="$(find $WF/NOTES | grep '.md')"
    NAMES="$(echo "$NOTES" | sed "s|$WF/NOTES/||")"
    empty=$'\n'
    if [ -z "$1" ]
    then
        SEL="$(echo -e "BACK\nCreate Note\nOpen All Notes HTML\n-----\n$NAMES" | $dmenu_normal)"
    else
        SEL="$1"
    fi
    case "$SEL" in
    "BACK")
        
        ;;
    "Create Note")
        name="$($dmenu_nop -p "Note name")"
        new_note "$name"
        menu_notes
        ;;
    "Open All Notes HTML")
        cat $(find $WF/NOTES | grep '.md') | pandoc --toc --self-contained --from=gfm --css=pandoc.css -o "$WF/notes.html"
        $TERM "lynx $WF/notes.html" && 
        menu_notes
        ;;
    *)  
        MENU=$'BACK\nAdd Schedule\nOpen HTML\nEdit file\nDelete file\n-----\n'
        NOTE="$(cat "$WF/NOTES/$SEL")"
        LINE="$(echo "$MENU$NOTE" | $dmenu_normal)"
        case "$LINE" in
        "BACK")
            menu_notes
            ;;
        "Add Schedule")
            MSG="$(echo "$NOTE" | $dmenu_nop -p "Select Line")"
            if [ -z "$MSG" ]
            then
                menu_notes
                break
            else
                TAG="$(echo -e "NOTE\nEVENT\nDEADLINE\n" | $dmenu_nop -p "Select or write TAG")"
                SCHEDULE="$($dmenu_nop -p "Type Date (yyyy-mm-dd[-hh:mm])")"
                schedule_item "$WF/NOTES/$SEL" "$MSG" "$SCHEDULE" "$TAG"
                menu_notes "$SEL"
            fi
            ;;
        "Open HTML")
            $TERM "pandoc --toc --self-contained -i "$WF/NOTES/$SEL" --from=gfm --to=html --css=pandoc.css | lynx -stdin" && 
            menu_notes
            ;;
        "Edit file")
            $EDITOR "$WF/NOTES/$SEL"
            echo "EXIT"
            ;;
        "Delete file")
            ans="$(confirm)"
            if [ "$ans" == "Yes" ]
            then
                rm "$WF/NOTES/$SEL"
            fi
            menu_notes
            ;;
        *)
            toggle_todo_item "$WF/NOTES/$SEL" "$LINE"
            menu_notes "$SEL"
            ;;
        esac
        ;;
    esac
}

while true 
do 
    OPT="$(start)"
    empty=$'\n'
    if [ ! -z "$OPT" ]
    then
        if [ "$OPT" == "EXIT" ]
        then
            exit 0
        fi
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

        fi
    fi
    
done
