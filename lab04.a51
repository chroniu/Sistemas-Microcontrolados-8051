#include <at89c5131.h>

; defines e constantes
// Driver interno de corrente. deve ser configurado via LEDCON
#define LED1        P3.6
#define LED2        P3.7
#define LED3        P1.4

FREQUENCIA  EQU R7;
AMPLITUDE   EQU R6;
POSITION    EQU R5;
TIMER_HIGH  EQU R4;
TIMER_LOW   EQU R3;

WAVE_OUTPUT EQU P2;

BUFFER		EQU R2
WAVE_NUMBER EQU R1;
	
ORG 0x0000;
CALL MAIN			;

ORG 0x00B			;
timer0_interrupt:
ljmp TIMER_WAVE_INTERRUPCAO ;

ORG 0x001B
timer1_interrupt:
ljmp TIMER_WAVE_INTERRUPCAO;


TIMER_WAVE_INTERRUPCAO:
;; primeiro manda o sinal.
;; atualiza a posi�ao
	;CPL LED3
	MOV TH0, TIMER_HIGH;
	MOV TL0, TIMER_LOW;
	MOV A, POSITION 	;
;	JNB WAVE_IS_SINE,STEP_OVER;
	MOVC A, @A+DPTR      ; carrega o estado em A
	;5instru��es
	
;	STEP_OVER:
	;; manda a onda pra porta
;	WAVE_1_25_V:
;	CJNE AMPLITUDE, #0x02, WAVE_2_5_V;
;	CLR C;
;	RR A;
	;CLR C
;	RR A;
;	SJMP FIM_UPDATE_WAVE_STATE; 
;WAVE_2_5_V:
;	CJNE AMPLITUDE, #0x01, WAVE_5_V;
;	RR A;
;	SJMP FIM_UPDATE_WAVE_STATE;
;WAVE_5_V:
;;FIM_UPDATE_WAVE_STATE:
	MOV WAVE_OUTPUT, A;
	
;;; ATUALIZA O PROXIMO ESTADO
	INC POSITION;
	;MOV P1, POSITION;
	CJNE POSITION, #0xC8, FIM_TIMER_WAVE_INTERRUPCAO;
	MOV POSITION, #0x00;
FIM_TIMER_WAVE_INTERRUPCAO:
RETI

;; muda a frequencia de acordo com o registrador FREQUENCIA.
CHANGE_FREQUENCY:
	CLR TR0			; stop timer 0
	CLR TF0			; overflow flag
FREQ_25:
	CJNE FREQUENCIA, #0x00, FREQ_50;	   ;; 65030
	mov TIMER_HIGH, #0xFE; 
	mov TIMER_LOW, #0x70;
	SJMP FIM_CHANGE_FREQUENCY;
FREQ_50:
	CJNE FREQUENCIA, #0x01, FREQ_100;	   65335
	mov TIMER_HIGH, #0FFh ; 
	mov TIMER_LOW, #037h
	SJMP FIM_CHANGE_FREQUENCY;
FREQ_100:
	CJNE FREQUENCIA, #0x02, FREQ_200; 65436
	mov TIMER_HIGH, #0xFF ; 
	mov TIMER_LOW, #0xA3
	SJMP FIM_CHANGE_FREQUENCY;
FREQ_200:
	CJNE FREQUENCIA, #0x03, FREQ_400;	65485
	mov TIMER_HIGH, #0xFF ; 
	mov TIMER_LOW, #0xD7
	SJMP FIM_CHANGE_FREQUENCY;		 
FREQ_400:
	mov TIMER_HIGH, #0xFF ; 	65510
	mov TIMER_LOW, #0xF0
FIM_CHANGE_FREQUENCY:				 
	CLR TF0			; overflow flag 
	SETB TR0; ; inicializa o timer 0 de novo
	
RET;


