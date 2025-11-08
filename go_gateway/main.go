package main

import (
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strconv"

	"github.com/go-redis/redis/v8"
	"github.com/gofiber/fiber/v2"
	"golang.org/x/net/context"
)

var ctx = context.Background()
var redisClient *redis.Client

// --- Job structures for Redis queues ---
type MessageJob struct {
	ApplicationToken string `json:"application_token"`
	ChatNumber       int    `json:"chat_number"`
	MessageNumber    int64  `json:"message_number"`
	Body             string `json:"body"`
}

type ChatJob struct {
	ApplicationToken string `json:"application_token"`
	ChatNumber       int64  `json:"chat_number"`
	Title            string `json:"title"`
}

func main() {
	// --- Setup Redis connection ---
	redisAddr := os.Getenv("REDIS_URL")
	if redisAddr == "" {
		redisAddr = "redis:6379"
	}

	redisClient = redis.NewClient(&redis.Options{Addr: redisAddr})
	app := fiber.New()

	// --- Routes ---
	app.Post("/applications/:token/chats", handleCreateChat)
	app.Post("/applications/:token/chats/:number/messages", handleCreateMessage)

	// --- Start server ---
	port := os.Getenv("PORT")
	if port == "" {
		port = "8081"
	}

	log.Printf("🚀 Go Gateway running on port %s", port)
	log.Fatal(app.Listen("0.0.0.0:" + port))
}

//
// ---------- CHAT CREATION ----------
//
func handleCreateChat(c *fiber.Ctx) error {
	appToken := c.Params("token")

	var body struct {
		Title string `json:"title"`
	}

    if len(c.Body()) > 0 {
        if err := c.BodyParser(&body); err != nil {
            log.Printf("[Go Gateway] Failed to parse body: %v", err)
            return c.Status(422).JSON(fiber.Map{"error": "Invalid JSON body"})
        }
    }

	// Atomic unique chat number per app
	seqKey := fmt.Sprintf("app:%s:chats_seq", appToken)
	chatNumber, err := redisClient.Incr(ctx, seqKey).Result()
	if err != nil {
		log.Printf("[Go Gateway] Redis INCR failed for chat: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate chat number"})
	}

	title := body.Title
	if title == "" {
		title = c.Query("title")
	}
	if title == "" {
		title = fmt.Sprintf("Chat #%d", chatNumber)
	}

	job := ChatJob{
		ApplicationToken: appToken,
		ChatNumber:       chatNumber,
		Title:            title,
	}

	data, _ := json.Marshal(job)
	if err := redisClient.RPush(ctx, "chats_queue", data).Err(); err != nil {
		log.Printf("[Go Gateway] Failed to push chat job: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to queue chat"})
	}

	log.Printf("[Go Gateway] Queued chat #%d for app=%s", chatNumber, appToken)

	return c.Status(202).JSON(fiber.Map{
		"number": chatNumber,
		"title": title,
	})
}

//
// ---------- MESSAGE CREATION ----------
//
func handleCreateMessage(c *fiber.Ctx) error {
	appToken := c.Params("token")
	chatNumStr := c.Params("number")

	chatNum, err := strconv.Atoi(chatNumStr)
	if err != nil {
		return c.Status(400).JSON(fiber.Map{"error": "Invalid chat number"})
	}

	var body struct {
		Body string `json:"body"`
	}
	if err := c.BodyParser(&body); err != nil || body.Body == "" {
		return c.Status(400).JSON(fiber.Map{"error": "Missing message body"})
	}

	// Atomic unique message number per chat
	seqKey := fmt.Sprintf("chat:%s:%d:messages_seq", appToken, chatNum)
	messageNumber, err := redisClient.Incr(ctx, seqKey).Result()
	if err != nil {
		log.Printf("[Go Gateway] Redis INCR failed: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to generate message number"})
	}

	job := MessageJob{
		ApplicationToken: appToken,
		ChatNumber:       chatNum,
		MessageNumber:    messageNumber,
		Body:             body.Body,
	}

	data, _ := json.Marshal(job)
	if err := redisClient.RPush(ctx, "messages_queue", data).Err(); err != nil {
		log.Printf("[Go Gateway] Failed to push message job: %v", err)
		return c.Status(500).JSON(fiber.Map{"error": "Failed to queue message"})
	}

	log.Printf("[Go Gateway] Queued message #%d for chat=%d (app=%s)", messageNumber, chatNum, appToken)

	return c.Status(202).JSON(fiber.Map{
		"number": messageNumber,
	})
}
