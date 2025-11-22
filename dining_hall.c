#define _POSIX_C_SOURCE 199309L

#include <stdio.h>
#include <stdlib.h>
#include <pthread.h>
#include <unistd.h>
#include <time.h>

// Variáveis globais para sincronização
pthread_mutex_t mutex = PTHREAD_MUTEX_INITIALIZER;
pthread_cond_t cond_eat = PTHREAD_COND_INITIALIZER;
pthread_cond_t cond_leave = PTHREAD_COND_INITIALIZER;

// Estados dos estudantes e contadores
int ready_to_eat = 0;
int eating = 0;
int ready_to_leave = 0;
int total_students;
int total_iterations;

// Protótipos das funções
void getFood(int id, int iteration);
void dine(int id, int iteration);
void leave(int id, int iteration);
void random_delay();
int can_start_eating(void);
int can_leave(void);

// Função para simular ações com tempos aleatórios
void random_delay() {
    struct timespec ts;
    ts.tv_sec = 0;
    ts.tv_nsec = 1000000 + (rand() % 2000000); // 1-3ms
    nanosleep(&ts, NULL);
}

// Ações dos estudantes
void getFood(int id, int iteration) {
    printf("Iteração %d: Estudante %d pegou comida.\n", iteration, id);
    fflush(stdout);
    random_delay();
}

void dine(int id, int iteration) {
    printf("Iteração %d: Estudante %d está comendo.\n", iteration, id);
    fflush(stdout);
    random_delay();
}

void leave(int id, int iteration) {
    printf("Iteração %d: Estudante %d saiu.\n", iteration, id);
    fflush(stdout);
}

// Verifica se um estudante pode começar a comer
int can_start_eating(void) {
    // REGRA 1: Não pode começar sozinho se não há ninguém comendo E não há pelo menos outro pronto para comer
    return !(eating == 0 && ready_to_eat < 2);
}

// Verifica se um estudante pode sair - LÓGICA COMPLETAMENTE REVISADA
int can_leave(void) {
    // INTERPRETAÇÃO CORRETA E DEFINITIVA:
    // Um estudante pode sair se e somente se sua saída não violar as regras:
    // 1. Se não há ninguém comendo, pode sair (mesa vazia)
    // 2. Se há múltiplos comendo, pode sair (não deixa ninguém sozinho)
    // 3. Se há apenas 1 comendo, só pode sair se houver backup suficiente
    
    if (eating == 0) {
        return 1; // Mesa vazia - pode sair
    }
    if (eating >= 2) {
        return 1; // Múltiplos comendo - sair não deixa ninguém sozinho
    }
    
    // Cenário crítico: apenas 1 estudante comendo
    // Só pode sair se houver pelo menos 1 outro pronto para sair para fazer companhia
    // Isso garante que o estudante comendo não ficará sozinho
    if (ready_to_leave >= 2) {
        return 1; // Há backup suficiente
    }
    
    // CASO CRÍTICO: 1 comendo, 1 pronto para sair
    // Não pode sair - isso deixaria o estudante comendo sozinho
    return 0;
}

// Comportamento do estudante - VERSÃO FINAL ROBUSTA
void* student(void* arg) {
    int id = *(int*)arg;
    free(arg);

    for (int iteration = 1; iteration <= total_iterations; iteration++) {
        getFood(id, iteration);
        
        pthread_mutex_lock(&mutex);
        ready_to_eat++;
        printf("Iteração %d: Estudante %d pronto para comer. (Prontos: %d, Comendo: %d)\n", 
               iteration, id, ready_to_eat, eating);
        fflush(stdout);

        // REGRA 1: Espera até poder comer (não sozinho)
        while (!can_start_eating()) {
            printf("Iteração %d: Estudante %d esperando para comer...\n", iteration, id);
            fflush(stdout);
            pthread_cond_wait(&cond_eat, &mutex);
        }
        
        ready_to_eat--;
        eating++;
        printf("Iteração %d: Estudante %d começou a comer. (Prontos: %d, Comendo: %d)\n", 
               iteration, id, ready_to_eat, eating);
        fflush(stdout);
        
        // Acorda outros que podem estar esperando para comer
        pthread_cond_broadcast(&cond_eat);
        pthread_mutex_unlock(&mutex);

        dine(id, iteration);

        pthread_mutex_lock(&mutex);
        eating--;
        ready_to_leave++;
        printf("Iteração %d: Estudante %d terminou de comer. (Saindo: %d, Comendo: %d)\n", 
               iteration, id, ready_to_leave, eating);
        fflush(stdout);

        // REGRA 2: Espera até poder sair (não deixar ninguém sozinho)
        while (!can_leave()) {
            printf("Iteração %d: Estudante %d esperando para sair... (Saindo: %d, Comendo: %d)\n", 
                   iteration, id, ready_to_leave, eating);
            fflush(stdout);
            pthread_cond_wait(&cond_leave, &mutex);
        }
        
        ready_to_leave--;
        printf("Iteração %d: Estudante %d saindo... (Saindo: %d, Comendo: %d)\n", 
               iteration, id, ready_to_leave, eating);
        fflush(stdout);
        
        // Acorda outros que podem estar esperando para sair OU para comer
        pthread_cond_broadcast(&cond_leave);
        pthread_cond_broadcast(&cond_eat); // Importante: acorda quem espera para comer também
        pthread_mutex_unlock(&mutex);

        leave(id, iteration);
    }
    return NULL;
}

// Função principal
int main(int argc, char* argv[]) {
    if (argc != 3) {
        fprintf(stderr, "Uso: %s <total_students> <iterations>\n", argv[0]);
        return 1;
    }

    total_students = atoi(argv[1]);
    total_iterations = atoi(argv[2]);
    if (total_students <= 0 || total_iterations <= 0) {
        fprintf(stderr, "Número de estudantes e iterações devem ser positivos.\n");
        return 1;
    }

    srand(time(NULL));
    pthread_t threads[total_students];

    printf("Iniciando jantar com %d estudantes por %d iterações...\n", total_students, total_iterations);
    fflush(stdout);

    // Cria threads dos estudantes
    for (int i = 0; i < total_students; i++) {
        int* id = malloc(sizeof(int));
        *id = i + 1;
        if (pthread_create(&threads[i], NULL, student, id) != 0) {
            perror("Erro ao criar thread");
            return 1;
        }
    }

    // Espera todas as threads terminarem
    for (int i = 0; i < total_students; i++) {
        pthread_join(threads[i], NULL);
    }

    printf("Todas as %d iterações foram concluídas por todos os %d estudantes.\n", 
           total_iterations, total_students);
    fflush(stdout);
    
    pthread_mutex_destroy(&mutex);
    pthread_cond_destroy(&cond_eat);
    pthread_cond_destroy(&cond_leave);
    
    return 0;
}
