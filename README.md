# 🎯 Bingo Online Multiplayer Server

A real-time multiplayer Bingo game server built with Go and WebSockets. This server handles room creation, player matching, and game state synchronization for online Bingo games.

## ✨ Features

- **Real-time Multiplayer**: WebSocket-based communication for instant game updates
- **Room Management**: Create and join game rooms with unique codes
- **Player Matching**: Connect two players per room (creator + joiner)
- **Game Synchronization**: Real-time move updates and game state management
- **Version Compatibility**: Ensures players have compatible app versions
- **Cross-platform**: Works with any WebSocket client

## 🏗️ Architecture

```
┌─────────────────┐    WebSocket    ┌─────────────────┐
│   Player 1      │ ◄─────────────► │   Bingo Server  │
│   (Creator)     │                 │   (Go)          │
└─────────────────┘                 └─────────────────┘
                                              │
                                              │ WebSocket
                                              ▼
                                    ┌─────────────────┐
                                    │   Player 2      │
                                    │   (Joiner)      │
                                    └─────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- Go 1.19 or higher
- Git

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd bingo-server
   ```

2. **Install dependencies**
   ```bash
   go mod tidy
   ```

3. **Run the server**
   ```bash
   go run main.go
   ```

The server will start on port 9000 by default.

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT`   | `9000`  | Server port number |

## 📡 API Reference

### WebSocket Endpoint

**URL**: `ws://localhost:9000/ws`

### Message Format

All messages use JSON format with the following structure:

```json
{
  "channel": "string",
  "res": "string",
  "roomCode": "string",
  "dimension": "number",
  "isCreator": "boolean",
  "move": "number",
  "appVersion": "string"
}
```

### Channels

#### 1. Create Room
**Channel**: `create-room`

**Request**:
```json
{
  "channel": "create-room",
  "res": "PlayerName",
  "dimension": 5,
  "appVersion": "1.0.0"
}
```

**Response**:
```json
{
  "channel": "create-room",
  "res": "abc12",
  "roomCode": "abc12"
}
```

#### 2. Join Room
**Channel**: `join-room`

**Request**:
```json
{
  "channel": "join-room",
  "res": "PlayerName",
  "roomCode": "abc12",
  "appVersion": "1.0.0"
}
```

**Response** (Success):
```json
{
  "channel": "game-ready",
  "res": "CreatorName",
  "dimension": 5,
  "isCreator": false
}
```

**Response** (Error):
```json
{
  "channel": "error",
  "res": "The room code you entered is invalid"
}
```

#### 3. Game Move
**Channel**: `game-on`

**Request**:
```json
{
  "channel": "game-on",
  "roomCode": "abc12",
  "move": 25,
  "isCreator": true
}
```

**Response**:
```json
{
  "channel": "game-on",
  "move": 25
}
```

#### 4. Win Claim
**Channel**: `win-claim`

**Request**:
```json
{
  "channel": "win-claim",
  "roomCode": "abc12",
  "isCreator": true
}
```

#### 5. Retry Game
**Channel**: `retry`

**Request**:
```json
{
  "channel": "retry",
  "roomCode": "abc12"
}
```

#### 6. Exit Room
**Channel**: `exit-room`

**Request**:
```json
{
  "channel": "exit-room",
  "roomCode": "abc12"
}
```

## 🏛️ Project Structure

```
bingo-server/
├── main.go              # Main server file with WebSocket handlers
├── go.mod               # Go module dependencies
├── go.sum               # Dependency checksums
├── util/
│   └── generator.go     # Room code generation utility
└── README.md            # This file
```

## 🔧 Development

### Running in Development Mode

```bash
# Set development port
set PORT=8080

# Run with hot reload (requires air or similar tool)
go run main.go
```

### Building for Production

```bash
# Build binary
go build -o bingo-server main.go

# Run binary
./bingo-server
```

### Testing

```bash
# Run tests
go test ./...

# Run with coverage
go test -cover ./...
```

## 🌐 WebSocket Client Example

Here's a simple JavaScript client example:

```javascript
const ws = new WebSocket('ws://localhost:9000/ws');

ws.onopen = function() {
    console.log('Connected to Bingo server');
    
    // Create a room
    ws.send(JSON.stringify({
        channel: 'create-room',
        res: 'Player1',
        dimension: 5,
        appVersion: '1.0.0'
    }));
};

ws.onmessage = function(event) {
    const data = JSON.parse(event.data);
    console.log('Received:', data);
    
    switch(data.channel) {
        case 'create-room':
            console.log('Room created:', data.roomCode);
            break;
        case 'game-ready':
            console.log('Game ready!');
            break;
        case 'error':
            console.error('Error:', data.res);
            break;
    }
};

ws.onclose = function() {
    console.log('Disconnected from server');
};
```

## 🚨 Error Handling

The server handles various error scenarios:

- **Invalid Room Code**: Returns error message for non-existent rooms
- **Room Full**: Prevents joining rooms with 2 players
- **Version Mismatch**: Ensures compatible app versions
- **Connection Issues**: Graceful handling of WebSocket disconnections

## 🔒 Security Considerations

- **CORS**: Currently allows all origins (`*`) - consider restricting for production
- **Input Validation**: Basic validation of incoming messages
- **Rate Limiting**: Not implemented - consider adding for production use

## 🚀 Deployment

### Docker (Recommended)

```dockerfile
FROM golang:1.19-alpine AS builder
WORKDIR /app
COPY . .
RUN go mod download
RUN go build -o bingo-server main.go

FROM alpine:latest
RUN apk --no-cache add ca-certificates
WORKDIR /root/
COPY --from=builder /app/bingo-server .
EXPOSE 9000
CMD ["./bingo-server"]
```

### Environment Variables for Production

```bash
# Set production port
PORT=8080

# Add other production configs as needed
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 📝 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🆘 Support

If you encounter any issues or have questions:

1. Check the [Issues](../../issues) page
2. Create a new issue with detailed description
3. Include your Go version and operating system

## 🔮 Roadmap

- [ ] Add authentication system
- [ ] Implement persistent storage
- [ ] Add admin dashboard
- [ ] Support for multiple game modes
- [ ] Real-time chat functionality
- [ ] Tournament system

---

**Happy Gaming! 🎲**