initialize:

    MOV LEDCON, #0xA0; // liga os leds
	SETB LED1;
	SETB LED2;
	SETB LED3;
	;; seta o estado inicial conforme o especificado
	MOV WAVE_NUMBER, #0x00
	MOV FREQUENCIA, #0x02; frequencia inical em 100 HZ
	MOV AMPLITUDE,  #0x01; amplitude inicial em 2,5V.

	MOV DPTR, #SINE_WAVE_2_5_DB;						  
	MOV POSITION, #0x00;


	MOV TMOD, #0x21 ; Timer 1 no modo 2, timer 0 no modo 1
	MOV TH1, #243  ; seta timer1 para baud rate 9600 
	SETB TR1
	MOV PCON,#0x80	  	  ;serial modo 1
	MOV SCON,#0x50		 ;habilita SM1 (coloca o serial para seguir o timer1) 
	
	CALL CHANGE_FREQUENCY;
	SETB TR0
	SETB ET0		;enable timer 0 interruption
	SETB EA			;enable interruptions	
RET;	

TIMER_SERIAL_INTERRUPT:

RETI;


UPDATE_WAVE_AMPLITUDE:
AMP_5_V:
	CJNE AMPLITUDE, #0x02, AMP_2_5_V
	SINE_WAVE_5:
		CJNE WAVE_NUMBER, #0x00, TRIANGLE_WAVE_5; 
		MOV DPTR, #SINE_WAVE_5_DB;
		SJMP  FIM_UP_WAVE;
	TRIANGLE_WAVE_5:
		CJNE WAVE_NUMBER, #0x01, SQUARE_WAVE_5; 
		MOV DPTR, #TRIANGLE_WAVE_5_DB;
		SJMP  FIM_UP_WAVE;
	SQUARE_WAVE_5:
		MOV DPTR, #SQUARE_WAVE_5_DB;
		SJMP  FIM_UP_WAVE;
AMP_2_5_V:
	CJNE AMPLITUDE, #0x01, AMP_1_5_V
	SINE_WAVE_2_5:
		CJNE WAVE_NUMBER, #0x00, TRIANGLE_WAVE_2_5; 
		MOV DPTR, #SINE_WAVE_2_5_DB;
		SJMP  FIM_UP_WAVE;
	TRIANGLE_WAVE_2_5:
		CJNE WAVE_NUMBER, #0x01, SQUARE_WAVE_2_5; 
		MOV DPTR, #TRIANGLE_WAVE_2_5_DB;
		SJMP  FIM_UP_WAVE;
	SQUARE_WAVE_2_5:
		MOV DPTR, #SQUARE_WAVE_2_5_DB;
		SJMP  FIM_UP_WAVE;

AMP_1_5_V:
 	SINE_WAVE_1_5:
		CJNE WAVE_NUMBER, #0x00, TRIANGLE_WAVE_1_5; 
		MOV DPTR, #SINE_WAVE_1_5_DB;
		SJMP  FIM_UP_WAVE;
	TRIANGLE_WAVE_1_5:
		CJNE WAVE_NUMBER, #0x01, SQUARE_WAVE_1_5; 
		MOV DPTR, #TRIANGLE_WAVE_1_5_DB;
		SJMP  FIM_UP_WAVE;
		
	SQUARE_WAVE_1_5:
		MOV DPTR, #SQUARE_WAVE_1_5_DB;
		SJMP  FIM_UP_WAVE;
FIM_UP_WAVE:
RET

										    
TRATAR_BYTE:
TECLA_SETA_CIMA:		 //aumenta amplitude.
	CJNE BUFFER, #'B', TECLA_SETA_BAIXO;
	CPL LED1;
	MOV A, AMPLITUDE;
	JZ CONTI_SETA_CIMA;
    DEC AMPLITUDE;		
	CONTI_SETA_CIMA:
	ACALL UPDATE_WAVE_AMPLITUDE
	SJMP  FIM_TRATAR_BYTE;
TECLA_SETA_BAIXO:		  /// diminui amplitude
	CJNE BUFFER, #'A', TECLA_SETA_DIREITA;	
	CPL LED1;
	INC  AMPLITUDE;
	CJNE AMPLITUDE, #0x03, CONTI_SETA_BAIXO;
	DEC AMPLITUDE;
	CONTI_SETA_BAIXO:
	ACALL UPDATE_WAVE_AMPLITUDE
	SJMP  FIM_TRATAR_BYTE;

