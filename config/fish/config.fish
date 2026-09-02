 if status is-interactive

# Commands to run in interactive sessions can go here
   set fish_greeting 
end

# Terminal text colors (force-applied every session)
set -g fish_color_normal white
set -g fish_color_command white
set -g fish_color_param white
set -g fish_color_error white
set -g fish_color_autosuggestion 555555

starship init fish | source

# Pi
fish_add_path "/home/larp/.local/share/pi-node/node-v22.22.3-linux-x64/bin"
