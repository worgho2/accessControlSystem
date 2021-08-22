
    .data
    pass:   .word 0,0,0,0,0,0,0,0
    unlock: .word 0,0,0,0,0,0,0,0

    msg_newPass: .asciz "Digite a nova senha para memorizacao:" 
    msg_asterisk: .asciz "*"
    msg_empty: .asciz " "
    msg_passStored: .asciz "Senha memorizada"
    msg_correctPass: .asciz "Acesso autorizado"
    msg_incorrectPass: .asciz "Senha incorreta"
    msg_maxUnlockAttempts: .asciz "Numero de tentativas maximo atingido!"

    .equ    SEG_0, 0x80 | 0x40 | 0x20 | 0x08 | 0x04 | 0x01
    .equ    SEG_1, 0x40 | 0x20
    .equ    SEG_2, 0x80 | 0x40 | 0x08 | 0x04 | 0x02
    .equ    SEG_3, 0x80 | 0x40 | 0x20 | 0x08 | 0x02
    .equ    DELAY_TIME, 0x1388
    .equ    RETRY_TIME, 0x2BC

    .text
    .align
main:
    mov     r0, #0                      @ reseta o registrador usado pelo swi
    mov     r1, #0                      @ reseta o registrador usado pelo swi
    swi     0x206                       @ limpa lcd
    swi     0x200                       @ limpa display
    swi     0x201                       @ limpa leds
    mov     r3, #0                      @ somador de tamanho input de senha
    mov     r4, #0                      @ somador de tentativas de senha
    ldr     r5, =pass                   @ referencia do endereço de memoria do password
    ldr     r6, =unlock                 @ referencia do endereço de memoria do unlock
    mov     r7, #0                      @ constante 0
    b       waitingForStart             @ pula

waitingForStart:
    swi     0x202                       @ captura input dos botão pretos
    cmp     r0, #1                      @ verifica se o botão esquerdo foi clicado
    beq     showNewPasswordMsg          @ pula
    b       waitingForStart             @ pula

showNewPasswordMsg:
    mov     r0, #0                      @ posiciona o cursor do lcd no eixo x
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    ldr     r2, =msg_newPass            @ coloca a mensagem no registrador
    swi     0x204                       @ mostra a mensagem no lcd
    b       listenForNewPass            @ pula

listenForNewPass:
    swi     0x203                       @ captura input do teclado
    cmp     r0, #0                      @ se alguma tecla for digitada
    bne     addPassInput                @ pula
    swi     0x202                       @ captura input dos botões pretos
    cmp     r0, #2                      @ se o botão direito foi apertado
    beq     delLastPassInput            @ pula
    cmp     r0, #1                      @ se o botão esquerdo foi apertado
    beq     changeToAccessState         @ pula
    b       listenForNewPass            @ pula

addPassInput:
    cmp     r3, #8                      @ Se o tamanho da senha chegou ao máximo
    bhs     listenForNewPass            @ pula
    str     r0, [r5], #4                @ salva o valor e incrementa o endereço de memoria do vetor de senha
    mov     r1, #1                      @ posiciona o cursor do lcd no eixo y
    mov     r0, r3                      @ posiciona o cursor do lcd no eixo x
    ldr     r2, =msg_asterisk           @ carrega o asterisco para printar
    swi     0x204                       @ mostra a mensagem no lcd
    add     r3, r3, #1                  @ incrementa o controlador da senha do lcd
    b       listenForNewPass            @ pula

delLastPassInput:
    cmp     r3, #0                      @ Se o o tamanho da senha chegou ao mínimo
    beq     listenForNewPass            @ pula
    sub     r5, r5, #4                  @ volta o endereço de memoria para poder limpar o vetor de senha
    str     r7, [r5]                    @ coloca um 0 no endereço deletado
    mov     r1, #1                      @ posiciona o cursor do lcd no eixo y
    sub     r3, r3, #1                  @ decrementa o controlador da senha do lcd
    mov     r0, r3                      @ posiciona o cursor do lcd no eixo x
    ldr     r2, =msg_empty              @ carrega mensagem a ser mostrada no lcd
    swi     0x204                       @ mostra a mensagem no lcd
    b       listenForNewPass            @ pula

