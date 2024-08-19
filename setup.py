import platform

def detect_os():
    os_name = platform.system()
    
    if os_name == 'Linux':
        return 'Linux'
    elif os_name == 'Windows':
        return 'Windows'
    else:
        return 'Unknown OS'

if __name__ == "__main__":
    detected_os = detect_os()
    print(f"Detected OS: {detected_os}")
