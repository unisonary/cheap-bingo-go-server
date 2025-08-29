package main

import (
	"encoding/json"
	"fmt"
	"log"
	"net/http"
	"os"
	"time"
	"util/util"

	"github.com/gorilla/websocket"
)

type RoomResponse struct {
	Channel    string `json:"channel"`
	Res        string `json:"res" default:""`
	RoomCode   string `json:"roomCode" default:""`
	Dimension  int    `json:"dimension" default:"0"`
	IsCreator  bool   `json:"isCreator" default:"false"`
	Move       int    `json:"move" default:"0"`
	AppVersion string `json:"appVersion" default:""`
}

type Player struct {
	Name   string `default:""`
	Socket *websocket.Conn
}
type Room struct {
	Creator    Player
	Joiner     Player
	Dimension  int
	AppVersion string
}

var rooms = make(map[string]Room)

func createRoom(roomCode string, creator Player, dimension int, appVersion string) {
	rooms[roomCode] = Room{Creator: creator, Dimension: dimension, AppVersion: appVersion}
}
func joinRoom(roomCode string, joiner Player) {
	if entry, ok := rooms[roomCode]; ok {
		entry.Joiner = joiner
		rooms[roomCode] = entry
	}
}
func getRoom(roomCode string) (Room, bool) {
	if _, ok := rooms[roomCode]; ok {
		return rooms[roomCode], false
	}
	return Room{}, true
}

var upgrader = websocket.Upgrader{}

func homePage(w http.ResponseWriter, r *http.Request) {
	fmt.Fprintf(w, "Home Page")
	// http.ServeFile(w, r, "./public")
}
func reader(conn *websocket.Conn) {
	if conn == nil {
		log.Println("Error: nil connection passed to reader")
		return
	}

	for {
		messageType, p, err := conn.ReadMessage()
		if err != nil {
			log.Println("WebSocket read error:", err)
			return
		}

		var data RoomResponse
		if err := json.Unmarshal([]byte(p), &data); err != nil {
			log.Println("JSON unmarshal error:", err)
			continue
		}

		switch data.Channel {
		case "create-room":
			fmt.Println("Creating room...")
			roomCode := util.GenerateRoomCode(5)

			createRoom(roomCode, Player{Name: data.Res, Socket: conn}, data.Dimension, data.AppVersion)

			msg, err := json.Marshal(&RoomResponse{Channel: "create-room", Res: roomCode, RoomCode: roomCode})
			if err != nil {
				log.Println("JSON marshal error:", err)
				continue
			}
			if err := conn.WriteMessage(messageType, msg); err != nil {
				log.Println("WebSocket write error:", err)
				return
			}

		case "join-room":
			fmt.Println("Creating room...")
			room, error := getRoom(data.RoomCode)
			if error {
				msgToJoiner, err := json.Marshal(&RoomResponse{Channel: "error", Res: "The room code you entered is invalid"})
				if err != nil {
					log.Println("JSON marshal error:", err)
					continue
				}
				if err := conn.WriteMessage(messageType, msgToJoiner); err != nil {
					log.Println("WebSocket write error:", err)
					return
				}
			} else {
				if room.AppVersion == data.AppVersion {
					if room.Joiner.Name == "" {
						joinRoom(data.RoomCode, Player{Name: data.Res, Socket: conn})

						msgToJoiner, err := json.Marshal(&RoomResponse{Channel: "game-ready", Res: room.Creator.Name, Dimension: room.Dimension, IsCreator: false})
						if err != nil {
							log.Println("JSON marshal error:", err)
							continue
						}
						if err := conn.WriteMessage(messageType, msgToJoiner); err != nil {
							log.Println("WebSocket write error:", err)
							return
						}

						msgToCreator, err := json.Marshal(&RoomResponse{Channel: "game-ready", Res: data.Res, IsCreator: true})
						if err != nil {
							log.Println("JSON marshal error:", err)
							continue
						}
						if err := room.Creator.Socket.WriteMessage(messageType, msgToCreator); err != nil {
							log.Println("WebSocket write error to creator:", err)
						}
					} else {
						msgToJoiner, err := json.Marshal(&RoomResponse{Channel: "error", Res: "Room is already full"})
						if err != nil {
							log.Println("JSON marshal error:", err)
							continue
						}
						if err := conn.WriteMessage(messageType, msgToJoiner); err != nil {
							log.Println("WebSocket write error:", err)
							return
						}
					}
				} else {
					msgToJoiner, err := json.Marshal(&RoomResponse{Channel: "error", Res: "Room creator has a different version of Bingo. Please make sure both have the latest version."})
					if err != nil {
						log.Println("JSON marshal error:", err)
						continue
					}
					if err := conn.WriteMessage(messageType, msgToJoiner); err != nil {
						log.Println("WebSocket write error:", err)
						return
					}
				}
			}

			fmt.Println("Game is ready")

		case "game-on":
			room, _ := getRoom(data.RoomCode)
			msg, _ := json.Marshal(&RoomResponse{Channel: "game-on", Move: data.Move})
			if data.IsCreator {
				room.Creator.Socket.WriteMessage(messageType, msg)
			} else {
				room.Joiner.Socket.WriteMessage(messageType, msg)
			}

		case "win-claim":
			room, _ := getRoom(data.RoomCode)
			msg, _ := json.Marshal(&RoomResponse{Channel: "win-claim"})
			if data.IsCreator {
				room.Creator.Socket.WriteMessage(messageType, msg)
			} else {
				room.Joiner.Socket.WriteMessage(messageType, msg)
			}

		case "retry":
			room, _ := getRoom(data.RoomCode)
			msg, _ := json.Marshal(&RoomResponse{Channel: "retry"})
			if data.IsCreator {
				room.Creator.Socket.WriteMessage(messageType, msg)
			} else {
				room.Joiner.Socket.WriteMessage(messageType, msg)
			}

		case "exit-room":
			room, _ := getRoom(data.RoomCode)
			delete(rooms, data.RoomCode)
			msg, _ := json.Marshal(&RoomResponse{Channel: "exit-room"})
			if data.IsCreator {
				room.Creator.Socket.WriteMessage(messageType, msg)
			} else {
				room.Joiner.Socket.WriteMessage(messageType, msg)
			}

		default:
			fmt.Println("Channel not implemented")
		}
	}
}
func wsEndpoint(w http.ResponseWriter, r *http.Request) {
	ws, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade failed:", err)
		return
	}
	log.Println("Client Connected")
	defer ws.Close()
	reader(ws)
}