TECLA_SETA_DIREITA:			//aumenta frequencia
	CJNE BUFFER, #'C', TECLA_SETA_ESQUERDA;	
	CPL LED2;
	MOV A, FREQUENCIA;
	ANL A, #0x04;
	JNZ FIM_TRATAR_BYTE;
	INC  FREQUENCIA;
	CALL CHANGE_FREQUENCY;
	SJMP  FIM_TRATAR_BYTE;
TECLA_SETA_ESQUERDA:       //diminui frequencia
	CJNE BUFFER, #'D', TECLA_F;	
	CPL LED2;
	MOV A, FREQUENCIA;
	JZ FIM_TRATAR_BYTE;
	DEC FREQUENCIA;
	CALL CHANGE_FREQUENCY;
	SJMP  FIM_TRATAR_BYTE;
TECLA_F:
	CJNE BUFFER, #'F', FIM_TRATAR_BYTE;	
	CPL LED2; 
	INC WAVE_NUMBER;
	CJNE WAVE_NUMBER, #0x03, CONTI
	MOV WAVE_NUMBER, #0x00
	CONTI:
	ACALL UPDATE_WAVE_AMPLITUDE;
FIM_TRATAR_BYTE:
 
RET;
	
receive_byte:
	JNB		RI, $	;espera receber
	CLR		RI
	MOV		A, SBUF
	MOV 	BUFFER, A 
	CALL TRATAR_BYTE;
	MOV BUFFER, #0x00;
	RET

MAIN: 
	CALL initialize;
loop:
	CALL receive_byte;
	SJMP loop;
 
 
 SINE_WAVE_5_DB:
db 0x80, 0x84, 0x88, 0x8b, 0x8f, 0x93, 0x97, 0x9b, 0x9f, 0xa3, 0xa7, 0xab, 0xae
db 0xb2, 0xb6, 0xb9, 0xbd, 0xc0, 0xc4, 0xc7, 0xca, 0xce, 0xd1, 0xd4, 0xd7, 0xda
db 0xdc, 0xdf, 0xe2, 0xe4, 0xe7, 0xe9, 0xeb, 0xed, 0xef, 0xf1, 0xf3, 0xf5, 0xf6
db 0xf7, 0xf9, 0xfa, 0xfb, 0xfc, 0xfd, 0xfd, 0xfe, 0xfe, 0xff, 0xff, 0xff, 0xff
db 0xff, 0xfe, 0xfe, 0xfd, 0xfd, 0xfc, 0xfb, 0xfa, 0xf9, 0xf7, 0xf6, 0xf5, 0xf3
db 0xf1, 0xef, 0xed, 0xeb, 0xe9, 0xe7, 0xe4, 0xe2, 0xdf, 0xdc, 0xda, 0xd7, 0xd4
db 0xd1, 0xce, 0xca, 0xc7, 0xc4, 0xc0, 0xbd, 0xb9, 0xb6, 0xb2, 0xae, 0xab, 0xa7
db 0xa3, 0x9f, 0x9b, 0x97, 0x93, 0x8f, 0x8b, 0x88, 0x84, 0x80, 0x7b, 0x77, 0x74
db 0x70, 0x6c, 0x68, 0x64, 0x60, 0x5c, 0x58, 0x54, 0x51, 0x4d, 0x49, 0x46, 0x42
db 0x3f, 0x3b, 0x38, 0x35, 0x31, 0x2e, 0x2b, 0x28, 0x25, 0x23, 0x20, 0x1d, 0x1b
db 0x18, 0x16, 0x14, 0x12, 0x10, 0x0e, 0x0c, 0x0a, 0x09, 0x08, 0x06, 0x05, 0x04
db 0x03, 0x02, 0x02, 0x01, 0x01, 0x00, 0x00, 0x00, 0x00, 0x00, 0x01, 0x01, 0x02
db 0x02, 0x03, 0x04, 0x05, 0x06, 0x08, 0x09, 0x0a, 0x0c, 0x0e, 0x10, 0x12, 0x14
db 0x16, 0x18, 0x1b, 0x1d, 0x20, 0x23, 0x25, 0x28, 0x2b, 0x2e, 0x31, 0x35, 0x38
db 0x3b, 0x3f, 0x42, 0x46, 0x49, 0x4d, 0x51, 0x54, 0x58, 0x5c, 0x60, 0x64, 0x68
db 0x6c, 0x70, 0x74, 0x77, 0x7b;
db 0x00;

