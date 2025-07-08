#!/bin/bash
# rtorrent-manager.sh - Manage rtorrent for user with /bin/false shell

TMUX_SESSION="rtorrent"
RTORRENT_USER="rtorrent"
RTORRENT_HOME="/home/rtorrent"
RTORRENT_CONFIG="$RTORRENT_HOME/.rtorrent.rc"
RTORRENT_WORKDIR="/srv/rtorrent"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
  echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
  echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
  echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
  echo -e "${BLUE}[DEBUG]${NC} $1"
}

# Function to check if tmux session exists
session_exists() {
  sudo -u "$RTORRENT_USER" tmux has-session -t "$TMUX_SESSION" 2>/dev/null
}

# Function to check if rtorrent process is running
rtorrent_running() {
  pgrep -u "$RTORRENT_USER" rtorrent >/dev/null
}

# Function to start rtorrent
start_rtorrent() {
  if session_exists; then
    print_warning "rtorrent tmux session already exists."
    status_rtorrent
    return 1
  fi

  if rtorrent_running; then
    print_warning "rtorrent process is already running but not in expected tmux session."
    print_info "You may need to kill the process manually: sudo pkill -u $RTORRENT_USER rtorrent"
    return 1
  fi

  print_status "Starting rtorrent in tmux session '$TMUX_SESSION'..."

  # Start tmux session as rtorrent user (bypassing shell restriction)
  sudo -u "$RTORRENT_USER" tmux new-session -d -s "$TMUX_SESSION" -c "$RTORRENT_WORKDIR" /bin/bash

  # Send rtorrent command to the session
  sudo -u "$RTORRENT_USER" tmux send-keys -t "$TMUX_SESSION" "cd $RTORRENT_WORKDIR" Enter
  sudo -u "$RTORRENT_USER" tmux send-keys -t "$TMUX_SESSION" "HOME=$RTORRENT_HOME rtorrent" Enter

  # Wait a moment and check if it started
  sleep 2
  if session_exists && rtorrent_running; then
    print_status "rtorrent started successfully in tmux session '$TMUX_SESSION'"
    print_info "To attach: $0 attach"
    print_info "To detach when attached: Ctrl+b then d"
    return 0
  else
    print_error "Failed to start rtorrent. Check logs with: $0 logs"
    return 1
  fi
}

# Function to stop rtorrent
stop_rtorrent() {
  if ! session_exists && ! rtorrent_running; then
    print_warning "rtorrent is not running."
    return 0
  fi

  print_status "Stopping rtorrent..."

  # Try graceful shutdown first
  if session_exists; then
    print_info "Sending quit command to rtorrent..."
    sudo -u "$RTORRENT_USER" tmux send-keys -t "$TMUX_SESSION" "C-q"

    # Wait for graceful shutdown
    for i in {1..10}; do
      if ! rtorrent_running; then
        print_status "rtorrent stopped gracefully."
        break
      fi
      sleep 1
    done
  fi

  # Force kill if still running
  if rtorrent_running; then
    print_warning "Forcing rtorrent to stop..."
    sudo pkill -u "$RTORRENT_USER" rtorrent
    sleep 2
  fi

  # Clean up tmux session
  if session_exists; then
    sudo -u "$RTORRENT_USER" tmux kill-session -t "$TMUX_SESSION" 2>/dev/null
  fi

  if ! rtorrent_running; then
    print_status "rtorrent stopped."
    return 0
  else
    print_error "Failed to stop rtorrent completely."
    return 1
  fi
}

# Function to show detailed status
status_rtorrent() {
  echo -e "${BLUE}=== rTorrent Status ===${NC}"

  if session_exists; then
    echo -e "Tmux session: ${GREEN}EXISTS${NC}"
    sudo -u "$RTORRENT_USER" tmux list-sessions | grep "$TMUX_SESSION"
  else
    echo -e "Tmux session: ${RED}NOT FOUND${NC}"
  fi

  if rtorrent_running; then
    echo -e "Process status: ${GREEN}RUNNING${NC}"
    echo "Process info:"
    ps aux | grep -E "(rtorrent|tmux)" | grep "$RTORRENT_USER" | grep -v grep
  else
    echo -e "Process status: ${RED}NOT RUNNING${NC}"
  fi

  # Check directories
  echo -e "\n${BLUE}=== Directory Status ===${NC}"
  for dir in "$RTORRENT_HOME" "$RTORRENT_WORKDIR" "$RTORRENT_WORKDIR/downloads" "$RTORRENT_WORKDIR/session"; do
    if [ -d "$dir" ]; then
      echo -e "$dir: ${GREEN}EXISTS${NC} ($(ls -la "$dir" 2>/dev/null | wc -l) items)"
    else
      echo -e "$dir: ${RED}MISSING${NC}"
    fi
  done

  # Check config file
  if [ -f "$RTORRENT_CONFIG" ]; then
    echo -e "Config file: ${GREEN}EXISTS${NC} ($RTORRENT_CONFIG)"
  else
    echo -e "Config file: ${RED}MISSING${NC} ($RTORRENT_CONFIG)"
  fi
}