changeToAccessState:
    cmp     r3, #8                      @ Se o tamanho da senha não é o esperado
    bne     listenForNewPass            @ pula
    mov     r3, #0                      @ reseta contador de tamanho de senha
    swi     0x206                       @ limpa lcd
    mov     r0, #0                      @ posiciona o cursor do lcd no eixo x
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    ldr     r2, =msg_passStored         @ carrega mensagem a ser mostrada no lcd
    swi     0x204                       @ mostra a mensagem no lcd
    mov     r0, #SEG_0                  @ carrega a informação para o display
    swi     0x200                       @ mostra a informação no display
    mov     r0, #1                      @ carrega a informação para o led
    swi     0x201                       @ mostra a informação no led
    swi     0x6d                        @ pega tempo atual
    mov     r1, r0                      @ carrega a informação do inicio do timer
    ldr     r2, =DELAY_TIME             @ carrega a informação da duração do timer
    b       waitLoop                    @ pula

waitLoop:
    swi     0x6d                        @ pega tempo atual
    subs    r0, r0, r1                  @ r0: tempo desde o inicio
    cmp     r0, r2                      @ scalcula a diferença do tempo
    blt     waitLoop                    @ pula
    swi     0x206                       @ limpa lcd
    b       listenToUnlockPass          @ pula

listenToUnlockPass:
    swi     0x203                       @ captura input do teclado
    cmp     r0, #0                      @ se alguma tecla for digitada
    bne     addUnlockPassInput          @ pula
    swi     0x202                       @ captura input dos botões pretos
    cmp     r0, #2                      @ se o botão direito foi apertado
    beq     delLastUnlockPassInput      @ pula
    cmp     r0, #1                      @ se o botão esquerdo foi apertado
    beq     verifyUnlockPassInput       @ pula
    b       listenToUnlockPass          @ pula

addUnlockPassInput:
    cmp     r3, #8                       @ Se o tamanho da senha chegou ao máximo
    bhs     listenToUnlockPass           @ pula
    str     r0, [r6], #4                @ salva o valor e incrementa o endereço de memoria do vetor de unlock
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    mov     r0, r3                      @ posiciona o cursor do lcd no eixo x
    ldr     r2, =msg_asterisk           @ carrega o asterisco para printar
    swi     0x204                       @ mostra a mensagem no lcd
    add     r3, r3, #1                  @ incrementa o controlador da senha do lcd
    b       listenToUnlockPass          @ pula

delLastUnlockPassInput:
    cmp     r3, #0                      @ Se o o tamanho da senha chegou ao mínimo
    beq     listenToUnlockPass          @ pula
    sub     r6, r6, #4                  @ volta o endereço de memoria para poder limpar o vetor de senha
    str     r7, [r6]                    @ coloca um 0 no endereço deletado
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    sub     r3, r3, #1                  @ decrementa o controlador da senha do lcd
    mov     r0, r3                      @ posiciona o cursor do lcd no eixo x
    ldr     r2, =msg_empty              @ carrega mensagem a ser mostrada no lcd
    swi     0x204                       @ mostra a mensagem no lcd
    b       listenToUnlockPass          @ pula

verifyUnlockPassInput:
    cmp     r3, #8                      @ Se o tamanho da senha não é o esperado
    bne     onVerifyFail                @ pula
    ldr     r0, =pass                   @ refaz a referencia do endereço de memoria do password
    ldr     r1, =unlock                 @ refaz a referencia do endereço de memoria do unlock
    mov     r2, #8                      @ utiliza o registrador para iterar os array
    b       verifyLoop                  @ pula

verifyLoop:
    cmp r2, r7                          @ se percorreu vetor inteiro
    bls onVerifySuccess                 @ pula
    sub r2, r2, #1                      @ decrementa registrador que controla o percorrimento
    ldr     r8, [r0], #4                @ carrega da memoria do pass o valor e incrementa uma posição
    ldr     r9, [r1], #4                @ carrega da memoria do unlock o valor e incrementa uma posição
    cmp     r8, r9                      @ se os valores são diferentes
    bne     onVerifyFail                @ pula
    b verifyLoop                        @ pula