TRIANGLE_WAVE_5_DB:
db 0x03, 0x05, 0x08, 0x0a, 0x0d, 0x0f, 0x12, 0x14, 0x17, 0x1a, 0x1c, 0x1f, 0x21
db 0x24, 0x26, 0x29, 0x2b, 0x2e, 0x30, 0x33, 0x36, 0x38, 0x3b, 0x3d, 0x40, 0x42 
db 0x45, 0x47, 0x4a, 0x4d, 0x4f, 0x52, 0x54, 0x57, 0x59, 0x5c, 0x5e, 0x61, 0x63
db 0x66, 0x69, 0x6b, 0x6e, 0x70, 0x73, 0x75, 0x78, 0x7a, 0x7d, 0x80, 0x82, 0x85
db 0x87, 0x8a, 0x8c, 0x8f, 0x91, 0x94, 0x96, 0x99, 0x9c, 0x9e, 0xa1, 0xa3, 0xa6
db 0xa8, 0xab, 0xad, 0xb0, 0xb3, 0xb5, 0xb8, 0xba, 0xbd, 0xbf, 0xc2, 0xc4, 0xc7 
db 0xc9, 0xcc, 0xcf, 0xd1, 0xd4, 0xd6, 0xd9, 0xdb, 0xde, 0xe0, 0xe3, 0xe6, 0xe8 
db 0xeb, 0xed, 0xf0, 0xf2, 0xf5, 0xf7, 0xfa, 0xfc, 0xff, 0xfc, 0xfa, 0xf7, 0xf5 
db 0xf2, 0xf0, 0xed, 0xeb, 0xe8, 0xe6, 0xe3, 0xe0, 0xde, 0xdb, 0xd9, 0xd6, 0xd4 
db 0xd1, 0xcf, 0xcc, 0xc9, 0xc7, 0xc4, 0xc2, 0xbf, 0xbd, 0xba, 0xb8, 0xb5, 0xb3 
db 0xb0, 0xad, 0xab, 0xa8, 0xa6, 0xa3, 0xa1, 0x9e, 0x9c, 0x99, 0x96, 0x94, 0x91 
db 0x8f, 0x8c, 0x8a, 0x87, 0x85, 0x82, 0x80, 0x7d, 0x7a, 0x78, 0x75, 0x73, 0x70
db 0x6e, 0x6b, 0x69, 0x66, 0x63, 0x61, 0x5e, 0x5c, 0x59, 0x57, 0x54, 0x52, 0x4f 
db 0x4d, 0x4a, 0x47, 0x45, 0x42, 0x40, 0x3d, 0x3b, 0x38, 0x36, 0x33, 0x30, 0x2e 
db 0x2b, 0x29, 0x26, 0x24, 0x21, 0x1f, 0x1c, 0x1a, 0x17, 0x14, 0x12, 0x0f, 0x0d 
db 0x0a, 0x08, 0x05, 0x03, 0x00
db 0x00;
	
SQUARE_WAVE_5_DB:
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff 
db 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0xff, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00;