func setupRoutes() {
	http.HandleFunc("/", homePage)
	http.HandleFunc("/ws", wsEndpoint)
	http.HandleFunc("/health", healthCheck)
}

func healthCheck(w http.ResponseWriter, r *http.Request) {
	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(http.StatusOK)
	json.NewEncoder(w).Encode(map[string]string{
		"status":    "healthy",
		"service":   "bingo-server",
		"timestamp": time.Now().Format(time.RFC3339),
	})
}

func main() {
	upgrader = websocket.Upgrader{
		CheckOrigin: func(r *http.Request) bool {
			return true
		},
		EnableCompression: true,
		ReadBufferSize:    1024,
		WriteBufferSize:   1024,
	}

	setupRoutes()
	port := os.Getenv("PORT")
	if port == "" {
		port = "9000"
	}
	corsHandler := func(next http.Handler) http.Handler {
		return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
			// Handle preflight requests
			if r.Method == "OPTIONS" {
				w.Header().Set("Access-Control-Allow-Origin", "*")
				w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
				w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization")
				w.Header().Set("Access-Control-Max-Age", "86400")
				w.WriteHeader(http.StatusOK)
				return
			}

			w.Header().Set("Access-Control-Allow-Origin", "*")
			w.Header().Set("Access-Control-Allow-Headers", "Origin, X-Requested-With, Content-Type, Accept, Authorization")
			w.Header().Set("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
			next.ServeHTTP(w, r)
		})
	}
	log.Fatal(http.ListenAndServe(":"+port, corsHandler(http.DefaultServeMux)))
	fmt.Println("Server listening on port " + port + " >:)")
}
