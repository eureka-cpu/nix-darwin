{
  description = "eureka-cpu's nix-darwin config";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nix-darwin = {
      url = "github:LnL7/nix-darwin";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-utils.url = "github:numtide/flake-utils";
    nix-watch = {
      url = "github:Cloud-Scythe-Labs/nix-watch";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nix-darwin, nixpkgs, flake-utils, nix-watch }:
    with flake-utils.lib;
    eachSystem
      (with system; [
        aarch64-darwin
        x86_64-darwin
      ])
      (system:
        let
          host-name = "yabai";
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (pkgs) lib;

          configuration = import ./configuration.nix {
            inherit system pkgs lib;
            rev = self.rev or self.dirtyRev or null;
          };
          todo =
            let
              todo_json = pkgs.writeTextFile rec {
                name = "todo.json";
                text = builtins.readFile ./${name};
              };
              items = pkgs.runCommand "get-items" {
                buildInputs = with pkgs; [ jq ];
              } ''
                mkdir -p $out

                # File that stores the JSON data
                json_file="${todo_json}"
                
                # Check if the JSON file exists
                if [ ! -f "$json_file" ]; then
                  exit 0
                fi
                
                # Function to list tasks marked as "todo"
                list_todo_tasks() {
                  echo "The following items still need attention:"
                  jq -r '.tasks[] | select(.status == "todo") | "\(.id) - \(.description)"' "$json_file"
                }
                
                # Show the list of "todo" tasks
                list_todo_tasks > $out/items.json
              '';
            in
            builtins.trace "${builtins.readFile "${items}/items.json"}" ''
              echo "Welcome back, $(whoami)."

              # File to store the JSON data
              json_file="todo.json"
              
              # Initialize JSON file if it does not exist
              if [ ! -f "$json_file" ]; then
                echo '{"tasks": [], "next_id": 1}' > "$json_file"
              fi
              
              # Function to add a task
              add_task() {
                local description="$1"
                local status
              
                # Loop until a valid status is entered
                while true; do
                  read -p "Enter status (done/todo): " status
                  if [[ "$status" == "done" || "$status" == "todo" ]]; then
                    break  # Exit the loop if input is valid
                  else
                    echo "Invalid status! Please enter 'done' or 'todo'."
                  fi
                done
              
                # Get the next available task ID from the JSON file
                next_id=$(jq '.next_id' "$json_file")
              
                # Add the new task to the JSON file using jq
                jq --arg desc "$description" --arg status "$status" --argjson id "$next_id" \
                  '.tasks += [{"id": $id, "description": $desc, "status": $status}] | .next_id += 1' \
                  "$json_file" > tmp.json && mv tmp.json "$json_file"
              
                echo "Task '$description' with status '$status' has been added with ID $next_id."
              }
              
              # Main loop to get multiple tasks
              while true; do
                read -p "Enter task description (or type 'exit' to finish): " description
              
                # Check if the user wants to exit the input loop
                if [[ "$description" == "exit" ]]; then
                  echo "Exiting task input."
                  break
                fi
              
                # Add the task using the add_task function
                add_task "$description"
              done
            '';
        in
        {
          inherit todo;

          # Rebuild darwin flake using:
          # $ darwin-rebuild switch --flake .#${system}.${host-name}
          darwinConfigurations.${host-name} = nix-darwin.lib.darwinSystem {
            modules = [ configuration ];
          };

          # Expose the package set, including overlays, for convenience.
          darwinPackages = self.darwinConfigurations.${host-name}.pkgs;

          devShells.default = pkgs.mkShell {
            buildInputs = with pkgs; [
              nil
              nixpkgs-fmt
              (callPackage ./todo.nix { })
            ] ++ nix-watch.nix-watch.${system}.devTools;
            shellHook = todo;
          };

          formatter = pkgs.nixpkgs-fmt;
        });
}
