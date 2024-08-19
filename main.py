import sys
import multiprocessing
import queue

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

def main():
    if len(sys.argv) != 2:
        print("Usage: main.py <command>")
        return
    
    command = sys.argv[1]
    if command == '1':
        # Start the background process
        p = multiprocessing.Process(target=background_process, args=(command_queue,))
        p.start()
        print(f"Started background process with PID {p.pid}.")
        p.join()
    elif command == '2':
        # Ensure the background process is running
        if not multiprocessing.active_children():
            print("Background process is not running.")
            return
        
        # Send command to the background process
        command_queue.put('add 2')
        print("Command 'add 2' sent to background process.")
    elif command == 'exit':
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
