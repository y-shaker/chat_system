# 🗨️ Chat System – Scalable Async Messaging Platform

A high-performance chat application built with **Ruby on Rails**, **Go**, **Redis**, **MySQL**, and **Sidekiq** — designed for concurrency, scalability, and eventual consistency.  

This project demonstrates a distributed architecture where **Rails handles persistence and search**, while a lightweight **Go gateway** efficiently processes concurrent chat and message creation requests via Redis queues.

---

## 🚀 Architecture Overview

### 🧩 Components
| Service | Role | Tech |
|----------|------|------|
| **Rails API** | Core backend for Applications, Chats, and Messages | Ruby on Rails 7, MySQL, Sidekiq |
| **Go Gateway** | Fast HTTP layer for concurrent request handling | Go + Fiber + Redis |
| **Redis** | Queue + Atomic sequence generator | Redis |
| **Sidekiq** | Background job processor for async persistence | Sidekiq |
| **Elasticsearch** | Full-text search for messages | Elasticsearch |

---

## ⚙️ Key Features

✅ **Asynchronous Processing**
- Chat and message creation requests are handled instantly via the Go layer.
- Writes to MySQL are deferred to Sidekiq workers through Redis queues.

✅ **Concurrency & Safety**
- Uses Redis atomic counters (`INCR`) for unique chat and message numbers.
- Avoids race conditions with idempotent job processing.

✅ **Scalability**
- Each component (Go, Rails, Sidekiq) runs independently — horizontally scalable.

✅ **Search**
- Messages are indexed in Elasticsearch for efficient search queries.

✅ **Test Coverage**
- RSpec test suite for Rails logic, and Sidekiq workers.

---

## 🐳 Getting Started (with Docker)

### 1. Clone the repository

```bash
git clone https://github.com/yourusername/chat_system.git
cd chat_system
````

### 2. Build and start the entire stack

Just run:

```bash
docker-compose up --build
````

This launches:

* **Rails API** (web)
* **Sidekiq worker**
* **Go gateway**
* **Redis**
* **MySQL**
* **Elasticsearch** (if configured)

### 3. Verify containers

```bash
docker ps
```

You should see containers for `web`, `go_gateway`, `sidekiq`, `redis`, `mysql`, etc.

---

## 🧠 How It Works

### 🔸 Chat Creation Flow

1. Client sends `POST /applications/:token/chats` to **Go Gateway**.
2. Go service atomically increments Redis key `app:<token>:chats_seq`.
3. Go pushes a job JSON to Redis list `chats_queue`.
4. `GoChatConsumerWorker` (in Rails) listens to that queue and:

   * Creates the chat record in MySQL.
   * Updates `chats_count` on the application.

### 🔸 Message Creation Flow

1. Client sends `POST /applications/:token/chats/:chat_number/messages`.
2. Go increments `chat:<token>:<chat_number>:messages_seq` in Redis.
3. Pushes JSON payload to `messages_queue`.
4. `GoMessageConsumerWorker` consumes and:

   * Creates or updates the message.
   * Increments message count.
   * Indexes in Elasticsearch (if enabled).

---

## 📮 Postman Collection

A complete Postman collection is available to test all API endpoints.

**[📥 View & Import Collection](https://studying-portal.postman.co/workspace/My-Workspace~7c7d5b61-194e-4bcf-80cf-f867ea410c3c/collection/21267494-962c4c8f-59be-4266-9b6c-5c4b6b14bd3c?action=share&creator=21267494)**

### Quick Setup

1. Click the link above to open in Postman
2. Click **Fork Collection** or **Import**
3. Set these environment variables:
   - `base_url`: `http://localhost:3000`
   - `go_gateway_url`: `http://localhost:8081`
4. Run the requests in order: Setup → Chats → Messages

The collection includes:
- ✅ Application CRUD operations
- ✅ Chat creation and retrieval
- ✅ Message creation and search
- ✅ Auto-saves tokens between requests

---

## 🧪 Running Tests

### Run all specs

```bash
docker compose exec web bash -c "RAILS_ENV=test bundle exec rspec"
```

### Run a specific test

```bash
docker compose exec web bash -c "RAILS_ENV=test bundle exec rspec spec/workers/go_message_consumer_worker_spec.rb"
```

---

## 🧰 Useful Commands

| Task                  | Command                             |
| --------------------- | ----------------------------------- |
| Enter Rails container | `docker compose exec web bash`      |
| Enter Go container    | `docker compose exec go_gateway sh` |
| View logs             | `docker compose logs -f`            |
| Restart stack         | `docker compose restart`            |
| Stop all containers   | `docker compose down`               |

---

## 🧱 Database Structure

### Applications

| Field       | Description                   |
| ----------- | ----------------------------- |
| token       | Unique application identifier |
| chats_count | Cached number of chats        |

### Chats

| Field          | Description                |
| -------------- | -------------------------- |
| application_id | Linked application         |
| number         | Redis-assigned chat number |
| messages_count | Cached message count       |

### Messages

| Field   | Description                   |
| ------- | ----------------------------- |
| chat_id | Linked chat                   |
| number  | Redis-assigned message number |
| body    | Message text                  |

Indexes ensure fast lookups on `(application_id, number)` and `(chat_id, number)`.

---

## 🧩 Workers Summary

| Worker                                     | Queue                | Purpose                       |
| ------------------------------------------ | -------------------- | ----------------------------- |
| **GoChatConsumerWorker**                   | `chats_queue`        | Creates chats from Go jobs    |
| **GoMessageConsumerWorker**                | `messages_queue`     | Creates messages from Go jobs |
| **ChatCreateWorker / MessageCreateWorker** | Internal async tasks | Optional legacy support       |

---

## 🧠 Design Philosophy

This system demonstrates:

* **Decoupled architecture** between HTTP layer (Go) and persistence (Rails).
* **Eventual consistency** through Redis-backed job queues.
* **Atomicity and concurrency** using Redis as both a queue and counter store.
* **Resiliency** with Sidekiq retry mechanisms.

---

## 🧾 License

MIT License © 2025 — Built for educational and demonstration purposes.

---

## 👨‍💻 Author

**Youssef Shaker**
Software Engineer
💼 [LinkedIn](linkedin.com/in/youssef-shaker-419593217) | 🌐 [GitHub](github.com/y-shaker)