SINE_WAVE_2_5_DB:
db 0x40,0x41,0x43,0x45,0x47,0x49,0x4b,0x4d,0x4f,0x51
db 0x53,0x55,0x57,0x59,0x5b,0x5c,0x5e,0x60,0x62,0x63
db 0x65,0x66,0x68,0x69,0x6b,0x6c,0x6e,0x6f,0x70,0x72
db 0x73,0x74,0x75,0x76,0x77,0x78,0x79,0x7a,0x7b,0x7b
db 0x7c,0x7c,0x7d,0x7d,0x7e,0x7e,0x7e,0x7f,0x7f,0x7f
db 0x7f,0x7f,0x7f,0x7f,0x7e,0x7e,0x7e,0x7d,0x7d,0x7c
db 0x7c,0x7b,0x7b,0x7a,0x79,0x78,0x77,0x76,0x75,0x74
db 0x73,0x72,0x70,0x6f,0x6e,0x6c,0x6b,0x69,0x68,0x66
db 0x65,0x63,0x62,0x60,0x5e,0x5c,0x5b,0x59,0x57,0x55
db 0x53,0x51,0x4f,0x4d,0x4b,0x49,0x47,0x45,0x43,0x41
db 0x40,0x3e,0x3c,0x3a,0x38,0x36,0x34,0x32,0x30,0x2e
db 0x2c,0x2a,0x28,0x26,0x24,0x23,0x21,0x1f,0x1d,0x1c
db 0x1a,0x19,0x17,0x16,0x14,0x13,0x11,0x10,0xf,0xd
db 0xc,0xb,0xa,0x9,0x8,0x7,0x6,0x5,0x4,0x4
db 0x3,0x3,0x2,0x2,0x1,0x1,0x1,0x0,0x0,0x0
db 0x0,0x0,0x0,0x0,0x1,0x1,0x1,0x2,0x2,0x3
db 0x3,0x4,0x4,0x5,0x6,0x7,0x8,0x9,0xa,0xb
db 0xc,0xd,0xf,0x10,0x11,0x13,0x14,0x16,0x17,0x19
db 0x1a,0x1c,0x1d,0x1f,0x21,0x23,0x24,0x26,0x28,0x2a
db 0x2c,0x2e,0x30,0x32,0x34,0x36,0x38,0x3a,0x3c,0x3e


SINE_WAVE_1_5_DB:
db 0x20,0x21,0x22,0x23,0x24,0x25,0x26,0x27,0x28,0x29
db 0x2a,0x2b,0x2c,0x2d,0x2e,0x2f,0x2f,0x30,0x31,0x32
db 0x33,0x34,0x34,0x35,0x36,0x37,0x37,0x38,0x39,0x39
db 0x3a,0x3a,0x3b,0x3c,0x3c,0x3d,0x3d,0x3d,0x3e,0x3e
db 0x3e,0x3f,0x3f,0x3f,0x3f,0x40,0x40,0x40,0x40,0x40
db 0x40,0x40,0x40,0x40,0x40,0x40,0x3f,0x3f,0x3f,0x3f
db 0x3e,0x3e,0x3e,0x3d,0x3d,0x3d,0x3c,0x3c,0x3b,0x3a
db 0x3a,0x39,0x39,0x38,0x37,0x37,0x36,0x35,0x34,0x34
db 0x33,0x32,0x31,0x30,0x2f,0x2f,0x2e,0x2d,0x2c,0x2b
db 0x2a,0x29,0x28,0x27,0x26,0x25,0x24,0x23,0x22,0x21
db 0x20,0x1f,0x1e,0x1d,0x1c,0x1b,0x1a,0x19,0x18,0x17
db 0x16,0x15,0x14,0x13,0x12,0x11,0x11,0x10,0xf,0xe
db 0xd,0xc,0xc,0xb,0xa,0x9,0x9,0x8,0x7,0x7
db 0x6,0x6,0x5,0x4,0x4,0x3,0x3,0x3,0x2,0x2
db 0x2,0x1,0x1,0x1,0x1,0x0,0x0,0x0,0x0,0x0
db 0x0,0x0,0x0,0x0,0x0,0x0,0x1,0x1,0x1,0x1
db 0x2,0x2,0x2,0x3,0x3,0x3,0x4,0x4,0x5,0x6
db 0x6,0x7,0x7,0x8,0x9,0x9,0xa,0xb,0xc,0xc
db 0xd,0xe,0xf,0x10,0x11,0x11,0x12,0x13,0x14,0x15
db 0x16,0x17,0x18,0x19,0x1a,0x1b,0x1c,0x1d,0x1e,0x1f


