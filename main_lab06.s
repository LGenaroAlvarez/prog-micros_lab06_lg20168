; Archivo: main_lab06.s
; Dispositivo: PIC16F887
; Autor: Luis Genaro Alvarez Sulecio
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: CONTADOR USANDO INTERRUPCIONES EN TMR1
; Hardware: LED EN PORTB
;
; Creado: 28 feb, 2022
; Última modificación: 02 ene, 2022

; PIC16F887 Configuration Bit Settings

; Assembly source line config statements

PROCESSOR 16F887  

//---------------------------CONFIGURACION WORD1--------------------------------
  CONFIG  FOSC = INTRC_NOCLKOUT ; Oscillator Selection bits (INTOSCIO oscillator: I/O function on RA6/OSC2/CLKOUT pin, I/O function on RA7/OSC1/CLKIN)
  CONFIG  WDTE = OFF            ; Watchdog Timer Enable bit (WDT disabled and can be enabled by SWDTEN bit of the WDTCON register)
  CONFIG  PWRTE = OFF            ; Power-up Timer Enable bit (PWRT enabled)
  CONFIG  MCLRE = OFF           ; RE3/MCLR pin function select bit (RE3/MCLR pin function is digital input, MCLR internally tied to VDD)
  CONFIG  CP = OFF              ; Code Protection bit (Program memory code protection is disabled)
  CONFIG  CPD = OFF             ; Data Code Protection bit (Data memory code protection is disabled)
  CONFIG  BOREN = OFF           ; Brown Out Reset Selection bits (BOR disabled)
  CONFIG  IESO = OFF            ; Internal External Switchover bit (Internal/External Switchover mode is disabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enabled bit (Fail-Safe Clock Monitor is disabled)
  CONFIG  LVP = OFF              ; Low Voltage Programming Enable bit (RB3/PGM pin has PGM function, low voltage programming enabled)

//---------------------------CONFIGURACION WORD2--------------------------------
  CONFIG  BOR4V = BOR40V        ; Brown-out Reset Selection bit (Brown-out Reset set to 4.0V)
  CONFIG  WRT = OFF             ; Flash Program Memory Self Write Enable bits (Write protection off)

// config statements should precede project file includes.
#include <xc.inc>

PSECT udata_bank0		; VARIABLES GLOBALES
  Cont:		DS 2		; VARIABLE DE CONTADOR PARA EL TMR1
  Cont_Seg:	DS 1		; VARIABLE PARA CONTEO DE SEGUNDOS
  Cont_Deci:	DS 1
  Cont_T2:	DS 2		; VARIABLE DE CONTEO PARA TMR2
  Cont_Led:	DS 1		; VARIABLE DE CONTEO PARA LED INTERMITENTE DE 500mS
  valor:	DS 1
  bandera:	DS 1
  nibbles:	DS 2
  display:	DS 2  
  
//----------------------------------MACRO---------------------------------------
    RESET_TMR0 MACRO TMR_VAR
    BANKSEL TMR0	    ; 
    MOVLW   TMR_VAR
    MOVWF   TMR0	    ; 
    BCF	    T0IF	    ; 
    ENDM
    
    TMR1_RESET MACRO TMR1_H, TMR1_L	; MACRO PARA RESETEO DEL TMR1
    MOVLW   TMR1_H		; PREPARACION DEL VALRO A CARGAR EN TMR1H
    MOVWF   TMR1H		; GARGA DEL VALOR AL TMR1H
    MOVLW   TMR1_L		; PREPARACION DEL VALOR A CARGAR EN TMR1L
    MOVWF   TMR1L		; CARGA DEL VALOR AL TMR1L
    BCF	    TMR1IF		; LIMPIADO DE LA BANDERA DE INTERRUPCIONES PARA EL TMR1
    ENDM

//--------------------------------MEM VARS--------------------------------------
PSECT udata_shr			; VARIABLES COMPARTIDAS
    W_TEMP:		DS 1	; VARIABLE TEMPORAL PARA REGISTRO W
    STATUS_TEMP:	DS 1	; VARIABLE REMPORAL PARA STATUS
    
PSECT udata_bank0
    
    
//------------------------------Vector reset------------------------------------
 PSECT resVect, class = CODE, abs, delta = 2;
 ORG 00h			; Posición 0000h RESET
 resetVec:			; Etiqueta para el vector de reset
    PAGESEL main
    goto main
  
 PSECT intVect, class = CODE, abs, delta = 2, abs
 ORG 04h			; Posición de la interrupción    
  
//--------------------------VECTOR INTERRUPCIONES------------------------------- 
PUSH:
    MOVWF   W_TEMP		; COLOCAR FALOR DEL REGISTRO W EN VARIABLE TEMPORAL
    SWAPF   STATUS, W		; INTERCAMBIAR STATUS CON REGISTRO W
    MOVWF   STATUS_TEMP		; CARGAR VALOR REGISTRO W A VARAIBLE TEMPORAL
    
ISR:     
    BTFSC   T0IF
    CALL    TMR0_INT
    
    BTFSC   TMR1IF		; REVISION DEL ESTADO DE LA BANDERA DE INTERRUPCION DEL TMR1
    CALL    TMR1_INT		; INICIAR INTERRUPCION DEL TMR1
    
    BTFSC   TMR2IF		; REVISION DEL ESTADO DE LA BANDERA DE INTERRUPCION DEL TMR2
    CALL    TMR2_INT		; INICIAR INTERRUPCION DEL TMR2
    
POP:
    SWAPF   STATUS_TEMP, W	; INTERCAMBIAR VALOR DE VARIABLE TEMPORAL DE ESTATUS CON W
    MOVWF   STATUS		; CARGAR REGISTRO W A STATUS
    SWAPF   W_TEMP, F		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO F
    SWAPF   W_TEMP, W		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO W
    RETFIE  
  
//----------------------------INT SUBRUTINAS------------------------------------


TMR1_INT:
    TMR1_RESET	0x0B, 0xDC	; REINICIO DEL TMR1
    INCF    Cont		; INCREMENTO EN CUENTA 
    MOVF    Cont, W		; CARGA DE CUENTA A REGISTRO W
    SUBLW   2			; USO DE RESTA PARA DETERMINAR SI LA CUENTA HA LLEGADO A 2X500mS QUE SERIA 1S
    BTFSC   ZERO		; SI NO SE HA LLEGADO AL SEGUNDO SALIR DE LA INTERRUPCION
    GOTO    INC_SEG		; SI SE LLEGO AL SEGUNDO IR A SUBRUTINA DE INCREMENTO DE SEGUNDOS
    RETURN
    
INC_SEG:
    INCF    Cont_Seg		; INCREMENTAR LA CUENTA DE SEGUNDOS
    INCF    PORTA		; MOSTRAR LA CUENTA DE SEGUNDOS EN PORTA
    CLRF    Cont		; LIMPIAR LA CUENTA DE 500 MILISEGUNDOS
    MOVF    Cont_Seg, W
    SUBLW   10
    BTFSC   ZERO
    GOTO    INC_DECI
    RETURN
    
INC_DECI:
    CLRF    Cont_Seg
    INCF    Cont_Deci
    MOVF    Cont_Deci, W
    SUBLW   10
    BTFSC   ZERO
    GOTO    TMR1_MC
    RETURN
    
TMR1_MC:
    CLRF    Cont_Seg
    CLRF    Cont_Deci
    RETURN
    
TMR0_INT:
    CALL    SHOW_DISPLAY
    RESET_TMR0 250
    RETURN
    
TMR2_INT:
    BCF	    TMR2IF		; LIMPIAR BANDERA DE INTERRUPCION DEL TMR2
    INCF    Cont_T2		; INCREMENTAR CUENTA DEL TMR2
    MOVF    Cont_T2, W		; CARGAR CUENTA DEL TMR2 AL REGISTRO W
    SUBLW   10			; USO DE RESTA PARA DETERMINAR SI LA CUENTA HA LLEGADO A 10X50mS QUE SERIA 500mS
    BTFSC   ZERO		; SI NO SE HA LLEGADO A LOS 500mS SALIR DE LA INTERRUPCION
    GOTO    INC_LED		; SI SE LLEGO A LOS 500mS IR A SUBRUTINA DE ACTIVACION DEL LED
    RETURN 
    
INC_LED:
    INCF    Cont_Led		; INCREMENTAR LA CUENTA DEL LED
    INCF    PORTB		; INCREMENTAR EN PORTB PARA TENER CICLO INTERMITENTE
    CLRF    Cont_T2		; LIMPIAR CUENTA DEL TMR2
    RETURN
    
PSECT code, delta=2, abs
ORG 100h			; posición 100h para el codigo    
    
//------------------------------MAIN CONFIG-------------------------------------
main:
    CALL    CLK_CONFIG		; INICIAR CONFIGURACION DE RELOJ
    CALL    IO_CONFIG		; INICIAR CONFIGURACION DE PINES
    CALL    TMR0_CONFIG		; INICIAR CONFIGURACION DEL TMR0
    CALL    TMR1_CONFIG		; INICIAR CONFIGURACION DEL TMR1
    CALL    TMR2_CONFIG		; INICIAR CONFIGURACION DEL TMR2
    CALL    INT_CONFIG		; INICIAR CONFIGURACION DE INTERRUPCIONES
    BANKSEL PORTA		; SELECCIONAR BANCO 0 COMO CONTINGENCIA
    
loop:				; CODIGO QUE SE DEBE EJECUTAR MIENTRAS NO OCURREN INTERRUPCIONES
    CALL    SET_DISPLAY
    GOTO    loop
    
//------------------------------SUBRUTINAS--------------------------------------    
CLK_CONFIG:
    BANKSEL OSCCON		; SELECCIONAR CONFIGURADOR DEL OSCILADOR
    BSF	    SCS			; USAR OSCILADOR INTERNO PARA RELOJ DE SISTEMA
    BCF	    IRCF0		; BIT 4 DE OSCCON EN 0
    BSF	    IRCF1		; BIT 5 DE OSCCON EN 1
    BSF	    IRCF2		; BIT 6 DE OSCCON EN 1
    //OSCCON 110 -> 4MHz RELOJ INTERNO
    RETURN

IO_CONFIG:
    BANKSEL ANSEL		; SELECCIONAR EL BANCO 3
    CLRF    ANSEL		; PORTA COMO DIGITAL
    CLRF    ANSELH		; PORTB COMO DIGITAL
    
    BANKSEL TRISA		; SELECCIONAR BANCO 1
    CLRF    TRISA		; PORTA COMO SALIDA
    BCF	    TRISB, 0		; BIT0 PORTB COMO SALIDA
    CLRF    TRISC
    MOVLW   0XC0
    MOVWF   TRISD    
    
    BANKSEL PORTA		; SELECCIONAR EL BANCO 0
    CLRF    PORTA		; LIMPIAR EL REGISTRO EN PORTA
    CLRF    PORTB		; LIMPIAR EL REGISTRO EN PORTB
    CLRF    PORTC
    CLRF    PORTD
    CLRF    bandera
    RETURN    

TMR0_CONFIG:
    BANKSEL OPTION_REG		;
    BCF	    T0CS		;
    BCF	    PSA			;
    BSF	    PS2			; PRESCALER EN 256
    BSF	    PS1
    BSF	    PS0
    
    BANKSEL TMR0		; SELECIONAR EL BANCO 
    MOVLW   250			; N=256-[(2mS*4MHz)/(4x256)]=248 redondeado es: 250
    MOVWF   TMR0
    BCF	    T0IF
    RETURN
    
TMR1_CONFIG:
    BANKSEL T1CON		; SELECIONAR EL BANCO DEL T1CON
    BCF	    TMR1GE		; ACTIVAR CUENTA PERPETUA EN TMR1
    BSF	    T1CKPS1		; PRESCALER EN 1:8
    BSF	    T1CKPS0		; |	    |	|
    BCF	    T1OSCEN		; MODO DE BAJA POTENCIA ACTIVADO
    BCF	    TMR1CS		; USO DEL RELOJ INTERNO
    BSF	    TMR1ON		; ENCENDIDO DEL TMR1
    
    TMR1_RESET 0x0B, 0xDC	; REINICIO DEL TMR1 EN 500mS
    ; VALOR A CARGAR: 65536-(0.5)/[8(1/1x10^6)]=3036d=0x0BDC
    RETURN
    
TMR2_CONFIG:
    BANKSEL PR2			; SELECCIONAR BANCO DEL PR2
    MOVLW   195			; CARGAR VALOR CALCULADO PARA INTERRUPCIONES DE 50mS EN EL TMR2 AL REGISTRO W
    MOVWF   PR2			; MOVER VALOR AL PR2
    
    BANKSEL T2CON		; SELECCIONAR EL BANCO DEL T2CON
    BSF	    T2CKPS1		; PRESCALER EN 1:16
    BSF	    T2CKPS0		
    
    BSF	    TOUTPS3		; POSTSCALER EN 1:16
    BSF	    TOUTPS2		
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    BSF	    TMR2ON		; ENCENDIDO DEL TMR2
    RETURN
    
INT_CONFIG:
    BANKSEL PIE1		; SELECCIONAR BANCO DEL PIE1
    BSF	    TMR1IE		; HABILITAR INTERRUPCIONES EN TMR1
    BSF	    TMR2IE		; HABILITAR INTERRUPCIONES EN TMR2
    
    BANKSEL INTCON		; SELECCIONAR BANCO DEL INTCON
    BSF	    PEIE		; HABILITAR INTERRUPCIONES EN PERIFERICOS
    BSF	    GIE			; HABILITAR INTERRUPCIONES GLOBALES
    BSF	    T0IE		;
    BCF	    T0IF		;
    BCF	    TMR1IF		; LIMPIAR BANDERA DE INTERRUPCIONES EN TMR1
    BCF	    TMR2IF		; LIMPIAR BANDERA DE INTERRUPCIONES EN TMR2
    RETURN
    
SET_DISPLAY:
    MOVF    Cont_Seg, W
    CALL    HEX_INDEX
    MOVWF   display
    
    MOVF    Cont_Deci, W
    CALL    HEX_INDEX
    MOVWF   display+1
    RETURN
    
SHOW_DISPLAY:
    BCF	    PORTD, 0
    BCF	    PORTD, 1
    BTFSC   bandera, 0
    GOTO    DISPLAY_1
    
DISPLAY_0:
    MOVF    display, W
    MOVWF   PORTC
    BSF	    PORTD, 1
    BSF	    bandera, 0
RETURN
    
DISPLAY_1:
    MOVF    display+1, W
    MOVWF   PORTC
    BSF	    PORTD, 0
    BCF	    bandera, 0
RETURN
	
//---------------------------INDICE DISPLAY 7SEG--------------------------------
PSECT HEX_INDEX, class = CODE, abs, delta = 2
ORG 200h			; POSICIÓN DE LA TABLA

HEX_INDEX:
    CLRF PCLATH
    BSF PCLATH, 1		; PCLATH en 01
    ANDLW 0x0F
    ADDWF PCL			; PC = PCLATH + PCL | SUMAR W CON PCL PARA INDICAR POSICIÓN EN PC
    RETLW 00111111B		; 0
    RETLW 00000110B		; 1
    RETLW 01011011B		; 2
    RETLW 01001111B		; 3
    RETLW 01100110B		; 4
    RETLW 01101101B		; 5
    RETLW 01111101B		; 6
    RETLW 00000111B		; 7
    RETLW 01111111B		; 8 
    RETLW 01101111B		; 9
    RETLW 01110111B		; A
    RETLW 01111100B		; b
    RETLW 00111001B		; C
    RETLW 01011110B		; D
    RETLW 01111001B		; C
    RETLW 01110001B		; F	
    
END
  
