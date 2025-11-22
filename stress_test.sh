#!/bin/bash

# Cores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configurações
LOG_DIR="stress_test_logs"
RANDOM_TESTS=8
MAX_STUDENTS=25
MAX_ITERATIONS=6
TIMEOUT_BASE=5

mkdir -p "$LOG_DIR"

# Função para log colorido
log_info() { echo -e "${BLUE}[INFO]${NC} $1"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
log_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Função para gerar números aleatórios
random_number() {
    local min=$1
    local max=$2
    echo $((min + RANDOM % (max - min + 1)))
}

# Função para calcular timeout
calculate_timeout() {
    local students=$1
    local iterations=$2
    local base_timeout=$TIMEOUT_BASE
    local complexity=0
    local timeout=$((base_timeout + complexity))
    
    if [ $timeout -gt 60 ]; then
        timeout=60
    fi
    echo "${timeout}s"
}

# Função para compilar
compile_program() {
    log_info "Compilando o programa..."
    if make > /dev/null 2>&1; then
        log_success "Compilação bem-sucedida"
        return 0
    else
        log_error "Falha na compilação"
        return 1
    fi
}

# Função para executar teste único
run_single_test() {
    local students=$1
    local iterations=$2
    local timeout_val=$3
    local test_name=$4
    
    log_info "Testando: $students estudantes, $iterations iterações (Timeout: $timeout_val)"
    
    local log_file="$LOG_DIR/${students}_${iterations}_${test_name}.log"
    
    # Executa com timeout
    timeout $timeout_val ./dining_hall $students $iterations > "$log_file" 2>&1
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        if grep -q "Todas as.*iterações foram concluídas" "$log_file"; then
            log_success "✅ COMPLETO: $test_name"
            return 0
        else
            log_error "❌ INCOMPLETO: $test_name"
            return 1
        fi
    elif [ $exit_code -eq 124 ]; then
        log_error "❌ TIMEOUT: $test_name"
        return 1
    else
        log_error "❌ FALHA: $test_name (código: $exit_code)"
        return 1
    fi
}

# Função para executar testes focados nos casos problemáticos
run_focused_tests() {
    log_info "Executando testes focados nos casos críticos..."
    
    # Testes específicos que anteriormente falhavam
    local focused_tests=(
        "3 5 focused_3_5"
        "4 3 focused_4_3" 
        "5 5 focused_5_5"
        "10 5 focused_10_5"
        "2 3 focused_2_3"
        "7 3 focused_7_3"
        "15 3 focused_15_3"
    )
    
    local tests_passed=0
    local tests_failed=0
    
    for test in "${focused_tests[@]}"; do
        local students=$(echo $test | cut -d' ' -f1)
        local iterations=$(echo $test | cut -d' ' -f2)
        local test_name=$(echo $test | cut -d' ' -f3)
        local timeout_val=$(calculate_timeout $students $iterations)
        
        if run_single_test $students $iterations $timeout_val $test_name; then
            ((tests_passed++))
        else
            ((tests_failed++))
        fi
        echo
    done
    
    echo "=== RESUMO TESTES FOCADOS ==="
    log_info "Total: ${#focused_tests[@]}"
    log_success "Aprovados: $tests_passed"
    if [ $tests_failed -gt 0 ]; then
        log_error "Reprovados: $tests_failed"
    fi
    echo
    
    return $tests_failed
}

# Função para executar testes aleatórios
run_random_tests() {
    log_info "Executando $RANDOM_TESTS testes aleatórios..."
    
    local tests_passed=0
    local tests_failed=0
    
    for ((i=1; i<=$RANDOM_TESTS; i++)); do
        local students=$(random_number 2 $MAX_STUDENTS)
        local iterations=$(random_number 1 $MAX_ITERATIONS)
        local test_name="random_${i}_${students}_${iterations}"
        local timeout_val=$(calculate_timeout $students $iterations)
        
        if run_single_test $students $iterations $timeout_val $test_name; then
            ((tests_passed++))
        else
            ((tests_failed++))
        fi
        
        sleep 1
        echo
    done
    
    echo "=== RESUMO TESTES ALEATÓRIOS ==="
    log_info "Total: $RANDOM_TESTS"
    log_success "Aprovados: $tests_passed"
    if [ $tests_failed -gt 0 ]; then
        log_error "Reprovados: $tests_failed"
    fi
    echo
    
    return $tests_failed
}

# Função principal
main() {
    log_info "Iniciando Testing Focado do Extended Dining Hall"
    log_info "Configuração:"
    log_info "  - Máximo de estudantes: $MAX_STUDENTS"
    log_info "  - Máximo de iterações: $MAX_ITERATIONS"
    log_info "  - Testes aleatórios: $RANDOM_TESTS"
    echo
    
    if ! compile_program; then
        exit 1
    fi
    
    run_focused_tests
    local focused_failed=$?
    
    run_random_tests
    local random_failed=$?
    
    local total_tests=$(( ${#focused_tests[@]} + RANDOM_TESTS ))
    local total_failed=$((focused_failed + random_failed))
    local total_passed=$((total_tests - total_failed))
    
    echo "========================================="
    echo "          RELATÓRIO FINAL DE TESTES"
    echo "========================================="
    log_info "Total de testes executados: $total_tests"
    log_success "Testes aprovados: $total_passed"
    
    if [ $total_failed -eq 0 ]; then
        log_success "Testes reprovados: $total_failed"
        log_success "🎉 TODOS OS TESTES PASSARAM!"
        echo
        log_info "O código está completamente validado!"
    else
        log_error "Testes reprovados: $total_failed"
    fi
    
}

# Executar
main "$@"
