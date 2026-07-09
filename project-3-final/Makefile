COMPOSE = docker compose -f docker/docker-compose.yml

.PHONY: run build down logs clean

run:
	$(COMPOSE) up --build

build:
	$(COMPOSE) build

down:
	$(COMPOSE) down

logs:
	$(COMPOSE) logs -f

clean:
	rm -rf output/*
