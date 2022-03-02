; Archivo: main_lab06.s
; Dispositivo: PIC16F887
; Autor: Luis Genaro Alvarez Sulecio
; Compilador: pic-as (v2.30), MPLABX V5.40
;
; Programa: CONTADOR USANDO INTERRUPCIONES EN TMR1
; Hardware: 7 SEGMENT DISPLAY
;
; Creado: 28 feb, 2022
; Última modificación: 19 feb, 2022

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

PSECT udata_bank0
  Cont:	    DS 2
  Cont_Seg: DS 1
  Cont_T2:  DS 2
  Cont_Led: DS 1
  
//----------------------------------MACRO---------------------------------------
TMR1_RESET MACRO TMR1_H, TMR1_L
    MOVLW   TMR1_H
    MOVWF   TMR1H
    MOVLW   TMR1_L
    MOVWF   TMR1L
    BCF	    TMR1IF
    ENDM

//--------------------------------MEM VARS--------------------------------------
PSECT udata_shr			; VARIABLES COMPARTIDAS
    W_TEMP:		DS 1	; VARIABLE TEMPORAL PARA REGISTRO W
    STATUS_TEMP:	DS 1	; VARIABLE REMPORAL PARA STATUS
    
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
    BTFSC   TMR1IF
    CALL    TMR1_INT
    
/*    BTFSC   TMR2IF
    CALL    TMR2_INT */
    
POP:
    SWAPF   STATUS_TEMP, W	; INTERCAMBIAR VALOR DE VARIABLE TEMPORAL DE ESTATUS CON W
    MOVWF   STATUS		; CARGAR REGISTRO W A STATUS
    SWAPF   W_TEMP, F		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO F
    SWAPF   W_TEMP, W		; INTERCAMBIAR VARIABLE TEMPORAL DE REGISTRO W CON REGISTRO W
    RETFIE  
  
//----------------------------INT SUBRUTINAS------------------------------------
TMR1_INT:
    TMR1_RESET	0x0B, 0xDC
    INCF    Cont
    MOVF    Cont, W
    SUBLW   2
    BTFSC   ZERO
    GOTO    INC_SEG
    RETURN
    
INC_SEG:
    INCF    Cont_Seg		; INCREMENTAR LA CUENTA DE SEGUNDOS
    INCF    PORTA		; MOSTRAR LA CUENTA DE SEGUNDOS EN PORTA
    CLRF    Cont		; LIMPIAR LA CUENTA DE 500 MILISEGUNDOS   
    RETURN
/*    
TMR2_INT:
    INCF    Cont_T2
    MOVF    Cont_T2, W
    INCF    PORTB
    RETURN */
    
PSECT code, delta=2, abs
ORG 100h			; posición 100h para el codigo    
    
//------------------------------MAIN CONFIG-------------------------------------
main:
    CALL    CLK_CONFIG		; INICIAR CONFIGURACIÓN DE RELOJ
    CALL    IO_CONFIG		; INICIAR CONFIGURACIÓN DE PINES    
    CALL    TMR1_CONFIG
;    CALL    TMR2_CONFIG
    CALL    INT_CONFIG		; INICIAR CONFIGURACION DE INTERRUPCIONES
    BANKSEL PORTA    
    
loop:
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
;    BCF	    TRISB, 0		; BIT0 PORTB COMO SALIDA
    
    BANKSEL PORTA		; SELECCIONAR EL BANCO 0
    CLRF    PORTA		; LIMPIAR EL REGISTRO EN PORTA
;    CLRF    PORTB		; LIMPIAR EL REGISTRO EN PORTC
    RETURN    

TMR1_CONFIG:
    BANKSEL T1CON		;
    BCF	    TMR1GE		;
    BSF	    T1CKPS1		;
    BSF	    T1CKPS0		;
    BCF	    T1OSCEN		;
    BCF	    TMR1CS		;
    BSF	    TMR1ON		;
    
    TMR1_RESET 0x0B, 0xDC
    RETURN
/*    
TMR2_CONFIG:
    BANKSEL PR2			;
    MOVLW   195			;
    MOVWF   PR2			;
    
    BANKSEL T2CON		;
    BSF	    T2CKPS1		;
    BSF	    T2CKPS0
    
    BSF	    TOUTPS3		;
    BSF	    TOUTPS2
    BSF	    TOUTPS1
    BSF	    TOUTPS0
    BSF	    TMR2ON
    RETURN */
    
INT_CONFIG:
    BANKSEL PIE1		;
    BSF	    TMR1IE		;
;    BSF	    TMR2IE		;
    
    BANKSEL INTCON		;
    BSF	    PEIE		;
    BSF	    GIE			;
    BCF	    TMR1IF		;
;    BCF	    TMR2IF
    RETURN
    
END
  
