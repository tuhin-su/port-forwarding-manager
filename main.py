import sys
import multiprocessing
import queue
from rich import print

# Shared queue for communication
command_queue = multiprocessing.Queue()
array = []

def background_process(command_queue):
    global array
    while True:
        try:
            command = command_queue.get()  # Blocking call to wait for a command
            if command == 'exit':
                print("Background process exiting.")
                break
            elif command.startswith('add'):
                _, value = command.split()
                value = int(value)
                array.append(value)
                print(f"Added {value} to array. Current array: {array}")
        except queue.Empty:
            continue


def start():
    # Start the background process
    p = multiprocessing.Process(target=background_process, args=(command_queue,))
    p.start()
    print(f"Started background process with PID {p.pid}.")
    p.join()

def main():
    if len(sys.argv) <= 2:
        print("Usage: main.py <command>")
        return
    
    command = sys.argv[1]
    print(sys.argv)
    if command == 'start':
        start();


    elif command == 'set':
        # Ensure the background process is running
        if not multiprocessing.active_children():
            print("Background process is not running.")
            return
        
        # Send command to the background process
        command_queue.put('add 2')
        print("Command 'add 2' sent to background process.")
    
    elif command == 'stop':
        # Ensure the background process is running
        if not multiprocessing.active_children():
            print("Background process is not running.")
            return
        
        # Send exit command to background process
        command_queue.put('exit')
        print("Exit command sent to background process.")
    else:
        print("Invalid command.")

if __name__ == "__main__":
    main()
