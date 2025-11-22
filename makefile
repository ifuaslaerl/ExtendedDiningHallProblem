CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -pthread -D_POSIX_C_SOURCE=199309L
TARGET = dining_hall
SOURCE = dining_hall.c

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE)

test: $(TARGET)
	chmod +x stress_test.sh
	./stress_test.sh

quick-test: $(TARGET)
	@echo "=== Teste Rápido ==="
	./dining_hall 3 2
	./dining_hall 5 2
	./dining_hall 7 2

stress: $(TARGET)
	@echo "=== Teste de Estresse ==="
	chmod +x stress_test.sh
	MAX_STUDENTS=30 RANDOM_TESTS=5 ./stress_test.sh

clean:
	rm -f $(TARGET)
	rm -rf stress_test_logs

.PHONY: clean test quick-test stress
