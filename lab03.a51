#include <at89c5131.h>
#define LED1        P3.6
#define LED2        P3.7
// Transistor externo
#define LED3        P1.4

ORG 0x0000;
CALL MAIN			;

ORG 0x00B			;
timer0_interrupt:
ljmp TIMER_MOTOR_INTERRUPCAO ;

;;;; DEFINICOES DE PORTAS 
SW_SENTIDO      	 EQU P3.0
SW_TIPO_PASSO   	 EQU P3.1
LED_SENTIDO     	 EQU LED1
LED_TIPO_PASSO  	 EQU LED2
LED_PASSO       	 EQU LED3

STEPER				 EQU P2;
;;; DEFINICOES DE VARIAVEIS/CONSTANTES
PASSO_COMPLETO  	 EQU 0x00;
SENTIDO_HORARIO 	 EQU 0x01;
CAN_CHANGE_DIRECTION EQU 0x04;
MOVIMENTO_POSIT 	 EQU R7;//varia de 0 a 7
ESTADO_INTERNO  	 EQU R6;
CONT	 	    	 EQU R3
TIMER_CONTROL		 EQU R2;
;; o estado interno podera ser 
;; 0 :> RODANDO
;; 1 :> ACELERANDO
;; 2 :> DESACELERANDO
ESTADO_RODANDO       EQU 0x00;
ESTADO_ACELERANDO    EQU 0x01;
ESTADO_DESACELERANDO EQU 0x02;

TEMPO_ENTRE_PASSOS 	 EQU R5;
TIMER_MIN			 EQU 0xAF;
TIMER_MAX		 	 EQU 0x09;  
ORG 0100h	
	
PASSO_COMPLETO_DB:
db 0x0C, 0x06, 0x03, 0x09, 0x0C, 0x06, 0x03, 0x09;
db 0x00;

MEIO_PASSO_DB:
db 0x08, 0x0C, 0x04, 0x06, 0x02, 0x03, 0x01, 0x09;
db 0x00;

;;;;;;;;;;;;;;;;; codigo do programa
inicializar:
;;setar LEDS, ENTRADA, SENTIDO INICIAL, TIPO INICIAL
	MOV LEDCON, #0xA0
	SETB PASSO_COMPLETO;
	SETB SENTIDO_HORARIO;
	MOV MOVIMENTO_POSIT, 0x00;
	CLR LED_SENTIDO;
	CLR LED_TIPO_PASSO;
	SETB LED_PASSO;
	CLR CAN_CHANGE_DIRECTION;
;;; timer set
	CLR TR0			; stop timer 0
	CLR TF0			; overflow flag
	MOV TMOD, #0x02		;// timer 0 on mode 2.
	MOV TH0, 0x00	;clear time 0 value.
	MOV DPTR, #PASSO_COMPLETO_DB;
	ORL TCON, #0x02								  
	MOV TH1,#0x00;        /	* init values */
	MOV TH0,#0x00		;
	;; SETB IE0
	//CLR GATE0		;
	SETB ET0		;enable timer 0 interruption
	SETB EA			;enable interruptions
	MOV TIMER_CONTROl, #TIMER_MIN; 
	MOV ESTADO_INTERNO, #ESTADO_ACELERANDO;
	SETB TR0		;timer 0 run
	
RET


	;;;  para trocar de tipo de passo, Alterar o valor do DPTR com MOV DPTR, #TIPO_PASSO_DB;
UPDATE_PASSO:
	
	MOV A, MOVIMENTO_POSIT 	;
	MOVC A, @A+DPTR      ; carrega o estado em A
	;; comando pro motor
	CALL SEND_TO_MOTOR	;

;;; ATUALIZA O PROXIMO ESTADO
	JB SENTIDO_HORARIO, SENT_HORARIO;
SENT_ANTI_HORARIO:	
	DEC MOVIMENTO_POSIT;
	CJNE MOVIMENTO_POSIT, #0xFF, FIM;
	MOV MOVIMENTO_POSIT, #0x07	;
	SJMP FIM;
SENT_HORARIO:
	INC MOVIMENTO_POSIT	;
	CJNE MOVIMENTO_POSIT, #0x08, FIM ;
	MOV MOVIMENTO_POSIT, #0x00	 ;
FIM:	
RET;

UPDATE_ESTADO:
	MOV A, ESTADO_INTERNO;
U_ESTADO_RODANDO: ;nesse estado nao fazer nada
	JNZ U_ESTADO_ACELERANDO;
	MOV A, #TIMER_MAX;
	MOV TIMER_CONTROl, #TIMER_MAX;
	SJMP FIM_UPDATE_ESTADO;
U_ESTADO_ACELERANDO: ;;aumentar o timer ate que esteja com o valor maximo
	CJNE A, #ESTADO_ACELERANDO, U_ESTADO_DESACELERANDO;
	DEC TIMER_CONTROl;
	MOV A, TIMER_CONTROl;
	CJNE A, #TIMER_MAX, FIM_UPDATE_ESTADO;
	MOV ESTADO_INTERNO, #ESTADO_RODANDO;
U_ESTADO_DESACELERANDO:;;decrementar o timer ate que esteja com o valor minimo
	CJNE A, #ESTADO_DESACELERANDO,FIM_UPDATE_ESTADO;
	INC TIMER_CONTROl;
	MOV A, TIMER_CONTROl
	CJNE A, #TIMER_MIN, FIM_UPDATE_ESTADO;
	MOV ESTADO_INTERNO, #ESTADO_ACELERANDO;
	CPL SENTIDO_HORARIO; muda o sentido
 	CPL LED_SENTIDO;
FIM_UPDATE_ESTADO:
	
	MOV	CONT, A;
RET;

																				 
TIMER_MOTOR_INTERRUPCAO:
	CLR TR0
	DJNZ CONT, FIM_TIMER_MOTOR_INTERRUPCAO;
	CPL LED_PASSO;
	ACALL UPDATE_PASSO;
	ACALL UPDATE_ESTADO;
FIM_TIMER_MOTOR_INTERRUPCAO:
	SETB TR0;
RETI	

SEND_TO_MOTOR:
  MOV STEPER, A;
FIM_SEND_TO_MOTOR:	
RET		

ler_chaves:
	JNB SW_SENTIDO, CHK_TIPO_PASSO;
	MOV ESTADO_INTERNO, #ESTADO_DESACELERANDO;
CHK_TIPO_PASSO:
    JNB SW_TIPO_PASSO, CHCK_TIPO_PASSO_SEND; 
	SETB CAN_CHANGE_DIRECTION;
	SJMP FIM_LER_CHAVES;
CHCK_TIPO_PASSO_SEND:
	JNB CAN_CHANGE_DIRECTION, FIM_LER_CHAVES;	
	CLR CAN_CHANGE_DIRECTION;
	CPL PASSO_COMPLETO;
	CPL LED_TIPO_PASSO;
	MOV DPTR, #PASSO_COMPLETO_DB;
	JB PASSO_COMPLETO, FIM_LER_CHAVES;
	MOV DPTR, #MEIO_PASSO_DB;
FIM_LER_CHAVES:
RET;																			 
	
main:
	CALL inicializar;
loop:
 	CALL ler_chaves;
	SJMP loop;
END;
