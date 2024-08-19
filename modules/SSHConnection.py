import paramiko

class SSHConnection:
    def __init__(self, host, port=22, username=None, password=None, key_file=None,
                 local_forward=None, remote_forward=None):
        """
        Initialize SSHConnection with parameters for SSH and port forwarding.
        
        :param host: SSH server hostname or IP address
        :param port: SSH server port (default is 22)
        :param username: SSH username
        :param password: SSH password (optional if key_file is provided)
        :param key_file: Path to the SSH private key file (optional if password is provided)
        :param local_forward: List of tuples (local_addr, local_port, remote_addr, remote_port)
        :param remote_forward: List of tuples (remote_addr, remote_port, local_addr, local_port)
        """
        self.host = host
        self.port = port
        self.username = username
        self.password = password
        self.key_file = key_file
        self.local_forward = local_forward or []
        self.remote_forward = remote_forward or []
        self.client = paramiko.SSHClient()

    def connect(self):
        """Establish SSH connection and setup port forwarding."""
        self.client.set_missing_host_key_policy(paramiko.AutoAddPolicy())
        
        if self.key_file:
            try:
                self.client.connect(self.host, port=self.port, username=self.username, key_filename=self.key_file)
            except Exception as e:
                print(f"Failed to connect using key file: {e}")
                raise
        elif self.password:
            try:
                self.client.connect(self.host, port=self.port, username=self.username, password=self.password)
            except Exception as e:
                print(f"Failed to connect using password: {e}")
                raise
        else:
            raise ValueError("Either key_file or password must be provided")

        # Setup local port forwarding
        for local_addr, local_port, remote_addr, remote_port in self.local_forward:
            try:
                self.client.get_transport().request_port_forward(local_addr, local_port, remote_addr, remote_port)
            except Exception as e:
                print(f"Failed to setup local port forwarding {local_addr}:{local_port} -> {remote_addr}:{remote_port}: {e}")
                raise

        # Setup remote port forwarding
        for remote_addr, remote_port, local_addr, local_port in self.remote_forward:
            try:
                self.client.get_transport().request_port_forward(remote_addr, remote_port, local_addr, local_port)
            except Exception as e:
                print(f"Failed to setup remote port forwarding {remote_addr}:{remote_port} -> {local_addr}:{local_port}: {e}")
                raise

    def close(self):
        """Close the SSH connection."""
        if self.client:
            self.client.close()

    def __enter__(self):
        """Enter the runtime context related to this object."""
        self.connect()
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """Exit the runtime context related to this object."""
        self.close()

# Example usage
if __name__ == "__main__":
    local_forwards = [
        ('127.0.0.1', 8080, 'remote.example.com', 80)  # Example: forward local port 8080 to remote port 80
    ]

    remote_forwards = [
        ('remote.example.com', 3306, '127.0.0.1', 5432)  # Example: forward remote port 3306 to local port 5432
    ]

    try:
        with SSHConnection(host='example.com', username='user', password='pass',
                           local_forward=local_forwards, remote_forward=remote_forwards) as ssh:
            print("Connected and port forwarding set up!")
            # Perform your SSH operations here
    except Exception as e:
        print(f"Connection failed: {e}")