# Function to attach to session
attach_rtorrent() {
  if ! session_exists; then
    print_error "rtorrent tmux session does not exist. Start it first with: $0 start"
    return 1
  fi

  print_info "Attaching to rtorrent tmux session..."
  print_info "To detach: Ctrl+b then d"
  print_info "To quit rtorrent: Ctrl+q"
  echo
  sudo -u "$RTORRENT_USER" tmux attach-session -t "$TMUX_SESSION"
}

# Function to show logs (tmux capture)
show_logs() {
  if ! session_exists; then
    print_error "rtorrent tmux session does not exist."
    return 1
  fi

  print_info "Capturing tmux session output..."
  sudo -u "$RTORRENT_USER" tmux capture-pane -t "$TMUX_SESSION" -p
}

# Function to send command to rtorrent
send_command() {
  if ! session_exists; then
    print_error "rtorrent tmux session does not exist."
    return 1
  fi

  if [ -z "$2" ]; then
    print_error "No command provided. Usage: $0 send 'command'"
    return 1
  fi

  print_info "Sending command to rtorrent: $2"
  sudo -u "$RTORRENT_USER" tmux send-keys -t "$TMUX_SESSION" "$2" Enter
}

# Function to setup directories and permissions
setup_directories() {
  print_status "Setting up directories for rtorrent..."

  # Create directories
  for dir in "$RTORRENT_HOME" "$RTORRENT_WORKDIR" "$RTORRENT_WORKDIR/downloads" "$RTORRENT_WORKDIR/logs" "$RTORRENT_WORKDIR/session" "$RTORRENT_WORKDIR/watch/load" "$RTORRENT_WORKDIR/watch/start"; do
    if [ ! -d "$dir" ]; then
      sudo mkdir -p "$dir"
      print_info "Created directory: $dir"
    fi
  done

  # Set ownership
  sudo chown -R "$RTORRENT_USER:$RTORRENT_USER" "$RTORRENT_HOME" "$RTORRENT_WORKDIR"
  sudo chmod -R 755 "$RTORRENT_WORKDIR"

  print_status "Directory setup complete."
}

# Function to show help
show_help() {
  echo -e "${BLUE}rTorrent Manager - For user with /bin/false shell${NC}"
  echo
  echo "Usage: $0 {start|stop|restart|status|attach|logs|send|setup|help}"
  echo
  echo "Commands:"
  echo "  start      - Start rtorrent in tmux session"
  echo "  stop       - Stop rtorrent and kill tmux session"
  echo "  restart    - Stop and start rtorrent"
  echo "  status     - Show detailed rtorrent status"
  echo "  attach     - Attach to rtorrent tmux session"
  echo "  logs       - Show current tmux session output"
  echo "  send 'cmd' - Send command to rtorrent session"
  echo "  setup      - Create directories and set permissions"
  echo "  help       - Show this help message"
  echo
  echo "Examples:"
  echo "  $0 start                    # Start rtorrent"
  echo "  $0 attach                   # Attach to rtorrent interface"
  echo "  $0 send 'Ctrl+s'          # Send Ctrl+s to rtorrent"
  echo "  $0 logs                     # View current output"
  echo
  echo "User: $RTORRENT_USER (shell: /bin/false)"
  echo "Session: $TMUX_SESSION"
  echo "Working directory: $RTORRENT_WORKDIR"
}

# Main script logic
case "$1" in
start)
  start_rtorrent
  ;;
stop)
  stop_rtorrent
  ;;
restart)
  stop_rtorrent
  sleep 2
  start_rtorrent
  ;;
status)
  status_rtorrent
  ;;
attach)
  attach_rtorrent
  ;;
logs)
  show_logs
  ;;
send)
  send_command "$@"
  ;;
setup)
  setup_directories
  ;;
help)
  show_help
  ;;
*)
  show_help
  exit 1
  ;;
esac