TRIANGLE_WAVE_2_5_DB:
db 0x1,0x3,0x4,0x5,0x6,0x8,0x9,0xa,0xb,0xd
db 0xe,0xf,0x11,0x12,0x13,0x14,0x16,0x17,0x18,0x19
db 0x1b,0x1c,0x1d,0x1e,0x20,0x21,0x22,0x24,0x25,0x26
db 0x27,0x29,0x2a,0x2b,0x2c,0x2e,0x2f,0x30,0x32,0x33
db 0x34,0x35,0x37,0x38,0x39,0x3a,0x3c,0x3d,0x3e,0x40
db 0x41,0x42,0x43,0x45,0x46,0x47,0x48,0x4a,0x4b,0x4c
db 0x4d,0x4f,0x50,0x51,0x53,0x54,0x55,0x56,0x58,0x59
db 0x5a,0x5b,0x5d,0x5e,0x5f,0x61,0x62,0x63,0x64,0x66
db 0x67,0x68,0x69,0x6b,0x6c,0x6d,0x6e,0x70,0x71,0x72
db 0x74,0x75,0x76,0x77,0x79,0x7a,0x7b,0x7c,0x7e,0x7f
db 0x7e,0x7c,0x7b,0x7a,0x79,0x77,0x76,0x75,0x74,0x72
db 0x71,0x70,0x6e,0x6d,0x6c,0x6b,0x69,0x68,0x67,0x66
db 0x64,0x63,0x62,0x61,0x5f,0x5e,0x5d,0x5b,0x5a,0x59
db 0x58,0x56,0x55,0x54,0x53,0x51,0x50,0x4f,0x4d,0x4c
db 0x4b,0x4a,0x48,0x47,0x46,0x45,0x43,0x42,0x41,0x40
db 0x3e,0x3d,0x3c,0x3a,0x39,0x38,0x37,0x35,0x34,0x33
db 0x32,0x30,0x2f,0x2e,0x2c,0x2b,0x2a,0x29,0x27,0x26
db 0x25,0x24,0x22,0x21,0x20,0x1e,0x1d,0x1c,0x1b,0x19
db 0x18,0x17,0x16,0x14,0x13,0x12,0x11,0xf,0xe,0xd
db 0xb,0xa,0x9,0x8,0x6,0x5,0x4,0x3,0x1,0x0

TRIANGLE_WAVE_1_5_DB:
db 0x1,0x1,0x2,0x3,0x3,0x4,0x4,0x5,0x6,0x6
db 0x7,0x8,0x8,0x9,0xa,0xa,0xb,0xc,0xc,0xd
db 0xd,0xe,0xf,0xf,0x10,0x11,0x11,0x12,0x13,0x13
db 0x14,0x14,0x15,0x16,0x16,0x17,0x18,0x18,0x19,0x1a
db 0x1a,0x1b,0x1c,0x1c,0x1d,0x1d,0x1e,0x1f,0x1f,0x20
db 0x21,0x21,0x22,0x23,0x23,0x24,0x24,0x25,0x26,0x26
db 0x27,0x28,0x28,0x29,0x2a,0x2a,0x2b,0x2c,0x2c,0x2d
db 0x2d,0x2e,0x2f,0x2f,0x30,0x31,0x31,0x32,0x33,0x33
db 0x34,0x34,0x35,0x36,0x36,0x37,0x38,0x38,0x39,0x3a
db 0x3a,0x3b,0x3c,0x3c,0x3d,0x3d,0x3e,0x3f,0x3f,0x40
db 0x3f,0x3f,0x3e,0x3d,0x3d,0x3c,0x3c,0x3b,0x3a,0x3a
db 0x39,0x38,0x38,0x37,0x36,0x36,0x35,0x34,0x34,0x33
db 0x33,0x32,0x31,0x31,0x30,0x2f,0x2f,0x2e,0x2d,0x2d
db 0x2c,0x2c,0x2b,0x2a,0x2a,0x29,0x28,0x28,0x27,0x26
db 0x26,0x25,0x24,0x24,0x23,0x23,0x22,0x21,0x21,0x20
db 0x1f,0x1f,0x1e,0x1d,0x1d,0x1c,0x1c,0x1b,0x1a,0x1a
db 0x19,0x18,0x18,0x17,0x16,0x16,0x15,0x14,0x14,0x13
db 0x13,0x12,0x11,0x11,0x10,0xf,0xf,0xe,0xd,0xd
db 0xc,0xc,0xb,0xa,0xa,0x9,0x8,0x8,0x7,0x6
db 0x6,0x5,0x4,0x4,0x3,0x3,0x2,0x1,0x1,0x0
	
SQUARE_WAVE_2_5_DB:
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f 
db 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x7f, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00;

SQUARE_WAVE_1_5_DB:
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40 
db 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x40, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00 
db 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00, 0x00, 0x00, 0x00, 0x00
db 0x00;
 
END
