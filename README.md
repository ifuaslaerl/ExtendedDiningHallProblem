This repository contains a solution for the "Extended Dining Hall Problem". The project implements a thread synchronization system in C, simulating students in a dining hall who must follow strict etiquette rules to avoid eating alone and to ensure no colleague is left alone at the table.

## About the Project

The program simulates an environment where multiple students (threads) attempt to eat simultaneously. Synchronization is achieved using the \`pthread\` library (POSIX Threads), ensuring that **deadlocks** and **starvation** do not occur, while strictly adhering to the following rules:

1.  **Entry Rule:** A student cannot start eating if they would be alone at the table, unless there is another student ready to eat immediately.
2.  **Exit Rule:** A student cannot leave the table if doing so would leave exactly one student eating alone (they must wait until another student can leave or until the table empties).

### Technologies Used
- C (Standard C99)
- POSIX Threads (pthreads) for concurrency (Mutexes and Condition Variables)
- Bash Script (for automated testing)

## Repository Structure

- \`dining_hall.c\`: Main source code containing the thread logic, mutexes, and condition variables.
- \`makefile\`: Automation file for compiling and running tests.
- \`stress_test.sh\`: Robust testing script that runs edge cases and random scenarios to validate stability.
- \`.gitignore\`: Files ignored by Git (binaries and logs).

## How to Use

### Prerequisites
You need \`gcc\` and \`make\` installed on your system (Linux/Unix environment).

### Compiling
To compile the project, run the \`make\` command in the root directory:

```bash
make
```

This will generate the \`dining_hall\` executable.

### Running Manually
You can run the program by specifying the number of students and the number of iterations (how many times each student will eat):

```bash
./dining_hall <number_of_students> <number_of_iterations>
```

Example:
```bash
./dining_hall 10 5
```

## Testing

The project includes automated scripts to verify the correctness of the solution and ensure no deadlocks occur.

### Quick Test
Runs a few simple scenarios for visual verification:
```bash
make quick-test
```

### Stress Test
Executes the \`stress_test.sh\` script, which runs various critical edge cases (known to cause issues) and random scenarios with strict timeouts to detect deadlocks:

```bash
make test
# Or for a more intense battery of tests:
make stress
```

Detailed test logs are saved in the \`stress_test_logs/\` directory.

## Cleaning

To remove compiled files and test logs:

```bash
make clean
```

## Authors

- **Developer**: [Luís Rafael Sena]

## License

This project is for academic/educational use.`
