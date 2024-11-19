{ writeShellScriptBin }:
writeShellScriptBin "rm-task.sh" ''
  # File that stores the JSON data
  json_file="todo.json"
  
  # Check if the JSON file exists
  if [ ! -f "$json_file" ]; then
    echo "Error: JSON file '$json_file' not found!"
    exit 1
  fi
  
  # Function to list tasks marked as "todo"
  list_todo_tasks() {
    echo "Available tasks marked as 'todo':"
    jq -r '.tasks[] | select(.status == "todo") | "\(.id) - \(.description)"' "$json_file"
  }
  
  # Function to mark a task as "done"
  mark_task_done() {
    local task_id="$1"
    
    # Check if the task ID is valid and exists
    if jq --argjson id "$task_id" '.tasks[] | select(.id == $id and .status == "todo")' "$json_file" > /dev/null; then
      # Update the task status to "done"
      jq --argjson id "$task_id" \
        '(.tasks[] | select(.id == $id)).status = "done"' \
        "$json_file" > tmp.json && mv tmp.json "$json_file"
      
      echo "Task ID $task_id has been marked as done."
    else
      echo "Error: Task ID $task_id is not valid or is not marked as 'todo'."
    fi
  }
  
  # List tasks and prompt user for a task to mark as done
  while true; do
    list_todo_tasks
    read -p "Enter the ID of the task to mark as done (or type 'exit' to quit): " task_id
  
    # Exit if the user types "exit"
    if [[ "$task_id" == "exit" ]]; then
      echo "Exiting."
      break
    fi
  
    # Check if the input is a valid number
    if [[ "$task_id" =~ ^[0-9]+$ ]]; then
      # Attempt to mark the task as done
      mark_task_done "$task_id"
    else
      echo "Invalid input! Please enter a valid task ID number."
    fi
  done
''