onVerifySuccess:
    mov     r3, #0                      @ reseta contador de tamanho de input de senha
    mov     r4, #0                      @ reseta o contador de tentantivas
    swi     0x206                       @ limpa lcd
    mov     r0, #0                      @ carrega a informação para o display
    swi     0x200                       @ mostra a informação no display
    mov     r0, #0                      @ carrega a informação para o led
    swi     0x201                       @ mostra a informação no led
    mov     r0, #0                      @ posiciona o cursor do lcd no eixo x
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    ldr     r2, =msg_correctPass        @ carrega a mensagem para printar
    swi     0x204                       @ mostra a mensagem no lcd
    swi     0x6d                        @ pega tempo atual
    mov     r1, r0                      @ carrega a informação do inicio do timer
    ldr     r2, =RETRY_TIME             @ carrega a informação da duração do timer
    b       waitRestartLoop             @ pula  

waitRestartLoop:
    swi     0x6d                        @ pega tempo atual
    subs    r0, r0, r1                  @ r0: tempo desde o inicio
    cmp     r0, r2                      @ calcula a diferença do tempo
    blt     waitRestartLoop             @ pula
    swi     0x206                       @ limpa lcd
    b       main                        @ pula

onVerifyFail:
    add     r4, r4, #1                  @ incrementa o contador de tentantivas
    swi     0x206                       @ limpa lcd
    mov     r3, #0                      @ reseta contador de tamanho de input de senha
    cmp     r4, #1                      @ se o numero da tentiva foi 1
    beq     updateDisplayToOne          @ pula   
    cmp     r4, #2                      @ se o numero da tentiva foi 2
    beq     updateDisplayToTwo          @ pula   
    cmp     r4, #3                      @ se o numero da tentiva foi 3
    bhs     updateDisplayToThree        @ pula   

updateDisplayToOne:
    mov     r0, #SEG_1                  @ carrega a informação para o display
    swi     0x200                       @ mostra a informação no display
    mov     r0, #0                      @ posiciona o cursor do lcd no eixo x
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    ldr     r2, =msg_incorrectPass      @ carrega a mensagem para printar
    swi     0x204                       @ mostra a mensagem no lcd
    swi     0x6d                        @ pega tempo atual
    mov     r1, r0                      @ carrega a informação do inicio do timer
    ldr     r2, =RETRY_TIME             @ carrega a informação da duração do timer
    b       waitRetryLoop               @ pula    

updateDisplayToTwo:
    mov     r0, #SEG_2                  @ carrega a informação para o display
    swi     0x200                       @ mostra a informação no display
    mov     r0, #0                      @ posiciona o cursor do lcd no eixo x
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    ldr     r2, =msg_incorrectPass      @ carrega a mensagem para printar
    swi     0x204                       @ mostra a mensagem no lcd
    swi     0x6d                        @ pega tempo atual
    mov     r1, r0                      @ carrega a informação do inicio do timer
    ldr     r2, =RETRY_TIME             @ carrega a informação da duração do timer
    b       waitRetryLoop               @ pula    

waitRetryLoop:
    swi     0x6d                        @ pega tempo atual
    subs    r0, r0, r1                  @ r0: tempo desde o inicio
    cmp     r0, r2                      @ scalcula a diferença do tempo
    blt     waitRetryLoop               @ pula
    swi     0x206                       @ limpa lcd
    ldr     r6, =unlock                 @ refaz a referencia do endereço de memoria do unlock
    b       listenToUnlockPass          @ pula

updateDisplayToThree:
    mov     r0, #SEG_3                  @ carrega a informação para o display
    swi     0x200                       @ mostra a informação no display
    mov     r0, #0                      @ posiciona o cursor do lcd no eixo x
    mov     r1, #0                      @ posiciona o cursor do lcd no eixo y
    ldr     r2, =msg_maxUnlockAttempts  @ carrega a mensagem para printar
    swi     0x204                       @ mostra a mensagem no lcd
    mov     r0, #3                      @ carrega a informação para o led
    swi     0x201                       @ mostra a informação no led
    b       end                         @ pula

end:
    swi     0x11                        @ fim de programa
