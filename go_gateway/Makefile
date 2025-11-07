run:
	go run main.go

build:
	go build -o main .

test:
	curl -X POST http://localhost:8081/messages \
	-H "Content-Type: application/json" \
	-d '{"application_token": "demo", "chat_number": 1, "body": "test"}'
